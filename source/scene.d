module scene;

import std.math;

import hittable_list;
import hittable;
import sphere;
import vec3;
import material;
import utility;

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

    for (int a = -11; a < 11; a++)
    {
        for (int b = -11; b < 11; b++)
        {
            const auto choose_mat = 0.7;

            Point3 center = Point3(a + 0.9 * 0.2, 0.2, b + 0.9 * 0.4);

            Material sphere_material;

            center - Point3(4, 0.2, 0);

            int modulus = b % 3;
            int z = cast(int) fabs(cast(real) modulus);
            auto albedo = Color3(0.5, 0.5, 0.5) * Color3(0.5, 0.5, 0.5);
            switch (z)
            {
            case 0:
                center - Point3(4, 0.2, 0); // diffuse

                sphere_material = Lambertian(albedo);
                world.add(Sphere(center, 0.2, sphere_material));
                break;
            case 1:
                center - Point3(4, 0.2, 0); // metal  
                albedo = Color3(0.85, 0.42, 0.14);
                auto fuzz = 0.24;
                sphere_material = Metal(albedo, fuzz);
                world.add(Sphere(center, 0.2, sphere_material));
                break;
            case 2:
                center - Point3(4, 0.2, 0); // glass
                sphere_material = Dielectric(1.5);
                world.add(Sphere(center, 0.2, sphere_material));
                break;
            default:
                break;
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
