/* This is the ray tracer software written in DAMSON */

#node raytracernode

#include "raytracer.h"

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
float Camera[22] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

// Modulo vector:
int DomMod[5] = {0, 1, 2, 0, 1};

float RGBChannels[3] = {0.0, 0.0, 0.0};

int LOOKUP_EXP1[24] = {
    65536, 108051, 178145, 293712, 484249, 798392, 1316326, 2170254, 
    3578144, 5899363, 9726405, 16036130, 26439109, 43590722, 71868951, 
    118491868, 195360063, 322094291, 531043708, 875543058, 1443526462, 
    2147483647, 2147483647, 2147483647
};
int LOOKUP_EXP2[31] = {
    -1016, -2016, -3001, -3971, -4925, -5865, -6790, -7701, -8597, -9480, 
    -10349, -11205, -12047, -12876, -13693, -14497, -15288, -16067, -16834, 
    -17589, -18332, -19064, -19784, -20494, -21192, -21880, -22556, -23223, 
    -23879, -24525, -25160
};
int LOOKUP_EXP3[31] = {
    -32, -64, -96, -128, -160, -192, -224, -256, -287, -319, -351, -383, 
    -415, -446, -478, -510, -542, -573, -605, -637, -669, -700, -732, -764, 
    -795, -827, -858, -890, -921, -953, -985
};

int LOOKUP_SQRT[31] = {
    1016, 2017, 3003, 3975, 4934, 5880, 6814, 7735, 8646, 9545, 10433, 
    11312, 12180, 13039, 13888, 14729, 15561, 16384, 17199, 18006, 18806, 
    19598, 20382, 21160, 21931, 22695, 23452, 24203, 24948, 25686, 26419
};

/* Prototypes */
float fp_sin(float x);
float fp_cos(float x);
float fp_exp(float z);
float fp_log(float a);
float fp_pow(float a, float b);
int fp_powi(int a, int b);
float fp_sqrt(float ina);
float fp_rsqrt(float a);
void setUVCoord(float u, float v);
void setVector(float x, float y, float z);
float deg2rad(float deg);
void vecMult(float u[3], float v[3]);
float dot(float u[3], float v[3]);
void cross(float u[3], float v[3]);
void scalarVecMult(float a, float u[3]);
void scalarVecDiv(float a, float u[3]);
void vecAdd(float u[3], float v[3]);
void vecSub(float u[3], float v[3]);
// float vecLength(float u[3]);
void vecNormalised(float u[3]);
void matVecMult(float F[16], float u[3]);
void matMult(float F[16], float G[16]);
void genIdentMat();
void genXRotateMat(float a);
void genYRotateMat(float a);
void genZRotateMat(float a);
void getRotateMatrix(float ax, float ay, float az);
void genTransMatrix(float tx, float ty, float tz);
void genScaleMatrix(float sx, float sy, float sz);
void setTriangle(int objectIndex, int triangleIndex, float u[3], float v[3], float w[3]);
void setCamera(float location[3], float view[3], float fov, int width, int height);
float triangleIntersection(float ray[6], int objectIdx, int triangleIdx, float currentDistance);
void objectIntersection(float ray[6], int objectIdx);
void sceneIntersection(float ray[6]);
float traceShadow(float localHitData[18], float direction[3]);
void reflectRay(float localHitData[18]);
void refractRay(float localHitData[18], float inverserefractivity, float squareinverserefractivity);
void createRay(int x, int y);
void ambiance(float localHitData[18], float textureColour[3]);
void diffusion(float localHitData[18], float lightDirection[3], float textureColour[3]);
void specular(float localHitData[18], float lightDirection[3], float textureColour[3]);
void setMaterial(int materialIdx, float colour[3], float ambiance, float diffusive, float specular, float shininess, float reflectivity, float opacity, float refractivity, int textureIndex);
void createCube(int objectIndex, float size, float transMat[16]);
void createPlaneXZ(int objectIndex, float size, float transMat[16]);
void getTexel(float localHitData[18], float uv[2]);
void getColour(float localHitData[18]);
void populateDefaultScene();
void populateScene();
void draw(float ray[6], int recursion);

/* Start functions */
float fp_sin(float a)
{
    float c;
    
    // Ensure input within the range of -pi to pi
    if (a > FP_PI)
        a -= FP_2PI;
    if (a < -FP_PI)
        a += FP_2PI;
    
    // Use fast sine parabola approximation
    c = (FP_CONST_B * a) + (FP_CONST_C * a * fabs(a));
    
    // Get extra precision weighting the parabola:
    c += (FP_CONST_Q * ((c * fabs(c)) - c)); // Q * output + P * output * abs(output)
    
    // Finally, convert the integer back to a float.
    return c;
}

/* Fixed point cosine */
float fp_cos(float a)
{
    // Use the sine function
    return fp_sin(a + FP_PI_2);
}

float fp_exp(float z) 
{
    int a = (void) z;
    int absv = a;
    int im;
    int i, k, l;
    float output;
    
    if (a < 0) 
    {
        if (a < -700244)
        {
            // Bound FPs < ln (0.5 / 65536) to 0
            if (a < -772244)
                return 0;
            else
                // Bound ln(0.5/65536) < FPs < ln(1.5/65536) to 1
                return (void) 1;
        }
        absv = -a;
    } 
    else
        // Bound FPs greater than ln(0.5 * 32768) to max value
        if (a > 681390)
            return (void) 0x7FFFFFFF;
    
    i = absv;
    i >>= 5;
    
    im = (i & 31) - 1; // Use bits 5 to 14
    if (im >= 0)
    {
        k = LOOKUP_EXP3[im] & 0xFFFF;
        i >>= 5;
        im = (i & 31) - 1; // Use its 15 to 19
        if (im >= 0)
        {
            k *= LOOKUP_EXP2[im] & 0xFFFF;
            k = (k < 0) ? (((k & 0x7FFFFFFF) >> 15) | 0x00010000) : k >> 15;
            k = (k + 1) >> 1;
        }
    }
    else
    {
        i >>= 5;
        im = (i & 31) - 1; // Use bits 15 to 19
        k = (im >= 0) ? LOOKUP_EXP2[im] & 0xFFFF : 0x10000;
    }
    im = absv & 31; // Use bits 0 to 4
    if (im > 0)
    {
        k *= 0x10000 - im;
        k = (k < 0) ? (((k & 0x7FFFFFFF) >> 15) | 0x00010000) : k >> 15;
        k = (k >> 1) + (k & 1);
    }
    
    i >>= 5;
    im = i & 31; // Use bits 15 to 19
    
    // Combine integer exponent and inverse fractional exponent
    if (a < 0)
        return (void) k / (void) LOOKUP_EXP1[im];
    else
        return (void) LOOKUP_EXP1[im] / (void) k;
}

float fp_log(float a)
{
    int t, y, x = (void) a;
    
    if (a <= 0)
        return (void) MIN_VAL;
    
    y = 0xa65af;
    if(x < 0x00008000)
    {
        x <<= 16;
        y -= 0xb1721;
    }
    if(x < 0x00800000)
    { 
        x <<= 8;
        y -= 0x58b91;
    }
    if(x < 0x08000000)
    {
        x <<= 4;
        y -= 0x2c5c8;
    }
    if(x < 0x20000000)
    {
        x <<= 2;
        y -= 0x162e4;
    }
    if(x < 0x40000000)
    {
        x <<= 1;
        y -= 0x0b172;
    }
    t = x + (x >> 1);
    if(!(t & 0x80000000)) 
    {
        x = t;
        y -= 0x067cd;
    }
    t = x + (x >> 2);
    if(!(t & 0x80000000))
    {
        x = t;
        y -= 0x03920;
    }
    t = x + (x >> 3);
    if(!(t & 0x80000000))
    {
        x = t;
        y -= 0x01e27;
    }
    t = x + (x >> 4);
    if(!(t & 0x80000000))
    {
        x = t;
        y -= 0x00f85;
    }
    t = x + (x >> 5); 
    if(!(t & 0x80000000))
    {
        x = t;
        y -= 0x007e1;
    }
    t = x + (x >> 6); 
    if(!(t & 0x80000000)) 
    {
        x = t;
        y -= 0x003f8;
    }
    t = x + (x >> 7);
    if(!(t & 0x80000000))
     {
         x = t;
         y -= 0x001fe;
     }
    x = 0x80000000 - x;
    y -= x >> 15;
    return (void) y;
}

float fp_pow(float a, float b)
{
    if (a <= 0.0)
        return 0.0;
    
    if (!((void) b))
        return 1.0;
    
    return fp_exp(fp_log(a) * b);
}

