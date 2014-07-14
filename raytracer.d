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
int ExternalComplete[MAX_COORDS];
int noExternalCoordinates = 0;

// Flag for termination.
int Terminate = 0;

// Result storage
float ResultStore[16];

// Hit data: hit location (3), hit normal (3), ray source (3), ray direction (3), objIdx (1), distance (1), triIndex (1), Mu (1), Mv (1), bitshift (1) = 18
float HitData[18];

// Prototypes
void datainterrupt(int, int, int, int);
void RayTrace(void);
void EnterExternalData(int, int, int, int);

// Functions start here:
int main(void)
{
    int i, h;
    // tickrate(1000);
    printf("Port number: %d\n", OUTPORT);
    printf("Initialising external coordinates...\n");
    for (i = 0; i < MAX_COORDS; i += 1)
    {
        ExternalSource[i] = 0;
        ExternalComplete[i] = 0;
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
                if (!ExternalComplete[i])
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
                    ExternalSource[i] = 0;
                    ExternalComplete[i] = 0;
                    
                    noExternalCoordinates -= 1;
                    
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

void datainterrupt(int source, int port, int data, int rxtime)
{
    switch(port)
    {
        case PORT_X: // X data received
        case PORT_Y: // Y data received
        case PORT_Z: // Z data received
            EnterExternalData(source, port, data, rxtime);
        break;
        default:
            printf("Unknown data received from %d on port %d.", source, port);
    }
    
}

// Find the latest source
void EnterExternalData(int source, int PortNumber, int Data, int RxTime)
{
    wait(&ExternalSemaphore);
    if (noExternalCoordinates == MAX_COORDS)
    {
        printf("The number of external coordinate requests has been exceeded.");
        printf("Data lost from %d:%d at %d", source, PortNumber, RxTime);
        signal(&ExternalSemaphore);
        return;
    }
    // If here, there's enough room to hold these coordinates.
    
    signal(&ExternalSemaphore);
}

#alias raytracernode 1
    // clockinterrupt: 0
     // datainterrupt: 2
     PIXEL_OFFSET = 0;
       