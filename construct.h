/*
 * bytecodeconstruct.h
 * 
 * This header file provides functions to read and interpret
 * a byte-code file produced by the OF2RayTracer.py script.
 *
 *  Created on: 1 Apr 2014
 *      Author: andrew
 */

// extern float ObjectDB[MAX_OBJECTS][MAX_TRIANGLES][20];
// extern float HitData[18];
// extern float ResultStore[16];
// extern int noObjects;
// extern int noTriangles[MAX_OBJECTS];
// extern float Light[8];
// extern float MaterialDB[MAX_OBJECTS][19];

// void ReadByteFile();
void populateDefaultScene();
void populateScene();
void draw(float ray[6], int recursion);

/* Function to read the byte file */
/*
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
*/
/* Populate a scene with set items */
void populateDefaultScene()
{
    int i;
    int red[3] = {255, 0, 0};
    int green[3] = {0, 255, 0};
    int blue[3] = {0, 0, 255};
    int purple[3] = {140, 0, 255};
    int white[3] = {255, 255, 255};
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
    matMult(transMat, tempMat);
    for (i = 0; i < 16; i += 1)
        transMat[i] = ResultStore[i];
    // createCube(int objectIndex, float size, float transMat[16])
    createCube(0, 1.0, transMat);
    
    // PlaneXZ 1: the base plane:
    genTransMatrix(1.0, 0.0, -4.0);
    for (i = 0; i < 16; i += 1)
        transMat[i] = ResultStore[i];
    createPlaneXZ(3, 10.0, transMat);
    
    // PlaneXZ 2: the top plane:
    genTransMatrix(1.0, 5.0, -4.0);
    for (i = 0; i < 16; i += 1)
        tempMat[i] = ResultStore[i];
    genZRotateMat(180.0);
    for (i = 0; i < 16; i += 1)
        transMat[i] = ResultStore[i];
    matMult(transMat, tempMat);
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
    matMult(transMat, tempMat);
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
    matMult(transMat, tempMat);
    for (i = 0; i < 16; i += 1)
        transMat[i] = ResultStore[i];
    createPlaneXZ(2, 10.0, transMat);
    
    // PlaneXZ 5: the left plane:
    genTransMatrix(1.0, 0.0, -6.0);
    for (i = 0; i < 16; i += 1)
        tempMat[i] = ResultStore[i];
    genXRotateMat(90.0);
    for (i = 0; i < 16; i += 1)
        transMat[i] = ResultStore[i];
    matMult(transMat, tempMat);
    for (i = 0; i < 16; i += 1)
        transMat[i] = ResultStore[i];
    createPlaneXZ(1, 10.0, transMat);
    
    // PlaneXZ 3: the left plane:
    genTransMatrix(0.0, 0.9, -2.7);
    for (i = 0; i < 16; i += 1)
        tempMat[i] = ResultStore[i];
    genYRotateMat(20.0);
    for (i = 0; i < 16; i += 1)
        transMat[i] = ResultStore[i];
    matMult(transMat, tempMat);
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
    float outputColour[3], reflectiveColour[3], refractiveColour[3], textureColour[3];
    float vector[3], hitLocation[3], localHitData[18], lightDirection[3];
    float colour[3], alpha;
    float reflection, refraction;
    float newRay[6], source[3];
    int i;
    
    // Default is black. We can add to this (if there's a hit) 
    // or just return it (if there's no object)
    for (i = 0; i < 3; i += 1)
        outputColour[i] = 0;
    
    // Check for an intersection. Results are stored in the hit data array
    sceneIntersection(ray);
    
    // Determine whether there was a hit. Otherwise default.
    if (HitData[HitDataObjectIndex] >= 0)
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
        if (MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex] < 0)
            for (i = 0; i < 3; i += 1)
                textureColour[i] = -1;
        else
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
        
        // printf("Hit at: %f, %f, %f\nRay Direction: %f, %f, %f\nLight direction: %f, %f, %f\n", fp_FP2Flt(hit.location.x), fp_FP2Flt(hit.location.y), fp_FP2Flt(hit.location.z), fp_FP2Flt(ray.direction.x), fp_FP2Flt(ray.direction.y), fp_FP2Flt(ray.direction.z), fp_FP2Flt(lightDirection.x), fp_FP2Flt(lightDirection.y), fp_FP2Flt(lightDirection.z));
        scalarVecMult(1 - traceShadow(localHitData, lightDirection), outputColour);
        // The result is saved to the result store.
        return;
    }
    
    // No hit, return black.
    
    for (i = 0; i < 3; i += 1)
        ResultStore[i] = outputColour[i];
}