int fp_powi(int a, int b)
{
    int result = 1;
    while (b)
    {
        if (b & 1)
            result *= a;
        b >>= 1;
        a *= a;
    }
    return result;
}

float fp_sqrt(float ina)
{
    int a = (void) ina;
    int im, p = -16;
    int i, k = 0;
    int longNum;
    float output;
    
    if (a <= 0)
        return 0;
    
    // Get MSB
    i = a;
    
    if (i & 0xFFFF0000)
    {
        i >>= 16;
        p += 16;
    }
    if (i & 0x0000FF00)
    {
        i >>= 8;
        p += 8;
    }
    if (i & 0x000000F0)
    {
        i >>= 4;
        p += 4;
    }
    if (i & 0x0000000C)
    {
        i >>= 2;
        p += 2;
    }
    if (i & 0x00000002)
    {
        i >>= 1;
        p += 1;
    }
    
    // Lookup the sqrt multiplier based on bits MSB + 0 to MSB + 3 then
    // correct odd MSB positions using sqrt(2). Sqrt(2) is roughly 92682
    if (p >= -11)
        i = a >> (11 + p);
    else
        i = a << (-11 - p);
    
    im = (i & 31) - 1;
    if (im >= 0)
    {
        k = LOOKUP_SQRT[im] & 0xFFFF;
        if (p & 1)
        {
            k = k * 92682;
            k = (k < 0) ? (((k & 0x7FFFFFFF) >> 16) | 0x8000) : k >> 16;
        }
    }
    
    if (p & 1)
        k += 92682; // add sqrt(2)
    else
        k += 0x10000; // add 1
    
    // Shift the square root estimate based on the halved MSB position
    if (p >= 0)
        k <<= (p >> 1);
    else
        k >>= ((1 - p) >> 1);
    
    // // Do two Newtonian square root iteration steps to increase precision
    
    // Andrew special:
    output = (void) k;
    output += ina / output;
    output = (void)((void) output >> 1);
    output += ina / output;
    
    return (void)((void) output >> 1);
}

float fp_rsqrt(float a)
{
    float output, flta;
    int inta = (void) a, msb = 0, shifted;
    
    if (a <= 0)
        return 0;
    
    // Locate MSB
    if (inta & 0xFFFF0000)
    {
        inta >>= 16;
        msb += 16;
    }
    if (inta & 0x0000FF00)
    {
        inta >>= 8;
        msb += 8;
    }
    if (inta & 0x000000F0)
    {
        inta >>= 4;
        msb += 4;
    }
    if (inta & 0x0000000C)
    {
        inta >>= 2;
        msb += 2;
    }
    if (inta & 0x00000002)
    {
        inta >>= 1;
        msb += 1;
    }
    // Plus any remainder.
    msb += inta;
    
    // Then start normalisation procedure
    if (msb > 15)
    {
        // Integer component. Need to shift right
        shifted = msb - 16;
        flta = (void)((void) a >> shifted);
    }
    else
    {
        // Decimal only. Need to shift left
        shifted = 16 - msb;
        flta = (void)((void) a << shifted);
    }
    
    // Initial guess then Newton iterations
    output = 1.78773 - 0.80999 * flta;
    // x_{n + 1} = x_n / 2 (3 - a x^2_n) 
    output = (void)((void)(output * (3.0 - flta * output * output)) >> 1);
    output = (void)((void)(output * (3.0 - flta * output * output)) >> 1);
    output = (void)((void)(output * (3.0 - flta * output * output)) >> 1);
    
    // // Was there an odd number of shifts?
    if (shifted & 1)
        // Yes, factor in 1/sqrt(2) by multiplying by sqrt(2)
        output *= SQRT2;
    
    // Undo the normalisation process and return the result
    if (msb > 15)
        return (void) (((void) output) >> ((shifted + 1) >> 1));
    else if (msb < 16)
        return (void) (((void) output) << (shifted >> 1));
}

/* Set the UV coordinates */
void setUVCoord(float u, float v)
{
    ResultStore[0] = u;
    ResultStore[1] = v;
}

/* Set the coordinates of a vector */
void setVector(float x, float y, float z)
{
    ResultStore[0] = x;
    ResultStore[1] = y;
    ResultStore[2] = z;
}

/* Convert from degrees to radians */
float deg2rad(float deg)
{
    // Equivalent to deg * pi / 180, but with increased resolution:
    deg *= 4.468042886;
    
    // shift
    // (deg * 256 * pi / 180) / 256
    return (void)((void) deg >> 8); // * M_PI / 180.0;
}

/* Vector multiply */
void vecMult(float u[3], float v[3])
{
    ResultStore[0] = u[0] * v[0];
    ResultStore[1] = u[1] * v[1];
    ResultStore[2] = u[2] * v[2];
}

/* Dot product of two vectors */
float dot(float u[3], float v[3])
{
    return u[0] * v[0] + u[1] * v[1] + u[2] * v[2];
}

/* Cross product of two vectors */
void cross(float u[3], float v[3])
{
    ResultStore[0] = u[1] * v[2] - v[1] * u[2];
    ResultStore[1] = u[2] * v[0] - v[2] * u[0];
    ResultStore[2] = u[0] * v[1] - v[0] * u[1];
}

/* Scalar multiplication with a vector */
void scalarVecMult(float a, float u[3])
{
    ResultStore[0] = a * u[0];
    ResultStore[1] = a * u[1];
    ResultStore[2] = a * u[2];
}

/* Scalar division with a vector */
void scalarVecDiv(float a, float u[3])
{
    ResultStore[0] = u[0] / a;
    ResultStore[1] = u[1] / a;
    ResultStore[2] = u[2] / a;
}

/* Vector addition */
void vecAdd(float u[3], float v[3])
{
    ResultStore[0] = u[0] + v[0];
    ResultStore[1] = u[1] + v[1];
    ResultStore[2] = u[2] + v[2];
}

/* Vector subtraction */
void vecSub(float u[3], float v[3])
{
    ResultStore[0] = u[0] - v[0];
    ResultStore[1] = u[1] - v[1];
    ResultStore[2] = u[2] - v[2];
}

// /* Get the length of a vector */
// float vecLength(float u[3])
// {
//     return fp_sqrt(u[0] * u[0] + u[1] * u[1] + u[2] * u[2]);
// }

/* Normalised vector */
void vecNormalised(float u[3])
{
    float tempVar = u[0] * u[0] + u[1] * u[1] + u[2] * u[2];
    if (!((void) tempVar))
    {
        ResultStore[0] = u[0];
        ResultStore[1] = u[1];
        ResultStore[2] = u[2];
    }
    else // Below function calls will populate ResultStore
        if ((void) tempVar == (void) 1)
            scalarVecMult(256.0, u); // Equivalent of 256 as 1 / sqrt(1.52E-5) is 256
        else
            scalarVecMult(fp_rsqrt(tempVar), u);
}

/* Matrix multiplied by a vector */
void matVecMult(float F[16], float u[3])
{
    // Note that we don't consider the last row within the matrix. This is discarded deliberately.
    ResultStore[0] = (F[0] * u[0]) + (F[1] * u[1]) + (F[2] * u[2]) + F[3];
    ResultStore[1] = (F[4] * u[0]) + (F[5] * u[1]) + (F[6] * u[2]) + F[7];
    ResultStore[2] = (F[8] * u[0]) + (F[9] * u[1]) + (F[10] * u[2]) + F[11];
}

/* Matrix multiplied by a matrix */
void matMult(float F[16], float G[16])
{
    int m, n, p, n4;
    
    for (m = 0; m < 4; m += 1)
    {
        for (n = 0; n < 4; n += 1)
        {
            n4 = 4 * n;
            // Initialise new matrix first
            ResultStore[n4 + m] = 0;
            
            // Now populate with the multiplication
            for (p = 0; p < 4; p += 1)
                 ResultStore[n4 + m] += F[n4 + p] * G[p * 4 + m]; // F[n][p] * G[p][m];
        }
    }
}

// /* Create an identity matrix */
// void genIdentMat()
// {
//     int i;
//     float m[16] = {1, 0, 0, 0,
//                    0, 1, 0, 0,
//                    0, 0, 1, 0,
//                    0, 0, 0, 1};
//     // Copy the array to the results store.
//     for (i = 0; i < 16; i += 1)
//         ResultStore[i] = m[i];
// }

