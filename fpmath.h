#ifndef FPMATH_H_
#define FPMATH_H_

#define MAX_VAL 0x7FFFFFFF;
#define MIN_VAL 0x80000000;

// Sine and cosine defines
#define FP_CONST_B   83443      // A = 4 / pi
#define FP_CONST_C  -26561      // B = -4 / pi * pi
#define FP_CONST_Q   14746      // P = 0.225 or 0.775
#define FP_PI       205887      // pi
#define FP_2PI      411775      // 2 * pi
#define FP_PI_2     102944      // pi / 2

float fp_sin(float a)
{
    // Ensure input within the range of -pi to pi
    // printf("Original: 0x%X, %f\n", a, fp_FP2Flt(a) * 180. / 3.141592653589793238);
    a -= (a > FP_PI) * FP_2PI;
    // printf("  Step 1: 0x%X, %f\n", a, fp_FP2Flt(a) * 180. / 3.141592653589793238);
    a += (a < -FP_PI) * FP_2PI;
    // printf("  Step 2: 0x%X, %f\n", a, fp_FP2Flt(a) * 180. / 3.141592653589793238);
    
#ifdef DEBUG
    if (a > FP_PI)
        printf("Sine function out of range: 0x%X\n", a);
    if (a < -FP_PI)
        printf("Sine function out of range: 0x%X\n", a);
#endif
    
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
}