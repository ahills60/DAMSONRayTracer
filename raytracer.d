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
void negVec(float u[3]);
float vecLength(float u[3]);
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
void scalarUVMult(float a, float u[2]);
void setCamera(float location[3], float view[3], float fov, int width, int height);
float triangleIntersection(float ray[6], int objectIdx, int triangleIdx, float currentDistance);
void objectIntersection(float ray[6], int objectIdx);
void sceneIntersection(float ray[6]);
float traceShadow(float localHitData[18], float direction[3]);
void reflectRay(float localHitData[18]);
// void refractRay(float localHitData[18], float inverserefreactivity, float squareinverserefractivity);
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
    float c, absc, absa;
    // int b = bitset(a);
    float output;
    // Ensure input within the range of -pi to pi
    // a += (a < -FP_PI) ? FP_2PI : 0.0;
    // a -= (a > FP_PI) ? FP_2PI : 0.0;
    if (a > FP_PI)
        a -= FP_2PI;
    if (a < -FP_PI)
        a += FP_2PI;
    
    // printf("%f\n", a);
    
    absa = fabs(a);
    
    // Use fast sine parabola approximation
    c = (FP_CONST_B * a) + (FP_CONST_C * a * absa);
    
    absc = fabs(c);
    
    // printf("%d : %d : %d\n", c, absc, FP_CONST_Q);
    
    // Get extra precision weighting the parabola:
    c += (FP_CONST_Q * ((c * absc) - c)); // Q * output + P * output * abs(output)
    
    // Finally, convert the integer back to a float.
    return c;
}

/* Fixed point cosine */
float fp_cos(float a)
{
    float b = a;
    b += FP_PI_2;
    // printf("%f (input) => %f (add pi/2)\n", a, b);
    // a += (a < -FP_PI) ? FP_2PI : 0;
    // c = (b > FP_PI) ? FP_2PI : 0.0;
    // b -= (b > FP_PI ? FP_2PI : 0.0);
    
    // printf("%f (if inline result) =/= %f (if branch result) (%f (inline eval) =/= %f (branch eval))\n", d, f, c, e);
    
    // Use the sine function
    return fp_sin(b);
}

float fp_exp(float z) 
{
    int t;
    int x = bitset(z);
    int y = 0x00010000;  /* 1.0 */
    
    // Bound to a maximum if larger than ln(0.5 * 32768)
    if (x > 0x000A65AE)
        return bitset(MAX_VAL);
    
    // Fix for negative values.
    if (x < 0)
    {
        x += 0xb1721; /* 11.0903 */
        y >>= 16;
    }
    
    t=x-0x58b91;   /* 5.5452 */ 
    if (t>=0) 
    {
        x=t;
        y<<=8;
    }
    t=x-0x2c5c8;   /* 2.7726 */
    if (t>=0) 
    {
        x=t;
        y<<=4;
    }
    t=x-0x162e4;  /* 1.3863 */
    if (t>=0) 
    {
        x=t;
        y<<=2;
    }
    t=x-0x0b172;  /* 0.6931 */
    if (t>=0) 
    {
        x=t;
        y<<=1;
    }
    t=x-0x067cd;  /* 0.4055 */
    if (t>=0)
    {
        x=t;
        y+=y>>1;
    }
    t=x-0x03920;  /* 0.2231 */
    if (t>=0)
    {
        x=t;
        y+=y>>2;
    }
    t=x-0x01e27;  /* 0.1178 */
    if (t>=0)
    {
        x=t;
        y+=y>>3;
    }
    t=x-0x00f85;  /* 0.0606 */
    if (t>=0)
    {
        x=t;
        y+=y>>4;
    }
    t=x-0x007e1;  /* 0.0308 */
    if (t>=0) 
    {
        x=t;
        y+=y>>5;
    }
    t=x-0x003f8;  /* 0.0155 */
    if (t>=0) 
    {
        x=t;
        y+=y>>6;
    }
    t=x-0x001fe;  /* 0.0078 */
    if (t>=0) 
    {
        x=t;
        y+=y>>7;
    }
    // This is does the same thing:
    y += ((y >> 8) * x) >> 8;
    return bitset(y);
}

float fp_log(float a)
{
    int t,y, x = bitset(a);
    
    if (a <= 0)
        return bitset(MIN_VAL);

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
    if((t & 0x80000000) == 0) 
    {
        x = t;
        y -= 0x067cd;
    }
    t = x + (x >> 2);
    if((t & 0x80000000) == 0)
    {
        x = t;
        y -= 0x03920;
    }
    t = x + (x >> 3);
    if((t & 0x80000000) == 0)
    {
        x = t;
        y -= 0x01e27;
    }
    t = x + (x >> 4);
    if((t & 0x80000000) == 0)
    {
        x = t;
        y -= 0x00f85;
    }
    t = x + (x >> 5); 
    if((t & 0x80000000) == 0)
    {
        x = t;
        y -= 0x007e1;
    }
    t = x + (x >> 6); 
    if((t & 0x80000000) == 0) 
    {
        x = t;
        y -= 0x003f8;
    }
    t = x + (x >> 7);
    if((t & 0x80000000) == 0)
     {
         x = t;
         y -= 0x001fe;
     }
    x = 0x80000000 - x;
    y -= x >> 15;
    return bitset(y);
}

