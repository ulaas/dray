import std.stdio;
import std.format;
import std.conv;
import std.math;
import core.thread.osthread;
import core.time;
import std.concurrency;
import std.stdio;
import std.datetime;

import utility;
import vec3;
import ray;
import sphere;
import hittable;
import hittable_list;
import camera;
import material;

import arsd.simpledisplay;
import std.conv;

Color3 ray_color(Ray r, Hittable world, int depth)
{
    Hit_Record rec;

    // If we've exceeded the ray bounce limit, no more light is gathered.
    if (depth <= 0)
        return Color3(0, 0, 0);

    if (world.hit(r, 0.001, infinity, rec))
    {
        Ray scattered;
        Color3 attenuation;
        if (rec.mat_ptr.scatter(r, rec, attenuation, scattered))
            return attenuation * ray_color(scattered, world, depth - 1);
        return Color3(0, 0, 0);
    }

    Vec3 unit_direction = unit_vector(r.direction());
    auto t = (unit_direction.y() + 1.0) * 0.5;
    return Vec3(1.0, 1.0, 1.0) * (1.0 - t) + Vec3(0.5, 0.7, 1.0) * t;
}

Hittable_List random_scene()
{
    auto world = Hittable_List();

    // World
    auto ground_material = Lambertian(Color3(0.5, 0.5, 0.5));
    world.add(Sphere(Point3(0, -1000, 0), 1000, ground_material));

    for (int a = -11; a < 11; a++)
    {
        for (int b = -11; b < 11; b++)
        {
            const auto choose_mat = random_double();

            Point3 center = Point3(a + 0.9 * random_double(), 0.2, b + 0.9 * random_double());

            if ((center - Point3(4, 0.2, 0)).length() > 0.9)
            {
                Material sphere_material;
                if (choose_mat < 0.8)
                {
                    // diffuse
                    auto albedo = Color3.random() * Color3.random();
                    sphere_material = Lambertian(albedo);
                    world.add(Sphere(center, 0.2, sphere_material));
                }
                else if (choose_mat < 0.95)
                {
                    // metal
                    auto albedo = Color3.random(0.5, 1);
                    auto fuzz = random_double(0, 0.5);
                    sphere_material = Metal(albedo, fuzz);
                    world.add(Sphere(center, 0.2, sphere_material));
                }
                else
                {
                    // glass
                    sphere_material = Dielectric(1.5);
                    world.add(Sphere(center, 0.2, sphere_material));
                }
            }
        }
    }

    auto material1 = Dielectric(1.5);
    world.add(Sphere(Point3(0, 1, 0), 1.0, material1));
    auto material2 = Lambertian(Color3(0.4, 0.2, 0.1));
    world.add(Sphere(Point3(-4, 1, 0), 1.0, material2));
    auto material3 = Metal(Color3(0.7, 0.6, 0.5), 0.0);
    world.add(Sphere(Point3(4, 1, 0), 1.0, material3));
    return world;
}

Hittable_List static_scene()
{
    auto world = Hittable_List();

    // World
    auto ground_material = Lambertian(Color3(0.5, 0.5, 0.5));
    world.add(Sphere(Point3(0, -1000, 0), 1000, ground_material));

    auto material1 = Dielectric(1.5);
    world.add(Sphere(Point3(0, 1, 0), 1.0, material1));
    auto material2 = Lambertian(Color3(0.4, 0.2, 0.1));
    world.add(Sphere(Point3(-4, 1, 0), 1.0, material2));
    auto material3 = Metal(Color3(0.7, 0.6, 0.5), 0.0);
    world.add(Sphere(Point3(4, 1, 0), 1.0, material3));
    return world;

}

/*
A custom struct that is used as a message
for a little thread army.
*/
struct RenderOrderMessage
{
    int render_width;
    int render_height;
    int h_current_pixel;
    int v_current_pixel;
    int spp;
    double aspect;
    int max_depth;

    this(int rw, int rh, int h, int v, int s, double a, int m)
    {
        this.render_width = rw;
        this.render_height = rh;
        this.h_current_pixel = h;
        this.v_current_pixel = v;
        this.spp = s;
        this.aspect = a;
        this.max_depth = m;
    }
}

struct PixelMessage
{
    int pixel_r;
    int pixel_g;
    int pixel_b;
    int pixel_a;
    int line_h;
    int line_v;

    this(int r, int g, int b, int a, int h, int v)
    {
        this.pixel_r = r;
        this.pixel_g = g;
        this.pixel_b = b;
        this.pixel_a = a;
        this.line_h = h;
        this.line_v = v;
    }
}

/*
Message is used as a stop sign for other
threads
*/
struct CancelMessage
{
}

/// Acknowledge a CancelMessage
struct CancelAckMessage
{
}

/*
The thread worker main
function which gets its parent id
passed as argument.
*/

Tid worker_thread_01;
Tid worker_thread_02;

bool worker_thread_started = false;
//Hittable_List M_world;

static Hittable_List* ptrWorld; // Declare pointer to a class.

// Save the address of first object 

