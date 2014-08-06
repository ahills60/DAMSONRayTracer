// Prototypes:
float triangleIntersection(float ray[6], int triangleIdx, float currentDistance);
void objectIntersection(float ray[6], int objectIdx);
float traceShadow(float localHitData[18], float direction[3]);
void reflectRay(float localHitData[18]);
void refractRay(float localHitData[18], float inverserefreactivity, float squareinverserefractivity);

// Modulo vector:
external int DomMod[5];

// External objects
extern float ObjectDB[MAX_OBJECTS][MAX_TRIANGLES][20];
extern float HitData[18];
extern float ResultStore[16];
extern int noObjects;
extern int noTriangles[MAX_OBJECTS];
extern float Light[8];
extern float Camera[22];



float triangleIntersection(float ray[6], int objectIdx, int triangleIdx, float currentDistance)
{
    int ku, kv;
    float dk, du, dv, ok, ou, ov, denom, dist, hu, hv, au, av, numer, beta, gamma, cmpopt;
    
    int shift1, msb1, msb2, bitdiff1, biteval;
    float tempVar1, tempVar2;
    
    int dominantAxisIdx = ObjectDB[objectIdx][triangleIdx][TriangleDominantAxisIdx] >> 16;
    
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
    if (denom < 0x4 && denom > -0x4)
        return 0;
    numer = ObjectDB[objectIdx][triangleIdx][TriangleNDDom] - ok - (ObjectDB[objectIdx][triangleIdx][TriangleNUDom] * ou) - (ObjectDB[objectIdx][triangleIdx][TriangleNVDom] * ov);
    
    if (numer == 0)
        return 0;
    // Do a sign check
    if ((denom & 0x80000000) ^ (numer & 0x80000000))
        return 0;
    
    // Locate the MSB of the numerator:
    tempVar1 = fabs(numer);
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
    tempVar1 = fabs(denom);
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
        dist = numer / (denom << bitdiff1);
        // Early exit:
        if ((currentDistance >> bitdiff1) < dist)
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
        hu = (ou >> bitdiff1) + (dist * du) - (au >> bitdiff1);
        hv = (ov >> bitdiff1) + (dist * dv) - (av >> bitdiff1);
    }
    
    beta = (hv * ObjectDB[objectIdx][triangleIdx][TriangleBUDom]) + (hu * ObjectDB[objectIdx][triangleIdx][TriangleBVDom]);
    cmpopt = EPS + (biteval ? 0x10000 : (0x10000 >> bitdiff1));
    
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
    float Mu, Mv, intersectionPoint, nearestIntersection = 0x7FFFFFFF;
    int n, i, nearestIdx, bitshift, nearestbitshift = 32;
    float dirVec[3], normVec[3], location[3];
    
    HitData[HitDataDistance] = 0;
    
    for (i = 0; i < 3; i += 1)
        dirVec[i] = ray[RaySourcex + i];
    
    for (n = 0; n < noTriangles[objectIdx]; n += 1)
    {
        intersectionPoint = triangleIntersection(ray, objectIdx, n, nearestIntersection);
        
        if (ResultStore[2] <= nearestbitshift && intersectionPoint > 0 && intersectionPoint < nearestIntersection)
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
                nearestbitshift = ResultStore[2];
                Mu = ResultStore[0];
                Mv = ResultStore[1];
            }
        }
    }
    
    // Only complete the hit data iff there was an intersection
    if (nearestIntersection > 0 && nearestIntersection < 0x7FFFFFFF)
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
        HitData[HitDatabitshift] = nearestbitshift;
        HitData[HitDataTriangleIndex] = nearestIdx;
        HitData[HitDataObjectIndex] = objectIdx;
    }
    else
        HitData[HitDataObjectIndex] = -1;
}

void sceneIntersection(float ray[6])
{
    int n, i;
    float nearestHit[18];
    
    nearestHit[HitDataDistance] = 0x7FFFFFFF;
    
    for (n = 0; n < noObjects; n += 1)
    {
        objectIntersection(ray, n);
        // Check to see if this hit is worth keeping. If so, take a copy
        if (HitData[HitDataDistance] > 0 && HitDataDistance[HitDataDistance] < nearestHit[HitDataDistance])
            for (i = 0; i < 18; i += 1)
                nearestHit[i] = HitData[i];
    }
    
    // Now check to see if there actually was a hit:
    if (nearestHit[HitDataDistance] <= 0 || nearestHit[HitDataDistance] >= 0x7FFFFFFF)
        nearestHit[HitDataObjectIndex] = -1;
    // Finally copy the contents of the nearest hit vector to the hit data vector.
    for (n = 0; n < 18; n += 1)
        HitData[n] = nearestHit[n];
}

float traceShadow(float localHitData[18], float direction[3])
{
    float ray[6];
    
    int n, m;
    float tempDist = 0x7FFFFFFF;
    
    // Populate the ray vector
    for (n = 0; n < 6; n += 1)
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
            if (m == localHitData[HitDataObjectIndex] && n == localHitData[HitDataTriangleIndex])
                continue;
            
            if (triangleIntersection(ray, m, n, tempDist) > (EPS << 1))
                return Light[LightShadowFactor];
        }
    }
    
    // If here, no objects obscured the light source, so return 0.
    return 0;
}

void reflectRay(float localHitData[18])
{
    float direction[3], normal[3];
    int i;
    
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
    
    scalarVecMult(dot(normal, direction) << 1, normal);
    
    for (i = 0; i < 3; i += 1)
    {
        // Move the reflection direction:
        ResultStore[3 + i] = ResultStore[i];
        // Then add the reflection source:
        ResultStore[i] = localHitData[HitDataHitLocation + i];
    }
}

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