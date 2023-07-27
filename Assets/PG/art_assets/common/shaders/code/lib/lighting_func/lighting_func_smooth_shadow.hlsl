#ifndef LIGHTING_FUNC_SMOOTH_SHADOW_INCLUDED
#define LIGHTING_FUNC_SMOOTH_SHADOW_INCLUDED


half SmoothShadow(half lightAtten, half intensity, half smoothness){
    intensity = ((intensity - 1) * 4);
    return smoothstep(intensity, smoothness, lightAtten);
}




#endif
