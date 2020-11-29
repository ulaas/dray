module hittable;

import vec3;
import ray;

struct hit_record {
    point3 p = point3();
    Vec3 normal = Vec3();
    double t;
    bool front_face;

    //static hit_record opCall() { return new hit_record(); }

    void set_face_normal(Ray r, Vec3 outward_normal) {
        front_face = dota(r.direction(), outward_normal) < 0;
        normal = front_face ? outward_normal :-outward_normal;
    }
}

abstract class Hittable {
    public:
     this() {}
     bool hit(Ray r, double t_min, double t_max, ref hit_record rec);
}
