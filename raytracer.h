#define OUTPORT                                 0xFFF   // The port where images are sent

// Output image dimensions
#define IMAGE_WIDTH                             1024
#define IMAGE_HEIGHT                            768
#define RECURSIONS                              0

// Node information
#define NODE_COUNT                              1
#define PIXEL_JUMP                              NODE_COUNT
#define MAX_THREADS                             10
// #define MAX_COORDS                              20
#define STACK_SIZE                              500

#define MAX_OBJECTS                             200
#define MAX_TRIANGLES                           10000
#define MAX_TEXTURES                            100

// Rays are in form: source (3), direction (3).
#define RaySourcex                              0
#define RaySourcey                              1
#define RaySourcez                              2
#define RayDirectionx                           3
#define RayDirectiony                           4
#define RayDirectionz                           5

// Hit offsets:
#define HitDataHitLocation                      0
#define HitDataHitNormal                        3
#define HitDataRaySource                        6
#define HitDataRayDirection                     9
#define HitDataObjectIndex                      12
#define HitDataDistance                         13
#define HitDataTriangleIndex                    14
#define HitDataMu                               15
#define HitDataMv                               16
#define HitDatabitshift                         17

// ObjectDB offsets:
#define TriangleAx                              0
#define TriangleAy                              1
#define TriangleAz                              2
#define TriangleAu                              3
#define TriangleAv                              4
#define TriangleBu                              5
#define TriangleBv                              6
#define TriangleCu                              7
#define TriangleCv                              8
#define TriangleDominantAxisIdx                 9
#define Trianglenormcrvmuwmux                   10
#define Trianglenormcrvmuwmuy                   11
#define Trianglenormcrvmuwmuz                   12
#define TriangleNUDom                           13
#define TriangleNVDom                           14
#define TriangleNDDom                           15
#define TriangleBUDom                           16
#define TriangleBVDom                           17
#define TriangleCUDom                           18
#define TriangleCDDom                           19

// Light vector
#define LightVector                             0
#define LightColour                             3
#define LightShadowFactor                       6
#define LightGlobalFlag                         7

// Material vector
#define MaterialColour                          0
#define MaterialReflectivity                    3
#define MaterialOpacity                         4
#define MaterialRefractivity                    5
#define MaterialInverseRefractivity             6
#define MaterialSquareInverseRefractivity       7
#define MaterialAmbiance                        8
#define MaterialDiffusive                       9
#define MaterialSpecular                        10
#define MaterialShininess                       11
#define MaterialLightColour                     12
#define MaterialCompAmbianceColour              15
#define MaterialTextureIndex                    18

// Texture vector
#define TextureWidth                            0
#define TextureHeight                           1
#define TextureAlpha                            2
#define TextureMemStart                         3

// Camera vector
#define CameraLocation                          0
#define CameraView                              3
#define CameraUp                                6
#define CameraHorizontal                        9
#define CameraVertical                          12
#define CameraFOV                               15
#define CameraAR                                16
#define CameraHeight                            17
#define CameraWidth                             18
#define CameraDFoVDW                            19
#define CameraFoVAR                             20
#define CameraDFoVDH                            21
