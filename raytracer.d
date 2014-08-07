/* This is the ray tracer software written in DAMSON */

#include "raytracer.h"
#include "fpmath.h"
#include "datatypes.h"
#include "rays.h"
#include "lighting.h"
#include "objects.h"
#include "shapes.h"
#include "textures.h"
#include "construct.h"

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

// ObjectDB holds triangle information. ObjectDB[ObjectIndex][TriangleIndex][Parameter]
// Holds: TriangleU (3), TriangleUuv (2), TriangleVuv (2), TriangleWuv (2), DominantAxis (1), normcrvmuwmu (3), NUDom (1), NVDom (1), NDDom (1), BUDom (1), BVDom (1), CUDom (1), CVDom (1) = 20
float ObjectDB[MAX_OBJECTS][MAX_TRIANGLES][20];
int noObjects = 0;
int noTriangles[MAX_OBJECTS];

// Likewise, do the same for a materials databse:
// Holds: colour (3), reflectivity (1), opacity (1), refractivity (1), inverserefractivity (1), squareinverserefractivity (1), ambiance (1), diffusive (1), specular (1), shininess (1), matLightColour (3), compAmbianceColour (3), textureIdx (1) = 19
float MaterialDB[MAX_OBJECTS][19];

// Lights have several parameters:
// Holds: Position/Direction (3), Colour (3), shadowfactor (1), Position/Distance flag (1) = 8
float Light[8];

// Textures database
// Holds: width (1), height (1), alpha bool (1), position in memory (1) = 4
int TextureDB[MAX_TEXTURES][4];

// Variable to denote transparencies should be rendered
int RenderTransparencies = 0;

// Define Camera:
float Camera[22];

// Modulo vector:
int DomMod[5] = {0, 1, 2, 0, 1};

// Prototypes
/*
void datainterrupt(int, int, int, int);
void RayTrace(void);
void EnterExternalData(int, int, int, int);
*/
// Functions start here:
int main(void)
{
    float clocation[3] = {1.0, 2.0, 4.0}, cTheta = 0x0001C4A8, cPhi = 0xFFFE6DDE, cview[3], ray[6];
    int i, x, y;
    
    // Set the light source:
    Light[LightVector + 0] = -1.0;
    Light[LightVector + 1] =  4.0;
    Light[LightVector + 2] =  4.0;
    
    // White light:
    Light[LightColour + 0] =  1.0;
    Light[LightColour + 1] =  1.0;
    Light[LightColour + 2] =  1.0;
    
    // Shadow factor:
    Light[LightShadowFactor] = 0.3;
    
    // Global Lighting flag:
    Light[LightGlobalFlag] = 0;
    
    // Now initialise the camera:
    cview[0] = fp_sin(cTheta) * fp_cos(cPhi);
    cview[1] = fp_cos(cTheta);
    cview[2] = fp_sin(cTheta) * fp_sin(cPhi);
    setCamera(clocation[3], cview, 45.0, IMAGE_WIDTH, IMAGE_HEIGHT);
    
    // Now populate the scene.
    populateScene();
    
    printf("Scene dimensions: %i %i\n", IMAGE_HEIGHT, IMAGE_WIDTH);
    
    // Begin main task:
    for (y = 0; y < IMAGE_HEIGHT; y += 1)
    {
        for (x = 0; x < IMAGE_WIDTH; x += 1)
        {
            // Create a ray and retrive it from the result store.
            createRay(x, y);
            for (i = 0; i < 6; i += 1)
                ray[i] = ResultStore[i];
            // Draw this ray. The result is stored in the result store.
            draw(ray, RECURSIONS);
            // Send the RGB value directly from the result store.
            printf("draw(%i, %i) = %f %f %f\n", x, y, ResultStore[0], ResultStore[1], ResultStore[2]);
        }
    }
}
/*
void RayTrace(void)
{
    int i, n, SourceNode = 0;
    float processVector[3];
    
    printf("Ray tracing thread initialised.\n");
    /*
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
        *
        
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

Find the latest source
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
*/

#alias raytracernode 1
    // clockinterrupt: 0
     // datainterrupt: 2
     PIXEL_OFFSET = 0;
       