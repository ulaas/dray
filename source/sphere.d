import std.math;
import std.algorithm;
public import vec3;
public import ray;
public import hittable;

class Sphere : Hittable{
    this() {}
    this(Vec3 cen, double r) {
        
    center = cen;
    radius = r;
    }

    //static Vec3 opCall() { return new Vec3(); }

    static Sphere opCall(Vec3 cen, double r) { return new Sphere(cen, r); }
    
    override bool hit(Ray r, double t_min, double t_max, hit_record rec)  {

        Vec3 oc = r.origin() - center;
        auto a = r.direction().length_squared();
        auto half_b = dota(oc, r.direction());
        auto c = oc.length_squared() - radius*radius;

        auto discriminant = half_b*half_b - a*c;
        if (discriminant < 0) return false;
        auto sqrtd = sqrt(discriminant);

        // Find the nearest root that lies in the acceptable range.
        auto root = (-half_b - sqrtd) / a;
        if (root < t_min || t_max < root) {
         root = (-half_b + sqrtd) / a;
         if (root < t_min || t_max < root)
             return false;
         }

        rec.t = root;
        rec.p = r.at(rec.t);
        Vec3 outward_normal = (rec.p - center) / radius;
        rec.set_face_normal(r, outward_normal);

        return true;
    }

    public:
        Vec3 center;
        double radius;
}


