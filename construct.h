/*
 * bytecodeconstruct.h
 * 
 * This header file provides functions to read and interpret
 * a byte-code file produced by the OF2RayTracer.py script.
 *
 *  Created on: 1 Apr 2014
 *      Author: andrew
 */

#ifndef BYTECODECONSTRUCT_H_
#define BYTECODECONSTRUCT_H_

#include <stdio.h>
#include "fpmath.h"
#include "craytracer.h"
#include "datatypes.h"
#include "rays.h"
#include "image.h"
#include "lighting.h"
#include "objects.h"
#include "colours.h"
#include "mathstats.h"
#include "funcstats.h"
#include "textures.h"
#include "shapes.h"

Texture *Textures;
extern char *inputFile;
extern int GlobalLightingFlag;

/* Function to read the byte file */
void ReadByteFile(Scene *scene, Light lightSrc, MathStat *m, FuncStat *f)
{
    fixedp minx = 0x7FFFFFFF, miny = 0x7FFFFFFF, minz = 0x7FFFFFFF, maxx = 0x80000000, maxy = 0x80000000, maxz = 0x80000000;
    // Variable declarations:
    FILE *fp;
    Vector lgrey = int2Vector(LIGHT_GREY);
    Vector u, v, w;
    UVCoord uUV, vUV, wUV;
    fixedp x, y, z, a, b;
    Triangle *triangle;
    Object myObj;
    int i, n, zeroCheck, matIdx, textIdx, noTriangles, noMaterials, noTextures;
    char *texturefn;
    // Variables for precomputing:
    int DominantAxisIdx;
    fixedp NUDom, NVDom, NDDom, BUDom, BVDom, CUDom, CVDom;
    Vector NormDom, normcrvmuwmu, vmu, wmu;
    long long int TotalTriangles = 0;
    
    // File initialisation
    printf("\nReading world \"%s\"...\n", inputFile);
    
    fp = fopen(inputFile, "rb");
    
    // Read the number of materials
    fread(&noMaterials, sizeof(noMaterials), 1, fp);
    // Then read the number of textures:
    fread(&noTextures, sizeof(noTextures), 1, fp);
    
    printf("Total materials: %i\nTotal textures: %i\n", noMaterials, noTextures);
    
    printf("Initialising variables...\n");
    // With this in mind, it's now possible to initialise the textures and materials store.
    Textures = (Texture *)malloc(sizeof(Texture) * noTextures);
    // Materials need only be specified here.
    Material myMat[noMaterials];
    
    printf("Initialising scene with %i objects...\n", noMaterials);
    // Next up: scene initialisation
    initialiseScene(scene, noMaterials, f);
    
    printf("Reading textures...\n");
    for (i = 0; i < noTextures; i++)
    {
        // Read the size of the filename to open
        // printf("Reading texture %i...\n", i);
        fread(&n, sizeof(n), 1, fp);
        // printf("Reserving space for character... ");
        texturefn = (char *)malloc(sizeof(char) * (n + 1));
        memset(texturefn, 0, sizeof(char) * (n + 1));
        // printf("Space reserved (%i)\nReading texture filename...\n", n);
        // The variable texturefn is a pointer. Pass the pointer directly.
        fread(texturefn, sizeof(char), n, fp);
        // printf("Attempting to read \"%s\"", texturefn);
        if (strcmp(texturefn, "terrain.tga") != 0 && n != 25)
        {
            memcpy(texturefn, texturefn + 12, 36);
            memset(texturefn + 36, 0, sizeof(char) * 12);
        }
        else
        {
            if (n == 25)
                texturefn[8] = '/';
        }
        ReadTexture(&Textures[i], texturefn, f);
        // printf("Texture read. Freeing memory.\n");
        free(texturefn);
        // printf("Memory freed.\n");
    }
    printf("Complete.\n");
    fread(&zeroCheck, sizeof(int), 1, fp);
    if (zeroCheck != 0)
    {
        printf("\nError encountered entering filenames. Failed zero check.\n");
        // Terminate now.
        exit(-1);
    }
    
    printf("Loading materials...\n");
    // Everything looks okay. Let's continue to the material and indexing structures
    for (i = 0; i < noMaterials; i++)
    {
        // Read the material index and then read the texture index
        fread(&matIdx, sizeof(int), 1, fp);
        fread(&textIdx, sizeof(int), 1, fp);
        // printf("\tMaterial index: %i, Texture Index: %i\n", matIdx, textIdx);
        // Now create a material:
        setMaterial(&myMat[matIdx], lightSrc, lgrey, fp_Flt2FP(1.0), 0, 0, fp_Flt2FP(0.1), fp_Flt2FP(0.2), 0, 0, textIdx, m, f);
        //setMaterial(Material *matObj, Light lightSrc, Vector colour, fixedp ambiance, fixedp diffusivity, fixedp specular, fixedp shininess, fixedp reflectivity, fixedp opacity, fixedp refractivity, int textureIdx, MathStat *m, FuncStat *f)
    }
    printf("Done.\n");
    // Once agian, do a zero check:
    fread(&zeroCheck, sizeof(int), 1, fp);
    if (zeroCheck != 0)
    {
        printf("\nError encountered pairing materials with textures. Failed zero check.\n");
        // Terminate now:
        exit(-2);
    }
    
    printf("Loading triangles...\n");
    // Next step is to go through triangles
    fread(&noTriangles, sizeof(int), 1, fp);
    // Whilst the EOF flag isn't raised:
    while(!feof(fp))
    {
        // printf("Initialising triangle...");
        TotalTriangles += noTriangles;
        triangle = (Triangle *)malloc(sizeof(Triangle) * noTriangles);
        // printf("Done.\n");
        for (i = 0; i < noTriangles; i++)
        {
            // printf("Triangle %i of %i...\n", i + 1, noTriangles);
            // printf("\tVector 1...");
            // Vector Values
            fread(&x, sizeof(fixedp), 1, fp);
            if (x > maxx)
                maxx = x;
            if (x < minx)
                minx = x;
            fread(&y, sizeof(fixedp), 1, fp);
            if (y > maxy)
                maxy = y;
            if (y < miny)
                miny = y;
            fread(&z, sizeof(fixedp), 1, fp);
            if (z > maxz)
                maxz = z;
            if (z < minz)
                minz = z;
            // UV coords
            fread(&a, sizeof(fixedp), 1, fp);
            fread(&b, sizeof(fixedp), 1, fp);
            
            // Add to vector:
            setVector(&u, x, y, z, f);
            setUVCoord(&uUV, a, b);
            
            // printf("Done.\n\tVector 2...");
            
            // Vector Values
            fread(&x, sizeof(fixedp), 1, fp);
            if (x > maxx)
                maxx = x;
            if (x < minx)
                minx = x;
            fread(&y, sizeof(fixedp), 1, fp);
            if (y > maxy)
                maxy = y;
            if (y < miny)
                miny = y;
            fread(&z, sizeof(fixedp), 1, fp);
            if (z > maxz)
                maxz = z;
            if (z < minz)
                minz = z;
            // UV coords
            fread(&a, sizeof(fixedp), 1, fp);
            fread(&b, sizeof(fixedp), 1, fp);
            
            // Add to vector:
            setVector(&v, x, y, z, f);
            setUVCoord(&vUV, a, b);
            
            // printf("Done.\n\tVector 3...");
            
            // Vector Values
            fread(&x, sizeof(fixedp), 1, fp);
            if (x > maxx)
                maxx = x;
            if (x < minx)
                minx = x;
            fread(&y, sizeof(fixedp), 1, fp);
            if (y > maxy)
                maxy = y;
            if (y < miny)
                miny = y;
            fread(&z, sizeof(fixedp), 1, fp);
            if (z > maxz)
                maxz = z;
            if (z < minz)
                minz = z;
            // UV coords
            fread(&a, sizeof(fixedp), 1, fp);
            fread(&b, sizeof(fixedp), 1, fp);
            
            // Add to vector:
            setVector(&w, x, y, z, f);
            setUVCoord(&wUV, a, b);
            
            // printf("Done.\n");
            
            //
            // Now precomputed variables:
            //
            // printf("\tDom axis...");
            // k:
            fread(&DominantAxisIdx, sizeof(int), 1, fp);
            // printf("Done.\n");
            // printf("\tDominant axis: %i\n", DominantAxisIdx);
            // printf("\tvmu...");
            // c == vmu:
            fread(&x, sizeof(fixedp), 1, fp);
            fread(&y, sizeof(fixedp), 1, fp);
            fread(&z, sizeof(fixedp), 1, fp);
            setVector(&vmu, x, y, z, f);
            // printf("Done.\n");
            // printf("\twmu...");
            // b == wmu:
            fread(&x, sizeof(fixedp), 1, fp);
            fread(&y, sizeof(fixedp), 1, fp);
            fread(&z, sizeof(fixedp), 1, fp);
            setVector(&wmu, x, y, z, f);
            // printf("Done.\n");
            // printf("\tNormDom...");
            // m_N == NormDom
            fread(&x, sizeof(fixedp), 1, fp);
            fread(&y, sizeof(fixedp), 1, fp);
            fread(&z, sizeof(fixedp), 1, fp);
            setVector(&NormDom, x, y, z, f);
            // printf("Done.\n");
            // printf("\tnormcrvmuwmu...");
            // m_N_norm == normcrvmuwmu
            fread(&x, sizeof(fixedp), 1, fp);
            fread(&y, sizeof(fixedp), 1, fp);
            fread(&z, sizeof(fixedp), 1, fp);
            setVector(&normcrvmuwmu, x, y, z, f);
            // printf("Done.\n");
            // printf("\tnu...");
            // nu
            fread(&NUDom, sizeof(fixedp), 1, fp);
            // printf("Done.\n");
            // printf("\tnv...");
            // nv
            fread(&NVDom, sizeof(fixedp), 1, fp);
            // printf("Done.\n");
            // printf("\tnd...");
            // nd
            fread(&NDDom, sizeof(fixedp), 1, fp);
            // printf("Done.\n");
            // printf("\tbnu...");
            // bnu
            fread(&BUDom, sizeof(fixedp), 1, fp);
            // printf("Done.\n");
            // printf("\tbnv...");
            // bnv
            fread(&BVDom, sizeof(fixedp), 1, fp);
            // printf("Done.\n");
            // printf("\tcnu...");
            // cnu
            fread(&CUDom, sizeof(fixedp), 1, fp);
            // printf("Done.\n");
            // printf("\tcnv...");
            // cnv
            fread(&CVDom, sizeof(fixedp), 1, fp);
            // printf("Done.\n");
            
            // printf("\tCommitting triangle...");
            // Now commit this to a triangle
            setPrecompTriangle(&triangle[i], u, v, w, uUV, vUV, wUV, vmu, wmu, normcrvmuwmu, DominantAxisIdx, NormDom, NUDom, NVDom, NDDom, BUDom, BVDom, CUDom, CVDom, f);
            // printf("Done.\n");
        }
        // Triangles are now added. Read the associated material index
        // printf("Reading material...");
        fread(&matIdx, sizeof(int), 1, fp);
        // printf("Done.\n");
        // printf("Material index: %i\n", matIdx);
        // printf("Creating object...");
        setObject(&myObj, myMat[matIdx], noTriangles, triangle, f);
        // printf("Done.\nCommitting to scene...");
        addObject(scene, myObj, f);
        // printf("Done.\n");
        // Now free up the space
        // free(triangle);
        
        // Finally do a zero check
        fread(&zeroCheck, sizeof(int), 1, fp);
        if (zeroCheck != 0)
        {
            printf("\nError encountered pairing triangle points with UV values. Failed zero check.\n");
            // Terminate now:
            exit(-3);
        }
        // Now read the next number of triangles value. EOF will raise if this failed.
        fread(&noTriangles, sizeof(int), 1, fp);
    }
    printf("Done.\n");
    printf("\nScene stats:\n\tMin: x: %f\ty: %f\tz: %f\n\tMax: x: %f\ty: %f\tz: %f\n\n", fp_FP2Flt(minx), fp_FP2Flt(miny), fp_FP2Flt(minz), fp_FP2Flt(maxx), fp_FP2Flt(maxy), fp_FP2Flt(maxz));
    printf("Total number of triangles: %lld\n\n", TotalTriangles);
    fclose(fp);
}

