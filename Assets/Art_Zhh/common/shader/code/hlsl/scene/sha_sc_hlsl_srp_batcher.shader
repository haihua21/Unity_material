Shader "code/scene/sha_sc_hlsl_srp_batcher"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor ("Base Color",Color) = (1,1,1,0)
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

            // #include "UnityCG.cginc"           CG 改 HLSL
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"   
           

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
             
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
           //  UNITY_FOG_COORDS(1)      CG 改 HLSL
                float fogCoord : TEXCOOR1;
                float4 vertex : SV_POSITION;
            };



         CBUFFER_START(UnityPerMaterial)     //  开启 SRP Batcher    
           float4 _MainTex_ST;
           float4 _BaseColor;
         CBUFFER_END
           sampler2D _MainTex;
           

         

            v2f vert (appdata v)
            {
                

                v2f o;
            //  o.vertex = UnityObjectToClipPos(v.vertex);        CG 改 HLSL
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
            //  UNITY_TRANSFER_FOG(o,o.vertex);                   CG 改 HLSL
                o.fogCoord = ComputeFogFactor(o.vertex.z); 
                return o;
            }

           

         // fixed4 frag (v2f i) : SV_Target     CG 改 HLSL
            half4 frag (v2f i) : SV_Target
            {
                

                // sample the texture
                half4 col = tex2D(_MainTex, i.uv) * _BaseColor ;
                // apply fog
          //   UNITY_APPLY_FOG(i.fogCoord, col);       CG 改 HLSL
                col.rgb = MixFog (col,i.fogCoord);
                return col;
            }
            ENDHLSL
        }
    }
}
