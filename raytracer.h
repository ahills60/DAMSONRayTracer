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