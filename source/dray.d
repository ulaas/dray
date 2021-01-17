import std.stdio;
import std.format;
import std.conv;
import std.math;
import core.thread.osthread;
import core.time;
import std.concurrency;
import std.stdio;
import std.datetime;
import std.algorithm.comparison;
import std.algorithm.iteration;
import std.parallelism;
import std.container;
import std.range;
import std.typecons;
import std.typetuple;
import std.getopt;

import utility;
import vec3;
import ray;
import sphere;
import hittable;
import hittable_list;
import camera;
import material;
import scene;
import raythreading;

import simpledisplay;

bool worker_threads_started = false;
double aspect_ratio = 1.7777;
int image_width = 200;
int image_height = 200; //
int samples_per_pixel = 5;
int max_depth = 10;
int render_thread_count = 4;
int pixels_per_work_order = 50;
bool dummyrender = false;

void main(string[] args)
{
    auto helpInformation = getopt(args, "width", &image_width, "aspect",
            &aspect_ratio, "threads", &render_thread_count,
            "samples", &samples_per_pixel, "maxdepth", &max_depth, "pixelbundlecount",
            &pixels_per_work_order, "dummyrender", &dummyrender); // enum

    if (helpInformation.helpWanted)
    {
        defaultGetoptPrinter("Some information about the program.", helpInformation.options);
    }

    writeln(dummyrender);

    const MonoTime render_start_time = MonoTime.currTime;

    image_height = castFrom!double.to!int(image_width / aspect_ratio);
    int total_pixels_to_render = image_width * image_height;
    bool render_finished = false;
    bool closed = false;

    log_debug_message(format("Total pixels to render %s", total_pixels_to_render), DEBUG_LOG_TYPE.GENERIC);

    auto window = new SimpleWindow(image_width, image_height, "d-ray",
            OpenGlOptions.no, Resizability.fixedSize, WindowTypes.normal, WindowFlags.normal);

    //the manager for render workers
    auto rmanager = RaytraceWorkerManager();

    //add and spawn n workers 
    for (int i = 1; i <= render_thread_count; i++)
    {
        RaytraceWorker theWorker = RaytraceWorker(to!string(i));
        rmanager.AddWorker(theWorker);
    }
    /*
    create point arrays for workers to render. 
    lets start with something simple like consecutive lines. 
    later we could do it in small rectangle shaped regions.
    */
    foreach (aWorker; rmanager.GetWorkerList())
    {
        aWorker.SetWorker(spawn(&render_worker, thisTid, aWorker.GetId()));
        send(aWorker.GetWorkerTid(), IsWorkerReadyMessage());
    }

    // And we wait until all threads have
    // acknowledged their READY STATUS
    foreach (ref tid; rmanager.threads)
    {
        auto msg = receiveOnly!(WorkerReadyACKMessage);
        log_debug_message(format("Received READY-ACK from worker: %s ", msg),
                DEBUG_LOG_TYPE.GENERIC);
    }

    log_debug_message(format("All workers ready. dispatching pixel arrays to render"),
            DEBUG_LOG_TYPE.GENERIC);

    shared(int)[] position_x = new shared(int)[pixels_per_work_order];
    shared(int)[] position_y = new shared(int)[pixels_per_work_order];

    int cc = 0;
    int bundle_no = 0;
    for (int y = 0; y < image_height; y++)
    {
        for (int x = 0; x < image_width; x++)
        {
            if (cc < pixels_per_work_order)
            {
                position_x[cc] = x;
                position_y[cc] = y;
                cc++;
            }

            if (cc == pixels_per_work_order)
            {
                bundle_no++;
                send(rmanager.GetNextWorker(), RenderOrderMessage(image_width, image_height, samples_per_pixel,
                        aspect_ratio, max_depth, position_x, position_y, dummyrender, bundle_no));
                position_x = new shared(int)[pixels_per_work_order];
                position_y = new shared(int)[pixels_per_work_order];
                cc = 0;
            }
        }
    }

    log_debug_message(format("All bundles sent waiting for draw calls and/or end of rendering"),
            DEBUG_LOG_TYPE.GENERIC);

    void draw_line()
    {

        if (!render_finished)
        {
            bool received = false;
            received = receiveTimeout(dur!("msecs")(10), (RenderResultMessage msg) {

                int bundlesize = cast(int) msg.position_y.length;
                log_debug_message(format("PixelRenderResultMessage received: has a bundle of %s pixels",
                    bundlesize), DEBUG_LOG_TYPE.WORKER);
                total_pixels_to_render -= bundlesize;

                if (total_pixels_to_render > 0)
                {
                    for (int render_cursor = 0; render_cursor < bundlesize; render_cursor++)
                    {
                        auto painter = window.draw();

                        int a = cast(int) msg.pixel_r[render_cursor];
                        int b = cast(int) msg.pixel_g[render_cursor];
                        int c = cast(int) msg.pixel_b[render_cursor];

                        int x = cast(int) msg.position_x[render_cursor];
                        int y = cast(int) msg.position_y[render_cursor];

                        painter.outlineColor = Color(a, b, c, a);
                        //Draw pixel to window 
                        painter.drawPixel(Point(x, image_height - y));

                    }
                }
                else
                {
                    //rendering shall be finished by now. lets send cancel messages to workers and wait for their acks
                    //before shutting dowmn gracefully
                    log_debug_message("Rendering finished", DEBUG_LOG_TYPE.GENERIC);
                    render_finished = true;
                }

            });

            if (!received)
            {
                log_debug_message(format("no render result. idling around"), DEBUG_LOG_TYPE.WORKER);
            }
        }
    }

    void close()
    {
        if (render_finished && !closed)
        {
            foreach (aWorker; rmanager.GetWorkerList())
            {
                log_debug_message(format("Sending cancel message for worker %s",
                        aWorker.GetId()), DEBUG_LOG_TYPE.GENERIC);
                send(aWorker.GetWorkerTid(), CanceRenderMessage());
            }

            closed = true;
            // And we wait until all threads have
            // acknowledged their CANCEL/STOP STATUS
            foreach (ref tid; rmanager.threads)
            {
                receiveOnly!(CancelRenderAckMessage);
                log_debug_message("Received CANCEL-ACK from all workers. Shutting down",
                        DEBUG_LOG_TYPE.GENERIC);
            }

            const MonoTime render_stop_time = MonoTime.currTime;
            const Duration timeElapsed = render_stop_time - render_start_time;
            auto seconds = timeElapsed.total!"seconds";

            log_debug_message(format("Render took %s seconds to complete.",
                    seconds), DEBUG_LOG_TYPE.GENERIC);

            window.close();
        }

    }

    window.eventLoop(5, () { draw_line(); close(); });
}

