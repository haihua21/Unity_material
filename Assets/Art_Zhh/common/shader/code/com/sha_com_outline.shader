Shader "code/common/Outline"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _Outline ("Outline", Range(0, 1)) = 0.1
        _OutlineColor ("Outline Color", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            //剔除正面   只看背面
            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float _Outline;
            float4 _OutlineColor;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex + normalize(v.vertex) * _Outline);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                return _OutlineColor;
            }

            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            sampler2D _MainTex;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                return tex2D(_MainTex, i.uv);
            }
            ENDCG
        }

    }
}
