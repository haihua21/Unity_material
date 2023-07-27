#ifndef CH_SURFACE_DATA_INCLUDED
#define CH_SURFACE_DATA_INCLUDED


struct CH_SurfaceData
{
    half3 albedo;
    half3 specular;
    half  metallic;
    half  smoothness;
    half3 normalTS;
    half3 emission;
    half  occlusion;
    half  sss_mask;
    half  alpha;
};

#endif
