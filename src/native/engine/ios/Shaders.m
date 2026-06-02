
#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
};

vertex VertexOut vertex_main(uint vertexID [[vertex_id]]) {
    VertexOut out;
    float2 positions[3] = {
        float2(-1.0, -1.0),
        float2( 3.0, -1.0),
        float2(-1.0,  3.0)
    };
    out.position = float4(positions[vertexID], 0.0, 1.0);
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    return float4(0.39, 0.59, 0.78, 1.0);
}