void main()
{
    // Image
    //castFrom!double.to!int(M_image_width / M_aspect_ratio);
    // writeln(format("SETTINGS:  %s %s %s", M_render_settings.samples_per_pixel, 
    //                 M_render_settings.render_width, 
    //                 M_render_settings.render_height 
    //                 ));

    // //open file
    // File file;
    // bool fileopened = false;
    // bool clearbg = false;
    // bool render_in_progress = true;
    const auto aspect_ratio = 16.0 / 9.0;
    const int image_width = 50;
    const int image_height = castFrom!double.to!int(image_width / aspect_ratio);
    const int samples_per_pixel = 40;
    const int max_depth = 40;

    const int v_pixel_count = image_height;
    const int h_pixel_count = image_width;
    int v_current_pixel = 0;
    int h_current_pixel = 0;

    //bool workers_created = false;

    auto window = new SimpleWindow(image_width, image_height, "d-ray",
            OpenGlOptions.no, Resizability.fixedSize, WindowTypes.normal, WindowFlags.normal);

    //void draw_line(Tid worker_thread)
    void draw_line()
    {
        if (v_current_pixel < v_pixel_count)
        {
            if (h_current_pixel < h_pixel_count)
            {
                //Clear window if needed.
                stdout.writef("line:%s pixel: %s\n", v_current_pixel + 1, h_current_pixel + 1);

                const int v_remaining_pixel_count = v_pixel_count - v_current_pixel;
                send(worker_thread_01, RenderOrderMessage(cast(int) image_width, 
                                                        cast(int) image_height,
                                                        cast(int) h_current_pixel, 
                                                        cast(int) v_current_pixel,
                                                        cast(int) samples_per_pixel,
                                                        cast(double) aspect_ratio,
                                                        cast(int) max_depth
                                                        ));
                h_current_pixel++;
            }
            else
            {
                v_current_pixel++;
                h_current_pixel = 0;

            }

            bool received = false;
            received = receiveTimeout(dur!("msecs")(100), (PixelMessage msg) {
                writeln(format("draw line ----   received: r:%s g:%s b:%s h:%s v:%s\n",
                    msg.pixel_r, msg.pixel_g, msg.pixel_b, msg.line_h, msg.line_v));
                auto painter = window.draw();
                painter.outlineColor = Color(msg.pixel_r, msg.pixel_g, msg.pixel_b, 255);
                //Draw pixel to window   
                painter.drawPixel(Point(msg.line_h, image_height - msg.line_v));
            });

            if (!received)
            {
                writeln("... no message yet");
            }
            //Thread.sleep(dur!("seconds")( 1 ));
        }
    }

    void wait()
    {

    }

    window.eventLoop(10, () {

        //Tid worker_thread;
        if (!worker_thread_started)
        {
            worker_thread_started = true;
            worker_thread_01 = spawn(&worker, thisTid, samples_per_pixel);
        }

        draw_line();

    }, delegate(KeyEvent event) { wait(); }, delegate(MouseEvent event) {
        wait();
    }, delegate(dchar ch) { wait(); });

    /*
    // And all threads get the cancel message!
    foreach(ref tid; threads) {
        send(tid, CancelMessage());
    }

    // And we wait until all threads have
    // acknowledged their stop request
    foreach(ref tid; threads) {
        receiveOnly!CancelAckMessage;
        writeln("Received CancelAckMessage!");
    }
*/

}

void worker(Tid parentId, int spp)
{
    bool canceled = false;
    writeln("Starting ", thisTid, "...");

    while (true)
    {
        bool received = false;
        received = receiveTimeout(dur!("msecs")(100), (RenderOrderMessage msg) {
            writeln(format("worker ----   received: %s\n", msg.h_current_pixel));
            Color3 pixel_color = renderpixel(msg.render_width, 
                                            msg.render_height,
                                            msg.h_current_pixel, 
                                            msg.v_current_pixel, 
                                            msg.spp, msg.aspect, 
                                            msg.max_depth );

            //get x,y,z color from the pixel
            auto r = pixel_color.x();
            auto g = pixel_color.y();
            auto b = pixel_color.z();

            auto scale = 1.0 / spp; //M_render_settings.samples_per_pixel;
            r = sqrt(scale * r);
            g = sqrt(scale * g);
            b = sqrt(scale * b);

            auto ir = castFrom!double.to!int(256 * clamp(r, 0.0, 0.999));
            auto ig = castFrom!double.to!int(256 * clamp(g, 0.0, 0.999));
            auto ib = castFrom!double.to!int(256 * clamp(b, 0.0, 0.999));

            send(parentId, PixelMessage(ir, ig, ib, 255, msg.h_current_pixel, msg.v_current_pixel));
        });

    }
}

Color3 renderpixel(int image_w, int image_h, int pixel_x, int pixel_y, int spp, double aspect, int max_depth)
{
    Hittable_List world = static_scene();
    Color3 pixel_color = Color3(0, 0, 0);
    for (int s = 0; s < spp; ++s)
    {
        auto u = (pixel_x + random_double()) / (image_w - 1);
        auto v = (pixel_y + random_double()) / (image_h - 1);

        Camera cam = Camera(Point3(13, 2, 3), Point3(0, 0, 0), Vec3(0, 1, 0), 20, aspect, 0.1, 10.0);
        Ray r = cam.get_ray(u, v);
        //todo: += operator overload does not work? WHY??????? i have removed it from vec3.d as it was getting awkward.
        pixel_color = pixel_color + ray_color(r, world, max_depth);
    }
    return pixel_color;
}
