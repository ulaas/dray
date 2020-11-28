import std.stdio;
import std.format;
import std.conv;
public import vec3;
public import hittable;

class Ray {
        this() {}
        this(Vec3 origin, Vec3 direction)
        {
            orig = origin;
            dir = direction;
        }

        Vec3 origin()   { return orig; }
        Vec3 direction()  { return dir; }

        Vec3 at(double t) {
            return orig + ( dir * t);
        }

        Vec3 orig;
        Vec3 dir;
}