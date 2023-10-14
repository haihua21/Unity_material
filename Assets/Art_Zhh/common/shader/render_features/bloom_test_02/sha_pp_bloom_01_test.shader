Shader "code/pp/bloom_test"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}        
        _Threshold("Threshold",Range(0, 1)) = 0.5		
        _Intensity("Intensity", Float) = 0.8
        _Scatter("Scatter", Float) = 1.0		
        _Radius("Radius", Float) = 1.0	
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
            float4 _MainTex_TexelSize;
           	float _Threshold;
            float _Intensity;
            float _Scatter;
            float _Radius;
			
			CBUFFER_END
			TEXTURE2D(_MainTex);           
			SAMPLER(sampler_MainTex);
            

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
                half4 d = _MainTex_TexelSize.xyxy * half4(-1,-1,1,1) * _Scatter;               
                half4 s = 0;
                s += SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv + d.xy);
                s += SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv + d.zy);
                s += SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv + d.xw);
                s += SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv + d.zw);
                s *= 0.25 ;
                s *= _baseColor ;

              // half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv)*_baseColor ;  // 采用屏幕                
                return s;
            }
            ENDHLSL
        }
    }
}