float fp_pow(float a, float b)
{
    float output;
    
    if (a <= 0.0)
        return 0.0;
    
    output = fp_exp(fp_log(a) * b);
    
    return output;
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
    int a = bitset(ina);
    int im, p = -16;
    int i, k = 0;
    int longNum;
    float output;
    
    if (a <= 0)
    {
        return 0;
    }
    
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
    {
        i = a >> (11 + p);
    }
    else
    {
        i = a << (-11 - p);
    }
    
    im = (i & 31) - 1;
    if (im >= 0)
    {
        k = LOOKUP_SQRT[im] & 0xFFFF;
        if ((p & 1) > 0)
        {
            k = k * 92682;
            if (k < 0)
            {
                k &= 0x7FFFFFFF;
                k >>= 16;
                k |= 0x8000;
            }
            else
                k = (k >> 16);
        }
    }
    
    if ((p & 1) > 0)
    {
        k += 92682; // add sqrt(2)
    }
    else
    {
        k += 0x10000; // add 1
    }
    
    // Shift the square root estimate based on the halved MSB position
    if (p >= 0)
    {
        k <<= (p >> 1);
    }
    else
    {
        k >>= ((1 - p) >> 1);
    }
    
    // // Do two Newtonian square root iteration steps to increase precision
    // int64 longNum = (int64)(a) << 16;
    // k += (fixedp) (longNum / k);
    // k = (k + (fixedp) ((longNum << 2) / k) + 2) >> 2;
    
    // longNum = a;
    /*
    printf("before: %d (a = %d)\n", k, a);
    k += a / k;
    printf("after: %d (a / k: %d)\n", k, a / k);
    k >>= 1;
    k += a / k;
    k >>= 1;
    */
    
    // Andrew special:
    output = bitset(k);
    output += ina / output;
    k = bitset(output);
    k >>= 1;
    output = bitset(k);
    output += ina / output;
    k = bitset(output);
    k >>= 1;
    
    // k >>= 1;
    // k = (k + ((longNum << 2) / k) + 2) >> 2;
    
    output = bitset(k);
    
    return output;
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

// /* Fast convert of list to matrix */
// void setMatrix(Matrix *F, fixedp *m, MathStat *ma, FuncStat *f)
// {
//     int n, p;
//
//     for (n = 0; n < 4; n++)
//     {
//         DEBUG_statPlusInt(ma, 1); // for the loop
//         for (p = 0; p < 4; p++)
//         {
//             DEBUG_statPlusInt(ma, 1); // for the loop
//             (*F).m[p][n] = m[n + 4 * p];
//
//             DEBUG_statGroupInt(ma, 1, 0, 1, 0);
//         }
//     }
// }

/* Convert from degrees to radians */
float deg2rad(float deg)
{
    int temp;
    // Equivalent to deg * pi / 180, but with increased resolution:
    deg *= 4.468042886;
    
    // shift
    temp = bitset(deg);
    temp >>= 8;
    deg = bitset(temp);
    // (deg * 256 * pi / 180) / 256
    return deg; // * M_PI / 180.0;
}

/* Vector multiply */
void vecMult(float u[3], float v[3])
{
    int i;
    for (i = 0; i < 3; i += 1)
        ResultStore[i] = u[i] * v[i];
}

/* Dot product of two vectors */
float dot(float u[3], float v[3])
{
    return u[0] * v[0] + u[1] * v[1] + u[2] * v[2];
}

/* Cross product of two vectors */
void cross(float u[3], float v[3])
{
    // {ResultStore[0][0], ResultStore[0][1], ResultStore[0][2]}
    ResultStore[0] = u[1] * v[2] - v[1] * u[2];
    ResultStore[1] = u[2] * v[0] - v[2] * u[0];
    ResultStore[2] = u[0] * v[1] - v[0] * u[1];
}

/* Scalar multiplication with a vector */
void scalarVecMult(float a, float u[3])
{
    int i;
    for (i = 0; i < 3; i += 1)
        ResultStore[i] = a * u[i];
}

/* Scalar division with a vector */
void scalarVecDiv(float a, float u[3])
{
    int i;
    for (i = 0; i < 3; i += 1)
        ResultStore[i] = u[i] / a;
}

/* Vector addition */
void vecAdd(float u[3], float v[3])
{
    int i;
    for (i = 0; i < 3; i += 1)
        ResultStore[i] = u[i] + v[i];
}

/* Vector subtraction */
void vecSub(float u[3], float v[3])
{
    int i;
    for (i = 0; i < 3; i += 1)
        ResultStore[i] = u[i] - v[i];
}

/* -1 * vector */
void negVec(float u[3])
{
    int i;
    for (i = 0; i < 3; i += 1)
        ResultStore[i] = -u[i];
}

/* Get the length of a vector */
float vecLength(float u[3])
{
    
    return fp_sqrt(u[0] * u[0] + u[1] * u[1] + u[2] * u[2]);
}

/* Normalised vector */
void vecNormalised(float u[3])
{
    float tempVar = u[0] * u[0] + u[1] * u[1] + u[2] * u[2];
    if ((void) tempVar == (void) 0)
    {
        ResultStore[0] = u[0];
        ResultStore[1] = u[1];
        ResultStore[2] = u[2];
    }
    else // Below function calls will populate ResultStore
        if ((void) tempVar == (void) 1)
            scalarVecMult(256.0, u); // Equivalent of 256 as 1 / sqrt(1.52E-5) is 256
        else
            scalarVecMult(fp_sqrt(1.0 / tempVar), u);
            // return scalarVecMult(fp_Flt2FP(1. / sqrtf(fp_FP2Flt(tempVar))), u, m, f);
            // return scalarVecMult(fp_sqrt(fp_div(fp_fp1, tempVar)), u, m, f);
}

/* Matrix multiplied by a vector */
void matVecMult(float F[16], float u[3])
{
    // Note that we don't consider the last row within the matrix. This is discarded deliberately.
    ResultStore[0] = F[0] * u[0] + F[1] * u[1] + F[2] * u[2] + F[3];
    ResultStore[1] = F[4] * u[0] + F[5] * u[1] + F[6] * u[2] + F[7];
    ResultStore[2] = F[8] * u[0] + F[9] * u[1] + F[10] * u[2] + F[11];
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
    
    ObjectDB[objectIndex][triangleIndex][TriangleDominantAxisIdx] = bitset(domIdx);
    
    // Use the array to quickly resolve modulo.
    uIdx = DomMod[domIdx + 1];
    vIdx = DomMod[domIdx + 2];
    
    // This should make calculations easier...
    dk = (domIdx == 1) ? NormDom[1] : (( domIdx == 2) ? NormDom[2] : NormDom[0]);
    du = (uIdx == 1) ? NormDom[1] : ((uIdx == 2) ? NormDom[2] : NormDom[0]);
    dv = (vIdx == 1) ? NormDom[1] : ((vIdx == 2) ? NormDom[2] : NormDom[0]);
    
    bu = (uIdx == 1) ? wmu[1] : ((uIdx == 2) ? wmu[2] : wmu[0]);
    bv = (vIdx == 1) ? wmu[1] : ((vIdx == 2) ? wmu[2] : wmu[0]);
    cu = (uIdx == 1) ? vmu[1] : ((uIdx == 2) ? vmu[2] : vmu[0]);
    cv = (vIdx == 1) ? vmu[1] : ((vIdx == 2) ? vmu[2] : vmu[0]);
    
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
    if ((void) dk == (void) 0)
        dk = 1.0;
    ObjectDB[objectIndex][triangleIndex][TriangleNUDom] = du / dk;
    ObjectDB[objectIndex][triangleIndex][TriangleNVDom] = dv / dk;
    ObjectDB[objectIndex][triangleIndex][TriangleNDDom] = dot(NormDom, u) / dk;
    
    // First line of the equation:
    coeff = (bu * cv) - (bv * cu);
    if ((void) coeff == (void) 0)
        coeff = 1.0;
    ObjectDB[objectIndex][triangleIndex][TriangleBUDom] = bu / coeff;
    ObjectDB[objectIndex][triangleIndex][TriangleBVDom] = -(bv / coeff);
    // Second line of the equation:
    ObjectDB[objectIndex][triangleIndex][TriangleCUDom] = cv / coeff;
    ObjectDB[objectIndex][triangleIndex][TriangleCVDom] = -(cu / coeff);
    
    // Finally, increment the number of triangles statistic.
    noTriangles[objectIndex] += 1;
    
}

// Multiple a UV coordinate by a scalar value
void scalarUVMult(float a, float u[2])
{
    int i;
    
    for (i = 0; i < 2; i += 1)
        ResultStore[i] = a * u[i];
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
    float vertical[3], horizontal[3], up[3] = {0, 1.0, 0}, ar, fovh, dfovardw, fovar, dfovdh;
    int i, temp;
    
    cross(view, up);
    for (i = 0; i < 3; i += 1)
        horizontal[i] = ResultStore[i];
    
    cross(horizontal, view);
    for (i = 0; i < 3; i += 1)
        vertical[i] = ResultStore[i];
    
    temp = bitset(fov);
    temp >>= 1;
    fovh = bitset(temp);
    fovh = deg2rad(fovh);
    
    // Now calcualte aspect ratio
    ar = (float) width / (float) height;
    
    temp = bitset(ar);
    temp <<= 1;
    dfovardw = bitset(temp);
    dfovardw *= fovh;
    dfovardw /= (float) width;
    
    fovar = fovh * ar;
    
    dfovdh = deg2rad(fov) / (float) height;
    
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
    Camera[CameraFoVAR] = fovar;
    Camera[CameraDFoVDH] = dfovdh;
}

float triangleIntersection(float ray[6], int objectIdx, int triangleIdx, float currentDistance)
{
    int ku, kv;
    float dk, du, dv, ok, ou, ov, denom, dist, hu, hv, au, av, numer, beta, gamma, cmpopt, tempFl, tempFl2;
    
    int shift1, msb1, msb2, bitdiff1, biteval, denomi, numeri, cmpopti;
    int tempVar1, tempVar2;
    
    int dominantAxisIdx = bitset(ObjectDB[objectIdx][triangleIdx][TriangleDominantAxisIdx]);
    
    // Determine if an error occurred when preprocessing this triangle:
    if (dominantAxisIdx > 2 || dominantAxisIdx < 0)
        return 0;
    
    // Now get the correct axes and offset using the modulo vector:
    ku = DomMod[dominantAxisIdx + 1];
    kv = DomMod[dominantAxisIdx + 2];
    
    
    // Now take the correct components for destination:
    dk = (dominantAxisIdx == 0) ? ray[RayDirectionx] : ((dominantAxisIdx == 1) ? ray[RayDirectiony] : ray[RayDirectionz]);
    du = (ku == 0) ? ray[RayDirectionx] : ((ku == 1) ? ray[RayDirectiony] : ray[RayDirectionz]);
    dv = (kv == 0) ? ray[RayDirectionx] : ((kv == 1) ? ray[RayDirectiony] : ray[RayDirectionz]);
    
    // Then do the same with the source:
    ok = (dominantAxisIdx == 0) ? ray[RaySourcex] : ((dominantAxisIdx == 1) ? ray[RaySourcex] : ray[RaySourcez]);
    ou = (ku == 0) ? ray[RaySourcex] : ((ku == 1) ? ray[RaySourcey] : ray[RaySourcez]);
    ov = (kv == 0) ? ray[RaySourcex] : ((kv == 1) ? ray[RaySourcey] : ray[RaySourcez]);
    
    // Compute the denominator:
    denom = dk + (ObjectDB[objectIdx][triangleIdx][TriangleNUDom] * du) + (ObjectDB[objectIdx][triangleIdx][TriangleNVDom] * dv);
    denomi = bitset(denom);
    if (denomi < 0x4 && denomi > -0x4)
        return 0;
    
    numer = ObjectDB[objectIdx][triangleIdx][TriangleNDDom] - ok - (ObjectDB[objectIdx][triangleIdx][TriangleNUDom] * ou) - (ObjectDB[objectIdx][triangleIdx][TriangleNVDom] * ov);
    
    numeri = bitset(numer);
    
    if (numeri == 0)
        return 0;
    // Do a sign check
    if ((denomi & 0x80000000) ^ (numeri & 0x80000000))
        return 0;
    
    // Locate the MSB of the numerator:
    tempVar1 = bitset(fabs(numer));
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
    tempVar1 = bitset(fabs(denom));
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
            return 0;
    }
    else
    {
        denomi <<= bitdiff1;
        tempFl = bitset(denomi);
        dist = numer / tempFl;
        // Early exit:
        tempVar1 = bitset(currentDistance);
        tempVar1 >>= bitdiff1;
        tempFl = bitset(tempVar1);
        if (tempFl < dist)
            return 0;
    }
    
    // Extract points from primary vector:
    au = (ku == 0) ? ObjectDB[objectIdx][triangleIdx][TriangleAx] : ((ku == 1) ? ObjectDB[objectIdx][triangleIdx][TriangleAy] : ObjectDB[objectIdx][triangleIdx][TriangleAz]);
    av = (kv == 0) ? ObjectDB[objectIdx][triangleIdx][TriangleAx] : ((kv == 1) ? ObjectDB[objectIdx][triangleIdx][TriangleAy] : ObjectDB[objectIdx][triangleIdx][TriangleAz]);
    
    // Continue calculating intersections:
    if (biteval)
    {
        hu = ou + (dist * du) - au;
        hv = ov + (dist * dv) - av;
    }
    else
    {
        tempVar1 = bitset(ou);
        tempVar2 = bitset(au);
        tempVar1 >>= bitdiff1;
        tempVar2 >>= bitdiff1;
        tempFl = bitset(tempVar1);
        tempFl2 = bitset(tempVar2);
        hu = tempFl + (dist * du) - tempFl2;
        tempVar1 = bitset(ov);
        tempVar2 = bitset(av);
        tempVar1 >>= bitdiff1;
        tempVar2 >>= bitdiff1;
        tempFl = bitset(tempVar1);
        tempFl2 = bitset(tempVar2);
        hv = tempFl + (dist * dv) - tempFl2;
    }
    
    beta = (hv * ObjectDB[objectIdx][triangleIdx][TriangleBUDom]) + (hu * ObjectDB[objectIdx][triangleIdx][TriangleBVDom]);
    cmpopti = EPS + (biteval ? 0x10000 : (0x10000 >> bitdiff1));
    cmpopt = bitset(cmpopti);
    
    // If negative, exit early
    if (beta < 0 || beta > cmpopt)
        return 0;
    
    gamma = (hu * ObjectDB[objectIdx][triangleIdx][TriangleCUDom]) + (hv * ObjectDB[objectIdx][triangleIdx][TriangleCVDom]);
    
    // If negative, exit early
    if (gamma < 0 || gamma > cmpopt)
        return 0;
    
    // As these are barycentric coordinates, the sum should be < 1
    if ((gamma + beta) > cmpopt)
        return 0;
    
    ResultStore[0] = beta;
    ResultStore[1] = gamma;
    ResultStore[2] = (float) bitdiff1;
    
    return dist;
}

