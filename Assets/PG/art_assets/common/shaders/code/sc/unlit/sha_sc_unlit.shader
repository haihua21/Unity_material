Shader "code/scene/unlit"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        
        [NoScaleOffset]_NormalMap("Normal Map", 2D) = "bump" {}
        _NormalScale ("Normal Scale", Range(-5,5)) = 1
        
        _DirtyMap ("Dirty Map", 2D) = "white" {}
        _DirtyColor ("Dirty Color", Color) = (1,1,1,1)
        _DirtyAmount ("Dirty Amount", Range(0, 1)) = 0 
        
        _ReflectionMap ("Reflection Map", Cube) = "black" {} 
        [HDR]_ReflectionColor("Reflection Color", Color) = (1,1,1,1)
        _ReflectionAmount("Reflection Amount", Range( 0 , 1)) = 0.1
        
        [NoScaleOffset]_EmissionMap ("Emission Map", 2D) = "black" {}
        [HDR]_EmissionColor("Emission Color", Color) = (0,0,0,0)
        
                
        ///////////////////////////////////////////////
        //              BaseProperty                 //
        ///////////////////////////////////////////////
        
        // Render Type
        [CustomEnumDrawer(CustomShaderEditor.RenderingType)] _RenderingType ("__RenderingType", float) = 0
        [UnityEngine.Rendering.BlendMode] _SrcBlend ("__SrcBlend", float) = 1
        [UnityEngine.Rendering.BlendMode] _DstBlend ("__DstBlend", float) = 0
        
        [CustomEnumDrawer(CustomShaderEditor.CustomBlendMode)] _CustomBlendMode ("__CustomBlendMode", float) = 0
        
        
        [Toggle(_ALPHATEST_ON)]_AlphaTest("Alpha Test", float)= 0
        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        
        [ShaderEditor.RenderFace] _Cull("__cull", Float) = 2.0
        _ColorMask ("__ColorMask", float) = 15
        [Toggle]_ZWrite ("__ZWrite", float) = 1
        _ZTest ("__ZTest", float) = 4
        
        [Toggle]
        _StencilEnable ("__StencilEnable", float) = 0
        _StencilID ("__StencilID", Range(0, 255)) = 0
        _StencilComp ("__StencilComp", float) = 0
        _StencilOp ("__StencilOp", float) = 0
        _StencilWriteMask ("__StencilWriteMask", Range(0, 255)) = 255
        _StencilReadMask ("__StencilReadMask", Range(0, 255)) = 255
        
        [Toggle(_RECEIVE_SHADOWS_OFF)]
        _ReceiveShadows ("Receive Shadows", float) = 1
        
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 100
        
        
        Blend [_SrcBlend][_DstBlend]
        ZWrite [_ZWrite]
        ZTest [_ZTest]
        Cull [_Cull]
        
        Stencil{
            Ref [_StencilID]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma shader_feature_local _BASEMAP
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _REFLECTIONMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            
            #pragma shader_feature_local _DIRTY_MAP
            
            #pragma shader_feature_local_fragment _DISTANCE_TRANSPARENCY
            
            
            #pragma multi_compile_fog
            
            #pragma skip_variants FOG_EXP FOG_EXP2
            

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "../../lib/com_func/com_func_distance_transparency.hlsl"
            #include "input_unlit.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
                half3 normalOS : NORMAL;
                half4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
#if defined(_DIRTY_MAP)
                float4 uv : TEXCOORD0;
#else
                float2 uv : TEXCOORD0;
#endif
                
                float3 normalWS : TEXCOORD1;
                
#ifdef _NORMALMAP
                half3x4 TBN : TEXCOORD2;
#else
                float3 view_dirWS : TEXCOORD2;
#endif
            };

            v2f vert (appdata input)
            {
                v2f output;
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                half3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = vertexInput.positionCS;
                half3 view_dirWS = SafeNormalize( GetCameraPositionWS() - vertexInput.positionWS);
                
#ifdef _NORMALMAP
                half4 tangentWS = half4(normalInput.tangentWS, view_dirWS.x);
                half4 bitangentWS = half4(normalInput.bitangentWS, view_dirWS.y);
                half4 normalWS = half4(normalInput.normalWS, view_dirWS.z);
                output.TBN = half3x4(tangentWS, bitangentWS, normalWS);
                output.normalWS = normalInput.normalWS;
#else
                output.normalWS = NormalizeNormalPerVertex( normalInput.normalWS);
                output.view_dirWS = view_dirWS;
#endif

                output.uv.xy = TRANSFORM_TEX(input.uv, _BaseMap);

#if defined(_DIRTY_MAP)
                output.uv.zw = TRANSFORM_TEX(input.uv, _DirtyMap);
#endif
                return output;
            }

            half4 frag (v2f input) : SV_Target
            {
                float2 base_map_uv = input.uv;
                
                SurfaceData surfaceData;
                InitializeStandardLitSurfaceData(base_map_uv, surfaceData);

#ifdef _NORMALMAP
                half3 view_dirWS = half3(input.TBN[0].w, input.TBN[1].w, input.TBN[2].w);
                half3 tangentWS = input.TBN[0].xyz;
                half3 bitangentWS = input.TBN[1].xyz;
                half3 normalWS = input.TBN[2].xyz;
                //half3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, base_map_uv));
                normalWS = TransformTangentToWorld(surfaceData.normalTS, half3x3(tangentWS, bitangentWS, normalWS));
                normalWS = SafeNormalize(normalWS);
#else
                half3 view_dirWS = input.view_dirWS;
                half3 normalWS = NormalizeNormalPerPixel(input.normalWS);
#endif

                half3 base_color = surfaceData.albedo;
                half3 emission_color = surfaceData.emission;
                
#ifdef _REFLECTIONMAP
                float3 reflectionWS = reflect(-view_dirWS, normalWS);
                half3 reflection_color = SAMPLE_TEXTURECUBE(_ReflectionMap, sampler_ReflectionMap, reflectionWS).rgb * _ReflectionColor.rgb;
                half3 albedo_color = lerp(base_color, reflection_color, _ReflectionAmount);
#else
                half3 albedo_color = base_color;
#endif

                half4 finalColor;
                
                finalColor.rgb = albedo_color + emission_color.rgb;
                finalColor.a = surfaceData.alpha;
                
#if defined(_DISTANCE_TRANSPARENCY)
                finalColor.a *= DistanceTransparencyAlpha(input.positionCS);
#endif
                AlphaDiscard(finalColor.a, _Cutoff);
                return finalColor;
            }
            ENDHLSL
        }
        
                Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #include "input_unlit.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }
        
        Pass
                {
                    Name "Meta"
                    Tags{"LightMode" = "Meta"}
        
                    Cull Off
        
                    HLSLPROGRAM
                    #pragma only_renderers gles gles3 glcore d3d11
                    #pragma target 2.0
        
                    #pragma vertex UniversalVertexMeta
                    #pragma fragment UniversalFragmentMeta
        
                    #pragma shader_feature_local_fragment _SPECULAR_SETUP
                    #pragma shader_feature_local_fragment _EMISSION
                    #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
                    #pragma shader_feature_local_fragment _ALPHATEST_ON
                    #pragma shader_feature_local_fragment _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
                    #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
        
                    #pragma shader_feature_local_fragment _SPECGLOSSMAP
        
                    #include "input_unlit.hlsl"
                    #include "Packages/com.unity.render-pipelines.universal/Shaders/LitMetaPass.hlsl"
        
                    ENDHLSL
                }
        
        
    }
    
        FallBack "Hidden/Universal Render Pipeline/FallbackError"
        CustomEditor "CustomShaderEditor.UnlitShaderEditor"
}