/* Create a rotation matrix for X-axis rotations */
void genXRotateMat(float a)
{
    int i;
    float b = deg2rad(a);
    float cosa = fp_cos(b), sina = fp_sin(b);
    
    float m[16] = {1.0, 0, 0, 0,
                   0, 1.0, 0, 0,
                   0, 0, 1.0, 0,
                   0, 0, 0, 1.0};
    m[5] = cosa;
    m[6] = -sina;
    m[9] = sina;
    m[10] = cosa;
    // Copy the array to the results store.
    for (i = 0; i < 16; i += 1)
        ResultStore[i] = m[i];
}

/* Create a rotation matrix for Y-axis rotations */
void genYRotateMat(float a)
{
    int i;
    float b = deg2rad(a);
    float cosa = fp_cos(b), sina = fp_sin(b);
    
    float m[16] = {1.0, 0, 0, 0,
                   0, 1.0, 0, 0,
                   0, 0, 1.0, 0,
                   0, 0, 0, 1.0};
    
    m[0] = cosa;
    m[2] = sina;
    m[8] = -sina;
    m[10] = cosa;
    // Copy the array to the results store.
    for (i = 0; i < 16; i += 1)
        ResultStore[i] = m[i];
}

/* Create a rotation matrix for Z-axis rotations */
void genZRotateMat(float a)
{
    int i;
    float b = deg2rad(a);
    float cosa = fp_cos(b), sina = fp_sin(b);
    
    float m[16] = {1.0, 0, 0, 0,
                   0, 1.0, 0, 0,
                   0, 0, 1.0, 0,
                   0, 0, 0, 1.0};
    
    m[0] = cosa;
    m[1] = -sina;
    m[4] = sina;
    m[5] = cosa;
    // Copy the array to the results store.
    for (i = 0; i < 16; i += 1)
        ResultStore[i] = m[i];
}

/* Combine the three matrix rotations to give a single rotation matrix */
// void getRotateMatrix(float ax, float ay, float az)
// {
//     int i;
//     float mat[16];
//     genXRotateMat(ax);
//     // Copy result
//     for (i = 0; i < 16; i += 1)
//         mat[i] = ResultStore[i];
//     genYRotateMat(ay);
//     matMult(mat, ResultStore);
//     // Copy result
//     for (i = 0; i < 16; i += 1)
//         mat[i] = ResultStore[i];
//     genZRotateMat(az);
//     matMult(mat, ResultStore);
// }

void genTransMatrix(float tx, float ty, float tz)
{
    int i;
    float m[16] = {1.0, 0, 0, 0,
                   0, 1.0, 0, 0,
                   0, 0, 1.0, 0,
                   0, 0, 0, 1.0};
    
    m[3] = tx;
    m[7] = ty;
    m[11] = tz;
    // Copy the array to the results store.
    for (i = 0; i < 16; i += 1)
        ResultStore[i] = m[i];
}

// void genScaleMatrix(float sx, float sy, float sz)
// {
//     int i;
//     float m[16] = {0, 0, 0, 0,
//                    0, 0, 0, 0,
//                    0, 0, 0, 0,
//                    0, 0, 0, 1};
//
//     m[0] = sx;
//     m[5] = sy;
//     m[10] = sz;
//    // Copy the array to the results store.
//     for (i = 0; i < 16; i += 1)
//         ResultStore[i] = m[i];
// }

void setTriangle(int objectIndex, int triangleIndex, float u[3], float v[3], float w[3])
{
    int uIdx, vIdx, i, domIdx;
    float dk, du, dv, bu, bv, cu, cv, coeff;
    float vmu[3], wmu[3], NormDom[3], fabsNormDom[3];
    
    for (i = 0; i < 3; i += 1)
    {
        ObjectDB[objectIndex][triangleIndex][TriangleAx + i] = u[i];
        vmu[i] = v[i] - u[i];
        wmu[i] = w[i] - u[i];
    }
    
    cross(vmu, wmu);
    for (i = 0; i < 3; i += 1)
        NormDom[i] = ResultStore[i];
    
    vecNormalised(NormDom);
    for (i = 0; i < 3; i += 1)
    {
        ObjectDB[objectIndex][triangleIndex][Trianglenormcrvmuwmux + i] = ResultStore[i];
        // Precompute fabs whilst we're at it.
        fabsNormDom[i] = fabs(NormDom[i]);
    }
    
    // Invalidate UV coordinates
    for (i = 0; i < 2; i += 1)
    {
        ObjectDB[objectIndex][triangleIndex][TriangleAu + i] = -1;
        ObjectDB[objectIndex][triangleIndex][TriangleBu + i] = -1;
        ObjectDB[objectIndex][triangleIndex][TriangleCu + i] = -1;
    }
    
    // Find the dominant axis
    if (fabsNormDom[0] > fabsNormDom[1])
    {
        if (fabsNormDom[0] > fabsNormDom[2])
            domIdx = 0;
        else
            domIdx = 2;
    }
    else
    {
        if (fabsNormDom[1] > fabsNormDom[2])
            domIdx = 1;
        else
            domIdx = 2;
    }
    
    ObjectDB[objectIndex][triangleIndex][TriangleDominantAxisIdx] = (void) domIdx;
    
    // Use the array to quickly resolve modulo.
    uIdx = DomMod[domIdx + 1];
    vIdx = DomMod[domIdx + 2];
    
    // This should make calculations easier...
    dk = (!domIdx) ? NormDom[0] : (( domIdx == 2) ? NormDom[2] : NormDom[1]);
    du = (!uIdx) ? NormDom[0] : ((uIdx == 2) ? NormDom[2] : NormDom[1]);
    dv = (!vIdx) ? NormDom[0] : ((vIdx == 2) ? NormDom[2] : NormDom[1]);
    
    bu = (!uIdx) ? wmu[0] : ((uIdx == 2) ? wmu[2] : wmu[1]);
    bv = (!vIdx) ? wmu[0] : ((vIdx == 2) ? wmu[2] : wmu[1]);
    cu = (!uIdx) ? vmu[0] : ((uIdx == 2) ? vmu[2] : vmu[1]);
    cv = (!vIdx) ? vmu[0] : ((vIdx == 2) ? vmu[2] : vmu[1]);
    
    /*
    if (dk == 0)
    {
        printf("Odd output:\ndk: 0x%X\ndu: 0x%X\ndv: 0x%X\n\n", dk, du, dv);
        printf("u.x: 0x%X\nu.y: 0x%X\nu.z: 0x%X\n", u.x, u.y, u.z);
        printf("v.x: 0x%X\nv.y: 0x%X\nv.z: 0x%X\n", v.x, v.y, v.z);
        printf("w.x: 0x%X\nw.y: 0x%X\nw.z: 0x%X\n\n", w.x, w.y, w.z);
        printf("vmu.x: 0x%X\nvmu.y: 0x%X\nvmu.z: 0x%X\n", (*triangle).vmu.x, (*triangle).vmu.y, (*triangle).vmu.z);
        printf("wmu.x: 0x%X\nwmu.y: 0x%X\nwmu.z: 0x%X\n", (*triangle).wmu.x, (*triangle).wmu.y, (*triangle).wmu.z);
        printf("nd.x: 0x%X\nnd.y: 0x%X\nnd.z: 0x%X\n\n", (*triangle).NormDom.x, (*triangle).NormDom.y, (*triangle).NormDom.z);
    }
    */
    // Now precompute components for Barycentric intersection
    if (!((void) dk))
        dk = 1.0;
    ObjectDB[objectIndex][triangleIndex][TriangleNUDom] = du / dk;
    ObjectDB[objectIndex][triangleIndex][TriangleNVDom] = dv / dk;
    ObjectDB[objectIndex][triangleIndex][TriangleNDDom] = dot(NormDom, u) / dk;
    
    // First line of the equation:
    coeff = (bu * cv) - (bv * cu);
    if (!((void) coeff))
        coeff = 1.0;
    ObjectDB[objectIndex][triangleIndex][TriangleBUDom] = bu / coeff;
    ObjectDB[objectIndex][triangleIndex][TriangleBVDom] = -(bv / coeff);
    // Second line of the equation:
    ObjectDB[objectIndex][triangleIndex][TriangleCUDom] = cv / coeff;
    ObjectDB[objectIndex][triangleIndex][TriangleCVDom] = -(cu / coeff);
    
    // Finally, increment the number of triangles statistic.
    noTriangles[objectIndex] += 1;
}

/*
// Add two UV coordinates
void uvAdd(float a[2], float b[2], MathStat *m)
{
    int i;
    for (i = 0; i < 2; i += 1)
        ResultStore[i] = a[i] + b[i];
}

void uvSub(float a[2], float b[2], MathStat *m)
{
    int i;
    for (i = 0; i < 2; i += 1)
        ResultStore = a[i] - b[i];
}
*/

