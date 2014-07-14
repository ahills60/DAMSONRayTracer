#define OUTPORT         0xFFF   // The port where images are sent

// Output image dimensions
#define IMAGE_WIDTH     1024
#define IMAGE_HEIGHT    768

// Node information
#define NODE_COUNT      1
#define PIXEL_JUMP      NODE_COUNT
#define MAX_THREADS     10
#define MAX_COORDS      20
#define STACK_SIZE      500

#define PORT_X          1000
#define PORT_Y          1001
#define PORT_Z          1002


// Hit offsets:
#define HitDataHitLocation     0
#define HitDataHitNormal       3
#define HitDataRaySource       6
#define HitDataRayDirection    9
#define HitDataObjIdx          12
#define HitDataDistance        13
#define HitDataTriangleIndex   14
#define HitDataMu              15
#define HitDataMv              16
#define HitDatabitshift        17

// ObjectDB offsets:
#define TriangleAx              0
#define TriangleAy              1
#define TriangleAz              2
#define TriangleAu              3
#define TriangleAv              4
#define TriangleBu              5
#define TriangleBv              6
#define TriangleCu              7
#define TriangleCv              8
#define TriangleDominantAxisIdx 9
#define Trianglenormcrvmuwmux   10
#define Trianglenormcrvmuwmuy   11
#define Trianglenormcrvmuwmuz   12
#define TriangleNUDom           13
#define TriangleNVDom           14
#define TriangleNDDom           15
#define TriangleBUDom           16
#define TriangleBVDom           17
#define TriangleCUDom           18
#define TriangleCDDom           19