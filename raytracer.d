/* This is the ray tracer software written in DAMSON */

#include "raytracer.h"

#node raytracernode

/* Constants to determine which pixels to process */
int PIXEL_OFFSET = 0;
int PIXEL_JUMP = NODE_COUNT;
int OpenThreads = 0;
int ThreadSemaphore = 2;
int SpaceCounter = 1;

void clockinterrupt(int, int, int, int);
void datainterrupt(int, int, int, int);
void RayTrace(void);

int main(void)
{
    int i;
    tickrate(1000);
    printf("Port number: %d\n", OUTPORT);
    return 1;
}

void RayTrace(void)
{
    // printf("Starting to ray trace...\n");
    
    wait(&ThreadSemaphore);
    // printf("Cleaning up...\n");
    OpenThreads -= 1;
    signal(&ThreadSemaphore);
    // printf("Ending...\n");
}

void clockinterrupt(int source, int port, int data, int time)
{
    int h;
    if (OpenThreads < MAX_THREADS)
    {
        wait(&ThreadSemaphore);
        // printf("Creating new thread...\n");
        h = createthread(RayTrace, 500);
        if (h == 0)
        {
            // Unable to create thread
            printf("Unable to create new thread\n");
        }
        else
        {
            OpenThreads += 1;
            // printf("New thread created. Total open: %d\n", OpenThreads);
        }
        signal(&ThreadSemaphore);
    }
    
}

void datainterrupt(int source, int port, int data, int time)
{
    
}

#alias raytracernode 1
    clockinterrupt: 0
     // datainterrupt: 2
     PIXEL_OFFSET = 0;
       