// Camera creation. Initialises the camera vector
void setCamera(float location[3], float view[3], float fov, int width, int height)
{
    float vertical[3], horizontal[3], up[3] = {0, 1.0, 0}, ar, fovh, dfovardw;
    int i;
    
    cross(view, up);
    for (i = 0; i < 3; i += 1)
        horizontal[i] = ResultStore[i];
    
    cross(horizontal, view);
    for (i = 0; i < 3; i += 1)
        vertical[i] = ResultStore[i];
    
    fovh = (void)((void) fov >> 1);
    fovh = deg2rad(fovh);
    
    // Now calcualte aspect ratio
    ar = (float) width / (float) height;
    
    dfovardw = (void)((void) ar << 1);
    dfovardw *= fovh;
    dfovardw /= (float) width;
    
    // Now populate the camera vector
    for (i = 0; i < 3; i += 1)
    {        
        Camera[CameraLocation + i] = location[i];
        Camera[CameraView + i] = view[i];
        Camera[CameraUp + i] = up[i];
        Camera[CameraHorizontal + i] = horizontal[i];
        Camera[CameraVertical + i] = vertical[i];
    }
    Camera[CameraFoV] = fovh;
    Camera[CameraAR] = ar;
    Camera[CameraHeight] = (float) height;
    Camera[CameraWidth] = (float) width;
    Camera[CameraDFoVARDW] = dfovardw;
    Camera[CameraFoVAR] = fovh * ar;
    Camera[CameraDFoVDH] = deg2rad(fov) / (float) height;
}

float triangleIntersection(float ray[6], int objectIdx, int triangleIdx, float currentDistance)
{
    int ku, kv, shift1, msb1, msb2, bitdiff1, biteval, denomi, numeri, cmpopti, tempVar1, tempVar2, dominantAxisIdx = (void) ObjectDB[objectIdx][triangleIdx][TriangleDominantAxisIdx];
    float dk, du, dv, ok, ou, ov, denom, dist, hu, hv, au, av, numer, beta, gamma, cmpopt;
    
    // Determine if an error occurred when preprocessing this triangle:
    if (dominantAxisIdx > 2 || dominantAxisIdx < 0)
        return -1;

    // Now get the correct axes and offset using the modulo vector:
    ku = DomMod[dominantAxisIdx + 1];
    kv = DomMod[dominantAxisIdx + 2];
    
    
    // Now take the correct components for destination (note, use of not are for == 0 cases as ! is faster):
    dk = (!dominantAxisIdx) ? ray[RayDirectionx] : ((dominantAxisIdx == 1) ? ray[RayDirectiony] : ray[RayDirectionz]);
    du = (!ku) ? ray[RayDirectionx] : ((ku == 1) ? ray[RayDirectiony] : ray[RayDirectionz]);
    dv = (!kv) ? ray[RayDirectionx] : ((kv == 1) ? ray[RayDirectiony] : ray[RayDirectionz]);
    
    // Then do the same with the source:
    ok = (!dominantAxisIdx) ? ray[RaySourcex] : ((dominantAxisIdx == 1) ? ray[RaySourcey] : ray[RaySourcez]);
    ou = (!ku) ? ray[RaySourcex] : ((ku == 1) ? ray[RaySourcey] : ray[RaySourcez]);
    ov = (!kv) ? ray[RaySourcex] : ((kv == 1) ? ray[RaySourcey] : ray[RaySourcez]);
    
    // Compute the denominator:
    denom = dk + (ObjectDB[objectIdx][triangleIdx][TriangleNUDom] * du) + (ObjectDB[objectIdx][triangleIdx][TriangleNVDom] * dv);
    denomi = (void) denom;
    if (denomi < 0x4 && denomi > -0x4)
        return -1;
    
    numer = ObjectDB[objectIdx][triangleIdx][TriangleNDDom] - ok - (ObjectDB[objectIdx][triangleIdx][TriangleNUDom] * ou) - (ObjectDB[objectIdx][triangleIdx][TriangleNVDom] * ov);
    
    numeri = (void) numer;
    
    if (!numeri)
        return -1;
    
    // Do a sign check
    if ((denomi & 0x80000000) ^ (numeri & 0x80000000))
        return -1;
    
    // Locate the MSB of the numerator:
    tempVar1 = abs(numeri);
    msb1 = 0;
    if (tempVar1 & 0xFFFF0000)
    {
        tempVar1 >>= 16;
        msb1 += 16;
    }
    if (tempVar1 & 0x0000FF00)
    {
        tempVar1 >>= 8;
        msb1 += 8;
    }
    if (tempVar1 & 0x000000F0)
    {
        tempVar1 >>= 4;
        msb1 += 4;
    }
    if (tempVar1 & 0x0000000C)
    {
        tempVar1 >>= 2;
        msb1 += 2;
    }
    if (tempVar1 & 0x00000002)
    {
        tempVar1 >>= 1;
        msb1 += 1;
    }
    // Then add any remainder:
    msb1 += tempVar1;
    
    // Then do the same for the denominator:
    tempVar1 = abs(denomi);
    msb2 = 0;
    if (tempVar1 & 0xFFFF0000)
    {
        tempVar1 >>= 16;
        msb2 += 16;
    }
    if (tempVar1 & 0x0000FF00)
    {
        tempVar1 >>= 8;
        msb2 += 8;
    }
    if (tempVar1 & 0x000000F0)
    {
        tempVar1 >>= 4;
        msb2 += 4;
    }
    if (tempVar1 & 0x0000000C)
    {
        tempVar1 >>= 2;
        msb2 += 2;
    }
    if (tempVar1 & 0x00000002)
    {
        tempVar1 >>= 1;
        msb2 += 1;
    }
    // Then add any remainder:
    msb2 += tempVar1;
    
    // Now evaluate the bit differences:
    bitdiff1 = 16 - msb2;
    biteval = (msb1 - msb2) <= 14;
    
    if (biteval)
    {
        dist = numer / denom;
        // Early exit if the computed distances is greater than what we've already encoutered
        // and if it's not a valid distance
        if (currentDistance < dist)
            return -1;
    }
    else
    {
        denomi <<= bitdiff1;
        dist = numer / (void) denomi;
        // Early exit:
        currentDistance = (void)((void) currentDistance >> bitdiff1);
        if (currentDistance < dist)
            return -1;
    }
    
    // Extract points from primary vector:
    au = (!ku) ? ObjectDB[objectIdx][triangleIdx][TriangleAx] : ((ku == 1) ? ObjectDB[objectIdx][triangleIdx][TriangleAy] : ObjectDB[objectIdx][triangleIdx][TriangleAz]);
    av = (!kv) ? ObjectDB[objectIdx][triangleIdx][TriangleAx] : ((kv == 1) ? ObjectDB[objectIdx][triangleIdx][TriangleAy] : ObjectDB[objectIdx][triangleIdx][TriangleAz]);
    
    // Continue calculating intersections:
    if (biteval)
    {
        hu = ou + (dist * du) - au;
        hv = ov + (dist * dv) - av;
    }
    else
    {
        hu = (void)((void) ou >> bitdiff1) + (dist * du) - (void)((void) au >> bitdiff1);
        hv = (void)((void) ov >> bitdiff1) + (dist * dv) - (void)((void) av >> bitdiff1);
    }
    
    beta = (hv * ObjectDB[objectIdx][triangleIdx][TriangleBUDom]) + (hu * ObjectDB[objectIdx][triangleIdx][TriangleBVDom]);
    cmpopti = EPS + (biteval ? 0x10000 : (0x10000 >> bitdiff1));
    cmpopt = (void) cmpopti;
    
    // If negative, exit early
    if (beta < 0 || beta > cmpopt)
        return -1;
    
    gamma = (hu * ObjectDB[objectIdx][triangleIdx][TriangleCUDom]) + (hv * ObjectDB[objectIdx][triangleIdx][TriangleCVDom]);
    
    // If negative, exit early
    if (gamma < 0 || gamma > cmpopt)
        return -1;
    
    // As these are barycentric coordinates, the sum should be < 1
    if ((gamma + beta) > cmpopt)
        return -1;
    
    ResultStore[0] = beta;
    ResultStore[1] = gamma;
    ResultStore[2] = (float) bitdiff1;
    
    return dist;
}

