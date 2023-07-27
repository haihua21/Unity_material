#ifndef LIGHTING_FUNC_D_G_F_INCLUDED
#define LIGHTING_FUNC_D_G_F_INCLUDED

float D_Function( float NdotH, float roughness )
{
        float a2 = roughness * roughness;
        float NdotH2 = NdotH * NdotH;
        float nom = a2;
        float denom = NdotH2 * (a2 - 1)+1;
        denom = denom * denom * 3.1415926;
        return nom /max(denom,0.000001);
}

float G_Function( float NdotL, float NdotV, float roughness )
{
        float k = pow(1+roughness,2)/8;
        float Gnl = NdotL/lerp(NdotL,1,k);
        float Gnv = NdotV/lerp(NdotV,1,k);
        return Gnl*Gnv;
}

float3 F_Function( float HdotL, float3 F0 )
{
    float Fre = exp2((-5.55473*HdotL-6.98316)*HdotL);
    return lerp(Fre,float3(1,1,1),F0);
}


half3 CalcDGF(half NDotL,half NDotV,half NDotH, half HDotL, half3 specular, half roughness, half3 sssLut){
    
    half3 DGF = D_Function(NDotH, roughness) * G_Function(NDotL, NDotV, roughness) * F_Function(HDotL, specular);
    half3 factor = max(sssLut * half3(4,4,4) * NDotV, half3( 0.0001, 0, 0)).xxx;
    
    return DGF / factor;
}




#endif
