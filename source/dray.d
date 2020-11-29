import std.stdio;
import std.format;
import std.conv;
import std.math;
import core.thread.osthread;
import core.time;

import utility;
import vec3;
import ray;
import sphere;
import hittable;
import hittable_list;
import camera;

Color ray_color(Ray r, Hittable world, int depth)
{
    hit_record rec;

    // If we've exceeded the ray bounce limit, no more light is gathered.
    if (depth <= 0)
        return Color(0, 0, 0);

    if (world.hit(r, 0, infinity, rec))
    {
        Point3 target = rec.p + rec.normal + random_in_unit_sphere();
        return ray_color(Ray(rec.p, target - rec.p), world, depth-1) * 0.5;
    }

    Vec3 unit_direction = unit_vector(r.direction());
    auto t = (unit_direction.y() + 1.0) * 0.5;
    return Vec3(1.0, 1.0, 1.0) * (1.0 - t) + Vec3(0.5, 0.7, 1.0) * t;
}

void main()
{
    // Image
    const auto aspect_ratio = 16.0 / 9.0;
    const int image_width = 200;
    const int image_height = castFrom!double.to!int(image_width / aspect_ratio);
    const int samples_per_pixel = 100;
    const int max_depth = 10;

    // World
    Hittable_List world = new Hittable_List();

    world.add(Sphere(Point3(0, 0, -1), 0.5));
    world.add(Sphere(Point3(0, -100.5, -1), 100));

    // Camera
    Camera cam = new Camera();

    //open file
    File file = File("render.ppm", "w+");

    //Render
    //write header
    file.writeln(format("%s", "P3"));
    file.writeln(format("%d %d", image_width, image_height));
    file.writeln(format("%d", 255));

    //write pixel data
    for (int j = image_height - 1; j >= 0; --j)
    {
        stderr.writef("Scanlines remain: %d\n", j);
        for (int i = 0; i < image_width; ++i)
        {
            Color pixel_color = Color(0, 0, 0);
            for (int s = 0; s < samples_per_pixel; ++s)
            {
                //todo: debug assert
                //stderr.writef("RANDOM: %s\n", random_double());
                auto u = (i + random_double()) / (image_width - 1);
                auto v = (j + random_double()) / (image_height - 1);
                Ray r = cam.get_ray(u, v);
                //todo: += operator overload does not work? WHY???????
                //also mult only works if vec is first argument
                pixel_color = pixel_color + ray_color(r, world, max_depth);
            }
            write_color(pixel_color, samples_per_pixel, file);
        }
    }

    stderr.writef("\nDONE!!!!\n");

}
