module vec3;

import std.stdio;
import std.format;
import std.conv;
import std.array;
import std.math;
import std.meta;

import utility;

class Vec3
{
public:
    double[3] e;

    this()
    {
        e = [0, 0, 0];
    }

    this(double e0, double e1, double e2)
    {
        e = [e0, e1, e2];
    }

    double x() const
    {
        return e[0];
    }

    double y() const
    {
        return e[1];
    }

    double z() const
    {
        return e[2];
    }

    static Vec3 opCall()
    {
        return new Vec3();
    }

    static Vec3 opCall(double e0, double e1, double e2)
    {
        return new Vec3(e0, e1, e2);
    }

    auto opBinary(string op)(Vec3 v)
    {
        if (op == "+")
        {
            return Vec3(this.e[0] + v.e[0], this.e[1] + v.e[1], this.e[2] + v.e[2]);
        }
        else if (op == "-")
        {
            return Vec3(this.e[0] - v.e[0], this.e[1] - v.e[1], this.e[2] - v.e[2]);
        }
        else if (op == "*")
        {
            return Vec3(this.e[0] * v.e[0], this.e[1] * v.e[1], this.e[2] * v.e[2]);
        }
        assert(0);
    }

    auto opUnary(string op)()
    {
        if (op == "-")
        {
            return Vec3(-e[0], -e[1], -e[2]);
        }
        assert(0);
    }

    auto opBinary(string op)(double t)
    {
        if (op == "*")
        {
            return Vec3(t * this.e[0], t * this.e[1], t * this.e[2]);
        }
        else if (op == "/")
        {
            return this * (1 / t);
        }
        assert(0);
    }

    //operator overload for class being on the right side of the equation. took me ages to find this out. lulz.
    auto opBinaryRight(string op)(double t)
    {        
        if (op == "*")
        {
            return Vec3(t * this.e[0], t * this.e[1], t * this.e[2]);
        }        
        else if (op == "/")
        {
            return (1 / t) * this;
        }       
        assert(0);
    }

    Vec3 opOpAssign(string op)(Vec3 v)
    {    
        if (op == "+")
        {
            return Vec3(this.e[0] + v.e[0], this.e[1] + v.e[1], this.e[2] + v.e[2]);
        }
        assert(0);
    }

    double opIndex(int i) const
    {
        return e[i];
    }

    double length() const
    {
        return sqrt(length_squared());
    }

    double length_squared() const
    {
        return e[0] * e[0] + e[1] * e[1] + e[2] * e[2];
    }

    static Vec3 random()
    {
        return Vec3(random_double(), random_double(), random_double());
    }

    static Vec3 random(double min, double max)
    {
        return Vec3(random_double(min, max), random_double(min, max), random_double(min, max));
    }

    bool near_zero()
    {
        // Return true if the vector is close to zero in all dimensions.
        const auto s = 1e-8;
        return (fabs(e[0]) < s) && (fabs(e[1]) < s) && (fabs(e[2]) < s);
    }
}

double dotp(Vec3 u, Vec3 v)
{
    return u.e[0] * v.e[0] + u.e[1] * v.e[1] + u.e[2] * v.e[2];
}

Vec3 cross(Vec3 u, Vec3 v)
{
    return Vec3(u.e[1] * v.e[2] - u.e[2] * v.e[1], 
                u.e[2] * v.e[0] - u.e[0] * v.e[2],
                u.e[0] * v.e[1] - u.e[1] * v.e[0]);
}

Vec3 unit_vector(Vec3 v)
{
    return v / v.length();
}

Vec3 random_unit_vector()
{
    return unit_vector(random_in_unit_sphere());
}

Vec3 random_in_unit_sphere()
{
    while (true)
    {
        auto p = Vec3.random(-1, 1);
        if (p.length_squared() >= 1)
            continue;
        return p;
    }
}

Vec3 random_in_hemisphere(ref Vec3 normal)
{
    Vec3 in_unit_sphere = random_in_unit_sphere();
    if (dotp(in_unit_sphere, normal) > 0.0) // In the same hemisphere as the normal
        return in_unit_sphere;
    else
        return -in_unit_sphere;
}

Vec3 random_in_unit_disk()
{
    while (true)
    {
        auto p = Vec3(random_double(-1, 1), random_double(-1, 1), 0);
        if (p.length_squared() >= 1)
            continue;
        return p;
    }
}

Vec3 reflect(Vec3 v, Vec3 n)
{
    const double d = 2 * dotp(v, n);
    return v - n * d;
}

Vec3 refract(Vec3 uv, Vec3 n, double etai_over_etat)
{
    const auto cos_theta = fmin(dotp(-uv, n), 1.0);
    Vec3 r_out_perp = (uv + n * cos_theta) * etai_over_etat;
    Vec3 r_out_parallel = n * -sqrt(fabs(1.0 - r_out_perp.length_squared()));
    return r_out_perp + r_out_parallel;
}

alias Point3 = Vec3;
alias Color = Vec3;
