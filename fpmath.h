#define MAX_VAL 0x7FFFFFFF;
#define MIN_VAL 0x80000000;

// Sine and cosine defines
#define FP_CONST_B   1.2732391357      // A = 4 / pi
#define FP_CONST_C  -0.4052886963      // B = -4 / pi * pi
#define FP_CONST_Q   0.225006      // P = 0.225 or 0.775
#define FP_PI       3.1415926535897932384626      // pi
#define FP_2PI      6.283185307      // 2 * pi
#define FP_PI_2     1.570796327      // pi / 2

float fp_sin(float x);
float fp_cos(float x);
float fp_exp(float z);
float fp_log(float a);
float fp_pow(float a, float b);
int fp_powi(int a, int b);

float fp_sin(float a)
{
    float c, absc, absa;
    // int b = bitset(a);
    float output;
    // Ensure input within the range of -pi to pi
    // a += (a < -FP_PI) ? FP_2PI : 0.0;
    // a -= (a > FP_PI) ? FP_2PI : 0.0;
    if (a > FP_PI)
        a -= FP_2PI;
    if (a < -FP_PI)
        a += FP_2PI;
    
    // printf("%f\n", a);
    
    absa = fabs(a);
    
    // Use fast sine parabola approximation
    c = (FP_CONST_B * a) + (FP_CONST_C * a * absa);
    
    absc = fabs(c);
    
    // printf("%d : %d : %d\n", c, absc, FP_CONST_Q);
    
    // Get extra precision weighting the parabola:
    c += (FP_CONST_Q * ((c * absc) - c)); // Q * output + P * output * abs(output)
    
    // Finally, convert the integer back to a float.
    return c;
}

/* Fixed point cosine */
float fp_cos(float a)
{
    float c, d, e = 0, f, b = a;
    b += FP_PI_2;
    // printf("%f (input) => %f (add pi/2)\n", a, b);
    // a += (a < -FP_PI) ? FP_2PI : 0;
    // c = (b > FP_PI) ? FP_2PI : 0.0;
    if (b > FP_PI)
        e = FP_2PI;
    d = b - c;
    f = b - e;
    
    // printf("%f (if inline result) =/= %f (if branch result) (%f (inline eval) =/= %f (branch eval))\n", d, f, c, e);
    
    // Use the sine function
    return fp_sin(f);
}

float fp_exp(float z) 
{
    int t;
    int x = bitset(z);
    int y = 0x00010000;  /* 1.0 */
    
    // Bound to a maximum if larger than ln(0.5 * 32768)
    if (x > 0x000A65AE)
        return bitset(MAX_VAL);
    
    // Fix for negative values.
    if (x < 0)
    {
        x += 0xb1721; /* 11.0903 */
        y >>= 16;
    }
    
    t=x-0x58b91;   /* 5.5452 */ 
    if (t>=0) 
    {
        x=t;
        y<<=8;
    }
    t=x-0x2c5c8;   /* 2.7726 */
    if (t>=0) 
    {
        x=t;
        y<<=4;
    }
    t=x-0x162e4;  /* 1.3863 */
    if (t>=0) 
    {
        x=t;
        y<<=2;
    }
    t=x-0x0b172;  /* 0.6931 */
    if (t>=0) 
    {
        x=t;
        y<<=1;
    }
    t=x-0x067cd;  /* 0.4055 */
    if (t>=0)
    {
        x=t;
        y+=y>>1;
    }
    t=x-0x03920;  /* 0.2231 */
    if (t>=0)
    {
        x=t;
        y+=y>>2;
    }
    t=x-0x01e27;  /* 0.1178 */
    if (t>=0)
    {
        x=t;
        y+=y>>3;
    }
    t=x-0x00f85;  /* 0.0606 */
    if (t>=0)
    {
        x=t;
        y+=y>>4;
    }
    t=x-0x007e1;  /* 0.0308 */
    if (t>=0) 
    {
        x=t;
        y+=y>>5;
    }
    t=x-0x003f8;  /* 0.0155 */
    if (t>=0) 
    {
        x=t;
        y+=y>>6;
    }
    t=x-0x001fe;  /* 0.0078 */
    if (t>=0) 
    {
        x=t;
        y+=y>>7;
    }
    /*
    // Old shift and add
    if (x&0x100)
    y+=y>>8;
    if (x&0x080)
    y+=y>>9;
    if (x&0x040)
    y+=y>>10;
    if (x&0x020)
    y+=y>>11;
    if (x&0x010)
    y+=y>>12;
    if (x&0x008)
    y+=y>>13;
    if (x&0x004)
    y+=y>>14;
    if (x&0x002)
    y+=y>>15;
    if (x&0x001)
    y+=y>>16;
    */
    // This is does the same thing:
    y += ((y >> 8) * x) >> 8;
    return bitset(y);
}

float fp_log(float a)
{
    int t,y, x = bitset(a);
    
    if (a <= 0)
        return bitset(MIN_VAL);

    y = 0xa65af;
    if(x < 0x00008000)
    {
        x <<= 16;
        y -= 0xb1721;
    }
    if(x < 0x00800000)
    { 
        x <<= 8;
        y -= 0x58b91;
    }
    if(x < 0x08000000)
    {
        x <<= 4;
        y -= 0x2c5c8;
    }
    if(x < 0x20000000)
    {
        x <<= 2;
        y -= 0x162e4;
    }
    if(x < 0x40000000)
    {
        x <<= 1;
        y -= 0x0b172;
    }
    t = x + (x >> 1);
    if((t & 0x80000000) == 0) 
    {
        x = t;
        y -= 0x067cd;
    }
    t = x + (x >> 2);
    if((t & 0x80000000) == 0)
    {
        x = t;
        y -= 0x03920;
    }
    t = x + (x >> 3);
    if((t & 0x80000000) == 0)
    {
        x = t;
        y -= 0x01e27;
    }
    t = x + (x >> 4);
    if((t & 0x80000000) == 0)
    {
        x = t;
        y -= 0x00f85;
    }
    t = x + (x >> 5); 
    if((t & 0x80000000) == 0)
    {
        x = t;
        y -= 0x007e1;
    }
    t = x + (x >> 6); 
    if((t & 0x80000000) == 0) 
    {
        x = t;
        y -= 0x003f8;
    }
    t = x + (x >> 7);
    if((t & 0x80000000) == 0)
     {
         x = t;
         y -= 0x001fe;
     }
    x = 0x80000000 - x;
    y -= x >> 15;
    return bitset(y);
}

float fp_pow(float a, float b)
{
    if (a <= 0)
        return 0;
        
    return fp_exp(fp_log(a) * b));
}

int fp_powi(int a, int b)
{
    int result = 1;
    while (b)
    {
        if (b & 1)
            result *= a;
        b >>= 1;
        a *= a;
    }
    return result;
}
