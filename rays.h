
float triangleIntersection(float ray[6], int triangleIdx, float currentDistance);

// Modulo vector:
int DomMod[5] = {0, 1, 2, 0, 1};

// External objects
extern float HitData[18];
extern float ResultStore[16];

// Rays are in form: source (3), direction (3).
#define RaySourcex       0
#define RaySourcey       1
#define RaySourcez       2
#define RayDirectionx    3
#define RayDirectiony    4
#define RayDirectionz    5


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
