/*
 * lighting.h
 * 
 * This header file provides primitives for lighting and shading.
 *
 *  Created on: 5 Dec 2013
 *      Author: andrew
 */

void ambiance(float localHitData[18], float textureColour[3]);
void diffusion(float localHitData[18], float lightDirection[3], float textureColour[3]);
void specular(float localHitData[18], float lightDirection[3], float textureColour[3]);

// extern float RGBChannels[3];
// extern float ResultStore[4][4];
// extern float Light[8];
// extern float MaterialDB[MAX_OBJECTS][19];

// void checkColour(Vector colour, int stage)
// {
//     if (colour.x < 0)
//     {
//         printf("Red is negative at stage %d: 0x%X\n", stage, (unsigned int) colour.x);
//     }
//     if (colour.y < 0)
//     {
//         printf("Green is negative at stage %d: 0x%X\n", stage, (unsigned int) colour.y);
//     }
//     if (colour.z < 0)
//     {
//         printf("Red is negative at stage %d: 0x%X\n", stage, (unsigned int) colour.z);
//     }
// }

/* Creates ambiance effect given a hit, a scene and some light */
void ambiance(float localHitData[18], float textureColour[3])
{
    int i, objIdx = localHitData[HitDataObjectIndex];
    
    // Check to see if there's a texture
    if (textureColour[0] < 0)
         // No texture. Apply material colour
        for (i = 0; i < 3; i += 1)
            RGBChannels[i] += MaterialDB[objIdx][MaterialCompAmbianceColour + i];
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
    int i;
    
    if (MaterialDB[localHitData[HitDataObjectIndex]][MaterialDiffusive] > 0)
    {
        for (i = 0; i < 3; i += 1)
            vector[i] = localHitData[HitDataHitNormal + i];
        
        // Need to compute the direction of light
        dotProduct = dot(vector, lightDirection);
        
        // If the dot product is negative, this term shouldn't be included.
        if (dotProduct < 0)
            return;
        
        // Dot product is positive, so continue
        distance = dotProduct * MaterialDB[localHitData[HitDataObjectIndex]][MaterialDiffusive];
        
        // Has a texture been defined?
        if (textureColour[0] < 0)
        {    
            for (i = 0; i < 3; i += 1)
                vector[i] = MaterialDB[localHitData[HitDataObjectIndex]][MaterialLightColour + i]
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
        RGBChannels[i] += ResultStore[i];
}

/* Creates specular effect given a hit, a scene and some light */
void specular(float localHitData[18], float lightDirection[3], float textureColour[3])
{
    int i;
    float vector[3], dotProduct, distance;
    
    if (MaterialDB[localHitData[HitDataObjectIndex]][MaterialSpecular] > 0)
    {
        // Reflective ray:
        reflectRay(localHitData);
        for (i = 0; i < 3; i += 1)
            vector[i] = ResultStore[RayDirectionx + i];
        
        dotProduct = dot(lightDirection, vector);
        
        if (dotProduct < 0)
            return;
        
        distance = fp_pow(dotProduct, MaterialDB[localHitData[HitDataObjectIndex]][MaterialShininess]) * MaterialDB[localHitData[HitDataObjectIndex]][MaterialSpecular]);
            
        // Has a texture been defined?
        if (textureColour[0] < 0)
        {
            for (i = 0; i < 3; i += 1)
                vector[i] = MaterialDB[localHitData[HitDataObjectIndex]][MaterialLightColour + i] 
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
        RGBChannels[i] += ResultStore[i];
}