void objectIntersection(float ray[6], int objectIdx)
{
    float Mu, Mv, intersectionPoint, nearestIntersection = bitset(FURTHEST_RAY);
    int n, i, nearestIdx, bitshift, nearestbitshift = 32;
    float dirVec[3], normVec[3], location[3];
    
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
            if (dot(normVec, dirVec) < EPS)
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
        scalarVecMult(nearestIntersection, dirVec);
        // Create the two vectors
        for (i = 0; i < 3; i += 1)
        {
            dirVec[i] = ResultStore[i];
            location[i] = ray[i];
        }
        // Add the two vectors together. The result is stored in the results store.
        vecAdd(location, dirVec);
        
        for (i = 0; i < 3; i += 1)
        {
            HitData[HitDataHitLocation + i] = ResultStore[i];
            HitData[HitDataHitNormal + i] = ObjectDB[objectIdx][nearestIdx][Trianglenormcrvmuwmux + i];
            HitData[HitDataRaySource + i] = ray[RaySourcex + i];
            HitData[HitDataRayDirection + i] = ray[RayDirectionx + i];
        }
        HitData[HitDataDistance] = nearestIntersection;
        HitData[HitDataMu] = Mu;
        HitData[HitDataMv] = Mv;
        // printf("NI: %f Mu: %f, Mv: %f\n", nearestIntersection, Mu, Mv);
        HitData[HitDatabitshift] = bitset(nearestbitshift);
        HitData[HitDataTriangleIndex] = bitset(nearestIdx);
        HitData[HitDataObjectIndex] = bitset(objectIdx);
    }
    else
        HitData[HitDataObjectIndex] = -1;
}

