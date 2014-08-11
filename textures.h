/* Defines functions for extracting RGB values from textures */

void getTexel(float localHitData[18], float uv[2]);
void getColour(float localHitData[18]);

// External variables
// extern float ObjectDB[MAX_OBJECTS][MAX_TRIANGLES][20];
// extern float MaterialDB[MAX_OBJECTS][19];
// extern float ResultStore[16];
// extern int TextureDB[MAX_TEXTURES][4];
// extern int RenderTransparency;

void getTexel(float localHitData[18], float uv[2])
{
    float c1[3], c2[3], c3[3], c4[3];
    float URem, VRem, alpha, uvf0, uvf1;
    int b1, b2, b3, b4, uv0 = bitset(uv[0]), uv1 = bitset(uv[1]);
    float a1, a2, a3, a4;
    int TextUPos, TextVPos, i;
    
    // Locate the pixel intersection
    uv0 += 0x03E80000;
    uv0 &= 0x0000FFFF;
    uv1 += 0x03E80000;
    uv1 &= 0x0000FFFF;
    uvf0 = bitset(uv0);
    uvf1 = bitset(uv1);
    
    uv[0] = uvf0 * (TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureWidth] << 16);
    uv[1] = uvf1 * (TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureHeight] << 16);
    
    uv0 = bitset(uv[0]);
    uv1 = bitset(uv[1]);
    
    // Get the whole number pixel value
    TextUPos = uv0 >> 16;
    TextVPos = uv1 >> 16;
    
    uv0 &= 0x0000FFFF;
    uv1 &= 0x0000FFFF;
         
    // Compute weights from the fractional part
    URem = bitset(uv0);
    VRem = bitset(uv1);
    
    // Border checks:
    // Offset (0, 0)
    b1 = TextUPos + TextVPos * TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureWidth];
    // Offset (1, 0)
    b2 = (TextUPos < TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureWidth]) ? b1 + 1 : 0;
    // Offset (0, 1)
    b3 = (TextVPos < TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureHeight]) ? TextUPos + (TextVPos + 1) * TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureWidth] : TextUPos;
    // Offset (1, 1)
    b4 = (TextUPos < TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureWidth]) ? (TextVPos < TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureHeight]) ? TextUPos + 1 + (TextVPos + 1) * TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureWidth] : TextUPos + 1 : (TextVPos < TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureHeight]) ? (TextVPos + 1) * TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureWidth] : 0;
    
    // Compute colours at points
    for (i = 0; i < 3; i += 1)
    {
        writesdram(TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureMemStart] + i + (b1 * (TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureAlpha] ? 4 : 3)), c1[i], 1);
        writesdram(TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureMemStart] + i + (b2 * (TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureAlpha] ? 4 : 3)), c2[i], 1);
        writesdram(TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureMemStart] + i + (b3 * (TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureAlpha] ? 4 : 3)), c3[i], 1);
        writesdram(TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureMemStart] + i + (b4 * (TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureAlpha] ? 4 : 3)), c4[i], 1);
    }
    
    // Bilinear filter:
    a1 = (1 - URem) * (1 - VRem);
    a2 = URem * (1 - VRem);
    a3 = (1 - URem) * VRem;
    a4 = URem * VRem;
    
    for (i = 0; i < 3; i += 1)
    {
        // Scaled sum of components:
        ResultStore[i] = a1 * c1[i] + a2 * c2[i] + a3 * c3[i] + a4 * c4[i];
        // Overflow check
        if (ResultStore[i] > 1)
            ResultStore[i] = 1;
    }
    
    // Now compute the alpha value:
    if (TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureAlpha] >= 0 && 0)
    {
        // Extract alpha channels
        writesdram(TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureMemStart] + 3 + (b1 * 4), c1[1], 1);
        writesdram(TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureMemStart] + 3 + (b2 * 4), c2[1], 1);
        writesdram(TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureMemStart] + 3 + (b3 * 4), c3[1], 1);
        writesdram(TextureDB[MaterialDB[localHitData[HitDataObjectIndex]][MaterialTextureIndex]][TextureMemStart] + 3 + (b4 * 4), c4[1], 1);
        a1 *= c1[1];
        a2 *= c2[1];
        a3 *= c3[1];
        a4 *= c4[1];
        // ResultStore[3] = alpha
        ResultStore[3] = a1 + a2 + a3 + a4;
        // Overflow check
        if (ResultStore[3] > 1)
            ResultStore[3] = 1;
    }
    else
        ResultStore[3] = 1;
}

void getColour(float localHitData[18])
{
    float uv1[2], uv2[2], uv3[2];
    int i;
    for (i = 0; i < 2; i += 1)
    {
        uv1[i] = ObjectDB[localHitData[HitDataObjectIndex]][localHitData[HitDataTriangleIndex]][TriangleAu + i];
        uv2[i] = ObjectDB[localHitData[HitDataObjectIndex]][localHitData[HitDataTriangleIndex]][TriangleBu + i] - uv1[i];
        uv3[i] = ObjectDB[localHitData[HitDataObjectIndex]][localHitData[HitDataTriangleIndex]][TriangleCu + i] - uv1[i];
    }
    // V - U
    // Scale with Mu
    scalarUVMult(localHitData[HitDataMu], uv2);
    // Extract the results
    uv2[0] = ResultStore[0];
    uv2[1] = ResultStore[1];
    
    // W - U
    // Scale with Mv
    scalarUVMult(localHitData[HitDataMv], uv3);
    // Contents of UV3 in results store. Let's just extract it from there.
    
    // Then add UV1, UV2 and UV3:
    uv1[0] += uv2[0] + ResultStore[0];
    uv1[1] += uv2[1] + ResultStore[1];
    
    getTexel(localHitData, uv1);
    // This should return the results within the results store.
}