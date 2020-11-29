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
import material;

Color ray_color(Ray r, Hittable world, int depth)
{
    hit_record rec;

    // If we've exceeded the ray bounce limit, no more light is gathered.
    if (depth <= 0)
        return Color(0, 0, 0);

    if (world.hit(r, 0.001, infinity, rec))
    {
        Ray scattered;
        Color attenuation;
        if (rec.mat_ptr.scatter(r, rec, attenuation, scattered))
            return attenuation * ray_color(scattered, world, depth - 1);
        return Color(0, 0, 0);
    }

    Vec3 unit_direction = unit_vector(r.direction());
    auto t = (unit_direction.y() + 1.0) * 0.5;
    return Vec3(1.0, 1.0, 1.0) * (1.0 - t) + Vec3(0.5, 0.7, 1.0) * t;
}

Hittable_List random_scene()
{
    Hittable_List world = new Hittable_List();

    // World

    auto ground_material = Lambertian(Color(0.5, 0.5, 0.5));
    world.add(Sphere(Point3(0, -1000, 0), 1000, ground_material));

    for (int a = -11; a < 11; a++)
    {
        for (int b = -11; b < 11; b++)
        {
            auto choose_mat = random_double();

            Point3 center = Point3(a + 0.9 * random_double(), 0.2, b + 0.9 * random_double());

            if ((center - Point3(4, 0.2, 0)).length() > 0.9)
            {
                Material sphere_material;
                if (choose_mat < 0.8)
                {
                    // diffuse
                    auto albedo = Color.random() * Color.random();
                    sphere_material = Lambertian(albedo);
                    world.add(Sphere(center, 0.2, sphere_material));
                }
                else if (choose_mat < 0.95)
                {
                    // metal
                    auto albedo = Color.random(0.5, 1);
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
    auto material2 = Lambertian(Color(0.4, 0.2, 0.1));
    world.add(Sphere(Point3(-4, 1, 0), 1.0, material2));
    auto material3 = Metal(Color(0.7, 0.6, 0.5), 0.0);
    world.add(Sphere(Point3(4, 1, 0), 1.0, material3));
    return world;
}

void main()
{
    // Image
    const auto aspect_ratio = 3.0 / 2.0;
    const int image_width = 1200;
    const int image_height = castFrom!double.to!int(image_width / aspect_ratio);
    const int samples_per_pixel = 500;
    const int max_depth = 100;

    //WORLD
    auto world = random_scene();

    /*  2 spheres
auto R = cos(pi / 4); 
    auto material_left = Lambertian(Color(0, 0, 1));
    auto material_right = Lambertian(Color(1, 0, 0));

    world.add(Sphere(Point3(-R, 0, -1), R, material_left));
    world.add(Sphere(Point3(R, 0, -1), R, material_right));
*/

    /*  5 spheres
    auto material_ground = Lambertian(Color(0.8, 0.8, 0.0));
    auto material_center = Lambertian(Color(0.1, 0.2, 0.5));
    auto material_left = Dielectric(1.5);
    auto material_right = Metal(Color(0.8, 0.6, 0.2), 0.0);

    world.add(Sphere(Point3(0.0, -100.5, -1.0), 100.0, material_ground));
    world.add(Sphere(Point3(0.0, 0.0, -1.0), 0.5, material_center));
    world.add(Sphere(Point3(-1.0, 0.0, -1.0), 0.5, material_left));
    world.add(Sphere(Point3(-1.0, 0.0, -1.0), -0.4, material_left));
    world.add(Sphere(Point3(1.0, 0.0, -1.0), 0.5, material_right));
*/
    // Camera
    Point3 lookfrom = Point3(13, 2, 3);
    Point3 lookat = Point3(0, 0, 0);
    Vec3 vup = Vec3(0, 1, 0);
    auto dist_to_focus = 10.0;
    auto aperture = 0.1;

    Camera cam = new Camera(lookfrom, lookat, vup, 20, aspect_ratio, aperture, dist_to_focus);

    //open file
    File file = File("render.ppm", "w+"); //Render
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
                Ray r = cam.get_ray(u, v); //todo: += operator overload does not work? WHY???????
                //also mult only works if vec is first argument
                pixel_color = pixel_color + ray_color(r, world, max_depth);
            }
            write_color(pixel_color, samples_per_pixel, file);
        }
    }

    stderr.writef("\nDONE!!!!\n");
}
