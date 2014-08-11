/* Implements basic shapes for the ray tracer */

// extern float ObjectDB[MAX_OBJECTS][MAX_TRIANGLES][20];
// extern int noObjects;
// extern int noTriangles[MAX_OBJECTS];
//
// // Result storage
// extern float ResultStore[16];

// Prototype these functions:
void createCube(int objectIndex, float size, float transMat[16]);
void createPlaneXZ(int objectIndex, float size, float transMat[16]);

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
        setTriangle(objectIndex, noTriangles[objectIndex], u, v, w);
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
    size >>= 1;
    
    minVal = -size;
    maxVal = size;
    
    // Create two triangles:
   for (i = 0; i < 2; i += 1)
   {
       for (j = 0; j < 2; j += 1)
       {
           u[i * 6 + j*2] = (pattern[i * 6 + j]) ? maxVal : minVal;
           v[i * 6 + j*2 + 2] = (pattern[i * 6 + j + 2]) ? maxVal : minVal;
           w[i * 6 + j*2 + 4] = (pattern[i * 6 + j + 4]) ? maxVal : minVal;
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
       setTriangle(objectIndex, noTriangles[objectIndex], u, v, w);
   }
}