void sceneIntersection(float ray[6])
{
    int n, i;
    float nearestHit[18];
    
    nearestHit[HitDataDistance] = bitset(FURTHEST_RAY);
    
    for (n = 0; n < noObjects; n += 1)
    {
        objectIntersection(ray, n);
        // Check to see if this hit is worth keeping. If so, take a copy
        if ((HitData[HitDataDistance] > 0) && (HitData[HitDataDistance] < nearestHit[HitDataDistance]))
            for (i = 0; i < 18; i += 1)
                nearestHit[i] = HitData[i];
    }
    
    // Now check to see if there actually was a hit:
    if (( nearestHit[HitDataDistance] <= 0) || ((void) nearestHit[HitDataDistance] >= (void) FURTHEST_RAY))
        nearestHit[HitDataObjectIndex] = -1;
    // Finally copy the contents of the nearest hit vector to the hit data vector.
    for (n = 0; n < 18; n += 1)
        HitData[n] = nearestHit[n];
}

float traceShadow(float localHitData[18], float direction[3])
{
    float ray[6];
    
    int n, m;
    float tempDist = bitset(FURTHEST_RAY);
    
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
        direction[i] = localHitData[HitDataRayDirection + i];
        normal[i] = localHitData[HitDataHitNormal + i];
    }
    
    // Based on 2 (n . v) * n - v
    negVec(direction);
    
    // Copy the result back to the direction
    for (i = 0; i < 3; i += 1)
        direction[i] = ResultStore[i];
    
    tempFl = bitset(dot(normal, direction));
    tempVar = bitset(tempFl);
    tempVar <<= 1;
    tempFl = bitset(tempVar);
    scalarVecMult(tempFl, normal);
    
    for (i = 0; i < 3; i += 1)
    {
        // Move the reflection direction:
        ResultStore[3 + i] = ResultStore[i];
        // Then add the reflection source:
        ResultStore[i] = localHitData[HitDataHitLocation + i];
    }
}
/*
void refractRay(float localHitData[18], float inverserefreactivity, float squareinverserefractivity)
{
    float direction[3], normal[3], c;
    int i;
    
    // Populate the direction and normal vectors:
    for (i = 0; i < 3; i += 1)
    {
        direction[i] = localHitData[HitDataRayDirection + i];
        normal[i] = localHitData[HitDataHitNormal + i];
    }
    
    // Compute the negative vector:
    negVec(direction);
    
    // Copy the result back to the direction
    for (i = 0; i < 3; i += 1)
        direction[i] = ResultStore[i];
    
    c = dot(direction, normal);
    c = (inverserefreactivity * c) - fp_sqrt(1 - (squareinverserefractivity * (1 - c * c)));
    
    // Direction of refractive ray:
    scalarVecMult(inverserefreactivity, direction);
    
    // Copy the result back to the direction
    for (i = 0; i < 3; i += 1)
        direction[i] = ResultStore[i];
    // Then scale the normal
    scalarVecMult(c, normal);
    // And copy the result back
    for (i = 0; i < 3; i += 1)
        normal[i] = ResultStore[i];
    // Subtract the two vectors
    vecSub(normal, direction);
    // Copy the result back
    for (i = 0; i < 3; i += 1)
        normal[i] = ResultStore[i];
    // Then normalise.
    vecNormalised(normal);
    // Next, create a ray array in the result store.
    for (i = 0; i < 3; i += 1)
    {
        // Shift the direction up
        ResultStore[i + 3] = ResultStore[i];
        // Then add the refraction start location
        ResultStore[i] = localHitData[HitDataHitLocation + i];
    }
}
*/
void createRay(int x, int y)
{
    float sx = (float) x, sy = (float) y, shorizontal[3], svertical[3], sview[3];
    int i;
    
    // First scale x and scale y:
    sx *= Camera[CameraDFoVARDW];
    sx -= Camera[CameraFoVAR];
    sy *= Camera[CameraDFoVDH];
    sy -= Camera[CameraFoV];
    
    
    
    // Next, scale horizontal and vertical.
    for (i = 0; i < 3; i += 1)
    {
        shorizontal[i] = sx * Camera[CameraHorizontal + i];
        svertical[i] = sy * Camera[CameraVertical + i];
        sview[i] = shorizontal[i] + svertical[i] + Camera[CameraView + i];
        // printf("sview[%i] = %f\n", i, sview[i]);
    }
    
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
    int i, objIdx = bitset(localHitData[HitDataObjectIndex]);
    
    // Check to see if there's a texture
    if (textureColour[0] < 0)
         // No texture. Apply material colour
        for (i = 0; i < 3; i += 1)
        {
            RGBChannels[i] += MaterialDB[objIdx][MaterialCompAmbianceColour + i];
            // printf("Ambiance: RGBChannels[%i] = %f\n", i, RGBChannels[i]);
        }
    else
    {
        scalarVecMult(MaterialDB[objIdx][MaterialAmbiance], textureColour); // Texture. Apply texture colour
        for (i = 0; i < 3; i += 1)
            RGBChannels[i] += ResultStore[i];
    }
}

