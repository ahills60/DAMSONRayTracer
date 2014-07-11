/*
 * datatypes.h
 *
 * This creates some rudimentary data types for the C ray tracer
 *
 *  Created on: 3 Dec 2013
 *      Author: andrew
 */
#include <math.h>
// Include fixed point maths
#include "fpmath.h"

#ifndef DATATYPES_H_
#define DATATYPES_H_

// Define some constants
#define EPS        6 // 512 // 6 // 31 // Was 0.00001

extern int ResultStore[4][4];

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
void setUVCoord(UVCoord *a, fixedp u, fixedp v)
{
    (*a).U = u;
    (*a).V = v;
}

/* Set the coordinates of a vector */
void setVector(Vector *v, fixedp x, fixedp y, fixedp z, FuncStat *f)
{
    (*v).x = x;
    (*v).y = y;
    (*v).z = z;
}

/* Fast convert of list to matrix */
void setMatrix(Matrix *F, fixedp *m, MathStat *ma, FuncStat *f)
{
    int n, p;
    
    for (n = 0; n < 4; n++)
    {
        DEBUG_statPlusInt(ma, 1); // for the loop
        for (p = 0; p < 4; p++)
        {
            DEBUG_statPlusInt(ma, 1); // for the loop
            (*F).m[p][n] = m[n + 4 * p];
            
            DEBUG_statGroupInt(ma, 1, 0, 1, 0);
        }
    }
}

/* Convert from degrees to radians */
float deg2rad(float deg)
{
    return deg * M_PI / 180.0;
}

/* Vector multiply */
void vecMult(float u[3], float v[3])
{
    ResultStore[0][0] = u[0] * v[0];
    ResultStore[0][1] = u[1] * v[1];
    ResultStore[0][2] = u[2] * v[2];
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
    ResultStore[0][0] = u[1] * v[2] - v[1] * u[2];
    ResultStore[0][1] = u[2] * v[0] - v[2] * u[0];
    ResultStore[0][2] = u[0] * v[1] - v[0] * u[1];
}

/* Scalar multiplication with a vector */
void scalarVecMult(float a, float u[3])
{
    ResultStore[0][0] = a * u[0];
    ResultStore[0][1] = a * u[1];
    ResultStore[0][2] = a * u[2];
}

/* Scalar division with a vector */
void scalarVecDiv(float a, float u[3])
{
    ResultStore[0][0] = u[0] / a;
    ResultStore[0][1] = u[1] / a;
    ResultStore[0][2] = u[2] / a;
}

/* Vector addition */
void vecAdd(float u[3], float v[3])
{
    ResultStore[0][0] = u[0] + v[0];
    ResultStore[0][1] = u[1] + v[1];
    ResultStore[0][2] = u[2] + v[2];
}

/* Vector subtraction */
void vecSub(float u[3], float v[3])
{
    ResultStore[0][0] = u[0] - v[0];
    ResultStore[0][1] = u[1] - v[1];
    ResultStore[0][2] = u[2] - v[2];
}

