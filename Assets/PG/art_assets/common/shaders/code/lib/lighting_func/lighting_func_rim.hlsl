#ifndef LIGHTING_FUNC_RIM_INCLUDED
#define LIGHTING_FUNC_RIM_INCLUDED


half3 CalcRim(half NDotV, half NDotL, half3 rim_color, half ao){
    half rim_edge = ( Pow4(1 - NDotV)) * NDotL;
    return rim_edge * rim_color * ao;
}


#endif