/* Creates diffusion effect given a hit, a scene and some light */
void diffusion(float localHitData[18], float lightDirection[3], float textureColour[3])
{
    float vector[3], distance, dotProduct;
    int i, hitObjIdx = bitset(localHitData[HitDataObjectIndex]);
    
    if (MaterialDB[hitObjIdx][MaterialDiffusive] > 0)
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
            for (i = 0; i < 3; i += 1)
                vector[i] = MaterialDB[hitObjIdx][MaterialLightColour + i];
             // No texture defined
            scalarVecMult(distance, vector);
        }
        else
        {
            // Extract the light colour:
            for (i = 0; i < 3; i += 1)
                vector[i] = Light[LightColour + i];
            // Combination of the texture colour and the material
            vecMult(textureColour, vector);
            // Extract the result from the result store
            for (i = 0; i < 3; i += 1)
                vector[i] = ResultStore[i];
            
            scalarVecMult(distance, vector);
        }
    }
    else 
        // Otherwise, return with nothing
        return;
    
    for (i = 0; i < 3; i += 1)
    {
        RGBChannels[i] += ResultStore[i];
        // printf("Diffusion: RGBChannels[%i] = %f\n", i, RGBChannels[i]);
    }
}

/* Creates specular effect given a hit, a scene and some light */
void specular(float localHitData[18], float lightDirection[3], float textureColour[3])
{
    int i, hitObjIdx = bitset(localHitData[HitDataObjectIndex]);
    float vector[3], dotProduct, distance;
    
    if (MaterialDB[hitObjIdx][MaterialSpecular] > 0)
    {
        // Reflective ray:
        reflectRay(localHitData);
        for (i = 0; i < 3; i += 1)
            vector[i] = ResultStore[RayDirectionx + i];
        
        dotProduct = dot(lightDirection, vector);
        
        if (dotProduct < 0)
            return;
        
        distance = fp_pow(dotProduct, MaterialDB[hitObjIdx][MaterialShininess]) * MaterialDB[hitObjIdx][MaterialSpecular]);
            
        // Has a texture been defined?
        if (textureColour[0] < 0)
        {
            for (i = 0; i < 3; i += 1)
                vector[i] = MaterialDB[hitObjIdx][MaterialLightColour + i] 
            scalarVecMult(distance, vector); // No texture defined
        }
        else
        {
            // Extract the light colour
            for (i = 0; i < 3; i += 1)
                vector[i] = Light[LightColour + i];
            vecMult(textureColour, vector);
            for (i = 0; i < 3; i += 1)
                vector[i] = ResultStore[i];
            scalarVecMult(distance, ResultStore);
        }
    }
    else
        // Otherwise return with nothing
        return;
    
    for (i = 0; i < 3; i += 1)
    {
        RGBChannels[i] += ResultStore[i];
        // printf("Specular: RGBChannels[%i] = %f\n", i, RGBChannels[i]);
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
    if ((void) refractivity == (void) 0)
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
    int i, j, isize = bitset(size);
    
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
    isize = isize >> 1;
    size = bitset(isize);
    
    // Points will always be at the extremes:
    minVal = -size;
    maxVal = size;
    
    for (i = 0; i < 4; i += 1)
        for (j = 0; j < 4; j += 1)
            printf("T[%i][%i] = %f\n", i, j, transMat[(i * 4 + j)]);
    
    for (i = 0; i < 12; i += 1)
    {
        for (j = 0; j < 3; j += 1)
        {
            u[j] = (pattern[i * 9 + j]) ? maxVal : minVal;
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
    int i, j, sizei = bitset(size);
    
    // Create a pattern
    int pattern[12] = {1, 1,
                       1, 0,
                       0, 0,
                       1, 1,
                       0, 1,
                       0, 0};
    
    // Halve the size
    sizei >>= 1;
    size = bitset(sizei);
    
    minVal = -size;
    maxVal = size;
    
    for (i = 0; i < 4; i += 1)
        for (j = 0; j < 4; j += 1)
            printf("T[%i][%i] = %f\n", i, j, transMat[(i * 4 + j)]);
    
    // Create two triangles:
   for (i = 0; i < 2; i += 1)
   {
       for (j = 0; j < 2; j += 1)
       {
           u[j * 2] = (pattern[i * 6 + j]) ? maxVal : minVal;
           v[j * 2] = (pattern[i * 6 + j + 2]) ? maxVal : minVal;
           w[j * 2] = (pattern[i * 6 + j + 4]) ? maxVal : minVal;
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
       if (i == 0)
           setTriangle(objectIndex, noTriangles[objectIndex], u, v, w);
       else
           setTriangle(objectIndex, noTriangles[objectIndex], w, v, u);
   }
}

void getTexel(float localHitData[18], float uv[2])
{
    float c1[3], c2[3], c3[3], c4[3];
    float URem, VRem, alpha, uvf0, uvf1;
    int b1, b2, b3, b4, uv0 = bitset(uv[0]), uv1 = bitset(uv[1]);
    float a1, a2, a3, a4;
    int TextUPos, TextVPos, i;
    
    // Locate the pixel intersection
    uv0 += 0x03E80000;
    uv0 &= 0x0000FFFF;
    uv1 += 0x03E80000;
    uv1 &= 0x0000FFFF;
    uvf0 = bitset(uv0);
    uvf1 = bitset(uv1);
    
    uv[0] = uvf0 * (TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureWidth] << 16);
    uv[1] = uvf1 * (TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureHeight] << 16);
    
    uv0 = bitset(uv[0]);
    uv1 = bitset(uv[1]);
    
    // Get the whole number pixel value
    TextUPos = uv0 >> 16;
    TextVPos = uv1 >> 16;
    
    uv0 &= 0x0000FFFF;
    uv1 &= 0x0000FFFF;
         
    // Compute weights from the fractional part
    URem = bitset(uv0);
    VRem = bitset(uv1);
    
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
    int i, hitObjIdx = bitset(localHitData[HitDataObjectIndex]), hitTriIdx = bitset(localHitData[HitDataTriangleIndex]);
    for (i = 0; i < 2; i += 1)
    {
        uv1[i] = ObjectDB[hitObjIdx][hitTriIdx][TriangleAu + i];
        uv2[i] = ObjectDB[hitObjIdx][hitTriIdx][TriangleBu + i] - uv1[i];
        uv3[i] = ObjectDB[hitObjIdx][hitTriIdx][TriangleCu + i] - uv1[i];
    }
    // V - U
    // Scale with Mu
    scalarUVMult(localHitData[HitDataMu], uv2);
    // Extract the results
    uv2[0] = ResultStore[0];
    uv2[1] = ResultStore[1];
    
    // W - U
    // Scale with Mv
    scalarUVMult(localHitData[HitDataMv], uv3);
    // Contents of UV3 in results store. Let's just extract it from there.
    
    // Then add UV1, UV2 and UV3:
    uv1[0] += uv2[0] + ResultStore[0];
    uv1[1] += uv2[1] + ResultStore[1];
    
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
    setMaterial(0, red, 0.0, 0.5, 0.0, 0.0, 0.0, 0.8, 1.4, -1);
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
    float outputColour[3], reflectiveColour[3], refractiveColour[3], textureColour[3] = {-1.0, -1.0, -1.0};
    float vector[3], hitLocation[3], localHitData[18], lightDirection[3];
    float colour[3], alpha;
    float reflection, refraction;
    float newRay[6], source[3];
    int i, hitObjIdx = -1;
    
    // Default is black. We can add to this (if there's a hit) 
    // or just return it (if there's no object)
    for (i = 0; i < 3; i += 1)
        {
            outputColour[i] = 0;
            RGBChannels[i] = 0;
        }
    
    // Check for an intersection. Results are stored in the hit data array
    sceneIntersection(ray);
    
    hitObjIdx = bitset(HitData[HitDataObjectIndex]);
    
    // Determine whether there was a hit. Otherwise default.
    if (hitObjIdx >= 0)
    {
        // There was a hit.
        
        // The first thing to do is to take a copy of the local hit data. This is necessary as the
        // draw function can be called (as a child) prior to completion of the (parent) draw function.
        for (i = 0; i < 18; i += 1)
            localHitData[i] = HitData[i];
        
        // Determine whether the light vector describes the direction or the position:
        if ((void) Light[LightGlobalFlag] != (void) 0)
            for (i = 0; i < 3; i +=1)
                lightDirection[i] = Light[LightVector + i];
        else
        {
            // Populate the light direction from the light location
            for (i = 0; i < 3; i += 1)
            {
                vector[i] = Light[LightVector + i];
                hitLocation[i] = localHitData[HitDataHitLocation + i];
            }
            // Subtract the light location and the hit position:
            vecSub(vector, hitLocation);
            // Take the evaluated subtraction from the result store
            for (i = 0; i < 3; i += 1)
                vector[i] = ResultStore[i];
            // Then normalise the resultant vector which will be the light direction
            vecNormalised(vector);
            // Copy the result from the result store
            for (i = 0; i < 3; i += 1)
                lightDirection[i] = ResultStore[i];
        }
        
        // Determine whether this has a texture or not
        i = bitset(MaterialDB[hitObjIdx][MaterialTextureIndex]);
        if (i >= 0)
        {
            // The getColour function doesn't need anything but the hit data to be passed to it.
            // It can determine which texture to use via the material DB (which uses the object
            // index).
            getColour(localHitData);
            // This function returns the RGBA value. This is held in the result store:
            for (i = 0; i < 3; i += 1)
                colour[i] = ResultStore[i];
            alpha = ResultStore[3];
            
            // Check to see if we need to create a new ray from this point:
            if (alpha < 1 && recursion >= 0)
            {
                // Yes, the alpha channel is < 1, so create a new ray starting from the point of intersection.
                // This ray has the same direction but a different source (the point of intersection).
                for (i = 0; i < 3; i += 1)
                {
                    newRay[RayDirectionx + i] = ray[RayDirectionx + i];
                    // At the same time, extract the ray direction:
                    vector[i] = ray[RayDirectionx + i];
                    source[i] = ray[i];
                }
                
                // Recompute the source by adding a little extra to the distance.
                // Compute the total distance first:
                scalarVecMult(localHitData[HitDataDistance] + 0x80, vector);
                // Extract the results from the result store:
                for (i = 0; i < 3; i += 1)
                    vector[i] = ResultStore[i];
                // Now add the two vectors together:
                vecAdd(vector, source);
                // Then set this as the new ray's source:
                for (i = 0; i < 3; i += 1)
                    newRay[i] = ResultStore[i];
                
                // Next, emit a ray. Don't reduce the recursion count.
                draw(newRay, recursion);
                
                // The resultant RGB value should be extracted:
                for (i = 0; i < 3; i += 1)
                    textureColour[i] = ResultStore[i];
                // Scale based on the alpha value:
                scalarVecMult(1 - alpha, textureColour);
                // And extract the result:
                for (i = 0; i < 3; i += 1)
                    textureColour[i] = ResultStore[i];
                
                // Next, take the colour and previous alpha value and compute the product:
                scalarVecMult(alpha, colour);
                for (i = 0; i < 3; i += 1)
                    vector[i] = ResultStore[i];
                // Add the two components together:
                vecAdd(vector, textureColour);
                // Then this is the texture colour:
                for (i = 0; i < 3; i += 1)
                    textureColour[i] = ResultStore[i];
            }
            else
                for (i = 0; i < 3; i += 1)
                    textureColour[i] = colour[i];
        }
        // Now compute the individual lighting effects and add the components together.
        // These are stored in the RGB components vector
        ambiance(localHitData, textureColour);
        diffusion(localHitData, lightDirection, textureColour);
        specular(localHitData, lightDirection, textureColour);
        
        // Extract the colours into a local variable.
        for (i = 0; i < 3; i += 1)
            outputColour[i] = RGBChannels[i];
        
        /*
        // Should we go deeper?
        if (recursion > 0)
        {
            // Yes, we should
            // Get the reflection
            // Create the new reflected ray:
            reflectRay(localHitData);
            // And then extract the result:
            for (i = 0; i < 6; i += 1)
                newRay[i] = ResultStore[i];
            // Call the draw function
            draw(newRay, recursion - 1);
            // And extract the result from result store:
            for (i = 0; i < 3; i += 1)
                reflectiveColour[i] = ResultStore[i];
            
            reflection = MaterialDB[localHitData[HitDataObjectIndex]][MaterialReflectivity];
            
            scalarVecMult(reflection, reflectiveColour);
            // Extract this result:
            for (i = 0; i < 3; i += 1)
                vector[i] = ResultStore[i];
            vecAdd(outputColour, vector);
            // Extract this result
            for (i = 0; i < 3; i += 1)
                outputColour[i] = ResultStore[i];
            
            // Get the refraction in a similar way:
            refractRay(localHitData MaterialDB[localHitData[HitDataObjectIndex]][MaterialInverseRefractivity], MaterialDB[localHitData[HitDataObjectIndex]][MaterialSquareInverseRefractivity]);
            // And then extract the result:
            for (i = 0; i < 6; i += 1)
                newRay[i] = ResultStore[i];
            // Call the draw function
            draw(newRay, recursion - 1);
            // Populate the refractiveColour vector:
            for (i = 0; i < 3; i += 1)
                refractiveColour[i] = ResultStore[i];
            
            // Extract the material's opacity:
            refraction = MaterialDB[localHitData[HitDataObjectIndex]][MaterialOpacity];
            // Compute the scaled refractive colour element:
            scalarVecMult(refraction, refractiveColour);
            // Extract the result from the result store:
            for (i = 0; i < 3; i += 1)
                vector[i] = ResultStore[i];
            vecAdd(outputColour, vector);
            
            // Before finally saving this as the output colour:
            for (i = 0; i < 3; i += 1)
                outputColour[i] = ResultStore[i];
        }
        */
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
    float clocation[3] = {1.0, 2.0, 4.0}, cTheta = bitset(0x0001C4A8), cPhi = bitset(0xFFFE6DDE), cview[3], ray[6];
    int i, x, y;
    
    for (i = 0; i < MAX_OBJECTS; i += 1)
        noTriangles[i] = 0;
    
    printf("Initialising light source...\n");
    
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
    
    return 0;
    exit(99);
}


#alias raytracernode 1
       