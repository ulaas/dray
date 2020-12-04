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
const DEBUG_MSG_worker = false;
const DEBUG_MSG_generic = true;

enum DEBUG_LOG_TYPE
{
    GENERIC,
    WORKER
}

// Utility Functions


// void write_color(int[4] color, ref File file)
// {
//     //write the pixel data to file
//     file.writeln(format("%s %s %s", color[0], color[1], color[2]));
//     //file.flush();
// }

void log_debug_message(string message, DEBUG_LOG_TYPE type)
{
    if (type == DEBUG_LOG_TYPE.GENERIC)
    {
        if (DEBUG_MSG_generic)
        {
        writeln(format("LOG_GENERIC : %s", message ));
        }

    }
    else if (type == DEBUG_LOG_TYPE.WORKER)
    {
        if (DEBUG_MSG_worker)
        {
        writeln(format("LOG_WORKER : %s", message ));
        }

    }
}

// int[4] get_integers_from_color(Color3 pixel_color, int samples_per_pixel)
// {
//     int[4] result;

//     //get x,y,z color from the pixel
//     auto r = pixel_color.x();
//     auto g = pixel_color.y();
//     auto b = pixel_color.z();

//     auto scale = 1.0 / samples_per_pixel;
//     r = sqrt(scale * r);
//     g = sqrt(scale * g);
//     b = sqrt(scale * b);

//     auto ir = castFrom!double.to!int(256 * clamp_it(r, 0.0, 0.999));
//     auto ig = castFrom!double.to!int(256 * clamp_it(g, 0.0, 0.999));
//     auto ib = castFrom!double.to!int(256 * clamp_it(b, 0.0, 0.999));

//     result[0] = ir;
//     result[1] = ig;
//     result[2] = ib;
//     result[3] = 255;

//     return result;
// }

double degrees_to_radians(double degrees)
{
    return degrees * pi / 180.0;
}

double clamp_it(double x, double min, double max)
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
