module ray;

import std.stdio;
import std.format;
import std.conv;
import vec3;
import hittable;

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