void objectIntersection(float ray[6], int objectIdx)
{
    float Mu, Mv, intersectionPoint, nearestIntersection = (void) FURTHEST_RAY, dirVec[3], normVec[3], location[3];
    int n, i, nearestIdx, bitshift, nearestbitshift = 32;
    
    HitData[HitDataDistance] = 0;
    
    for (i = 0; i < 3; i += 1)
        dirVec[i] = ray[RayDirectionx + i];
    
    for (n = 0; n < noTriangles[objectIdx]; n += 1)
    {
        intersectionPoint = triangleIntersection(ray, objectIdx, n, nearestIntersection);
        
        if (((int) ResultStore[2] <= nearestbitshift) && (intersectionPoint > 0) && (intersectionPoint < nearestIntersection))
        {
            // Populate the vectors
            for (i = 0; i < 3; i += 1)
                normVec[i] = ObjectDB[objectIdx][n][Trianglenormcrvmuwmux + i];
            
            // Determine whether the triangle is front facing.
            if ((void) dot(normVec, dirVec) < (void) EPS)
            {
                // This is better, so save the results of this
                nearestIdx = n;
                nearestIntersection = intersectionPoint;
                nearestbitshift = (int) ResultStore[2];
                Mu = ResultStore[0];
                Mv = ResultStore[1];
            }
        }
    }
    
    // Only complete the hit data iff there was an intersection
    if ((nearestIntersection > 0) && ((void) nearestIntersection < (void) FURTHEST_RAY))
    {
        for (i = 0; i < 3; i += 1)
        {
            // Create the two vectors and add the two vectors together.
            HitData[HitDataHitLocation + i] = ray[i] + (nearestIntersection * dirVec[i]);
            HitData[HitDataHitNormal + i] = ObjectDB[objectIdx][nearestIdx][Trianglenormcrvmuwmux + i];
            HitData[HitDataRaySource + i] = ray[RaySourcex + i];
            HitData[HitDataRayDirection + i] = ray[RayDirectionx + i];
        }
        HitData[HitDataDistance] = nearestIntersection;
        HitData[HitDataMu] = Mu;
        HitData[HitDataMv] = Mv;
        // printf("NI: %f Mu: %f, Mv: %f\n", nearestIntersection, Mu, Mv);
        HitData[HitDatabitshift] = (void) nearestbitshift;
        HitData[HitDataTriangleIndex] = (void) nearestIdx;
        HitData[HitDataObjectIndex] = (void) objectIdx;
    }
    else
        HitData[HitDataObjectIndex] = -1;
}

void sceneIntersection(float ray[6])
{
    int n, i;
    float nearestHit[18];
    nearestHit[HitDataDistance] = (void) FURTHEST_RAY;
    
    for (n = 0; n < noObjects; n += 1)
    {
        objectIntersection(ray, n);
        // Check to see if this hit is worth keeping. If so, take a copy
        if ((HitData[HitDataDistance] > 0) && (HitData[HitDataDistance] < nearestHit[HitDataDistance]))
            for (i = 0; i < 18; i += 1)
                nearestHit[i] = HitData[i];
    }
    
    // Now check to see if there actually was a hit:
    if ((nearestHit[HitDataDistance] <= 0) || ((void) nearestHit[HitDataDistance] >= (void) FURTHEST_RAY))
        nearestHit[HitDataObjectIndex] = -1;
    // Finally copy the contents of the nearest hit vector to the hit data vector.
    for (n = 0; n < 18; n += 1)
        HitData[n] = nearestHit[n];
}

float traceShadow(float localHitData[18], float direction[3])
{
    float ray[6];
    
    int n, m;
    float tempDist = (void) FURTHEST_RAY;
    
    // Populate the ray vector
    for (n = 0; n < 3; n += 1)
    {
        ray[n] = localHitData[HitDataHitLocation + n];
        ray[RayDirectionx + n] = direction[n];
    }
    
    // Now send the shadow ray back to the light. If it intersects, then the ray is a shadow
    for (m = 0; m < noObjects; m += 1)
    {
        for (n = 0; n < noTriangles[m]; n += 1)
        {
            // Ensure there are no self-intersections
            if (((void) m == (void) localHitData[HitDataObjectIndex]) && ((void) n == (void) localHitData[HitDataTriangleIndex]))
                continue;
            
            if ((void) triangleIntersection(ray, m, n, tempDist) > (void) (EPS << 1))
                return Light[LightShadowFactor];
        }
    }
    // If here, no objects obscured the light source, so return 0.
    return 0;
}

void reflectRay(float localHitData[18])
{
    float direction[3], normal[3], tempFl;
    int i, tempVar;
    
    // Populate the direction vector:
    for (i = 0; i < 3; i += 1)
    {
        direction[i] = -localHitData[HitDataRayDirection + i];
        normal[i] = localHitData[HitDataHitNormal + i];
    }
    
    // Based on 2 (n . v) * n - v
    
    tempFl = (void)((void) dot(normal, direction) << 1);
    
    for (i = 0; i < 3; i += 1)
    {
        // Move the reflection direction:
        ResultStore[RayDirectionx + i] = (tempFl * normal[i]) - direction[i];
        // Then add the reflection source:
        ResultStore[i] = localHitData[HitDataHitLocation + i];
    }
}

void refractRay(float localHitData[18], float inverserefractivity, float squareinverserefractivity)
{
    float direction[3], normal[3], c;
    int i, diri[3];
    
    // Populate the direction and normal vectors:
    for (i = 0; i < 3; i += 1)
    {
        direction[i] = localHitData[HitDataRayDirection + i];
        diri[i] = (void) direction[i];
        diri[i] >>= 12;
        normal[i] = localHitData[HitDataHitNormal + i];
        // Compute the negative vector:
        direction[i] = -direction[i];
    }
    
    c = dot(direction, normal);
    c = (inverserefractivity * c) - fp_sqrt(1.0 - (squareinverserefractivity * (1.0 - c * c)));
    
    for (i = 0; i < 3; i += 1)
    {
        // Direction of refractive ray, then scale the normal and subtract the two vectors
        normal[i] = (c * normal[i]) - inverserefractivity * direction[i];
    }
    // Then normalise.
    vecNormalised(normal);
    // Next, create a ray array in the result store.
    for (i = 0; i < 3; i += 1)
    {
        // Shift the direction up
        ResultStore[i + RayDirectionx] = ResultStore[i];
        // Then add the refraction start location
        direction[i] = (void) diri[i];
        ResultStore[i] = localHitData[HitDataHitLocation + i] + direction[i];
    }
}

void createRay(int x, int y)
{
    float sx = (float) x, sy = (float) y, sview[3];
    int i;
    
    // First scale x and scale y:
    sx *= Camera[CameraDFoVARDW];
    sx -= Camera[CameraFoVAR];
    sy *= Camera[CameraDFoVDH];
    sy -= Camera[CameraFoV];
    
    
    
    // Next, scale horizontal and vertical.
    for (i = 0; i < 3; i += 1)
        sview[i] = (sx * Camera[CameraHorizontal + i]) + (sy * Camera[CameraVertical + i]) + Camera[CameraView + i];
        // printf("sview[%i] = %f\n", i, sview[i]);
    
    vecNormalised(sview);
    
    // Populate the resultstore with the ray vector
    for (i = 0; i < 3; i += 1)
    {
        ResultStore[i + 3] = ResultStore[i];
        ResultStore[i] = Camera[CameraLocation + i];
    }
    // for (i = 0; i < 6; i += 1)
    //     printf("CreateRay[%i] = %f\n", i, ResultStore[i]);
}

/* Creates ambiance effect given a hit, a scene and some light */
void ambiance(float localHitData[18], float textureColour[3])
{
    int i, objIdx = (void) localHitData[HitDataObjectIndex];
    
    // Check to see if there's a texture
    if (textureColour[0] < 0)
    {
         // No texture. Apply material colour
        for (i = 0; i < 3; i += 1)
            RGBChannels[i] = MaterialDB[objIdx][MaterialCompAmbianceColour + i];
    }
    else
    {
        // Texture. Apply texture colour
        for (i = 0; i < 3; i += 1)
            RGBChannels[i] = MaterialDB[objIdx][MaterialAmbiance] * textureColour[i];
    }
}

/* Creates diffusion effect given a hit, a scene and some light */
void diffusion(float localHitData[18], float lightDirection[3], float textureColour[3])
{
    float vector[3], distance, dotProduct;
    int i, hitObjIdx = (void) localHitData[HitDataObjectIndex];
    
    if ((void)MaterialDB[hitObjIdx][MaterialDiffusive])
    {
        for (i = 0; i < 3; i += 1)
            vector[i] = localHitData[HitDataHitNormal + i];
        
        // Need to compute the direction of light
        dotProduct = dot(vector, lightDirection);
        
        // If the dot product is negative, this term shouldn't be included.
        if (dotProduct < 0)
            return;
        
        // Dot product is positive, so continue
        distance = dotProduct * MaterialDB[hitObjIdx][MaterialDiffusive];
        
        // Has a texture been defined?
        if (textureColour[0] < 0)
        {
            // No texture defined
            for (i = 0; i < 3; i += 1)
                RGBChannels[i] += distance * MaterialDB[hitObjIdx][MaterialLightColour + i];
        }
        else
        {
            // Combination of the texture colour and the material
            // Extract the light colour:
            for (i = 0; i < 3; i += 1)
                RGBChannels[i] += distance * Light[LightColour + i] * textureColour[i];
        }
    }
}

