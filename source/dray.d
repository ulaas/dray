import std.stdio;
import std.format;
import std.conv;
import std.math;
import core.thread.osthread;
import core.time;

import vec3;
import ray;
import sphere;
import hittable;
import hittable_list;

void WriteColor(color v)
{
  auto ir = castFrom!double.to!int(255.999 * v.x());
  auto ig = castFrom!double.to!int(255.999 * v.y());
  auto ib = castFrom!double.to!int(255.999 * v.z());
  writeln(format("%s %s %s", ir, ig, ib));
}

// Constants

const double infinity = double.infinity;
const double pi = 3.1415926535897932385;

// Utility Functions
double degrees_to_radians(double degrees) {
    return degrees * pi / 180.0;
}


Vec3 ray_color(Ray r, Hittable world) {
    hit_record rec;

    if (world.hit(r, 0, infinity, rec)) {
        return (rec.normal + Vec3(1,1,1)) * 0.5;
    }

    Vec3 unit_direction = unit_vector(r.direction());
    auto t = (unit_direction.y() + 1.0) * 0.5;
    return Vec3(1.0, 1.0, 1.0) * (1.0-t)  + Vec3(0.5, 0.7, 1.0) * t;
}

void main()
{
  // Image
  const auto aspect_ratio = 16.0 / 9.0;
  const int image_width = 1280;
  const int image_height = castFrom!double.to!int(image_width / aspect_ratio);

  // World
  Hittable_List world = new Hittable_List();

  world.add(Sphere(point3(0,0,-1), 0.5));
  world.add(Sphere(point3(0,-100.5,-1), 100));

  // Camera

  auto viewport_height = 2.0;
  auto viewport_width = aspect_ratio * viewport_height;
  auto focal_length = 1.0;

  auto origin = point3(0, 0, 0);
  auto horizontal = point3(viewport_width, 0, 0);
  auto vertical = point3(0, viewport_height, 0);
  auto lower_left_corner = origin - horizontal/2 - vertical/2 - Vec3(0, 0, focal_length);
  
  //Render

  //write header
 writeln(format("%s", "P3"));
 writeln(format("%d %d", image_width, image_height));
 writeln(format("%d", 255));

 //write pixel data
  for (int j = image_height-1; j >= 0; --j) {
    stderr.writef("Scanlines remain: %d\n", j); 
    for(int i = 0; i < image_width; ++i) {
            auto u = double(i) / (image_width-1);
            auto v = double(j) / (image_height-1);
            Ray r = new Ray(origin, lower_left_corner + horizontal*u + vertical*v - origin);
            color pixel_color = ray_color(r, world);
            WriteColor(pixel_color);
            //Thread.sleep(dur!("msecs")( 5 ));
     }
  }

stderr.writef("\nDONE!!!!\n"); 

}
