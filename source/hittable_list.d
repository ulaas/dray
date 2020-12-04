module hittable_list;

import hittable;
import ray;
import vec3;

class Hittable_List : Hittable
{
    Hittable[] objects;
    this()
    {
    }

    this(Hittable anObject)
    {
        objects ~= anObject;
    }

    static Hittable_List opCall()
    {
        return new Hittable_List();
    }

    static Hittable_List opCall(Hittable anObject)
    {
        return new Hittable_List(anObject);
    }

    void add(Hittable anObject)
    {
        objects ~= anObject;
    }

    ulong spherecount()
    {
        return objects.length;
    }

    override bool hit(Ray r, double t_min, double t_max, Hit_Record rec)
    {
        auto temp_rec = Hit_Record();
        bool hit_anything = false;
        auto closest_so_far = t_max;

        foreach (anObject; objects)
        {

            if (anObject.hit(r, t_min, closest_so_far, temp_rec))
            {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                rec = temp_rec;
            }
        }

        return hit_anything;
    }

}
