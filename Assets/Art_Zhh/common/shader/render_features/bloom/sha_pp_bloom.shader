Shader "code/pp/bloom"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Pass
        {
            //Kawase Blur passid = 0
            HLSLPROGRAM
            #include "KawaseBlur.hlsl"
            #pragma vertex vertex
            #pragma fragment drawhighlights
            ENDHLSL
        }
        Pass
        {
            //Kawase Blur passid = 1
            HLSLPROGRAM
            #include "KawaseBlur.hlsl"
            #pragma vertex vertex
            #pragma fragment fragment
            ENDHLSL
        } 
        Pass
        {
          
            //Kawase Blur passid = 2
            HLSLPROGRAM
            #include "KawaseBlur.hlsl"
            #pragma vertex vertex
            #pragma fragment fragmentmerge
            ENDHLSL
        }        
        Pass
        {
            //Dual Blur 降采样 passid = 3
            HLSLPROGRAM
            #include "DualBlur.hlsl"
            #pragma vertex DualBlurDownVert
            #pragma fragment DualBlurDownFrag
            ENDHLSL
        }
        Pass
        {
            //Dual Blur 升采样 passid = 4
            HLSLPROGRAM
            #include "DualBlur.hlsl"
            #pragma vertex DualBlurUpVert
            #pragma fragment DualBlurUpFrag
            ENDHLSL
        }
        Pass
        {
            //Dual Blur 取高光 passid = 5
            HLSLPROGRAM
            #include "DualBlur.hlsl"
            #pragma vertex DualBlurDownVert
            #pragma fragment frag_PreFilter
            ENDHLSL
        }
        Pass
        {
            //Dual Blur 合并 passid = 6
            HLSLPROGRAM
            #include "DualBlur.hlsl"
            #pragma vertex DualBlurDownVert
            #pragma fragment fragmentmerge
            ENDHLSL
        }
        // Pass
        // {
        //     //Dual Blur 取高光 passid = 7
        //     HLSLPROGRAM
        //     #include "StandardBlur.hlsl"
        //     #pragma vertex FragBlurV
        //     #pragma fragment FragBlurV
        //     ENDHLSL
        // }
    }
}
