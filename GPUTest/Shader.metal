//
//  Shader.metal
//  GPUTest
//
//  Created by vo1dw4lker on 12/02/2025.
//

#include <metal_stdlib>
using namespace metal;

kernel void multiplyArrays(device const float* inA,
                       device const float* inB,
                       device float* result,
                       uint index [[thread_position_in_grid]]) {
    result[index] = inA[index] * inB[index];
}

kernel void rand(device float* buf,
                 constant uint& seedX,
                 uint index [[thread_position_in_grid]])
{
    uint seed = seedX + index * 57;
    seed = (seed << 13) ^ seed;
    
    float randVal = ((1.0 - ((seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
    
    buf[index] = randVal;
}
