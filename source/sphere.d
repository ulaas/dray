module sphere;

import std.math;
import std.algorithm;
import vec3;
import ray;
import hittable;
import material;

class Sphere : Hittable
{
    Point3 center;
    double radius;
    Material mat_ptr;

    this()
    {
    }

    this(Point3 cen, double r, Material m)
    {
        mat_ptr = m;
        center = cen;
        radius = r;
    }

    static Sphere opCall(Point3 cen, double r, Material m)
    {
        return new Sphere(cen, r, m);
    }

    override bool hit(Ray r, double t_min, double t_max, Hit_Record rec)
    {

        Vec3 oc = r.origin() - center;
        const auto a = r.direction().length_squared();
        const auto half_b = dotp(oc, r.direction());
        const auto c = oc.length_squared() - radius * radius;

        auto discriminant = half_b * half_b - a * c;
        if (discriminant < 0)
            return false;
        const auto sqrtd = sqrt(discriminant);

        // Find the nearest root that lies in the acceptable range.
        double root = (-half_b - sqrtd) / a;
        if (root < t_min || t_max < root)
        {
            root = (-half_b + sqrtd) / a;
            if (root < t_min || t_max < root)
                return false;
        }

        rec.t = root;
        rec.p = r.at(rec.t);
        Vec3 outward_normal = (rec.p - center) / radius;
        rec.set_face_normal(r, outward_normal);
        rec.mat_ptr = mat_ptr;

        return true;
    }
}
