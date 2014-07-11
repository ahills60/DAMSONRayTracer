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

// Add math stats
#include "mathstats.h"

// Add function stats
#include "funcstats.h"

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
float ambiance(Hit hit, Scene scene, Light light, Vector textureColour, MathStat *m, FuncStat *f)
{
#ifdef DEBUG
    (*f).ambiance++;
#endif
    Vector outputColour;
    
    // Check to see if there's a texture
    if (textureColour.x < 0)
        outputColour = scene.object[hit.objectIndex].material.compAmbianceColour; // No texture. Apply material colour
    else
        outputColour = scalarVecMult(scene.object[hit.objectIndex].material.ambiance, textureColour, m, f); // Texture. Apply texture colour
    
    return outputColour;
}

/* Creates diffusion effect given a hit, a scene and some light */
Vector diffusion(Hit hit, Scene scene, Light light, Vector lightDirection, Vector textureColour, MathStat *m, FuncStat *f)
{
#ifdef DEBUG
    (*f).diffusion++;
#endif
    Vector outputColour;
    
    setVector(&outputColour, 0, 0, 0, f);
    
    if (scene.object[hit.objectIndex].material.diffusivity > 0)
    {
        // Need to compute the direction of light
        fixedp dotProduct = dot(hit.normal, lightDirection, m, f);
        
        // If the dot product is negative, this term shouldn't be included.
        if (dotProduct < 0)
            return outputColour;
        
        // Dot product is positive, so continue
        fixedp distance = fp_mult(dotProduct, scene.object[hit.objectIndex].material.diffusivity);
        
        DEBUG_statMultiplyFlt(m, 1);
        
        // Has a texture been defined?
        if (textureColour.x < 0)
            outputColour = scalarVecMult(distance, scene.object[hit.objectIndex].material.matLightColour, m, f); // No texture defined
        else
            outputColour = scalarVecMult(distance, vecMult(textureColour, light.colour, m, f), m, f);
    }
    
    return outputColour;
}

/* Creates specular effect given a hit, a scene and some light */
Vector specular(Hit hit, Scene scene, Light light, Vector lightDirection, Vector textureColour, MathStat *m, FuncStat *f)
{
#ifdef DEBUG
    (*f).specular++;
#endif
    Vector outputColour;
    
    setVector(&outputColour, 0, 0, 0, f);
    
    if (scene.object[hit.objectIndex].material.specular > 0)
    {
        fixedp dotProduct;
    
        // Reflective ray:
        Ray reflection = reflectRay(hit, m, f);
        dotProduct = dot(lightDirection, reflection.direction, m, f);
    
        if (dotProduct < 0)
            return outputColour;
    
        fixedp distance = fp_mult(fp_pow(dotProduct, scene.object[hit.objectIndex].material.shininess), scene.object[hit.objectIndex].material.specular);
        DEBUG_statMultiplyFlt(m, 1);
        DEBUG_statPower(m, 1);
    
        // Has a texture been defined?
        if (textureColour.x < 0)
            outputColour = scalarVecMult(distance, scene.object[hit.objectIndex].material.matLightColour, m, f); // No texture defined
        else
            outputColour = scalarVecMult(distance, vecMult(textureColour, light.colour, m, f), m, f);
    }
    return outputColour;
}

#endif
