Shader "code/pp/distort"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex("Noise", 2D) = "black"{}	
        _DistortInt("DistortInt",Range(0, 1)) = 0.5		
        _DistortScale("DistortScale", Float) = 1.0	
        _DistortSpeed("DistortSpeed", Float) = 1.0				
		_baseColor("baseColor", Color) = (1,1,1,0)
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
            // make fog work
            // #pragma multi_compile_fog

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };
			CBUFFER_START(UnityPerMaterial)
			float4 _baseColor;
			float4 _MainTex_ST;
            float4 _NoiseTex_ST;
			float _DistortInt;
            float _DistortScale;
            float _DistortSpeed;
			
			CBUFFER_END
			TEXTURE2D(_MainTex);
            TEXTURE2D(_NoiseTex);
			SAMPLER(sampler_MainTex);
            SAMPLER(sampler_NoiseTex);

            v2f vert (appdata v)
            {
                v2f o;
				VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
				o.pos = vertexInput.positionCS;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // sample the texture
				// half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv);  // 采用屏幕
                half2 noiseuv = i.uv/_DistortScale;
                noiseuv += _Time.x *-_DistortSpeed;
                half4 noise =SAMPLE_TEXTURE2D(_NoiseTex,sampler_NoiseTex,noiseuv);
                half2 uv = saturate(i.uv + noise * _DistortInt*0.1);
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, uv)*_baseColor ;  // 采用屏幕                
                return col;
            }
            ENDHLSL
        }
    }
}
