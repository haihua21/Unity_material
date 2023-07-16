Shader "Cus/LineStyle"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_lineStrength("lineStrength", Float) = 1.0
		_lineColor("lineColor", Color) = (0,0,0,0)
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
            #pragma multi_compile_fog

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
			float _lineStrength;
			float4 _lineColor;
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
                // sample the texture
				half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv);
				float grayscale  = col.r * 0.2126729f + col.g * 0.7151522f + col.b * 0.0721750f;
				float ddVal = (saturate(ddx(grayscale) + ddy(grayscale))*_lineStrength);
				half3 finalCol = _baseColor.rgb * (1.0 - ddVal) + _lineColor.rgb * ddVal;
                return half4(finalCol,1);
            }
            ENDHLSL
        }
    }
}