/* Populate a scene with set items */
void populateDefaultScene(Scene *scene, Light lightSrc, MathStat *m, FuncStat *f)
{
    Object cube, planeBase, planeLeft, planeRight, planeTop, planeBack, mirrCube;
    Material redGlass, nonreflBlue, nonreflGreen, nonreflPurple, mirror;
    Vector red = int2Vector(RED);
    Vector blue = int2Vector(BLUE);
    Vector green = int2Vector(GREEN);
    Vector purple = int2Vector(PURPLE);
    Vector white = int2Vector(WHITE);
    
    // Set material types
    //setMaterial(*matObj, light, Vector colour, fixedp ambiance, fixedp diffusivity, fixedp specular, fixedp shininess, fixedp reflectivity, fixedp opacity, fixedp refractivity)
    setMaterial(&redGlass, lightSrc, red, fp_Flt2FP(0.0), fp_Flt2FP(0.5), fp_Flt2FP(0.0), fp_Flt2FP(0.0), fp_Flt2FP(0.0), fp_Flt2FP(0.8), fp_Flt2FP(1.4), -1, m, f);
    setMaterial(&nonreflBlue, lightSrc, blue, fp_Flt2FP(0.1), fp_Flt2FP(0.5), fp_Flt2FP(0.4), fp_Flt2FP(2.0), fp_Flt2FP(0.0), fp_Flt2FP(0.0), fp_Flt2FP(1.4), -1, m, f);
    setMaterial(&nonreflGreen, lightSrc, green, fp_Flt2FP(0.1), fp_Flt2FP(0.5), fp_Flt2FP(0.4), fp_Flt2FP(2.0), fp_Flt2FP(0.0), fp_Flt2FP(0.0), fp_Flt2FP(1.4), -1, m, f);
    setMaterial(&nonreflPurple, lightSrc, purple, fp_Flt2FP(0.1), fp_Flt2FP(0.5), fp_Flt2FP(0.4), fp_Flt2FP(2.0), fp_Flt2FP(0.0), fp_Flt2FP(0.0), fp_Flt2FP(1.4), -1, m, f);
    setMaterial(&mirror, lightSrc, white, fp_Flt2FP(0.1), fp_Flt2FP(0.0), fp_Flt2FP(0.9), fp_Flt2FP(32.0), fp_Flt2FP(0.6), fp_Flt2FP(0.0), fp_Flt2FP(1.4), -1, m, f);
    
    // Create objects
    createCube(&cube, redGlass, fp_Flt2FP(1.0), m, f);
    createPlaneXZ(&planeBase, nonreflPurple, fp_Flt2FP(10.0), m, f);
    createPlaneXZ(&planeTop, nonreflPurple, fp_Flt2FP(10.0), m, f);
    createPlaneXZ(&planeLeft, nonreflGreen, fp_Flt2FP(10.0), m, f);
    createPlaneXZ(&planeRight, nonreflGreen, fp_Flt2FP(10.0), m, f);
    createPlaneXZ(&planeBack, nonreflBlue, fp_Flt2FP(10.0), m, f);
    createCube(&mirrCube, mirror, fp_Flt2FP(1.5), m, f);
    
    // Arrange
    transformObject(&cube, matMult(genTransMatrix(fp_Flt2FP(2), fp_Flt2FP(0.5), -fp_Flt2FP(1), m, f), genYRotateMat(fp_Flt2FP(45), m, f), m, f), m, f);
    transformObject(&planeBase, genTransMatrix(fp_Flt2FP(1), 0, -fp_Flt2FP(4), m, f), m, f);
    transformObject(&planeLeft, matMult(genTransMatrix(-fp_Flt2FP(2), 0, -fp_Flt2FP(4), m, f), genZRotateMat(-fp_Flt2FP(90), m, f), m, f), m, f);
    transformObject(&planeRight, matMult(genTransMatrix(fp_Flt2FP(4), 0, -fp_Flt2FP(4), m, f), genZRotateMat(fp_Flt2FP(90), m, f), m, f), m, f);
    transformObject(&planeBack, matMult(genTransMatrix(fp_Flt2FP(1), 0, -fp_Flt2FP(6), m, f), genXRotateMat(fp_Flt2FP(90), m, f), m, f), m, f);
    transformObject(&planeTop, matMult(genTransMatrix(fp_Flt2FP(1), fp_Flt2FP(5), -fp_Flt2FP(4), m, f), genZRotateMat(fp_Flt2FP(180), m, f), m, f), m, f);
    transformObject(&mirrCube, matMult(genTransMatrix(fp_Flt2FP(0), fp_Flt2FP(0.9), -fp_Flt2FP(2.7), m, f), genYRotateMat(fp_Flt2FP(20), m, f), m, f), m, f);
    
    // Create the scene
    initialiseScene(scene, 6, f);
    addObject(scene, cube, f);
    addObject(scene, planeBase, f);
    addObject(scene, planeLeft, f);
    addObject(scene, planeRight, f);
    addObject(scene, planeBack, f);
    addObject(scene, mirrCube, f);
    // addObject(scene, planeTop);
}

