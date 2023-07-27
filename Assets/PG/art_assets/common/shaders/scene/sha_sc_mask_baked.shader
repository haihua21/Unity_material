Shader "scene/mask_baked"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _R_Color ("R_Color", Color) = (0,0,0,0)
        _G_Color ("G_Color", Color) = (0,0,0,0)
        _B_Color ("B_Color", Color) = (0,0,0,0)
        _A_Color ("A_Color", Color) = (0,0,0,0)
        
        [HDR]_EmissionColor ("Emission Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
                float2 lightmapUV   : TEXCOORD1;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
                float3 normalWS : TEXCOORD2;
                float fogFactor : TEXCOORD3;
            };
            
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                half4 _EmissionColor;
                
                half4 _R_Color;
                half4 _G_Color;
                half4 _B_Color;
                half4 _A_Color;
            CBUFFER_END

            v2f vert (appdata input)
            {
                v2f output;
                
                half3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(positionWS);
                output.fogFactor = ComputeFogFactor(output.positionCS.z);
                
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                
                OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                OUTPUT_SH(output.normalWS, output.vertexSH);
                
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                return output;
            }

            half4 frag (v2f input) : SV_Target
            {
                float3 lightDir = _MainLightPosition.xyz;
                
                half3 base_color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).rgb;
                
                half3 albedo_color = lerp(_A_Color.rgb, _B_Color.rgb, base_color.b);
                albedo_color = lerp(albedo_color, _G_Color.rgb, base_color.g);
                albedo_color = lerp(albedo_color, _R_Color.rgb, base_color.r);
                albedo_color *= _BaseColor.rgb;
            
                half4 final_color = half4(1,1,1,1);
                
                half3 bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, input.normalWS);
                Light mainLight = GetMainLight();
                MixRealtimeAndBakedGI(mainLight, input.normalWS, bakedGI, half4(0,0,0,0));
                
                final_color.rgb = albedo_color * bakedGI;
                
                final_color.rgb += _EmissionColor.rgb;
                final_color.rgb = MixFog( final_color.rgb, input.fogFactor);
                
                return final_color;
            }
            ENDHLSL
        }
    }
}
