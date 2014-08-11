/*
 * datatypes.h
 *
 * This creates some rudimentary data types for the C ray tracer
 *
 *  Created on: 3 Dec 2013
 *      Author: andrew
 */
// Include fixed point maths

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

// Define some constants
#define EPS        0x6 // 512 // 6 // 31 // Was 0.00001

// extern int ResultStore[16];
// extern float ObjectDB[MAX_OBJECTS][MAX_TRIANGLES][20];
// extern int noObjects;
// extern int noTriangles[MAX_OBJECTS];
// // Modulo vector:
// extern int DomMod[5];
//
// // Camera vector
// extern float Camera[22];

/*
// UV coordinate structure
typedef struct UVCoord
{
    fixedp U;
    fixedp V;
}
UVCoord;

// A 3D vector
typedef struct Vector
{
    fixedp x;
    fixedp y;
    fixedp z;
}
Vector;

typedef struct VectorAlpha
{
    Vector vector;
    fixedp alpha;
}
VectorAlpha;

typedef struct Matrix
{
    fixedp m[4][4];
}
Matrix;

typedef struct Triangle
{
    Vector u;
    Vector v;
    Vector w;
    Vector vmu;             // v - u
    Vector wmu;             // w - u
    Vector normcrvmuwmu;    // vecNormalised(cross(vmu, wmu))
    // Texture coordinate information
    UVCoord uUV;
    UVCoord vUV;
    UVCoord wUV;
    int DominantAxisIdx;    // The dominant axis index
    Vector NormDom;         // Used for the normal.
    fixedp NUDom;
    fixedp NVDom;
    fixedp NDDom;
    fixedp BUDom;
    fixedp BVDom;
    fixedp CUDom;
    fixedp CVDom;
}
Triangle;
*/

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
    
    // Temporary convert to int to shift
    temp = bitset(deg);
    temp >>= 8;
    
    // (deg * 256 * pi / 180) / 256
    return bitset(temp); // * M_PI / 180.0;
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
            scalarVecMult(0x1000000, u); // Equivalent of 256 as 1 / sqrt(1.52E-5) is 256
        else
            scalarVecMult(fp_sqrt(1.0 / tempVar), u);
            // return scalarVecMult(fp_Flt2FP(1. / sqrtf(fp_FP2Flt(tempVar))), u, m, f);
            // return scalarVecMult(fp_sqrt(fp_div(fp_fp1, tempVar)), u, m, f);
    /*
    fixedp a = vecLength(u, m, f);
    // Vector w;
    // printf("vecNormalised: x: 0x%08X, y: 0x%08X, z: 0x%08X, a: 0x%08X\n", u.x, u.y, u.z, a);
    
    // Assume anything less than epsilon is zero
    if (a < EPS && a > -EPS)
        return u;
    
    // setVector(&w, u.x / a, u.y / a, u.z / a);
    statDivideFlt(m, 1);
    return scalarVecDiv(a, u, m, f);
    */
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

/* Create an identity matrix */
void genIdentMat()
{
    int i;
    float m[16] = {1, 0, 0, 0,
                   0, 1, 0, 0,
                   0, 0, 1, 0,
                   0, 0, 0, 1};
    // Copy the array to the results store.
    for (i = 0; i < 16; i += 1)
        ResultStore[i] = m[i];
}

/* Create a rotation matrix for X-axis rotations */
void genXRotateMat(float a)
{
    int i;
    float cosa = fp_cos(deg2rad(a)), sina = fp_sin(deg2rad(a));
    
    float m[16] = {1, 0, 0, 0,
                   0, 0, 0, 0,
                   0, 0, 0, 0,
                   0, 0, 0, 1};
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
    float cosa = fp_cos(deg2rad(a)), sina = fp_sin(deg2rad(a));
    
    float m[16] = {0, 0, 0, 0,
                   0, 1, 0, 0,
                   0, 0, 0, 0,
                   0, 0, 0, 1};
    
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
    float cosa = fp_cos(deg2rad(a)), sina = fp_sin(deg2rad(a));
    
    float m[16] = {0, 0, 0, 0,
                   0, 0, 0, 0,
                   0, 0, 1, 0,
                   0, 0, 0, 1};
    
    m[0] = cosa;
    m[1] = -sina;
    m[4] = sina;
    m[5] = cosa;
    // Copy the array to the results store.
    for (i = 0; i < 16; i += 1)
        ResultStore[i] = m[i];
}

