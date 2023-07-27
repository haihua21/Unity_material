Shader "code/scene/urp_metallic"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1,1,1,0)

        [NoScaleOffset]_NormalMap("Normal Map", 2D) = "bump" {}

        _DetailNormalMap("Detail Normal Map", 2D) = "bump" {}
        _BlendNormalAmount ("Blend Normal Amount", Range(0, 1)) = 1
        _NormalScale ("Normal Scale", Range(-1, 5)) = 1

        [NoScaleOffset]_SOMMap("SOM Map", 2D) = "white" {}

        _Smoothness ("Smoothness", Range(0, 1))= 0.5
        _AO ("AO", Range(0, 1))= 0
        _Metallic ("Metallic", Range(0, 1))= 0

        _EmissionMap ("Emission Map", 2D) = "black" {}
        [HDR]_EmissionColor("Emission Color", Color) = (0,0,0,0)

        _Matcap ("Matcap", 2D) = "white" {}
        _MatcapColor("Matcap Color", Color) = (1,1,1,1)
        _MatcapIntensity ("Matcap Intensity", Range(0, 30)) = 0

        _DirtyMap ("Dirty Map", 2D) = "white" {}
        _DirtyColor ("Dirty Color", Color) = (1,1,1,1)
        _DirtyAmount ("Dirty Amount", Range(0, 1)) = 0

        [Space]

        //[Header(Specular Choose One)]
        //[Space]
        _SpecularIntensity ("Specular Intensity", Range(0, 50)) = 1
        [CustomEnumDrawer(CustomShaderEditor.SpecularAlgorithmSc)] _SpecularAlgorithm("Specular Algorithm", Float) = 0

        //[Header(Direct Lighting)]
        //[Space]
        [Toggle(_DIRECT_DIFFUSE)] _Direct_Diffuse("Direct Diffuse", Float) = 1
        [Toggle(_DIRECT_SPECULAR)] _Direct_Specular("Direct Specular", Float) = 1

        //[Header(GI)]
        //[Space]        
        [Toggle(_GI_DIFFUSE)] _GI_Diffuse("GI Diffuse", Float) = 1

        //[Space]
        [Toggle(_GI_SPECULAR)] _GI_Specular("GI Specular", Float) = 1


        _GI_ShadowIntensity ("GI Shadow Intensity", Range(0, 1)) = 0


//        [Toggle(_PLANAR_REFLECTION)] _Planar_Reflection("Planar Reflection", Float) = 0
//        _ReflectionAmount ("Reflection Amount", Range(0, 1)) = 0


        // Render Type
        [CustomEnumDrawer(CustomShaderEditor.RenderingType)] _RenderingType ("__RenderingType", float) = 0
        [UnityEngine.Rendering.BlendMode] _SrcBlend ("__SrcBlend", float) = 1
        [UnityEngine.Rendering.BlendMode] _DstBlend ("__DstBlend", float) = 0

        [CustomEnumDrawer(CustomShaderEditor.CustomBlendMode)] _CustomBlendMode ("__CustomBlendMode", float) = 0


        //        [Toggle(_ALPHATEST_ON)]_AlphaTest("Alpha Test", float)= 0
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


        Blend [_SrcBlend][_DstBlend]
        ZWrite [_ZWrite]
        ZTest [_ZTest]
        Cull [_Cull]

        Stencil
        {
            Ref [_StencilID]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }


        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            ColorMask [_ColorMask]

            HLSLPROGRAM
            #pragma vertex PassVertexSimple
            #pragma fragment PassFragmentUrpMetallic

            #define _MAIN_LIGHT_SHADOWS_CASCADE 1

            // GPU Instancing
            #pragma multi_compile_instancing

            // -------------------------------------
            // Material Keywords

            #define _NORMALMAP
            #pragma shader_feature_local _ _DETAIL_NORMAL_MAP
            // #pragma shader_feature_local _ _PLANAR_REFLECTION

            #define _BASEMAP
            #define _EMISSION
            #define _SOMMAP
            #pragma shader_feature_local_fragment _ _MATCAP

            #pragma shader_feature_local _DIRTY_MAP

            #pragma shader_feature_local_fragment _ _SPECULAR_BRDF
            #define _DIRECT_DIFFUSE
            #define _DIRECT_SPECULAR
            #define _GI_DIFFUSE
            #define _GI_SPECULAR

            // #pragma shader_feature_local_fragment _ALPHATEST_ON

            // #pragma shader_feature_local_fragment _DISTANCE_TRANSPARENCY


            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            //#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX
            //#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            //#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            //#pragma multi_compile _ SHADOWS_SHADOWMASK
            //#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION

            // -------------------------------------
            // Unity defined keywords
            //#pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON


            #include "input_urp_metallic.hlsl"
            #include "fragment_urp_metallic.hlsl"
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
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            // -------------------------------------
            // Material Keywords
            // #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "input_urp_metallic.hlsl"
            #include "Assets/Packages/LocalPackages/ShadowCasterPass.hlsl"
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
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            // #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #include "input_urp_metallic.hlsl"
            #include "Assets/Packages/LocalPackages/DepthOnlyPass.hlsl"
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
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            // #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "input_urp_metallic.hlsl"
            #include "Assets/Packages/LocalPackages/DepthNormalsPass.hlsl"
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
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMeta

            #pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            // #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED

            #pragma shader_feature_local_fragment _SPECGLOSSMAP

            #include "input_urp_metallic.hlsl"
            #include "Assets/Packages/LocalPackages/LitMetaPass.hlsl"
            ENDHLSL
        }

    }


    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "CustomShaderEditor.URP_MetallicShaderEditor"
}