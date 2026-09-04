// Aether Spatial Rescue Lite (ASR-Lite) - original prototype
// Low-cost spatial upscale + edge-aware sharpen for legacy GPUs.
// Prototype only: not wired into OptiScaler runtime yet.
Texture2D<float4> Src : register(t0);
RWTexture2D<float4> Dst : register(u0);
SamplerState LinearClamp : register(s0);
cbuffer Params : register(b0) { uint2 SrcSize; uint2 DstSize; float Sharpness; float _pad0; float2 _pad1; }
[numthreads(8,8,1)]
void main(uint3 id : SV_DispatchThreadID){
    if(any(id.xy >= DstSize)) return;
    float2 uv=(float2(id.xy)+0.5)/float2(DstSize);
    float2 texel=1.0/float2(SrcSize);
    float3 c=Src.SampleLevel(LinearClamp,uv,0).rgb;
    float3 n=Src.SampleLevel(LinearClamp,uv+float2(0,-texel.y),0).rgb;
    float3 s=Src.SampleLevel(LinearClamp,uv+float2(0, texel.y),0).rgb;
    float3 e=Src.SampleLevel(LinearClamp,uv+float2( texel.x,0),0).rgb;
    float3 w=Src.SampleLevel(LinearClamp,uv+float2(-texel.x,0),0).rgb;
    float grad=abs(dot(e-w,float3(.2126,.7152,.0722)))+abs(dot(s-n,float3(.2126,.7152,.0722)));
    float edge=saturate(grad*2.0);
    float3 blur=(n+s+e+w)*0.25;
    float amount=Sharpness*(1.0-0.65*edge);
    Dst[id.xy]=float4(saturate(c+(c-blur)*amount),1);
}
