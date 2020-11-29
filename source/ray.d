module ray;

import std.stdio;
import std.format;
import std.conv;
import vec3;
import hittable;

class Ray {
        this() {}
        this(point3 origin, Vec3 direction)
        {
            orig = origin;
            dir = direction;
        }

        point3 origin()   { return orig; }
        Vec3 direction()  { return dir; }

        point3 at(double t) {
            return orig + ( dir * t);
        }

        point3 orig;
        Vec3 dir;
}