/* Creates specular effect given a hit, a scene and some light */
void specular(float localHitData[18], float lightDirection[3], float textureColour[3])
{
    int i, hitObjIdx = (void) localHitData[HitDataObjectIndex];
    float vector[3], dotProduct, distance;
    
    if ((void) MaterialDB[hitObjIdx][MaterialSpecular])
    {
        // Reflective ray:
        reflectRay(localHitData);
        for (i = 0; i < 3; i += 1)
            vector[i] = ResultStore[RayDirectionx + i];
        
        dotProduct = dot(lightDirection, vector);
        
        if (dotProduct < 0)
            return;
        
        distance = fp_pow(dotProduct, MaterialDB[hitObjIdx][MaterialShininess]) * MaterialDB[hitObjIdx][MaterialSpecular];
            
        // Has a texture been defined?
        if (textureColour[0] < 0)
        {
            // No texture defined
            for (i = 0; i < 3; i += 1)
                RGBChannels[i] += distance * MaterialDB[hitObjIdx][MaterialLightColour + i];
        }
        else
        {
            // Extract the light colour
            for (i = 0; i < 3; i += 1)
                RGBChannels[i] += (distance * Light[LightColour + i] * textureColour[i]);
        }
    }
}

void setMaterial(int materialIdx, float colour[3], float ambiance, float diffusive, float specular, float shininess, float reflectivity, float opacity, float refractivity, int textureIndex)
{
    int i;
    
    // Start by populating the colour
    for (i = 0; i < 3; i += 1)
    {
        MaterialDB[materialIdx][MaterialColour + i] = colour[i];
        MaterialDB[materialIdx][MaterialLightColour + i] = colour[i] * Light[i + LightColour];
        MaterialDB[materialIdx][MaterialCompAmbianceColour + i] = ambiance * MaterialDB[materialIdx][MaterialLightColour + i];
    }
    
    MaterialDB[materialIdx][MaterialReflectivity] = reflectivity;
    MaterialDB[materialIdx][MaterialOpacity] = opacity;
    MaterialDB[materialIdx][MaterialRefractivity] = refractivity;
    if (!((void) refractivity))
    {
        MaterialDB[materialIdx][MaterialInverseRefractivity] = 1.0;
        MaterialDB[materialIdx][MaterialSquareInverseRefractivity] = 1.0;
    }
    else
    {
        MaterialDB[materialIdx][MaterialInverseRefractivity] = 1.0 / refractivity;
        MaterialDB[materialIdx][MaterialSquareInverseRefractivity] = 1.0 / (refractivity * refractivity);
    }

    MaterialDB[materialIdx][MaterialAmbiance] = ambiance;
    MaterialDB[materialIdx][MaterialDiffusive] = diffusive;
    MaterialDB[materialIdx][MaterialSpecular] = specular;
    MaterialDB[materialIdx][MaterialShininess] = shininess;
    MaterialDB[materialIdx][MaterialTextureIndex] = textureIndex;
}

void createCube(int objectIndex, float size, float transMat[16])
{
    float u[3], v[3], w[3];
    float minVal, maxVal;
    int i, j;
    
    int pattern[108] = {0, 0, 0, // T1
                        1, 0, 0,
                        1, 1, 0,
                        1, 1, 0, // T2
                        0, 1, 0,
                        0, 0, 0,
                        1, 0, 0, // T3
                        1, 0, 1,
                        1, 1, 1,
                        1, 1, 1, // T4
                        1, 1, 0,
                        1, 0, 0,
                        1, 0, 1, // T5
                        0, 0, 1,
                        0, 1, 1,
                        0, 1, 1, // T6
                        1, 1, 1,
                        1, 0, 1,
                        0, 0, 1, // T7
                        0, 0, 0,
                        0, 1, 0,
                        0, 1, 0, // T8
                        0, 1, 1,
                        0, 0, 1,
                        0, 0, 0, // T9
                        0, 0, 1,
                        1, 0, 1,
                        1, 0, 1, // T10
                        1, 0, 0,
                        0, 0, 0,
                        0, 1, 0, // T11
                        1, 1, 0,
                        1, 1, 1,
                        1, 1, 1, // T12
                        0, 1, 1,
                        0, 1, 0};
    
    // Halve the size:
    size = (void)((void) size >> 1);
    
    // Points will always be at the extremes:
    minVal = -size;
    maxVal = size;
    
    // for (i = 0; i < 4; i += 1)
    //     for (j = 0; j < 4; j += 1)
    //         printf("T[%i][%i] = %f\n", i, j, transMat[(i * 4 + j)]);
    
    for (i = 0; i < 12; i += 1)
    {
        for (j = 0; j < 3; j += 1)
        {
            u[j] = (pattern[(i * 9) + j]) ? maxVal : minVal;
            v[j] = (pattern[(i * 9) + 3 + j]) ? maxVal : minVal;
            w[j] = (pattern[(i * 9) + 6 + j]) ? maxVal : minVal;
        }
        matVecMult(transMat, u);
        for (j = 0; j < 3; j += 1)
            u[j] = ResultStore[j];
        matVecMult(transMat, v);
        for (j = 0; j < 3; j += 1)
            v[j] = ResultStore[j];
        matVecMult(transMat, w);
        for (j = 0; j < 3; j += 1)
            w[j] = ResultStore[j];
        setTriangle(objectIndex, noTriangles[objectIndex], w, v, u);
    }
}

void createPlaneXZ(int objectIndex, float size, float transMat[16])
{
    float u[3] = {0, 0, 0}, v[3] = {0, 0, 0}, w[3] = {0, 0, 0};
    float minVal, maxVal;
    int i, j;
    
    // Create a pattern
    int pattern[12] = {1, 1,
                       1, 0,
                       0, 0,
                       1, 1,
                       0, 1,
                       0, 0};
    
    // Halve the size
    size = (void)((void) size >> 1);
    
    minVal = -size;
    maxVal = size;
    
    // for (i = 0; i < 4; i += 1)
    //     for (j = 0; j < 4; j += 1)
    //         printf("T[%i][%i] = %f\n", i, j, transMat[(i * 4 + j)]);
    
    // Create two triangles:
   for (i = 0; i < 2; i += 1)
   {
       u[1] = 0;
       v[1] = 0;
       w[1] = 0;
       for (j = 0; j < 2; j += 1)
       {
           u[j * 2] = (pattern[(i * 6) + j]) ? maxVal : minVal;
           v[j * 2] = (pattern[(i * 6) + j + 2]) ? maxVal : minVal;
           w[j * 2] = (pattern[(i * 6) + j + 4]) ? maxVal : minVal;
       }
       matVecMult(transMat, u);
       for (j = 0; j < 3; j += 1)
           u[j] = ResultStore[j];
       matVecMult(transMat, v);
       for (j = 0; j < 3; j += 1)
           v[j] = ResultStore[j];
       matVecMult(transMat, w);
       for (j = 0; j < 3; j += 1)
           w[j] = ResultStore[j];
       if (!i)
           setTriangle(objectIndex, noTriangles[objectIndex], u, v, w);
       else
           setTriangle(objectIndex, noTriangles[objectIndex], w, v, u);
   }
}

