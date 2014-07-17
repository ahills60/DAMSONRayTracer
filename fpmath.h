float fp_sin(float a);
float fp_cos(float a);
float fp_log(float a);

#define MAX_VAL 0x7FFFFFFF;
#define MIN_VAL 0x80000000;

// Sine and cosine defines
#define FP_CONST_B   83443      // A = 4 / pi
#define FP_CONST_C  -26561      // B = -4 / pi * pi
#define FP_CONST_Q   14746      // P = 0.225 or 0.775
#define FP_PI       205887      // pi
#define FP_2PI      411775      // 2 * pi
#define FP_PI_2     102944      // pi / 2

int LOOKUP_LOG1[31] = {
    2017, 3973, 5873, 7719, 9515, 11262, 12965, 14624, 16242, 17821, 19364, 
    20870, 22343, 23783, 25193, 26573, 27924, 29248, 30546, 31818, -32469, 
    -31244, -30042, -28861, -27701, -26561, -25441, -24340, -23256, -22191, 
    -21142
};
int LOOKUP_LOG2[31] = {
    64, 128, 192, 256, 319, 383, 446, 510, 573, 637, 700, 764, 827, 890, 
    953, 1016, 1079, 1142, 1205, 1268, 1330, 1393, 1456, 1518, 1581, 1643, 
    1706, 1768, 1830, 1892, 1955
};

float fp_sin(float a)
{
    // Ensure input within the range of -pi to pi
    // printf("Original: 0x%X, %f\n", a, fp_FP2Flt(a) * 180. / 3.141592653589793238);
    a -= (a > FP_PI) * FP_2PI;
    // printf("  Step 1: 0x%X, %f\n", a, fp_FP2Flt(a) * 180. / 3.141592653589793238);
    a += (a < -FP_PI) * FP_2PI;
    // printf("  Step 2: 0x%X, %f\n", a, fp_FP2Flt(a) * 180. / 3.141592653589793238);
    
// #ifdef DEBUG
//     if (a > FP_PI)
//         printf("Sine function out of range: 0x%X\n", a);
//     if (a < -FP_PI)
//         printf("Sine function out of range: 0x%X\n", a);
// #endif
    
    // Use fast sine parabola approximation
    float output = (FP_CONST_B * a) + ((FP_CONST_C * a) * fabs(a));
    
    // Get extra precision weighting the parabola:
    output = FP_CONST_Q * ((output * fabs(output)) - output) + output; // Q * output + P * output * abs(output)
    
    // printf("  Output: %f\n", fp_FP2Flt(output));
    
    return output;
}

/* Fixed point cosine */
float fp_cos(float a)
{
    a -= (a > FP_PI) * FP_2PI;
    a += (a < -FP_PI) * FP_2PI;
    // Use the sine function
    return fp_sin(a + FP_PI_2);
float fp_log(float a)
{
    if (a <= 0)
    {
        return MIN_VAL;
    }
    
    // Get the MSB position
    int im, j2, j1, j3, p = -16;
    float i = a;
    
    if (i & 0xFFFF0000)
    {
        i = i >> 16;
        p += 16;
    }
    if (i & 0x0000FF00)
    {
        i = i >> 8;
        p += 8;
    }
    if (i & 0x000000F0)
    {
        i = i >> 4;
        p += 4;
    }
    if (i & 0x0000000C)
    {
        i = i >> 2;
        p += 2;
    }
    if (i & 0x00000002)
    {
        i = i >> 1;
        p += 1;
    }
    
    // Create a log based on MSB position
    float k = p * 45426;
    
    // Create 3 parts of the 15 bits after MSB
    if (p >= 0)
    {
        j3 = a >> (p + 1);
    }
    else
    {
        j3 = a << (-1 - p);
    }
    j2 = j3 >> 5;
    j1 = j2 >> 5;
    
    // Use bits MSB + 1 to MSB + 5
    im = (j1 & 31) - 1;
    if (im >= 0)
    {
        k += ((float) LOOKUP_LOG1[im] & 0xFFFF);
    }
    
    // Use bits MSB + 6 to MSB + 10
    im = (j3 & 0x03E0);
    if (im >= j1)
    {
        im = im / j1;
        k += ((float) LOOKUP_LOG2[im - 1] & 0xFFFF);
        im = im * j1;
    }
    else
    {
        im = 0;
    }
    // Finally use bits MSB + 11 to MSB + 16
    im = ((j3 & 0x3FF) - im) << 12;
    if (im >= j2)
    {
        i = im / j2;
        k += (i + 1) >> 1;
    }
    
    return k;
}