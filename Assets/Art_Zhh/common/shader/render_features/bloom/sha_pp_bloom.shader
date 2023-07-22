Shader "Unlit/sha_pp_bloom"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Threshold("Intensity ",float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag        
          
            #include "UnityCG.cginc"

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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Threshold;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);               
                return o;
            }

            fixed luminance(fixed4 color)
            {
            return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                //
                float br = max(max(col.r,col.g),col.b);
                br = max (0.0f, (br - _Threshold)) / max(br,0.0001f);
              //  col.rgb *= br;   
                
             //   float br =max(col.r,max(col.g,col.b));
             //   float contribution = max(0.0f,br - _Threshold);
             //   contribution /= max(br,0.00001f);
                float val = clamp(luminance(col) - _Threshold, 0.0, 1.0);
                  
               col.rgb *= val;  
              
                return col;
            }
            ENDCG
        }
    }
}
