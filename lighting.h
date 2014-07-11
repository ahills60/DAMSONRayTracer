/*
 * lighting.h
 * 
 * This header file provides primitives for lighting and shading.
 *
 *  Created on: 5 Dec 2013
 *      Author: andrew
 */

#ifndef LIGHTING_H_
#define LIGHTING_H_

#include "fpmath.h"

#include "rays.h"

extern float RGBChannels[3];
extern float ResultStore[4][4];

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
void ambiance(Hit hit, Scene scene, Light light, float textureColour[3])
{
    float outputColour[3];
    
    // Check to see if there's a texture
    if (textureColour[0] < 0)
        //TODO: Resolve the material object
        //TODO: Unravel the objects within the scenery
        outputColour = scene.object[hit.objectIndex].material.compAmbianceColour; // No texture. Apply material colour
    else
    {
        scalarVecMult(scene.object[hit.objectIndex].material.ambiance, textureColour); // Texture. Apply texture colour
        outputColour = {ResultStore[0][0], ResultStore[0][1], ResultStore[0][2]};
    }
    RGBChannels[0] += outputColour[0];
    RGBChannels[1] += outputColour[1];
    RGBChannels[2] += outputColour[2];
}

/* Creates diffusion effect given a hit, a scene and some light */
void diffusion(Hit hit, Scene scene, Light light, float lightDirection[3], float textureColour[3])
{
    float outputColour;
    
    if (scene.object[hit.objectIndex].material.diffusivity > 0)
    {
        // Need to compute the direction of light
        float dotProduct = dot(hit.normal, lightDirection);
        
        // If the dot product is negative, this term shouldn't be included.
        if (dotProduct < 0)
            return;
        
        // Dot product is positive, so continue
        float distance = dotProduct * scene.object[hit.objectIndex].material.diffusivity;
        
        // Has a texture been defined?
        if (textureColour[0] < 0)
        {    
            scalarVecMult(distance, scene.object[hit.objectIndex].material.matLightColour);
            outputColour = {ResultStore[0][0], ResultStore[0][1], ResultStore[0][2]}; // No texture defined
        }
        else
        {
            scalarVecMult(distance, textureColour * light.colour));
            outputColour = {ResultStore[0][0], ResultStore[0][1], ResultStore[0][2]};
        }
    }
    else 
        // Otherwise, return with nothing
        return;
    
    RGBChannels[0] += outputColour[0];
    RGBChannels[1] += outputColour[1];
    RGBChannels[2] += outputColour[2];
}

/* Creates specular effect given a hit, a scene and some light */
void specular(Hit hit, Scene scene, Light light, float lightDirection[3], float textureColour[3])
{
    float outputColour[3] = {0, 0, 0};
    
    if (scene.object[hit.objectIndex].material.specular > 0)
    {
        float dotProduct;
    
        // Reflective ray:
        Ray reflection = reflectRay(hit);
        dotProduct = dot(lightDirection, reflection.direction);
    
        if (dotProduct < 0)
            return;
    
        float distance = fp_pow(dotProduct, scene.object[hit.objectIndex].material.shininess) * scene.object[hit.objectIndex].material.specular);
            
        // Has a texture been defined?
        if (textureColour[0] < 0)
        {
            scalarVecMult(distance, scene.object[hit.objectIndex].material.matLightColour); // No texture defined
            outputColour = {ResultStore[0][0], ResultStore[0][1], ResultStore[0][2]};
        }
        else
        {
            vecMult(textureColour, light.colour)
            scalarVecMult(distance, {ResultStore[0][0], ResultStore[0][1], ResultStore[0][2]});
            outputColour = {ResultStore[0][0], ResultStore[0][1], ResultStore[0][2]};
        }
    }
    else
        // Otherwise return with nothing
        return;
    
    RGBChannels[0] += outputColour[0];
    RGBChannels[1] += outputColour[1];
    RGBChannels[2] += outputColour[2];
}

#endif
