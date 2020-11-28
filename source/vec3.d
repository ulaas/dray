import std.stdio;
import std.format;
import std.conv;
import std.array;
import std.math;
import std.meta;
//import hittable;


class Vec3
{
  public:
  double[3] e;

  this()
  {
    e = [0, 0, 0];
  }

  this(double e0, double e1, double e2)
  {
    e = [e0, e1, e2];
  }

  double x() const
  {
    return e[0];
  }

  double y() const
  {
    return e[1];
  }

  double z() const
  {
    return e[2];
  }

  static Vec3 opCall() { return new Vec3(); }

  static Vec3 opCall(double e0, double e1, double e2) { return new Vec3(e0, e1, e2); }

  auto opBinary(string op)(Vec3 v) {
   if (op == "+") 
   {
      return Vec3(this.e[0] + v.e[0], this.e[1] + v.e[1], this.e[2] + v.e[2]);
   }
   if (op == "-") 
   {
      return Vec3(this.e[0] - v.e[0], this.e[1] - v.e[1], this.e[2] - v.e[2]);
   }
   if (op == "*") 
   {
      return Vec3(this.e[0] * v.e[0], this.e[1] * v.e[1], this.e[2] * v.e[2]);
   }
   assert(0);
  }

  auto opUnary(string op) () {
     if (op == "-")
     {
       return Vec3(-e[0], -e[1], -e[2]);
     } 
     assert(0);
  }

  auto opBinary(string op)(double t) {
   if (op == "*") 
   {
      return Vec3(t * this.e[0], t * this.e[1], t *  this.e[2]);
   }
   if (op == "/") 
   {
      return this * (1/t);
   }
   assert(0);
  }


  Vec3 opOpAssign(string op)(Vec3 v)
  {
    if (op == "+=")
    {
      e[0] += v.e[0];
      e[1] += v.e[1];
      e[2] += v.e[2];
      return *this;
    }

    assert(0);
  }

  Vec3 opOpAssign(string op)(double t)
  {
    if (op == "*=")
    {
      e[0] *= t;
      e[1] *= t;
      e[2] *= t;
      return *this;
    }

    assert(0);
  }

  Vec3 opOpAssign(string op)( double t)
  {
    if (op == "/=")
    {
      return *this *= 1/t;
    }

    assert(0);
  }

  double opIndex(int i) const
  {
    return e[i];
  }

   double length() const
  {
    return sqrt(length_squared());
  }

  double length_squared() const
  {
    return e[0] * e[0] + e[1] * e[1] + e[2] * e[2];
  }
}


double dota(Vec3 u, Vec3 v)
{
  return u.e[0] * v.e[0] + u.e[1] * v.e[1] + u.e[2] * v.e[2];
}


Vec3 cross(Vec3 u, Vec3 v) {
   return Vec3(u.e[1] * v.e[2] - u.e[2] * v.e[1],
    u.e[2] * v.e[0] - u.e[0] * v.e[2],
    u.e[0] * v.e[1] - u.e[1] * v.e[0]);
}

Vec3 unit_vector(Vec3 v)
{
  return v / v.length();
}



