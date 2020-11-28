import std.stdio;
import std.format;
import std.conv;
import std.math;
public import vec3;
public import ray;
public import sphere;
public import hittable;
public import hittable_list;



//alias color = Vec3;
//alias color(Vec3) = Vec3; 

void WriteColor(Vec3 v)
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
    auto rec = hit_record();
    stderr.writef("ALO-LOOP\n");
    stderr.writef("ALO-HIT-%s\n", rec.normal[0]); 

    if (world.hit(r, 0, infinity, rec)) {
      stderr.writef("ALO-4\n"); 
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
  const int image_width = 400;
  const int image_height = castFrom!double.to!int(image_width / aspect_ratio);

stderr.writef("ALO-1\n"); 
  // World
  Hittable_List world = new Hittable_List();

stderr.writef("ALO-2\n"); 
  world.add(Sphere(Vec3(0,0,-1), 0.5));
  world.add(Sphere(Vec3(0,-100.5,-1), 100));

stderr.writef("ALO-3\n"); 


stderr.writef("COUNTTTTTTTTTT= %s", world.spherecount()); 

  // Camera

  auto viewport_height = 2.0;
  auto viewport_width = aspect_ratio * viewport_height;
  auto focal_length = 1.0;

  auto origin = Vec3(0, 0, 0);
  auto horizontal = Vec3(viewport_width, 0, 0);
  auto vertical = Vec3(0, viewport_height, 0);
  auto lower_left_corner = origin - horizontal/2 - vertical/2 - Vec3(0, 0, focal_length);
  
  //Render

  //write header
 writeln(format("%s", "P3"));
 writeln(format("%d %d", image_width, image_height));
 writeln(format("%d", 255));

 //write pixel data
  for (int j = image_height-1; j >= 0; --j) {
    //stderr.writef("Scanlines remain: %d\n", j); 
    for(int i = 0; i < image_width; ++i) {
            auto u = double(i) / (image_width-1);
            auto v = double(j) / (image_height-1);
            Ray r = new Ray(origin, lower_left_corner + horizontal*u + vertical*v - origin);
            Vec3 pixel_color = ray_color(r, world);
            WriteColor(pixel_color);
      
     }
  }
 

//Vec3 test2 = new Vec3(20.0, 12.0, 14.0);
//Vec3 test3 = unit_vector(test2);
//stderr.writef("Test = %s\n", test3[0]); 


stderr.writef("\nDONE!!!!\n"); 
}
