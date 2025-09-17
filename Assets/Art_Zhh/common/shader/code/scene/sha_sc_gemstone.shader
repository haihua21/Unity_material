Shader "code/scene/gemstone"
{
    Properties
    {
        [NoScaleOffset]_NormalMap("NormalMap", 2D) = "bump" {}
        _NormalTile("Normal Tile", Float) = 1
        _NormalStrength("Normal Strength", Range(0, 2)) = 1 // 主法线强度
        
        [NoScaleOffset]_Matcap_NormalMap("Matcap_NormalMap", 2D) = "bump" {}
        _Matcap_NormalTile("Matcap_Normal Tile", Float) = 1
        _MatcapNormalStrength("Matcap Normal Strength", Range(0, 2)) = 1 // Matcap法线强度
        
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

        // 移除自定义缩放参数，使用Unity内置的光照贴图UV控制（在Mesh Renderer中设置）
    }
    SubShader
    {
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        CBUFFER_START(UnityPerMaterial)
            float _NormalTile;
            float _NormalStrength; // 主法线强度变量
            
            float _Matcap_NormalTile;
            float _MatcapNormalStrength; // Matcap法线强度变量
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
            // 新增：声明Unity内置光照贴图缩放偏移变量（_Lightmap_ST）
            float4 _Lightmap_ST;
        CBUFFER_END
        
        // 声明内置纹理采样器（含光照贴图）
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_Lightmap);      // 直接光照贴图（Unity烘焙后自动赋值）
        SAMPLER(sampler_Lightmap); // 直接光照贴图采样器
        TEXTURE2D(_LightmapInd);   // 间接光照贴图（GI，Unity自动赋值）
        SAMPLER(sampler_LightmapInd); // 间接光照贴图采样器
        ENDHLSL
        
        Tags { 
            "RenderPipeline"="UniversalPipeline" 
            "RenderType"="Opaque" 
            "Queue"="Geometry" 
        }
        Cull Back
        
        // 主渲染Pass（支持烘焙+实时）
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
            
            // 引入必要的光照库
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            
            // 烘焙相关编译指令（确保烘焙时启用光照贴图逻辑）
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SOFT
            
            // 原有纹理采样器声明
            TEXTURE2D(_NormalMap);SAMPLER(sampler_NormalMap);
            TEXTURE2D(_Matcap_NormalMap);SAMPLER(sampler_Matcap_NormalMap);
            TEXTURE2D(_SOMSMap);SAMPLER(sampler_SOMSMap);
            TEXTURE2D(_LutMap);SAMPLER(sampler_LutMap);
            TEXTURE2D(_Matcap);SAMPLER(sampler_Matcap);
            samplerCUBE _CubeMap;
            
            // 顶点输入结构（保留第二套UV用于光照贴图）
            struct a2v{
                float4 positionOS : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;   // 主纹理UV
                float4 tangent : TANGENT;
                float4 texcoord1 : TEXCOORD1;  // 光照贴图UV（烘焙用第二套UV，Unity自动分配）
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            // 顶点输出结构（新增光照贴图UV）
            struct v2f{
                float4 positionCS: SV_POSITION;
                float3 positionWS: TEXCOORD0;
                float4 uv: TEXCOORD1;          // 主纹理UV(xy) + 备用UV(zw)
                float3 normalWS: TEXCOORD2;    // 世界空间法线
                float3 tangentWS: TEXCOORD3;   // 世界空间切线
                float3 bitangentWS: TEXCOORD4; // 世界空间副切线
                float3 viewDirWS: TEXCOORD5;   // 世界空间视角方向
                float2 lightmapUV : TEXCOORD6; // 传递到片段的光照贴图UV（已处理缩放偏移）
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            // 顶点着色器（处理光照贴图UV传递）
            v2f vert(a2v i){
                v2f o;
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_TRANSFER_INSTANCE_ID(i, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                // 计算世界空间法线/切线/副切线
                VertexNormalInputs normalInputs = GetVertexNormalInputs(i.normal, i.tangent);
                o.normalWS = normalInputs.normalWS;
                o.tangentWS = normalInputs.tangentWS;
                o.bitangentWS = normalInputs.bitangentWS;
                
                // 计算世界空间位置和裁剪空间位置
                float3 positionWS = TransformObjectToWorld(i.positionOS.xyz);
                o.positionWS = positionWS;
                o.positionCS = TransformWorldToHClip(positionWS);
                
                // 传递主纹理UV和视角方向
                o.uv.xy = i.texcoord.xy;
                o.uv.zw = i.texcoord1.xy;
                o.viewDirWS = normalize(GetWorldSpaceViewDir(positionWS));
                
                // 修复：使用内置_Lightmap_ST处理光照贴图UV（TRANSFORM_TEX依赖此变量）
                o.lightmapUV = TRANSFORM_TEX(i.texcoord1.xy, _Lightmap);
                
                return o;
            }
            
            // 片段着色器（融合烘焙光照与宝石效果）
            half4 frag(v2f i):SV_Target{
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                // ==============================================
                // 1. 原有宝石效果计算（法线/Matcap/反射/AO/菲涅尔）
                // ==============================================
                // 主法线贴图处理
                float4 normalTXS = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv.xy * _NormalTile);
                float3 normalTS = UnpackNormal(normalTXS);
                normalTS.xy *= _NormalStrength;
                normalTS = normalize(normalTS);
                float3 normalWS = normalize(TransformTangentToWorld(normalTS, half3x3(i.tangentWS, i.bitangentWS, i.normalWS)));
                
                // Matcap法线贴图处理
                float4 matcapNormalTXS = SAMPLE_TEXTURE2D(_Matcap_NormalMap, sampler_Matcap_NormalMap, i.uv.xy * _Matcap_NormalTile);
                float3 mapcapNormalTS = UnpackNormal(matcapNormalTXS);
                mapcapNormalTS.xy *= _MatcapNormalStrength;
                mapcapNormalTS = normalize(mapcapNormalTS);
                float3 matcapNormalWS = normalize(TransformTangentToWorld(mapcapNormalTS, half3x3(i.tangentWS, i.bitangentWS, i.normalWS)));
                
                // Matcap采样
                float3 tangentToViewDir = normalize(TransformWorldToViewDir(matcapNormalWS));
                float2 matcapUV = (tangentToViewDir * 0.5 + 0.5).xy;
                float4 matCap = pow(SAMPLE_TEXTURE2D(_Matcap, sampler_Matcap, matcapUV) * _MatcapColor * _MatcapInt, _MatcapPower);
                
                // AO处理
                float4 somsMap = SAMPLE_TEXTURE2D(_SOMSMap, sampler_SOMSMap, i.uv.xy);
                float albedoAO = lerp(1, somsMap.g, _Decal_AO);
                float AO = lerp(1, somsMap.g, _AO);
                
                // 环境反射（CubeMap）
                float3 worldViewDir = normalize(i.viewDirWS);
                float3 reflectWS = reflect(-worldViewDir, normalWS);
                float4 cubemap = (pow(AO, 3.0) * texCUBElod(_CubeMap, float4(reflectWS, _CubeMapBlue)) * _CubeMapInt);
                
                // LUT贴图处理
                float3 lutReflectWS = reflect(worldViewDir, matcapNormalWS);
                float3 nor = normalize(float3(lutReflectWS.x, lutReflectWS.y * -1.0, lutReflectWS.z));
                float2 lvtUV = (nor.xy * 0.5 + 0.5 + i.uv.zw * _TileLut) / _ReflectSpeed;
                float4 lutMap = pow(SAMPLE_TEXTURE2D(_LutMap, sampler_LutMap, lvtUV) * _LutMapIntensity * _LutMapColor, _LutMapPower);
                
                // 菲涅尔效果
                float NdotV = dot(worldViewDir, normalWS);
                float fresnel = saturate(_FresnelBias + _FresnelScale * pow(max(1.0 - NdotV, 0.0001), _FresnelPower));
                
                // ==============================================
                // 2. 采样烘焙光照贴图（适配烘焙模式）
                // ==============================================
                half4 bakedLight = 0;
                #if LIGHTMAP_ON
                    // 采样直接+间接光照贴图（Unity烘焙后自动填充_Lightmap和_LightmapInd）
                    half4 lightmapDirect = SAMPLE_TEXTURE2D(_Lightmap, sampler_Lightmap, i.lightmapUV);
                    half4 lightmapIndirect = SAMPLE_TEXTURE2D(_LightmapInd, sampler_LightmapInd, i.lightmapUV);
                    
                    // 解码光照贴图（转换为线性空间颜色，Unity内置函数）
                    bakedLight.rgb = DecodeLightmap(lightmapDirect) + DecodeLightmap(lightmapIndirect);
                    bakedLight.a = 1;
                #else
                    // 非烘焙模式： fallback到实时光源
                    Light lightData = GetMainLight();
                    bakedLight.rgb = lightData.color * saturate(dot(normalWS, lightData.direction));
                    bakedLight.a = 1;
                #endif
                
                // ==============================================
                // 3. 最终颜色融合（烘焙光照+宝石特效）
                // ==============================================
                float4 albedo = albedoAO * lutMap;                  // 基础颜色（LUT+AO）
                float4 emission = (albedo * cubemap + matCap * albedoAO) * (1 + fresnel); // 自发光/反射
                float4 finalColor = bakedLight * albedo + emission; // 融合烘焙光照与特效
                
                
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