/* The populateScene function calls the ReadByteFile function. This is here mainly
   for compatibility with older generations of the OFconstruct header file.        */
void populateScene(Scene *scene, Light lightSrc, MathStat *m, FuncStat *f)
{
    // Should the default scene be loaded?
    if (inputFile[0] == '\0')
        populateDefaultScene(scene, lightSrc, m, f); // Pass inputs to the default scene.
    else
        ReadByteFile(scene, lightSrc, m, f); // Pass all inputs to the byte file reader.
}

/* And then the standard draw function that's been previously constructed */
Vector draw(Ray ray, Scene scene, Light light, int recursion, MathStat *m, FuncStat *f)
{
    Hit hit;
    Vector outputColour, reflectiveColour, refractiveColour, textureColour;
    VectorAlpha ColourAlpha;
    fixedp reflection, refraction;
    Ray newRay;
    
#ifdef DEBUG
    (*f).draw++;
#endif
    
    // Default is black. We can add to this (if there's a hit) 
    // or just return it (if there's no object)
    setVector(&outputColour, 0, 0, 0, f);
    
    hit = sceneIntersection(ray, scene, m, f);
    
    // Determine whether there was a hit. Otherwise default.
    if (hit.objectIndex >= 0)
    {
        // There was a hit.
        Vector lightDirection = GlobalLightingFlag ? light.direction : vecNormalised(vecSub(light.location, hit.location, m, f), m, f);
        
        // Determine whether this has a texture or not
        if (scene.object[hit.objectIndex].material.textureIdx < 0)
            setVector(&textureColour, -1, -1, -1, f);
        else
        {
            ColourAlpha = getColour(Textures[scene.object[hit.objectIndex].material.textureIdx], scene, hit, m, f);
            
            // Check to see if we need to create a new ray from this point:
            if (ColourAlpha.alpha < fp_fp1 && recursion >= 0)
            {
                // Yes, the alpha channel is < 1, so create a new ray starting from the point of intersection.
                // This ray has the same direction but a different source (the point of intersection).
                newRay.direction = ray.direction;
                // Recompute the source by adding a little extra to the distance.
                newRay.source = vecAdd(ray.source, scalarVecMult(hit.distance + 0x80, ray.direction, m, f), m, f); // hit.location;
                // Next, emit a ray. Don't reduce the recursion count.
                textureColour = vecAdd(scalarVecMult(ColourAlpha.alpha, ColourAlpha.vector, m, f), scalarVecMult(fp_fp1 - ColourAlpha.alpha, draw(newRay, scene, light, recursion, m, f), m, f), m, f);
            }
            else
                textureColour = ColourAlpha.vector;
        }
            

        // outputColour = vecAdd(ambiance(hit, scene, light, m, f), diffusion(hit, scene, light, m, f), m, f);
        outputColour = vecAdd(ambiance(hit, scene, light, textureColour, m, f), vecAdd(diffusion(hit, scene, light, lightDirection, textureColour, m, f), specular(hit, scene, light, lightDirection, textureColour, m, f), m, f), m, f);
        
        // Should we go deeper?
        if (recursion > 0)
        {
            // Yes, we should
            // Get the reflection
            reflectiveColour = draw(reflectRay(hit, m, f), scene, light, recursion - 1, m, f);
            DEBUG_statSubtractInt(m, 1);
            reflection = scene.object[hit.objectIndex].material.reflectivity;
            outputColour = vecAdd(outputColour, scalarVecMult(reflection, reflectiveColour, m, f), m, f);
            
            // Get the refraction
            refractiveColour = draw(refractRay(hit, scene.object[hit.objectIndex].material.inverserefractivity, scene.object[hit.objectIndex].material.squareinverserefractivity, m, f), scene, light, recursion - 1, m, f);
            DEBUG_statSubtractInt(m, 1);
            refraction = scene.object[hit.objectIndex].material.opacity;
            outputColour = vecAdd(outputColour, scalarVecMult(refraction, refractiveColour, m, f), m, f);
        }
        
        // We've got what we needed after the hit, so return
        DEBUG_statSubtractFlt(m, 1);
        // printf("Hit at: %f, %f, %f\nRay Direction: %f, %f, %f\nLight direction: %f, %f, %f\n", fp_FP2Flt(hit.location.x), fp_FP2Flt(hit.location.y), fp_FP2Flt(hit.location.z), fp_FP2Flt(ray.direction.x), fp_FP2Flt(ray.direction.y), fp_FP2Flt(ray.direction.z), fp_FP2Flt(lightDirection.x), fp_FP2Flt(lightDirection.y), fp_FP2Flt(lightDirection.z));
        return scalarVecMult(fp_fp1 - traceShadow(hit, scene, light, lightDirection, m, f), outputColour, m, f);
    }
    
    // No hit, return black.
    
    return outputColour;
}

#endif