/* -1 * vector */
void negVec(float u[3])
{
    ResultStore[0][0] = -u[0];
    ResultStore[0][1] = -u[1];
    ResultStore[0][2] = -u[2];
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
    if (tempVar == 0)
    {
        ResultStore[0][0] = u[0];
        ResultStore[0][1] = u[1];
        ResultStore[0][2] = u[2];
    }
    else // Below function calls will populate ResultsStore
        if (tempVar == 1)
            scalarVecMult(0x1000000, u); // Equivalent of 256 as 1 / sqrt(1.52E-5) is 256
        else
            scalarVecMult(fp_sqrt(fp_fp1 / tempVar), u);
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
Vector matVecMult(Matrix F, Vector u, MathStat *m, FuncStat *f)
{
#ifdef DEBUG
    (*f).matVecMult++;
#endif
    Vector w;
    // Note that we don't consider the last row within the matrix. This is discarded deliberately.
    setVector(&w, fp_mult(F.m[0][0], u.x) + fp_mult(F.m[0][1], u.y) + fp_mult(F.m[0][2], u.z) + F.m[0][3],
                  fp_mult(F.m[1][0], u.x) + fp_mult(F.m[1][1], u.y) + fp_mult(F.m[1][2], u.z) + F.m[1][3],
                  fp_mult(F.m[2][0], u.x) + fp_mult(F.m[2][1], u.y) + fp_mult(F.m[2][2], u.z) + F.m[2][3], f);
    DEBUG_statGroupFlt(m, 9, 0, 9, 0);
    return w;
}

/* Matrix multiplied by a matrix */
Matrix matMult(Matrix F, Matrix G, MathStat *ma, FuncStat *f)
{
#ifdef DEBUG
    (*f).matMult++;
#endif
    Matrix H;
    int m, n, p;
    
    for (m = 0; m < 4; m++)
    {
        DEBUG_statPlusInt(ma, 1);
        for (n = 0; n < 4; n++)
        {
            DEBUG_statPlusInt(ma, 1);
            // Initialise new matrix first
            H.m[n][m] = 0;
            
            // Now populate with the multiplication
            for (p = 0; p < 4; p++)
            {
                 DEBUG_statPlusInt(ma, 1);
                 H.m[n][m] += fp_mult(F.m[n][p], G.m[p][m]);
                 DEBUG_statGroupFlt(ma, 1, 0, 1, 0);
            }
        }
    }
    return H;
}

/* Create an identity matrix */
Matrix genIdentMat(MathStat *ma, FuncStat *f)
{
#ifdef DEBUG
    (*f).genIdentMat++;
#endif
    Matrix H;
    fixedp m[16] = {fp_fp1, 0, 0, 0,
                    0, fp_fp1, 0, 0,
                    0, 0, fp_fp1, 0,
                    0, 0, 0, fp_fp1};
    setMatrix(&H, m, ma, f);
    return H;
}

/* Create a rotation matrix for X-axis rotations */
Matrix genXRotateMat(fixedp a, MathStat *ma, FuncStat *f)
{
#ifdef DEBUG
    (*f).genXRotateMat++;
#endif
    Matrix H;
    float cosa = cos(deg2rad(fp_FP2Flt(a), ma, f)), sina = sin(deg2rad(fp_FP2Flt(a), ma, f));
    DEBUG_statSine(ma, 1);
    DEBUG_statCosine(ma, 1);
    
    fixedp fpcosa = fp_Flt2FP(cosa);
    fixedp fpsina = fp_Flt2FP(sina);
    
    fixedp m[16] = {fp_fp1, 0, 0, 0,
                    0, fpcosa, -fpsina, 0,
                    0, fpsina, fpcosa, 0,
                    0, 0, 0, fp_fp1};
   setMatrix(&H, m, ma, f);
   return H;
}

/* Create a rotation matrix for Y-axis rotations */
Matrix genYRotateMat(fixedp a, MathStat *ma, FuncStat *f)
{
#ifdef DEBUG
    (*f).genYRotateMat++;
#endif
    Matrix H;
    float cosa = cos(deg2rad(fp_FP2Flt(a), ma, f)), sina = sin(deg2rad(fp_FP2Flt(a), ma, f));
    DEBUG_statSine(ma, 1);
    DEBUG_statCosine(ma, 1);
    
    fixedp fpcosa = fp_Flt2FP(cosa);
    fixedp fpsina = fp_Flt2FP(sina);
    
    fixedp m[16] = {fpcosa, 0, fpsina, 0,
                   0, fp_fp1, 0, 0,
                   -fpsina, 0, fpcosa, 0,
                   0, 0, 0, fp_fp1};
   setMatrix(&H, m, ma, f);
   return H;
}

/* Create a rotation matrix for Z-axis rotations */
Matrix genZRotateMat(fixedp a, MathStat *ma, FuncStat *f)
{
#ifdef DEBUG
    (*f).genZRotateMat++;
#endif
    Matrix H;
    float cosa = cos(deg2rad(fp_FP2Flt(a), ma, f)), sina = sin(deg2rad(fp_FP2Flt(a), ma, f));
    DEBUG_statSine(ma, 1);
    DEBUG_statCosine(ma, 1);
    
    fixedp fpcosa = fp_Flt2FP(cosa);
    fixedp fpsina = fp_Flt2FP(sina);
    
    fixedp m[16] = {fpcosa, -fpsina, 0, 0,
                   fpsina, fpcosa, 0, 0,
                   0, 0, fp_fp1, 0,
                   0, 0, 0, fp_fp1};
   setMatrix(&H, m, ma, f);
   return H;
}

/* Combine the three matrix rotations to give a single rotation matrix */
Matrix getRotateMatrix(fixedp ax, fixedp ay, fixedp az, MathStat *ma, FuncStat *f)
{
#ifdef DEBUG
    (*f).getRotateMatrix++;
#endif
    return matMult(matMult(genXRotateMat(ax, ma, f), genYRotateMat(ay, ma, f), ma, f), genZRotateMat(az, ma, f), ma, f);
}

Matrix genTransMatrix(fixedp tx, fixedp ty, fixedp tz, MathStat *ma, FuncStat *f)
{
#ifdef DEBUG
    (*f).genTransMatrix++;
#endif
    Matrix H;
    fixedp m[16] = {fp_fp1, 0, 0, tx,
                   0, fp_fp1, 0, ty,
                   0, 0, fp_fp1, tz,
                   0, 0, 0, fp_fp1};
   setMatrix(&H, m, ma, f);
   return H;
}

Matrix genScaleMatrix(fixedp sx, fixedp sy, fixedp sz, MathStat *ma, FuncStat *f)
{
#ifdef DEBUG
    (*f).genScaleMatrix++;
#endif
    Matrix H;
    fixedp m[16] = {sx, 0, 0, 0,
                   0, sy, 0, 0,
                   0, 0, sz, 0,
                   0, 0, 0, fp_fp1};
    setMatrix(&H, m, ma, f);
    return H;
}

void setTriangle(Triangle *triangle, Vector u, Vector v, Vector w, MathStat *m, FuncStat *f)
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
    UVCoord tempCoord;
    setUVCoord(&tempCoord, -1, -1);
    (*triangle).uUV = tempCoord;
    (*triangle).vUV = tempCoord;
    (*triangle).wUV = tempCoord;
    
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
    */
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
    */
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

/* Multiple a UV coordinate by a scalar value */
UVCoord scalarUVMult(fixedp a, UVCoord u, MathStat *m)
{
    UVCoord r;
    setUVCoord(&r, fp_mult(a, u.U), fp_mult(a, u.V));
    DEBUG_statMultiplyFlt(m, 2);
    return r;
}

/* Add two UV coordinates */
UVCoord uvAdd(UVCoord a, UVCoord b, MathStat *m)
{
    UVCoord r;
    setUVCoord(&r, a.U + b.U, a.V + b.V);
    DEBUG_statPlusFlt(m, 2);
    return r;
}

UVCoord uvSub(UVCoord a, UVCoord b, MathStat *m)
{
    UVCoord r;
    setUVCoord(&r, a.U - b.U, a.V - b.V);
    DEBUG_statSubtractFlt(m, 2);
    return r;
}

#endif /* DATATYPES_H_ */
