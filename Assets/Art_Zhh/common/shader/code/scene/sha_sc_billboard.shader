Shader "code/sc/sha_sc_billboard"
{
    Properties
    {
        [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
        _AlphaClip("AlphaClip" ,Range(0,1)) = 0.1
    }
    SubShader
    {
	    Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" }
       
        // Tags { "RenderType"="Opaque" }
        
		Cull Back
		AlphaToMask Off
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
           
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"   

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
            //    UNITY_FOG_COORDS(1) 
                float4 vertex : SV_POSITION;
            };

             TEXTURE2D(_MainTex);

             CBUFFER_START(UnityPerMaterial) 
             SAMPLER(sampler_MainTex);
             half _AlphaClip;
             CBUFFER_END

            v2f vert (appdata v)
            {
                float3 centerOffset = float3(0, 0, 0);

                #ifdef _MULTIPLE
                centerOffset = v.tangent;
                #endif

                v.vertex.xyz -= centerOffset;

                float3 viewerLocal = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos, 1)); //将摄像机的坐标转换到物体模型空间
                float3 localDir = viewerLocal - centerOffset; //计算新的“forward”

                localDir.y = 0; //这里有两种方式，一种是仰面也要对齐，涉及XYZ面，另外一种就是只考虑XY面，即把y值置0。
                localDir = normalize(localDir); //归一化。

                float3  upLocal =  float3(0, 1, 0); //默认模型空间的up轴全部为（0,1,0）
                float3  rightLocal = normalize(cross(localDir, upLocal)); //计算新的right轴
                upLocal = cross(rightLocal, localDir); //计算新的up轴。

                float3  BBLocalPos = rightLocal * v.vertex.x + upLocal * v.vertex.y; //将原本的xy坐标以在新轴上计算，相当于一个线性变换【原模型空间】->【新模型空间】

                #ifdef _MULTIPLE
                BBLocalPos += centerOffset;
                #endif

                v2f o;  
                o.vertex = TransformObjectToHClip(BBLocalPos); //MVP变换
                o.uv = v.uv;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                clip(col.a - _AlphaClip); 
                // apply fog
                // UNITY_APPLY_FOG(i.fogCoord, col);
                return  half4(col);
            }
            ENDHLSL
        }
    }
}