/* Combine the three matrix rotations to give a single rotation matrix */
void getRotateMatrix(float ax, float ay, float az)
{
    int i;
    float mat[16];
    genXRotateMat(ax);
    // Copy result
    for (i = 0; i < 16; i += 1)
        mat[i] = ResultStore[i];
    genYRotateMat(ay);
    matMult(mat, ResultStore);
    // Copy result
    for (i = 0; i < 16; i += 1)
        mat[i] = ResultStore[i];
    genZRotateMat(az);
    matMult(mat, ResultStore);
}

void genTransMatrix(float tx, float ty, float tz)
{
    int i;
    float m[16] = {1, 0, 0, 0,
                   0, 1, 0, 0,
                   0, 0, 1, 0,
                   0, 0, 0, 1};
    
    m[3] = tx;
    m[7] = ty;
    m[11] = tz;
    // Copy the array to the results store.
    for (i = 0; i < 16; i += 1)
        ResultStore[i] = m[i];
}

void genScaleMatrix(float sx, float sy, float sz)
{
    int i;
    float m[16] = {0, 0, 0, 0,
                   0, 0, 0, 0,
                   0, 0, 0, 0,
                   0, 0, 0, 1};
                   
    m[0] = sx;
    m[5] = sy;
    m[10] = sz;
   // Copy the array to the results store.
    for (i = 0; i < 16; i += 1)
        ResultStore[i] = m[i];
}

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
/*
void setUVTriangle(Triangle *triangle, Vector u, Vector v, Vector w, UVCoord uUV, UVCoord vUV, UVCoord wUV, MathStat *m, FuncStat *f)
{
    int uIdx, vIdx;
    fixedp dk, du, dv, bu, bv, cu, cv, coeff;
    
#ifdef DEBUG
    (*f).setTriangle++;
#endif
    (*triangle).u = u;
    (*triangle).v = v;
    (*triangle).w = w;
    (*triangle).vmu = vecSub(v, u, m, f);
    (*triangle).wmu = vecSub(w, u, m, f);
    (*triangle).NormDom = cross((*triangle).vmu, (*triangle).wmu, m, f);
    (*triangle).normcrvmuwmu = vecNormalised((*triangle).NormDom, m, f);
    (*triangle).uUV = uUV;
    (*triangle).vUV = vUV;
    (*triangle).wUV = wUV;
    
    // Now compute dominant axes:
    if (fp_fabs((*triangle).NormDom.x) > fp_fabs((*triangle).NormDom.y))
    {
        if (fp_fabs((*triangle).NormDom.x) > fp_fabs((*triangle).NormDom.z))
            (*triangle).DominantAxisIdx = 0;
        else
            (*triangle).DominantAxisIdx = 2;
    }
    else
    {
        if (fp_fabs((*triangle).NormDom.y) > fp_fabs((*triangle).NormDom.z))
            (*triangle).DominantAxisIdx = 1;
        else
            (*triangle).DominantAxisIdx = 2;
    }
    uIdx = ((*triangle).DominantAxisIdx + 1) % 3;
    vIdx = ((*triangle).DominantAxisIdx + 2) % 3;
    
    // This should make calculations easier...
    dk = ((*triangle).DominantAxisIdx == 1) ? (*triangle).NormDom.y : (((*triangle).DominantAxisIdx == 2) ? (*triangle).NormDom.z : (*triangle).NormDom.x);
    du = (uIdx == 1) ? (*triangle).NormDom.y : ((uIdx == 2) ? (*triangle).NormDom.z : (*triangle).NormDom.x);
    dv = (vIdx == 1) ? (*triangle).NormDom.y : ((vIdx == 2) ? (*triangle).NormDom.z : (*triangle).NormDom.x);
    
    bu = (uIdx == 1) ? (*triangle).wmu.y : ((uIdx == 2) ? (*triangle).wmu.z : (*triangle).wmu.x);
    bv = (vIdx == 1) ? (*triangle).wmu.y : ((vIdx == 2) ? (*triangle).wmu.z : (*triangle).wmu.x);
    cu = (uIdx == 1) ? (*triangle).vmu.y : ((uIdx == 2) ? (*triangle).vmu.z : (*triangle).vmu.x);
    cv = (vIdx == 1) ? (*triangle).vmu.y : ((vIdx == 2) ? (*triangle).vmu.z : (*triangle).vmu.x);
    
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
    *//*
    // Now precompute components for Barycentric intersection
    dk = (dk == 0) ? fp_fp1 : dk;
    (*triangle).NUDom = fp_div(du, dk);
    (*triangle).NVDom = fp_div(dv, dk);
    (*triangle).NDDom = fp_div(dot((*triangle).NormDom, u, m, f) , dk);
    
    // First line of the equation:
    coeff = fp_mult(bu, cv) - fp_mult(bv, cu);
    coeff = (coeff == 0) ? fp_fp1 : coeff;
    (*triangle).BUDom = fp_div(bu, coeff);
    (*triangle).BVDom = -fp_div(bv, coeff);
    // Second line of the equation:
    (*triangle).CUDom = fp_div(cv, coeff);
    (*triangle).CVDom = -fp_div(cu, coeff);
}

void setPrecompTriangle(Triangle *triangle, Vector u, Vector v, Vector w, UVCoord uUV, UVCoord vUV, UVCoord wUV, Vector vmu, Vector wmu, Vector normcrvmuwmu, int DominantAxisIdx, Vector NormDom, fixedp NUDom, fixedp NVDom, fixedp NDDom, fixedp BUDom, fixedp BVDom, fixedp CUDom, fixedp CVDom, FuncStat *f)
{
    // Everything about the triangle is saved. Just take inputs and save them
    (*triangle).u = u;
    (*triangle).v = v;
    (*triangle).w = w;
    (*triangle).vmu = vmu;             // v - u
    (*triangle).wmu = wmu;             // w - u
    (*triangle).normcrvmuwmu = normcrvmuwmu;    // vecNormalised(cross(vmu, wmu))
    (*triangle).uUV = uUV;
    (*triangle).vUV = vUV;
    (*triangle).wUV = wUV;
    (*triangle).DominantAxisIdx = DominantAxisIdx;    // The dominant axis index
    (*triangle).NormDom = NormDom;         // Used for the normal.
    (*triangle).NUDom = NUDom;
    (*triangle).NVDom = NVDom;
    (*triangle).NDDom = NDDom;
    (*triangle).BUDom = BUDom;
    (*triangle).BVDom = BVDom;
    (*triangle).CUDom = CUDom;
    (*triangle).CVDom = CVDom;
}
*/
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
    
    printf("Setting camera with dimensions %i x %i\n", width, height);
    
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
    
    printf("About to set values...\n");
    
    // Now populate the camera vector
    for (i = 0; i < 3; i += 1)
    {        
        Camera[CameraLocation + i] = location[i];
        Camera[CameraView + i] = view[i];
        Camera[CameraUp + i] = up[i];
        Camera[CameraHorizontal + i] = horizontal[i];
        Camera[CameraVertical + i] = vertical[i];
    }
    printf("Setting more values...\n");
    Camera[CameraFoV] = fovh;
    Camera[CameraAR] = ar;
    Camera[CameraHeight] = (float) height;
    Camera[CameraWidth] = (float) width;
    Camera[CameraDFoVARDW] = dfovardw;
    Camera[CameraFoVAR] = fovar;
    Camera[CameraDFoVDH] = dfovdh;
}
