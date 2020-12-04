module raythreading;

import std.stdio;
import std.format;
import std.conv;
import std.math;
import core.thread.osthread;
import core.time;
import std.concurrency;
import std.stdio;
import std.datetime;
import std.algorithm.comparison;
import std.algorithm.iteration;
import std.parallelism;
import std.container;
import std.range;
import std.typecons;
import std.typetuple;

/*
A custom struct that is used as a message
for a little thread army.
*/
struct RenderOrderMessage
{
    shared(int) render_width;
    shared(int) render_height;
    shared(int) spp;
    shared(double) aspect;
    shared(int) max_depth;
    shared(int)[] position_x;
    shared(int)[] position_y;

    this(shared(int) render_w, shared(int) render_h, 
                                shared(int) sample_per_pixel, 
                                shared(double) asp_r, 
                                shared(int) max_d, 
                                shared(int)[] pos_x,
                                shared(int)[] pos_y
                                )
    {
        this.render_width = render_w;
        this.render_height = render_h;
        this.spp = sample_per_pixel;
        this.aspect = asp_r;
        this.max_depth = max_d;
        this.position_x = pos_x;
        this.position_y = pos_y;
    }
}


struct RenderResultMessage
{
    shared(int)[] pixel_r;
    shared(int)[] pixel_g;
    shared(int)[] pixel_b;
    shared(int)[] pixel_a;
    shared(int)[] position_x;
    shared(int)[] position_y;

    this(shared(int)[] r, shared(int)[] g, shared(int)[] b, shared(int)[] a, shared(int)[] x, shared(int)[] y)
    {
        this.pixel_r = r;
        this.pixel_g = g;
        this.pixel_b = b;
        this.pixel_a = a;
        this.position_x = x;
        this.position_y = y;
    }
}


struct IsWorkerReadyMessage
{

}

struct WorkerReadyACKMessage
{
    string strID;
    this (string id)
    {
        this.strID = id;
    }
}

/*
Message is used as a stop sign for other
threads
*/

struct FinishedRenderWorkerMessage
{
}

struct StartRenderWorkerAckMessage
{
}

struct CanceRenderMessage
{
}

/// Acknowledge a CancelRenderMessage
struct CancelRenderAckMessage
{
}

class RaytraceWorker
{
    Tid w;
    string n;

    this(string id)
    {
        n = id;
    }

    static RaytraceWorker opCall(string id)
    {
        return new typeof(this)(id);
    }

    void SetWorker(Tid worker)
    {
        w = worker;
    }

    string GetId()
    {
        return n;
    }

    Tid GetWorkerTid()
    {
        return w;
    }
}

class RaytraceWorkerManager
{
    Array!RaytraceWorker wa;
    Tid[] threads;
    static int worker_cursor = 0;

    this()
    {

    }

    static RaytraceWorkerManager opCall()
    {
        return new typeof(this)();
    }

    bool AddWorker(RaytraceWorker worker)
    {
        wa.insertBack(worker);
        threads ~= worker.GetWorkerTid();
        return true;
    }

    Array!RaytraceWorker GetWorkerList()
    {
        return wa;
    }

    RaytraceWorker GetWorkerAt(int i)
    {
        return wa[i];
    }

    int GetWorkerCount()
    {
        return castFrom!ulong.to!int(wa.length);
    }

    Tid  GetNextWorker()
    {
        int next_to_select = worker_cursor % cast(int)threads.length;
        worker_cursor++;
        return  GetWorkerAt(next_to_select).GetWorkerTid();


    }

}
