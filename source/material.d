module material;

import std.math;

import utility;
import hittable;
import ray;
import vec3;

abstract class Material
{
    this()
    {
    }

    bool scatter(ref Ray r_in, ref Hit_Record rec, ref Color attenuation, ref Ray scattered);
}

class Lambertian : Material
{
    Color albedo;

    this(Color a)
    {
        albedo = a;
    }

    static Lambertian opCall(Color a)
    {
        return new Lambertian(a);
    }

    override bool scatter(ref Ray r_in, ref Hit_Record rec, ref Color attenuation, ref Ray scattered)
    {
        auto scatter_direction = rec.normal + random_unit_vector();

        // Catch degenerate scatter direction
        if (scatter_direction.near_zero())
            scatter_direction = rec.normal;

        scattered = Ray(rec.p, scatter_direction);
        attenuation = albedo;
        return true;
    }

}

class Metal : Material
{
    Color albedo;
    double fuzz;

    this(Color a, double f)
    {
        albedo = a;
        fuzz = (f < 1) ? f : 1;
    }

    static Metal opCall(Color a, double f)
    {
        return new Metal(a, f);
    }

    override bool scatter(ref Ray r_in, ref Hit_Record rec, ref Color attenuation, ref Ray scattered)
    {
        Vec3 reflected = reflect(unit_vector(r_in.direction()), rec.normal);
        scattered = Ray(rec.p, reflected + random_in_unit_sphere() * fuzz);
        attenuation = albedo;
        return (dotp(scattered.direction(), rec.normal) > 0);
    }
}

class Dielectric : Material
{
    double ir;

    this(double index_of_refraction)
    {
        ir = index_of_refraction;
    }

    static Dielectric opCall(double index_of_refraction)
    {
        return new Dielectric(index_of_refraction);
    }

    override bool scatter(ref Ray r_in, ref Hit_Record rec, ref Color attenuation, ref Ray scattered)
    {
        attenuation = Color(1.0, 1.0, 1.0);
        const double refraction_ratio = rec.front_face ? (1.0 / ir) : ir;

        Vec3 unit_direction = unit_vector(r_in.direction());

        const double cos_theta = fmin(dotp(-unit_direction, rec.normal), 1.0);
        const double sin_theta = sqrt(1.0 - cos_theta * cos_theta);

        const bool cannot_refract = refraction_ratio * sin_theta > 1.0;
        Vec3 direction;

        if (cannot_refract || reflectance(cos_theta, refraction_ratio) > random_double())
            direction = reflect(unit_direction, rec.normal);
        else
            direction = refract(unit_direction, rec.normal, refraction_ratio);

        scattered = Ray(rec.p, direction);
        return true;
    }

    static double reflectance(double cosine, double ref_idx)
    {
        // Use Schlick's approximation for reflectance.
        auto r0 = (1 - ref_idx) / (1 + ref_idx);
        r0 = r0 * r0;
        return r0 + (1 - r0) * pow((1 - cosine), 5);
    }

}
