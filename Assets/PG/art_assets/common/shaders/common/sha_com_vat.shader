Shader "Unlit/VATShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _VATPosTex ("VAT Positions", 2D) = "white" {}
        _MatCapTex ("Mat Cap", 2D) = "white" {}
        _FrameCount ("Frame Count", Float) = 20
        _CurrentFrame ("Current Frame", Range(0 , 1)) = 0
        _Color("Color", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True" }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 matCapUv : TEXCOORD1;
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _VATPosTex;
            float4 _VATPosTex_TexelSize;
            sampler2D _MatCapTex;
            float _FrameCount;

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
                UNITY_DEFINE_INSTANCED_PROP(float, _CurrentFrame)
            UNITY_INSTANCING_BUFFER_END(Props)

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                float frameOffset = _VATPosTex_TexelSize.y * (_FrameCount - 1.0) * UNITY_ACCESS_INSTANCED_PROP(Props, _CurrentFrame);
                float4 posOffset = tex2Dlod(_VATPosTex, float4(v.uv2.x, v.uv2.y + frameOffset, 0, 0));
                o.vertex = UnityObjectToClipPos(v.vertex + posOffset);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                float3 worldNorm = normalize(unity_WorldToObject[0].xyz * v.normal.x + unity_WorldToObject[1].xyz * v.normal.y + unity_WorldToObject[2].xyz * v.normal.z);
                worldNorm = mul((float3x3)UNITY_MATRIX_V, worldNorm);
                o.matCapUv.xy = worldNorm.xy * 0.5 + 0.5;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                // sample the texture
                fixed4 tex = tex2D(_MainTex, i.uv);
                fixed4 mc = tex2D(_MatCapTex, i.matCapUv);
                return tex * UNITY_ACCESS_INSTANCED_PROP(Props, _Color) * mc;
            }
            ENDCG
        }
    }
}
