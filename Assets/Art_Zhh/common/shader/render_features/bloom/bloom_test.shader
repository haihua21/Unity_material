Shader "Unlit/Bloom_test"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Bloom ("Bloom", 2D) = "black" {}
        _LuminanceThreshold ("LuminanceThreshold", Float) = 0.5
        _BlurSize("Blur Size", Float) = 1.0
    }
    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"
        
        sampler2D _MainTex;
        float4 _MainTex_TexelSize;
        sampler2D _Bloom;
        float _LuminanceThreshold;
        float _BlurSize;


        
        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct v2f
        {
            float4 pos : SV_POSITION;
            float2 uv : TEXCOORD0;
        };

        //提取高亮区域的顶点着色器
        v2f vertExtractBright(appdata v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.uv;
            return o;
        }

        fixed luminance(fixed4 color)
        {
            return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
        }

        //根据_LuminanceThreshold值 提取高亮区域的片元着色器
        fixed4 fragExtractBright(v2f i) : SV_Target
        {
            fixed4 col = tex2D(_MainTex,i.uv);
            fixed val = clamp(luminance(col) - _LuminanceThreshold, 0.0, 1.0);
            //fixed val = saturate(luminance(col) - _LuminanceThreshold);
            
            return col * val;
        }


        struct v2fBloom
        {
            float4 pos : SV_POSITION;
            float4 uv : TEXCOORD0;
        };

        //混合亮部纹理核原纹理使用的顶点着色器
        v2fBloom vertBloom(appdata v)
        {
            v2fBloom o;

            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv.xy = v.uv;
            o.uv.zw = v.uv;

            //对坐标进行平台差异化处理
            #if UNITY_UV_STARTS_AT_TOP			
			if (_MainTex_TexelSize.y < 0.0)
				o.uv.w = 1.0 - o.uv.w;
			#endif
            
            return o;
        }
        
        //混合亮部纹理核原纹理使用的片元着色器
        fixed4 fragBloom(v2fBloom i) : SV_Target
        {
            fixed4 tex = tex2D(_MainTex,i.uv.xy);
            fixed4 bloomTex = tex2D(_Bloom,i.uv.zw);
            return tex + bloomTex;
        }
        
        ENDCG
        
        //后处理三件套
        ZTest Always
        Cull Off
        ZWrite Off
        
        //提取高亮区域
        Pass
        {
            CGPROGRAM
            #pragma vertex vertExtractBright
            #pragma fragment fragExtractBright
            ENDCG
        }
        //对高亮区域进行横向模糊
        UsePass "Unlit/GaussianBlur/GAUSSIAN_BLUR_VERTICAL"
        //对高亮区域进行纵向模糊
        UsePass "Unlit/GaussianBlur/GAUSSIAN_BLUR_HORIZONTAL"
        //模糊后的高亮纹理和原纹理混合
        Pass
        {
            CGPROGRAM
            #pragma vertex vertBloom
            #pragma fragment fragBloom
            ENDCG
        }
    }
}