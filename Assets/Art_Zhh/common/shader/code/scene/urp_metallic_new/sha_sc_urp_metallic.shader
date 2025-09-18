Shader "code/scene/sc_urp_metallic"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1,1,1,0)
        _AlphaMap("ALpha Map R通道 ",2D)="white"{}

        _DetailNormalMap("Detail Normal Map", 2D) = "bump" {}
        _BlendNormalAmount ("Blend Normal Amount", Range(0, 1)) = 1

        [NoScaleOffset]_NMSMap("NMS Map", 2D) = "white" {}
        _Smoothness ("Smoothness", Range(0, 1))= 1
        _Metallic ("Metallic", Range(0, 1))= 1

        _AO ("AO", Range(0, 1))= 0
        _EmissionMap ("Emission Map", 2D) = "black" {}
        [HDR]_EmissionColor("Emission Color", Color) = (0,0,0,0)

        _Matcap ("Matcap", 2D) = "white" {}
        _MatcapColor("Matcap Color", Color) = (1,1,1,1)
        _MatcapIntensity ("Matcap Intensity", Range(0, 30)) = 0

        [Toggle(_DITHER_FADE_ON)]_DitherFadeOn("Dither Fade On", Float) = 0
        _DitherScale("Dither Scale", Float) = 1.5
        _DitherFadeAmount("Fade Amount", Range(0, 1)) = 0

        _DirtyMap ("Dirty Map", 2D) = "white" {}
        _DirtyColor ("Dirty Color", Color) = (1,1,1,1)
        _DirtyAmount ("Dirty Amount", Range(0, 1)) = 0

        _GI_ShadowIntensity ("GI Shadow Intensity", Range(0, 1)) = 0

//        [Toggle(_PLANAR_REFLECTION)] _Planar_Reflection("Planar Reflection", Float) = 0
//        _ReflectionAmount ("Reflection Amount", Range(0, 1)) = 0

        // Render Type
        [CustomEnumDrawer(CustomShaderEditor.RenderingType)] _RenderingType ("__RenderingType", float) = 0
        [UnityEngine.Rendering.BlendMode] _SrcBlend ("__SrcBlend", float) = 1
        [UnityEngine.Rendering.BlendMode] _DstBlend ("__DstBlend", float) = 0

        [CustomEnumDrawer(CustomShaderEditor.CustomBlendMode)] _CustomBlendMode ("__CustomBlendMode", float) = 0

        [Toggle(_ALPHATEST_ON)]_AlphaTest("Alpha Test", float)= 0
        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        [CustomShaderEditor.RenderFace] _Cull("__cull", Float) = 2.0
        [Toggle]_ZWrite ("__ZWrite", float) = 1
        _ZTest ("__ZTest", float) = 4

        [Toggle]
        _StencilEnable ("__StencilEnable", float) = 0
        _StencilID ("__StencilID", Range(0, 255)) = 0
        _StencilComp ("__StencilComp", float) = 0
        _StencilOp ("__StencilOp", float) = 0
        _StencilWriteMask ("__StencilWriteMask", Range(0, 255)) = 255
        _StencilReadMask ("__StencilReadMask", Range(0, 255)) = 255
        [CustomEnumDrawer(CustomShaderEditor.ColorMask)] _ColorMask ("ColorMask", float) = 15

        [Toggle(_RECEIVE_SHADOWS_OFF)]
        _ReceiveShadows ("Receive Shadows", float) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry"
        }
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Blend [_SrcBlend][_DstBlend]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
            Cull [_Cull]
            ColorMask [_ColorMask]

            Stencil
            {
                Ref [_StencilID]
                Comp [_StencilComp]
                Pass [_StencilOp]
                ReadMask [_StencilReadMask]
                WriteMask [_StencilWriteMask]
            }

            HLSLPROGRAM
            #pragma vertex PassVertexSimple
            #pragma fragment PassFragmentUrpMetallic

            // ------------------------------------- _ADDITIONAL_LIGHT
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHTS_SHADOWS
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            // #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _DETAIL_NORMAL_MAP
            // #pragma shader_feature_local _ _PLANAR_REFLECTION
            #pragma shader_feature_local_fragment _MATCAP
            #pragma shader_feature_local_fragment _DIRTY_MAP
            // #pragma shader_feature_local_fragment _DISTANCE_TRANSPARENCY

            #pragma multi_compile _ _DITHER_FADE_ON

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            //#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX
            //#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            //#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION

            #define _MAIN_LIGHT_SHADOWS_CASCADE 1

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            //#pragma multi_compile_fog

            // GPU Instancing
            #pragma multi_compile_instancing
            //#pragma multi_compile _ DOTS_INSTANCING_ON

            // -------------------------------------
            // Custom defined keywords
            #pragma shader_feature_fragment _DEBUG_MODE

            #include "urp_metallic_new_input.hlsl"
            #include "urp_metallic_new_pass.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            // -------------------------------------
            // Material Keywords
            // #pragma shader_feature_local_fragment _ALPHATEST_ON
            //#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "urp_metallic_new_input.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            // #pragma shader_feature_local_fragment _ALPHATEST_ON
            //#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #include "urp_metallic_new_input.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        // This pass is used when drawing to a _CameraNormalsTexture texture
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            //if we don't define _NORMALMAP, unity will enable EVALUATE_SH_VERTEX in Lighting.hlsl
            //#pragma shader_feature_local _NORMALMAP
            // #pragma shader_feature_local_fragment _ALPHATEST_ON
            //#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "urp_metallic_new_input.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"
            ENDHLSL
        }

        // This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            Cull Off

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaLit

            //#pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local_fragment _EMISSION
            //#pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            // #pragma shader_feature_local_fragment _ALPHATEST_ON
            //#pragma shader_feature_local_fragment _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            //#pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            //#pragma shader_feature_local_fragment _SPECGLOSSMAP

            #include "urp_metallic_new_input.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitMetaPass.hlsl"

            ENDHLSL
        }
    }


    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "CustomShaderEditor.SceneCommonShaderEditor"
}