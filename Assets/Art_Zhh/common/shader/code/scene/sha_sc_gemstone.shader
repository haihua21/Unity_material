Shader "code/scene/gemstone"
{
    Properties
    {
        [NoScaleOffset]_NormalMap("NormalMap", 2D) = "bump" {}
        _NormalTile("Normal Tile", Float) = 1
        _NormalStrength("Normal Strength", Range(0, 2)) = 1 
        
        [NoScaleOffset]_Matcap_NormalMap("Matcap_NormalMap", 2D) = "bump" {}
        _Matcap_NormalTile("Matcap_Normal Tile", Float) = 1
        _MatcapNormalStrength("Matcap Normal Strength", Range(0, 2)) = 1 
        
        [NoScaleOffset]_SOMSMap("AO( R、alpha)", 2D) = "white" {}
        _Decal_AO("Decal_AO", Range( 0 , 1)) = 0.5
        _AO("AO", Range( 0 , 1)) = 0.5
        
        [NoScaleOffset]_CubeMap("CubeMap", CUBE) = "white" {}
        _CubeMapInt("CubeMapInt", Range( 0 , 5)) = 0
        _CubeMapBlue("CubeMapBlue", Range( 0 , 5)) = 3.422353
        
        [NoScaleOffset]_Matcap("Matcap", 2D) = "white" {}
        _MatcapColor("MatcapColor", Color) = (1,1,1,0)
        _MatcapInt("MatcapInt", Range( 0 , 5)) = 1
        _MatcapPower("MatcapPower", Range( 0 , 5)) = 1
        
        [NoScaleOffset]_LutMap("LutMap", 2D) = "white" {}
        _LutMapIntensity("LutMap Intensity", Range( 0.1 , 5)) = 1
        _LutMapPower("LutMap Power", Range( 0.1 , 2)) = 1
        _TileLut("Tile Lut", Range( 0 , 10)) = 0
        _LutMapColor("LutMap Color", Color) = (1,1,1,0)
        _ReflectSpeed("Reflect Speed", Float) = 1
        _FresnelPower("Fresnel Power", Range( 1 , 15)) = 15
        _FresnelBias("Fresnel Bias", Range( -0.1 , 0.1)) = -0.1
        _FresnelScale("Fresnel Scale", Range( 0 , 10)) = 1
        
        _Specular("Center Specular", Range( 0 , 1)) = 0.5


    }
    SubShader
    {
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        CBUFFER_START(UnityPerMaterial)
            float _NormalTile;
            float _NormalStrength; 
            
            float _Matcap_NormalTile;
            float _MatcapNormalStrength; 
            float _Decal_AO;
            float _AO;
            
            float _CubeMapInt;
            float _CubeMapBlue;
            
            float4 _MatcapColor;
            float _MatcapInt;
            float _MatcapPower;
            
            float _LutMapIntensity;
            float _LutMapPower;
            float _TileLut;
            
            float _ReflectSpeed;
            float4 _LutMapColor;
            float _FresnelBias;
            float _FresnelScale;
            float _FresnelPower;
            
            float _Specular;                 
        CBUFFER_END
        
        float4 _Lightmap_ST;
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_Lightmap);      
        SAMPLER(sampler_Lightmap); 
        TEXTURE2D(_LightmapInd);   
        SAMPLER(sampler_LightmapInd); 
        ENDHLSL
        
        Tags { 
            "RenderPipeline"="UniversalPipeline" 
            "RenderType"="Opaque" 
            "Queue"="Geometry" 
        }
        Cull Back
        

        Pass
        {
            Name "Forward"
            Tags { "LightMode"="UniversalForward" }
            Blend One Zero, One Zero
            ZWrite On
            ZTest LEqual
            Offset 0 , 0
            ColorMask RGBA
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
  
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            
    
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SOFT
            
  
            TEXTURE2D(_NormalMap);SAMPLER(sampler_NormalMap);
            TEXTURE2D(_Matcap_NormalMap);SAMPLER(sampler_Matcap_NormalMap);
            TEXTURE2D(_SOMSMap);SAMPLER(sampler_SOMSMap);
            TEXTURE2D(_LutMap);SAMPLER(sampler_LutMap);
            TEXTURE2D(_Matcap);SAMPLER(sampler_Matcap);
            samplerCUBE _CubeMap;
            
   
            struct a2v{
                float4 positionOS : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;   
                float4 tangent : TANGENT;
                float4 texcoord1 : TEXCOORD1;  
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
        
            struct v2f{
                float4 positionCS: SV_POSITION;
                float3 positionWS: TEXCOORD0;
                float4 uv: TEXCOORD1;          
                float3 normalWS: TEXCOORD2;   
                float3 tangentWS: TEXCOORD3;   
                float3 bitangentWS: TEXCOORD4;
                float3 viewDirWS: TEXCOORD5;  
                float2 lightmapUV : TEXCOORD6; 
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
           
            v2f vert(a2v i){
                v2f o;
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_TRANSFER_INSTANCE_ID(i, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
               
                VertexNormalInputs normalInputs = GetVertexNormalInputs(i.normal, i.tangent);
                o.normalWS = normalInputs.normalWS;
                o.tangentWS = normalInputs.tangentWS;
                o.bitangentWS = normalInputs.bitangentWS;
                
             
                float3 positionWS = TransformObjectToWorld(i.positionOS.xyz);
                o.positionWS = positionWS;
                o.positionCS = TransformWorldToHClip(positionWS);
                
                
                o.uv.xy = i.texcoord.xy;
                o.uv.zw = i.texcoord1.xy;
                o.viewDirWS = normalize(GetWorldSpaceViewDir(positionWS));
                
              
                o.lightmapUV = TRANSFORM_TEX(i.texcoord1.xy, _Lightmap);
                
                return o;
            }
            
         
            half4 frag(v2f i):SV_Target{
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);                
           
                float4 normalTXS = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv.xy * _NormalTile);
                float3 normalTS = UnpackNormal(normalTXS);
                normalTS.xy *= _NormalStrength;
                normalTS = normalize(normalTS);
                float3 normalWS = normalize(TransformTangentToWorld(normalTS, half3x3(i.tangentWS, i.bitangentWS, i.normalWS)));                
               
                float4 matcapNormalTXS = SAMPLE_TEXTURE2D(_Matcap_NormalMap, sampler_Matcap_NormalMap, i.uv.xy * _Matcap_NormalTile);
                float3 mapcapNormalTS = UnpackNormal(matcapNormalTXS);
                mapcapNormalTS.xy *= _MatcapNormalStrength;
                mapcapNormalTS = normalize(mapcapNormalTS);
                float3 matcapNormalWS = normalize(TransformTangentToWorld(mapcapNormalTS, half3x3(i.tangentWS, i.bitangentWS, i.normalWS)));                
            
                float3 tangentToViewDir = normalize(TransformWorldToViewDir(matcapNormalWS));
                float2 matcapUV = (tangentToViewDir * 0.5 + 0.5).xy;
                float4 matCap = pow(SAMPLE_TEXTURE2D(_Matcap, sampler_Matcap, matcapUV) * _MatcapColor * _MatcapInt, _MatcapPower);                
          
                float4 somsMap = SAMPLE_TEXTURE2D(_SOMSMap, sampler_SOMSMap, i.uv.xy);
                float albedoAO = lerp(1, somsMap.g, _Decal_AO);
                float AO = lerp(1, somsMap.g, _AO);                
         
                float3 worldViewDir = normalize(i.viewDirWS);
                float3 reflectWS = reflect(-worldViewDir, normalWS);
                float4 cubemap = (pow(AO, 3.0) * texCUBElod(_CubeMap, float4(reflectWS, _CubeMapBlue)) * _CubeMapInt);                
     
                float3 lutReflectWS = reflect(worldViewDir, matcapNormalWS);
                float3 nor = normalize(float3(lutReflectWS.x, lutReflectWS.y * -1.0, lutReflectWS.z));
                float2 lvtUV = (nor.xy * 0.5 + 0.5 + i.uv.zw * _TileLut) / _ReflectSpeed;
                float4 lutMap = pow(SAMPLE_TEXTURE2D(_LutMap, sampler_LutMap, lvtUV) * _LutMapIntensity * _LutMapColor, _LutMapPower);                
      
                float NdotV = dot(worldViewDir, normalWS);
                float fresnel = saturate(_FresnelBias + _FresnelScale * pow(max(1.0 - NdotV, 0.0001), _FresnelPower));                
     
                half4 bakedLight = 0;
                #if LIGHTMAP_ON
               
                    half4 lightmapDirect = SAMPLE_TEXTURE2D(_Lightmap, sampler_Lightmap, i.lightmapUV);
                    half4 lightmapIndirect = SAMPLE_TEXTURE2D(_LightmapInd, sampler_LightmapInd, i.lightmapUV);                    
                 
                    bakedLight.rgb = DecodeLightmap(lightmapDirect) + DecodeLightmap(lightmapIndirect);
                    bakedLight.a = 1;
                #else                    
                    Light lightData = GetMainLight();
                    bakedLight.rgb = lightData.color * saturate(dot(normalWS, lightData.direction));
                    bakedLight.a = 1;
                #endif
                
           
                float4 albedo = albedoAO * lutMap;                 
                float4 emission = (albedo * cubemap + matCap * albedoAO) * (1 + fresnel); 
                float4 finalColor = bakedLight * albedo + emission; 
                
                
                finalColor.rgb = clamp(finalColor.rgb, 0, 1);
                
                return half4(finalColor.rgb, 1);
            }
            ENDHLSL
        }        
        
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }

            ZWrite On
            ZTest LEqual
            AlphaToMask Off

            HLSLPROGRAM
            #pragma multi_compile_instancing
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 clipPos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            float3 _LightDirection;
            v2f vert( a2v v )
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
                o.worldPos = positionWS;
                float3 normalWS = TransformObjectToWorldDir(v.normal);
                float4 clipPos = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

                #if UNITY_REVERSED_Z
                    clipPos.z = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    clipPos.z = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
                #endif
                o.clipPos = clipPos;
                return o;
            }
            
            half4 frag(v2f IN) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);
                return 0;
            }
            ENDHLSL
        }
     }
    
     FallBack "Hidden/Universal Render Pipeline/FallbackError"
}