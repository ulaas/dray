#Ray Tracing in One Weekend with -D-

And attempt to convert "The Ray Tracing in One Weekend" to D-lang 
original tutorial/book/books can be found at https://github.com/RayTracing/raytracing.github.io/. Great work and read!!
the code is currently identical to what is offered at the original c++ implementation however the aim for me is to learn d so i will work on morphing this into a multi-threaded / interactive raytracer for fun. loading 3d models would be super cool also.

REQUIREMENTS
a working dmd/ldc2 stack with dub  

BUILD
clone and run
dub.exe build --compiler=ldc2 --arch=x86_64 --build=debug --config=dray
