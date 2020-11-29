module camera;

import std.math;

import ray;
import vec3;
import utility;

class Camera
{
    Point3 origin;
    Point3 lower_left_corner;
    Vec3 horizontal;
    Vec3 vertical;
    Vec3 u, v, w;
    double lens_radius;

    this(Point3 lookfrom, Point3 lookat, Vec3 vup, double vfov, double aspect_ratio,
            double aperture, double focus_dist)
    {
        const auto theta = degrees_to_radians(vfov);
        const auto h = tan(theta / 2);
        const auto viewport_height = 2.0 * h;
        const auto viewport_width = aspect_ratio * viewport_height;

        w = unit_vector(lookfrom - lookat);
        u = unit_vector(cross(vup, w));
        v = cross(w, u);

        origin = lookfrom;
        horizontal = focus_dist * viewport_width * u;
        vertical = v * focus_dist * viewport_height;
        lower_left_corner = origin - horizontal / 2 - vertical / 2 - w * focus_dist;

        lens_radius = aperture / 2;
    }

    static Camera opCall(Point3 lookfrom, Point3 lookat, Vec3 vup, double vfov,
            double aspect_ratio, double aperture, double focus_dist)
    {
        return new Camera(lookfrom, lookat, vup, vfov, aspect_ratio, aperture, focus_dist);
    }

    Ray get_ray(double s, double t)
    {
        Vec3 rd = random_in_unit_disk() * lens_radius;
        Vec3 offset = u * rd.x() + v * rd.y();

        return Ray(origin + offset, lower_left_corner + horizontal * s + vertical
                * t - origin - offset);

    }

}
