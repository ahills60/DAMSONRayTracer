extern float MaterialDB[MAX_OBJECTS][19];
extern float ObjectDB[MAX_OBJECTS][MAX_TRIANGLES][20];
extern float Light[8];
extern int noTriangles[MAX_OBJECTS];
extern int noObjects;

// Prototypes
void setMaterial(int materialIdx, float colour[3], float ambiance, float diffusive, float specular, float shininess, float reflectivity, float opacity, float refractivity, int textureIndex);
// void transformObject(int ObjectIndex, float transformMatrix[16]);



void setMaterial(int materialIdx, float colour[3], float ambiance, float diffusive, float specular, float shininess, float reflectivity, float opacity, float refractivity, int textureIndex)
{
    int i;
    
    // Start by populating the colour
    for (i = 0; i < 3; i += 1)
    {
        MaterialDB[materialIdx][MaterialColour + i] = colour[i];
        MaterialDB[materialIdx][MaterialLightColour + i] = colour[i] * Light[i + LightColour];
        MaterialDB[materialIdx][MaterialCompAmbianceColour + i] = ambiance * MaterialDB[materialIdx][MaterialLightColour + i];
    }
    
    MaterialDB[materialIdx][MaterialReflectivity] = reflectivity;
    MaterialDB[materialIdx][MaterialOpacity] = opacity;
    MaterialDB[materialIdx][MaterialRefractivity] = refractivity;
    if ((void) refractivity == 0)
    {
        MaterialDB[materialIdx][MaterialInverseRefractivity] = 1.0;
        MaterialDB[materialIdx][MaterialSquareInverseRefractivity] = 1.0;
    }
    else
    {
        MaterialDB[materialIdx][MaterialInverseRefractivity] = 1.0 / refractivity;
        MaterialDB[materialIdx][MaterialSquareInverseRefractivity] = 1.0 / (refractivity * refractivity);
    }

    MaterialDB[materialIdx][MaterialAmbiance] = ambiance;
    MaterialDB[materialIdx][MaterialDiffusive] = diffusive;
    MaterialDB[materialIdx][MaterialSpecular] = specular;
    MaterialDB[materialIdx][MaterialShininess] = shininess;
    MaterialDB[materialIdx][MaterialTextureIndex] = textureIndex;
}

// void transformObject(int ObjectIndex, float transformMatrix[16])
// {
//     int i, thisNoTris = noTriangles[ObjectIndex];
//
//     for (i = 0; i < thisNoTris; i += 1)
//     {
//
//
//     }
// }
