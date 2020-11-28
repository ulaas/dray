public import vec3;
public import ray;

class hit_record {
    this() {
        p = Vec3();
        normal = Vec3();
        t = 0.0;
        front_face = false;
    }

    Vec3 p;
    Vec3 normal;
    double t;
    bool front_face;

    static hit_record opCall() { return new hit_record(); }

    void set_face_normal(out Ray r, out Vec3 outward_normal) {
        front_face = dota(r.direction(), outward_normal) < 0;
        normal = front_face ? outward_normal :-outward_normal;
    }
}

abstract class Hittable {
    public:
     this() {}
     bool hit(Ray r, double t_min, double t_max, hit_record rec);
}
