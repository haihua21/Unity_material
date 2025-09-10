Shader "Code/HairPBR_Transparent"
{
    Properties
    {
        [Header(Base Properties)]
        _BaseMap("Base Map", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1,1,1,0.8)
        _BaseAlpha("Alpha Strength", Range(0, 1)) = 1.0
        _NormalMap("Normal Map", 2D) = "bump" {}
        _NormalStrength("Normal Strength", Range(0, 3)) = 1
        _Smoothness("Smoothness", Range(0, 1)) = 0.5

        [Header(Hair Effects)]
        _ShiftMap("Shift Map (G-Ch)", 2D) = "white" {}
        _ShiftMapTilingU("Shift Map Tiling U", Range(0.1, 5)) = 3
        _Jitter("Jitter", Range(0, 2)) = 0.5
        _GeneralShift("General Shift", Range(-2, 2)) = 0.8
        _BackStrength("Back Face Strength", Range(0, 0.8)) = 0.2

        [Header(Transparency)]
        _Transparency("Transparency", Range(0, 1)) = 0.5
        _TransparencyFalloff("Transparency Falloff", Range(0.1, 5)) = 2.0
        _ThicknessMap("Thickness Map", 2D) = "gray" {}
        _ThicknessScale("Thickness Scale", Range(0.1, 3)) = 1.0

        [Header(Lighting)]
        _Highlight1Color("Highlight 1 Color", Color) = (0.349, 0.349, 0.349, 1)
        _Highlight1Power("Highlight 1 Power", Range(0, 1000)) = 100
        _Highlight1Strength("Highlight 1 Strength", Range(0, 1)) = 1
        _Highlight2Color("Highlight 2 Color", Color) = (0.502, 0.502, 0.502, 1)
        _Highlight2Power("Highlight 2 Power", Range(0, 1000)) = 100
        _Highlight2Strength("Highlight 2 Strength", Range(0, 1)) = 1
        _RimColor("Rim Color", Color) = (0.502, 0.502, 0.502, 1)
        _RimEdge("Rim Edge", Range(2, 10)) = 5
        _RimStrength("Rim Strength", Range(0, 1)) = 1
        _EdgeGradient("Edge Gradient", Range(0.1, 5)) = 1

        [Header(Render Control)]
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("Cull Mode", Float) = 0

        [HideInInspector]_texcoord("", 2D) = "white" {}
        [HideInInspector]_ReceiveShadows("Receive Shadows", Float) = 1.0
    }

    SubShader
    {
        LOD 100
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjector"="True" }

        Cull [_CullMode]
        ZWrite Off
        ZTest LEqual
        Blend SrcAlpha OneMinusSrcAlpha
        Offset 0, -1

        HLSLINCLUDE
        #pragma target 3.5
        #pragma prefer_hlslcc gles

        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float4 _BaseColor;
            float _BaseAlpha;
            float4 _NormalMap_ST;
            float4 _ThicknessMap_ST;
            float4 _Highlight1Color;
            float4 _Highlight2Color;
            float4 _RimColor;
            float _Smoothness;
            float _NormalStrength;
            float _BackStrength;
            float _RimStrength;
            float _RimEdge;
            float _Highlight2Strength;
            float _Highlight2Power;
            float _Highlight1Strength;
            float _Highlight1Power;
            float _GeneralShift;
            float _ShiftMapTilingU;
            float _Jitter;
            float _EdgeGradient;
            float _Transparency;
            float _TransparencyFalloff;
            float _ThicknessScale;
        CBUFFER_END

        sampler2D _BaseMap;
        sampler2D _NormalMap;
        sampler2D _ShiftMap;
        sampler2D _ThicknessMap;

        inline float3 CalculateHairAnisotropy(float3 viewDir, float3 lightDir, float3 tangent, float3 bitangent, float3 normal, float shift)
        {
            float3 halfDir = SafeNormalize(viewDir + lightDir);
            float3x3 worldToTangent = float3x3(tangent, bitangent, normal);
            float3 tangentNormal = SafeNormalize(mul(worldToTangent, normal));

            float3 shiftedBitangent1 = SafeNormalize(bitangent + tangentNormal * (shift + 0.1));
            float dot1 = dot(halfDir, shiftedBitangent1);
            float smooth1 = smoothstep(-1.0, 0.0, dot1);
            float spec1 = smooth1 * pow(sqrt(1.0 - dot1*dot1), _Highlight1Power) * _Highlight1Strength;

            float3 shiftedBitangent2 = SafeNormalize(bitangent + tangentNormal * (shift + 0.05));
            float dot2 = dot(halfDir, shiftedBitangent2);
            float smooth2 = smoothstep(-1.0, 0.0, dot2);
            float spec2 = smooth2 * pow(sqrt(1.0 - dot2*dot2), _Highlight2Power) * _Highlight2Strength;

            return spec1 * _Highlight1Color.rgb + spec2 * _Highlight2Color.rgb;
        }

        inline float3 CalculateHairRim(float3 normal, float3 viewDir, float3 lightDir)
        {
            float fresnelLight = pow(1.0 - saturate(dot(normal, lightDir)), _EdgeGradient);
            float fresnelView = pow(1.0 - saturate(dot(normal, viewDir)), _RimEdge);
            return (1.0 - fresnelLight) * fresnelView * _RimColor.rgb * _RimStrength;
        }

        struct HairVertexInput
        {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float4 tangent : TANGENT;
            float2 texcoord : TEXCOORD0;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct HairVertexOutput
        {
            float4 clipPos : SV_POSITION;
            float2 uvBase : TEXCOORD0;
            float2 uvNormal : TEXCOORD1;
            float2 uvShift : TEXCOORD2;
            float2 uvThickness : TEXCOORD3;
            float4 tSpace0 : TEXCOORD4;
            float4 tSpace1 : TEXCOORD5;
            float4 tSpace2 : TEXCOORD6;
            float4 screenPos : TEXCOORD7;
            half4 fogFactor : TEXCOORD8;
            float3 worldPos : TEXCOORD9;
            UNITY_VERTEX_INPUT_INSTANCE_ID
            UNITY_VERTEX_OUTPUT_STEREO
        };

        HairVertexOutput HairVert(HairVertexInput v)
        {
            HairVertexOutput o;
            UNITY_SETUP_INSTANCE_ID(v);
            UNITY_TRANSFER_INSTANCE_ID(v, o);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

            float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
            o.worldPos = worldPos;
            
            VertexNormalInputs normalInput = GetVertexNormalInputs(v.normal, v.tangent);
            o.tSpace0 = float4(normalInput.tangentWS, worldPos.x);
            o.tSpace1 = float4(normalInput.bitangentWS, worldPos.y);
            o.tSpace2 = float4(normalInput.normalWS, worldPos.z);

            o.uvBase = TRANSFORM_TEX(v.texcoord, _BaseMap);
            o.uvNormal = TRANSFORM_TEX(v.texcoord, _NormalMap);
            o.uvShift = v.texcoord * float2(_ShiftMapTilingU, 1.0) + _BaseMap_ST.zw;
            o.uvThickness = TRANSFORM_TEX(v.texcoord, _ThicknessMap);

            o.clipPos = TransformWorldToHClip(worldPos);
            o.screenPos = ComputeScreenPos(o.clipPos);
            o.fogFactor.x = ComputeFogFactor(o.clipPos.z);
            o.fogFactor.yzw = VertexLighting(worldPos, normalInput.normalWS);

            return o;
        }
        ENDHLSL

        Pass
        {
            Name "Forward"
            Tags { "LightMode"="UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            ZTest LEqual
            ColorMask RGBA

            HLSLPROGRAM
            #pragma vertex HairVert
            #pragma fragment frag

            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF

            half4 frag(HairVertexOutput IN, bool isFrontFace : SV_IsFrontFace) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

                float3 worldPos = IN.worldPos;
                float3 worldTangent = normalize(IN.tSpace0.xyz);
                float3 worldBitangent = normalize(IN.tSpace1.xyz);
                float3 worldNormal = normalize(IN.tSpace2.xyz);
                float3 viewDirWS = SafeNormalize(_WorldSpaceCameraPos - worldPos);
                Light mainLight = GetMainLight(TransformWorldToShadowCoord(worldPos));

                // Sample base color texture with alpha control
                float4 baseTex = tex2D(_BaseMap, IN.uvBase);
                float3 baseColor = baseTex.rgb * _BaseColor.rgb;
                float baseAlpha = baseTex.a * _BaseColor.a * _BaseAlpha;

                // Sample normal map
                float3 normalTex = UnpackNormalScale(tex2D(_NormalMap, IN.uvNormal), _NormalStrength);
                float3 tangentNormal = TransformTangentToWorld(normalTex, float3x3(worldTangent, worldBitangent, worldNormal));
                tangentNormal = NormalizeNormalPerPixel(tangentNormal);

                // Calculate hair shift
                float shiftValue = tex2D(_ShiftMap, IN.uvShift).g;
                shiftValue = lerp(0.5 - _Jitter, 0.5 + _Jitter, shiftValue);
                shiftValue = (shiftValue + _Jitter * 0.5) - _GeneralShift;

                // Calculate hair thickness
                float thickness = tex2D(_ThicknessMap, IN.uvThickness).r * _ThicknessScale;

                // Calculate highlights and rim lighting
                float3 anisotropy = CalculateHairAnisotropy(viewDirWS, mainLight.direction, worldTangent, worldBitangent, tangentNormal, shiftValue);
                float3 rimLight = CalculateHairRim(tangentNormal, viewDirWS, mainLight.direction);

                // Combine colors
                float3 finalColor = baseColor + anisotropy + rimLight;
                finalColor = lerp(finalColor * _BackStrength, finalColor, isFrontFace);

                // Calculate transparency based on angle and thickness
                float viewDotNormal = saturate(dot(viewDirWS, tangentNormal));
                float angleBasedTransparency = pow(viewDotNormal, _TransparencyFalloff);
                float thicknessBasedTransparency = saturate(1.0 - thickness * 0.5);
                
                // Combine transparency factors
                float alpha = baseAlpha * 
                             lerp(1.0, _Transparency, angleBasedTransparency) *
                             thicknessBasedTransparency;

                // Prepare PBR input data
                InputData inputData;
                ZERO_INITIALIZE(InputData, inputData);
                
                inputData.positionWS = worldPos;
                inputData.viewDirectionWS = viewDirWS;
                inputData.normalWS = tangentNormal;
                inputData.fogCoord = IN.fogFactor.x;
                inputData.vertexLighting = IN.fogFactor.yzw;
                inputData.bakedGI = SAMPLE_GI(IN.uvBase, SampleSH(tangentNormal), tangentNormal);
                inputData.shadowMask = 1.0;

                // Calculate PBR color
                half4 pbrColor = UniversalFragmentPBR(
                    inputData,
                    finalColor,
                    0.0,
                    0.5,
                    lerp(0.8, _Smoothness, isFrontFace),
                    1.0,
                    0.0,
                    alpha
                );

                // Apply fog and set final alpha
                pbrColor.rgb = MixFog(pbrColor.rgb, IN.fogFactor.x);
                pbrColor.a = alpha;

                return pbrColor;
            }
            ENDHLSL
        }

        Pass
        {
            Name "ReceiveShadows"
            Tags { "LightMode"="ReceiveShadows" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            ZTest LEqual

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing

            struct VertexInput
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexOutput
            {
                float4 clipPos : SV_POSITION;
                float2 uvBase : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.clipPos = TransformWorldToHClip(o.worldPos);
                o.uvBase = TRANSFORM_TEX(v.texcoord, _BaseMap);
                
                return o;
            }

            half4 frag(VertexOutput IN) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                
                float4 baseTex = tex2D(_BaseMap, IN.uvBase);
                float alpha = baseTex.a * _BaseColor.a * _BaseAlpha * (1.0 - _Transparency);
                
                return half4(0, 0, 0, alpha);
            }
            ENDHLSL
        }
    }
    
    CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
    Fallback "Hidden/InternalErrorShader"
}
    