void getTexel(float localHitData[18], float uv[2])
{
    float c1[3], c2[3], c3[3], c4[3];
    float URem, VRem, alpha, uvf0, uvf1;
    int b1, b2, b3, b4, uv0 = (void) uv[0], uv1 = (void) uv[1];
    float a1, a2, a3, a4;
    int TextUPos, TextVPos, i;
    
    // Locate the pixel intersection
    uv0 += 0x03E80000;
    uv0 &= 0x0000FFFF;
    uv1 += 0x03E80000;
    uv1 &= 0x0000FFFF;
    uvf0 = (void) uv0;
    uvf1 = (void) uv1;
    
    uv[0] = uvf0 * (TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureWidth] << 16);
    uv[1] = uvf1 * (TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureHeight] << 16);
    
    uv0 = (void) uv[0];
    uv1 = (void) uv[1];
    
    // Get the whole number pixel value
    TextUPos = uv0 >> 16;
    TextVPos = uv1 >> 16;
    
    uv0 &= 0x0000FFFF;
    uv1 &= 0x0000FFFF;
         
    // Compute weights from the fractional part
    URem = (void) uv0;
    VRem = (void) uv1;
    
    // Border checks:
    // Offset (0, 0)
    b1 = TextUPos + TextVPos * TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureWidth];
    // Offset (1, 0)
    b2 = (TextUPos < TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureWidth]) ? b1 + 1 : 0;
    // Offset (0, 1)
    b3 = (TextVPos < TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureHeight]) ? TextUPos + (TextVPos + 1) * TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureWidth] : TextUPos;
    // Offset (1, 1)
    b4 = (TextUPos < TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureWidth]) ? (TextVPos < TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureHeight]) ? TextUPos + 1 + (TextVPos + 1) * TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureWidth] : TextUPos + 1 : (TextVPos < TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureHeight]) ? (TextVPos + 1) * TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureWidth] : 0;
    
    // Compute colours at points
    for (i = 0; i < 3; i += 1)
    {
        writesdram(TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureMemStart] + i + (b1 * (TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureAlpha] ? 4 : 3)), c1[i], 1);
        writesdram(TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureMemStart] + i + (b2 * (TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureAlpha] ? 4 : 3)), c2[i], 1);
        writesdram(TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureMemStart] + i + (b3 * (TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureAlpha] ? 4 : 3)), c3[i], 1);
        writesdram(TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureMemStart] + i + (b4 * (TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureAlpha] ? 4 : 3)), c4[i], 1);
    }
    
    // Bilinear filter:
    a1 = (1 - URem) * (1 - VRem);
    a2 = URem * (1 - VRem);
    a3 = (1 - URem) * VRem;
    a4 = URem * VRem;
    
    for (i = 0; i < 3; i += 1)
    {
        // Scaled sum of components:
        ResultStore[i] = a1 * c1[i] + a2 * c2[i] + a3 * c3[i] + a4 * c4[i];
        // Overflow check
        if (ResultStore[i] > 1)
            ResultStore[i] = 1;
    }
    
    // Now compute the alpha value:
    if (TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureAlpha] >= 0 && 0)
    {
        // Extract alpha channels
        writesdram(TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureMemStart] + 3 + (b1 * 4), c1[1], 1);
        writesdram(TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureMemStart] + 3 + (b2 * 4), c2[1], 1);
        writesdram(TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureMemStart] + 3 + (b3 * 4), c3[1], 1);
        writesdram(TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureMemStart] + 3 + (b4 * 4), c4[1], 1);
        a1 *= c1[1];
        a2 *= c2[1];
        a3 *= c3[1];
        a4 *= c4[1];
        // ResultStore[3] = alpha
        ResultStore[3] = a1 + a2 + a3 + a4;
        // Overflow check
        if (ResultStore[3] > 1)
            ResultStore[3] = 1;
    }
    else
        ResultStore[3] = 1;
    
}

void getColour(float localHitData[18])
{
    float uv1[2], uv2[2], uv3[2];
    int i, hitObjIdx = (void) localHitData[HitDataObjectIndex], hitTriIdx = (void) localHitData[HitDataTriangleIndex];
    
    for (i = 0; i < 2; i += 1)
    {
        uv1[i] = ObjectDB[hitObjIdx][hitTriIdx][TriangleAu + i];
        uv2[i] = ObjectDB[hitObjIdx][hitTriIdx][TriangleBu + i] - uv1[i];
        uv3[i] = ObjectDB[hitObjIdx][hitTriIdx][TriangleCu + i] - uv1[i];
    }
    // V - U
    // Scale with Mu
    // Extract the results
    uv2[0] *= localHitData[HitDataMu];
    uv2[1] *= localHitData[HitDataMu];
    
    // W - U
    // Scale with Mv
    // Contents of UV3 in results store. Let's just extract it from there.
    
    // Then add UV1, UV2 and UV3:
    uv1[0] += uv2[0] + localHitData[HitDataMv] * uv3[0];
    uv1[1] += uv2[1] + localHitData[HitDataMv] * uv3[1];
    
    getTexel(localHitData, uv1);
    // This should return the results within the results store.
}


/* Populate a scene with set items */
void populateDefaultScene()
{
    int i;
    float red[3] = {1.0, 0, 0};
    float green[3] = {0, 1.0, 0};
    float blue[3] = {0, 0, 1.0};
    float purple[3] = {0.54, 0, 1.0};
    float white[3] = {1.0, 1.0, 1.0};
    float transMat[16], tempMat[16];
    
    // Set material types
    // setMaterial(int materialIdx, float colour[3], float ambiance, float diffusive, float specular, float shininess, float reflectivity, float opacity, float refractivity, int textureIndex)
    setMaterial(0, red, 0.3, 0.5, 0.0, 0.0, 0.0, 0.8, 1.4, -1);
    setMaterial(1, blue, 0.1, 0.5, 0.4, 2.0, 0.0, 0.0, 1.4, -1);
    setMaterial(2, green, 0.1, 0.5, 0.4, 2.0, 0.0, 0.0, 1.4, -1);
    setMaterial(3, purple, 0.1, 0.5, 0.4, 2.0, 0.0, 0.0, 1.4, -1);
    setMaterial(4, white, 0.1, 0.0, 0.9, 32.0, 0.6, 0.0, 1.4, -1);
    
    noObjects = 5;
    
    // Create one object at a time by first creating transformation matrix and then shape.
    
    // Cube 1:
    genTransMatrix(2.0, 0.5, -1.0);
    for (i = 0; i < 16; i += 1)
        tempMat[i] = ResultStore[i];
    genYRotateMat(45.0);
    for (i = 0; i < 16; i += 1)
        transMat[i] = ResultStore[i];
    matMult(tempMat, transMat);
    for (i = 0; i < 16; i += 1)
        transMat[i] = ResultStore[i];
    // createCube(int objectIndex, float size, float transMat[16])
    createCube(0, 1.0, transMat);
    
    // PlaneXZ 1: the base plane:
    genTransMatrix(1.0, 0.0, -4.0);
    for (i = 0; i < 16; i += 1)
        transMat[i] = ResultStore[i];
    createPlaneXZ(3, 10.0, transMat);
    
    // PlaneXZ 3: the left plane:
    genTransMatrix(-2.0, 0.0, -4.0);
    for (i = 0; i < 16; i += 1)
        tempMat[i] = ResultStore[i];
    genZRotateMat(-90.0);
    for (i = 0; i < 16; i += 1)
        transMat[i] = ResultStore[i];
    matMult(tempMat, transMat);
    for (i = 0; i < 16; i += 1)
        transMat[i] = ResultStore[i];
    createPlaneXZ(2, 10.0, transMat);
    
    // PlaneXZ 4: the right plane:
    genTransMatrix(4.0, 0.0, -4.0);
    for (i = 0; i < 16; i += 1)
        tempMat[i] = ResultStore[i];
    genZRotateMat(90.0);
    for (i = 0; i < 16; i += 1)
        transMat[i] = ResultStore[i];
    matMult(tempMat, transMat);
    for (i = 0; i < 16; i += 1)
        transMat[i] = ResultStore[i];
    createPlaneXZ(2, 10.0, transMat);
    
    // PlaneXZ 5: the back plane:
    genTransMatrix(1.0, 0.0, -6.0);
    for (i = 0; i < 16; i += 1)
        tempMat[i] = ResultStore[i];
    genXRotateMat(90.0);
    for (i = 0; i < 16; i += 1)
        transMat[i] = ResultStore[i];
    matMult(tempMat, transMat);
    for (i = 0; i < 16; i += 1)
        transMat[i] = ResultStore[i];
    createPlaneXZ(1, 10.0, transMat);
    
    // // PlaneXZ 2: the top plane:
    // genTransMatrix(1.0, 5.0, -4.0);
    // for (i = 0; i < 16; i += 1)
    //     tempMat[i] = ResultStore[i];
    // genZRotateMat(180.0);
    // for (i = 0; i < 16; i += 1)
    //     transMat[i] = ResultStore[i];
    // matMult(tempMat, transMat);
    // for (i = 0; i < 16; i += 1)
    //     transMat[i] = ResultStore[i];
    // // createPlaneXZ(3, 10.0, transMat);
    
    // Mirror Cube:
    genTransMatrix(0.0, 0.9, -2.7);
    for (i = 0; i < 16; i += 1)
        tempMat[i] = ResultStore[i];
    genYRotateMat(20.0);
    for (i = 0; i < 16; i += 1)
        transMat[i] = ResultStore[i];
    matMult(tempMat, transMat);
    for (i = 0; i < 16; i += 1)
        transMat[i] = ResultStore[i];
    // createCube(int objectIndex, float size, float transMat[16])
    createCube(4, 1.5, transMat);
    
}

