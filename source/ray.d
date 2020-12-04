module ray;

import std.stdio;
import std.format;
import std.conv;
import std.math;


import vec3;
import hittable;
import utility;

class Ray
{
    Point3 orig;
    Vec3 dir;

    this()
    {
    }

    this(Point3 origin, Vec3 direction)
    {
        orig = origin;
        dir = direction;
    }

    static Ray opCall(Point3 origin, Vec3 direction)
    {
        return new Ray(origin, direction);
    }

    Point3 origin()
    {
        return orig;
    }

    Vec3 direction()
    {
        return dir;
    }

    Point3 at(double t)
    {
        return orig + (dir * t);
    }

}

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

