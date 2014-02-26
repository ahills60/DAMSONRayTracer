/* This is the ray tracer software written in DAMSON */

#include "raytracer.h"

#node raytracernode

/* Constants to determine which pixels to process */
int PIXEL_OFFSET = 0;

int SpaceCounter = 1;

// For jobs received externally
int ExternalSemaphore = 1;
float ExternalCoordinates[MAX_COORDS][3];
int ExternalCoordinateTimes[MAX_COORDS][3];
int ExternalSource[MAX_COORDS];
int noExternalCoordinates = 0;

// Flag for termination.
int Terminate = 0;


void clockinterrupt(int, int, int, int);
void datainterrupt(int, int, int, int);
void RayTrace(void);

int main(void)
{
    int i, h;
    // tickrate(1000);
    printf("Port number: %d\n", OUTPORT);
    printf("Initialising external coordinates...\n");
    for (i = 0; i < MAX_COORDS; i += 1)
    {
        ExternalSource[i] = 0;
        ExternalCoordinateTimes[i][0] = 0;
        ExternalCoordinateTimes[i][1] = 0;
        ExternalCoordinateTimes[i][2] = 0;
    }
    
    printf("Spawning processes...\n");
    for (i = 0; i < MAX_THREADS; i += 1)
    {
        h = createthread(RayTrace, STACK_SIZE);
        
        if (!h)
        {
            // Unable to create thread
            printf("Unable to create a new thread. Total number of threads: %d.\n", (i + 1));
            break;
        }
    }
    return 1;
}

void RayTrace(void)
{
    int i, n, SourceNode = 0;
    float processVector[3];
    
    printf("Ray tracing thread initialised.\n");
    
    while (!Terminate)
    {
        // Lock the variables
        wait(&ExternalSemaphore);
        // Start to look for outstanding external jobs
        if (noExternalCoordinates > 0)
        {
            // Take a job from the external coordinates
            printf("Taking a job from external source\n.");
            
            for (i = 0; i < MAX_COORDS; i += 1)
            {
                // Check to see if the external source variable has been written
                if (ExternalSource[i] > 0)
                {
                    // Process this one
                    for (n = 0; n < 3; n += 1)
                    {
                        processVector[n] = ExternalCoordinates[i][n];
                        // Now reset the variables
                        ExternalCoordinates[i][n] = 0.0;
                        ExternalCoordinateTimes[i][n] = 0;
                    }
                    SourceNode = ExternalSource[i];
                    
                    // Stop looking for more jobs
                    break;
                }
            }
        }
        // Let other threads access the variables
        signal(&ExternalSemaphore);
        
        // Determine whether the job to process is an inside or outside job
        if (SourceNode)
        {
            // Process the external job
            
        }
        else
        {
            // Process inside job
            
            
        }
        
        
        // Reset variables
        SourceNode = 0;
    }
    printf("Thread has seen terminate flag. Terminating...");
    // Clean up if necessary
    
    printf("Thread terminated.");
}

void datainterrupt(int source, int port, int data, int time)
{
    
}

#alias raytracernode 1
    // clockinterrupt: 0
     // datainterrupt: 2
     PIXEL_OFFSET = 0;
       