void render_worker(Tid parentId, string myid)
{
    bool cancelled = false;
    log_debug_message(format("Starting WORKER %s ...", myid), DEBUG_LOG_TYPE.GENERIC);
    int bundles_received = 0;
    while (!cancelled)
    {
        bool received = false;
        received = receiveTimeout(dur!("msecs")(5), (RenderOrderMessage msg) {
            log_debug_message(format("Worker %s ----   received: %s pixels to render. rendering now.",
                myid, msg.position_x.length), DEBUG_LOG_TYPE.WORKER);
            //new render code.
            bundles_received++;
            const int size = to!int(msg.position_x.length);

            shared int[] array_color_r = new shared(int)[size];
            shared int[] array_color_g = new shared(int)[size];
            shared int[] array_color_b = new shared(int)[size];
            shared int[] array_color_a = new shared(int)[size];
            shared int[] array_pos_x = new shared(int)[size];
            shared int[] array_pos_y = new shared(int)[size];

            for (int render_cursor = 0; render_cursor < size; render_cursor++)
            {
                Color3 line_color;
                if (msg.dummy_render)
                {
                    line_color = rdummy(msg.render_width, msg.render_height, msg.position_x[render_cursor],
                        msg.position_y[render_cursor], msg.spp, msg.aspect, msg.max_depth);
                }
                else
                {
                    line_color = renderpixel(msg.render_width, msg.render_height,
                        msg.position_x[render_cursor], msg.position_y[render_cursor],
                        msg.spp, msg.aspect, msg.max_depth);
                }

                auto scale = 1.0 / msg.spp;
                auto r = sqrt(scale * line_color.x());
                auto g = sqrt(scale * line_color.y());
                auto b = sqrt(scale * line_color.z());

                auto ir = castFrom!double.to!int(256 * clamp_it(r, 0.0, 0.999));
                auto ig = castFrom!double.to!int(256 * clamp_it(g, 0.0, 0.999));
                auto ib = castFrom!double.to!int(256 * clamp_it(b, 0.0, 0.999));
                auto ix = cast(int) msg.position_x[render_cursor];
                auto iy = cast(int) msg.position_y[render_cursor];

                array_color_r[render_cursor] = ir;
                array_color_g[render_cursor] = ig;
                array_color_b[render_cursor] = ib;
                array_color_a[render_cursor] = 255;
                array_pos_x[render_cursor] = ix;
                array_pos_y[render_cursor] = iy;
            }

            send(parentId, RenderResultMessage(array_color_r, array_color_g,
                array_color_b, array_color_a, array_pos_x, array_pos_y));

                log_debug_message(format("Worker %s ----   received: bundle no %s",
                myid, msg.bundle_no), DEBUG_LOG_TYPE.WORKER);

        }, (IsWorkerReadyMessage msg) {
            // we are ready lets send back ack
            send(parentId, WorkerReadyACKMessage(myid));
        }, (CanceRenderMessage msg) {
            // we are cancelling lets send back ack
            log_debug_message(format("TID: %s received cancel/stop. shutting down.",
                myid), DEBUG_LOG_TYPE.GENERIC);
            send(parentId, CancelRenderAckMessage());
            cancelled = true;
        });

        if (!received)
        {
            log_debug_message(format("TID: %s worker waiting for messages",
                    myid), DEBUG_LOG_TYPE.WORKER);
        }
    }

    log_debug_message(format("Cancelled WORKER %s ...", myid), DEBUG_LOG_TYPE.GENERIC);
}

Color3 renderpixel(int image_w, int image_h, int pixel_x, int pixel_y, int spp,
        double aspect, int max_depth)
{
    Hittable_List world = static_scene();
    Color3 pixel_color = Color3(0, 0, 0);
    Camera cam = Camera(Point3(13, 2, 3), Point3(0, 0, 0), Vec3(0, 1, 0), 20, aspect, 0.1, 10.0);
    for (int s = 0; s < spp; ++s)
    {
        auto u = (pixel_x + random_double()) / (image_w - 1);
        auto v = (pixel_y + random_double()) / (image_h - 1);

        Ray r = cam.get_ray(u, v);
        //todo: += operator overload does not work? WHY??????? i have removed it from vec3.d as it was getting awkward.
        pixel_color = pixel_color + ray_color(r, world, max_depth);
    }

    return pixel_color;
}

Color3 rdummy(int image_w, int image_h, int pixel_x, int pixel_y, int spp,
        double aspect, int max_depth)
{

    Color3 color = Color3(random_double(), random_double(), random_double());
    return color;
}