/* The populateScene function calls the ReadByteFile function. This is here mainly
   for compatibility with older generations of the OFconstruct header file.        */
void populateScene()
{
    // Should the default scene be loaded?
    /*
    if (inputFile[0] == '\0')
    */
    populateDefaultScene(); // Pass inputs to the default scene.
    /*
    else
        ReadByteFile(scene, lightSrc, m, f); // Pass all inputs to the byte file reader.
    */
}

/* And then the standard draw function that's been previously constructed */
void draw(float ray[6], int recursion)
{
    float outputColour[3] = {0, 0, 0}, textureColour[3] = {-1.0, -1.0, -1.0};
    float vector[3], localHitData[18], lightDirection[3];
    float alpha, reflection, refraction;
    float newRay[6];
    int i, hitObjIdx;
    
    // Check for an intersection. Results are stored in the hit data array
    sceneIntersection(ray);
    
    hitObjIdx = (void) HitData[HitDataObjectIndex];
    
    // Determine whether there was a hit. Otherwise default.
    if (hitObjIdx >= 0)
    {
        // There was a hit.
        
        // The first thing to do is to take a copy of the local hit data. This is necessary as the
        // draw function can be called (as a child) prior to completion of the (parent) draw function.
        for (i = 0; i < 18; i += 1)
            localHitData[i] = HitData[i];
        
        // Determine whether the light vector describes the direction or the position:
        if ((void) Light[LightGlobalFlag])
            for (i = 0; i < 3; i +=1)
                lightDirection[i] = Light[LightVector + i];
        else
        {
            // Populate the light direction from the light location
            for (i = 0; i < 3; i += 1)
            {
                // Subtract the light location and the hit position:
                vector[i] = Light[LightVector + i] - localHitData[HitDataHitLocation + i];
            }
            
            // Then normalise the resultant vector which will be the light direction
            vecNormalised(vector);
            // Copy the result from the result store
            for (i = 0; i < 3; i += 1)
                lightDirection[i] = ResultStore[i];
        }
        
        // Determine whether this has a texture or not
        i = (void) MaterialDB[hitObjIdx][MaterialTextureIndex];
        if (i >= 0)
        {
            // The getColour function doesn't need anything but the hit data to be passed to it.
            // It can determine which texture to use via the material DB (which uses the object
            // index).
            getColour(localHitData);
            // This function returns the RGBA value. This is held in the result store:
            for (i = 0; i < 3; i += 1)
                textureColour[i] = ResultStore[i];
            alpha = ResultStore[3];
            
            // Check to see if we need to create a new ray from this point:
            if (alpha < 1 && recursion >= 0)
            {
                // Yes, the alpha channel is < 1, so create a new ray starting from the point of intersection.
                // This ray has the same direction but a different source (the point of intersection).
                for (i = 0; i < 3; i += 1)
                {
                    newRay[RayDirectionx + i] = ray[RayDirectionx + i];
                    // Recompute the source by adding a little extra to the distance.
                    // Compute the total distance first, then add the two vectors together:
                    // Then set this as the new ray's source:
                    newRay[i] = ((localHitData[HitDataDistance] + 0.001953125) * ray[RayDirectionx + i]) + ray[i]; // .001953125 is eqivalent to 0x80
                }
                
                // Next, emit a ray. Don't reduce the recursion count.
                draw(newRay, recursion);
                
                // The resultant RGB value should be extracted and scaled based on the alpha value.
                // Next, take the colour and previous alpha value and compute the product,
                // Then add the two components together and the result is the texture colour:
                for (i = 0; i < 3; i += 1)
                    textureColour[i] = ((1 - alpha) * ResultStore[i]) + (alpha * textureColour[i]);
            }
        }
        // Now compute the individual lighting effects and add the components together.
        // These are stored in the RGB components vector
        ambiance(localHitData, textureColour);
        diffusion(localHitData, lightDirection, textureColour);
        specular(localHitData, lightDirection, textureColour);
        
        // Extract the colours into a local variable.
        for (i = 0; i < 3; i += 1)
            outputColour[i] = RGBChannels[i];
        
        // Should we go deeper?
        if (recursion > 0)
        {
            // Yes, we should
            // Get the reflection
            reflection = MaterialDB[localHitData[HitDataObjectIndex]][MaterialReflectivity];
            if ((void) reflection)
            {
                // Create the new reflected ray:
                reflectRay(localHitData);
                // And then extract the result:
                for (i = 0; i < 6; i += 1)
                    newRay[i] = ResultStore[i];
                // Call the draw function
                draw(newRay, recursion - 1);
                // And extract the result from result store:
                for (i = 0; i < 3; i += 1)
                    outputColour[i] += (reflection * ResultStore[i]);
            }
            // Extract the material's opacity:
            refraction = MaterialDB[localHitData[HitDataObjectIndex]][MaterialOpacity];
            if ((void) refraction)
            {
                // Get the refraction in a similar way:
                refractRay(localHitData, MaterialDB[localHitData[HitDataObjectIndex]][MaterialInverseRefractivity], MaterialDB[localHitData[HitDataObjectIndex]][MaterialSquareInverseRefractivity]);
                // And then extract the result:
                for (i = 0; i < 6; i += 1)
                    newRay[i] = ResultStore[i];
                // Call the draw function
                draw(newRay, recursion - 1);
                // Populate the refractiveColour vector:
                for (i = 0; i < 3; i += 1)
                    outputColour[i] += (refraction * ResultStore[i]);
            }
        }
        // printf("Hit at: %f, %f, %f\nRay Direction: %f, %f, %f\nLight direction: %f, %f, %f\n", fp_FP2Flt(hit.location.x), fp_FP2Flt(hit.location.y), fp_FP2Flt(hit.location.z), fp_FP2Flt(ray.direction.x), fp_FP2Flt(ray.direction.y), fp_FP2Flt(ray.direction.z), fp_FP2Flt(lightDirection.x), fp_FP2Flt(lightDirection.y), fp_FP2Flt(lightDirection.z));
        // printf("Got to shadow...\n");
        // printf("Col so far: %f, %f, %f\n", outputColour[0], outputColour[1], outputColour[2]);
        scalarVecMult(1.0 - traceShadow(localHitData, lightDirection), outputColour);
        // The result is saved to the result store.
        return;
    }
    
    // No hit, return black.
    
    for (i = 0; i < 3; i += 1)
        ResultStore[i] = outputColour[i];
}
// Prototypes
/*
void datainterrupt(int, int, int, int);
void RayTrace(void);
void EnterExternalData(int, int, int, int);
*/
// Functions start here:
int main(void)
{
    float clocation[3] = {1.0, 2.0, 4.0}, cTheta = (void) 0x0001C4A8, cPhi = (void) 0xFFFE6DDE, cview[3], ray[6];
    int i, x, y;
    
    for (i = 0; i < MAX_OBJECTS; i += 1)
        noTriangles[i] = 0;
    
    printf("Initialising light source...\n");
    
    // Global Lighting flag:
    Light[LightGlobalFlag] = 0;
    
    if (!((void) Light[LightGlobalFlag]))
    {
        // Set the light source coordinates:
        Light[LightVector + 0] = -1.0;
        Light[LightVector + 1] =  4.0;
        Light[LightVector + 2] =  4.0;
    }
    else
    {
        // Set the light direction
        Light[LightVector + 0] = -0.441128773;
        Light[LightVector + 1] =  0.514650235;
        Light[LightVector + 2] =  0.735214622;
    }
    
    // White light:
    Light[LightColour + 0] =  1.0;
    Light[LightColour + 1] =  1.0;
    Light[LightColour + 2] =  1.0;
    
    // Shadow factor:
    Light[LightShadowFactor] = 0.3;
    
    printf("Initialising camera...\n");
    // Now initialise the camera:
    cview[0] = fp_sin(cTheta) * fp_cos(cPhi);
    cview[1] = fp_cos(cTheta);
    cview[2] = fp_sin(cTheta) * fp_sin(cPhi);
    
    printf("View vector: %f, %f, %f\n", cview[0], cview[1], cview[2]);
    printf("Setting camera options...\n");
    setCamera(clocation, cview, 45.0, IMAGE_WIDTH, IMAGE_HEIGHT);
    
    printf("Populating scene...\n");
    // Now populate the scene.
    populateScene();
    
    printf("Scene dimensions: %i %i\n", IMAGE_WIDTH, IMAGE_HEIGHT);
    
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
    
    exit(99);
    return 0;
}


#alias raytracernode 1
       