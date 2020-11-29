module utility;

import std.stdio;
import std.format;
import std.conv;
import std.math;
import std.random;

import vec3;

// Constants
const double infinity = double.infinity;
const double pi = 3.1415926535897932385;

// Utility Functions
void write_color(Color pixel_color, int samples_per_pixel, File file)
{
    //get x,y,z color from the pixel
    auto r = pixel_color.x();
    auto g = pixel_color.y();
    auto b = pixel_color.z();

    // Divide the color by the number of samples and gamma-correct for gamma=2.0.
    auto scale = 1.0 / samples_per_pixel;
    r = sqrt(scale * r);
    g = sqrt(scale * g);
    b = sqrt(scale * b);

    //cast to 8bit per pixel for ppm format
    auto ir = castFrom!double.to!int(256 * clamp(r, 0.0, 0.999));
    auto ig = castFrom!double.to!int(256 * clamp(g, 0.0, 0.999));
    auto ib = castFrom!double.to!int(256 * clamp(b, 0.0, 0.999));

    //write the pixel data to file
    file.writeln(format("%s %s %s", ir, ig, ib));
}

double degrees_to_radians(double degrees)
{
    return degrees * pi / 180.0;
}

double clamp(double x, double min, double max)
{
    if (x < min)
        return min;
    if (x > max)
        return max;
    return x;
}

double random_double()
{
    Mt19937 gen;
    // Seed with an unpredictable value
    gen.seed(unpredictableSeed);
    auto n = uniform01(gen);
    return n;
}

double random_double(double min, double max)
{
    // Returns a random real in [min,max).
    return min + (max - min) * random_double();
}
