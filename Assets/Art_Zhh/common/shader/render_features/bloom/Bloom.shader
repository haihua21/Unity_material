Shader "Unlit/Bloom"
{
    Properties
    {
        _MainTex("输入的渲染纹理", 2D) = "white" {}
        _Bloom("高斯模糊后的较亮区域", 2D) = "black" {}
        _Threshold("用于提取较亮区域的阈值", Float) = 0.5
        _BlurSize("用于控制不同迭代之间的高斯模糊的模糊区域范围", Float) = 1.0
    }

    SubShader
    {
        CGINCLUDE

        #include "UnityCG.cginc"

        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        sampler2D _Bloom;
        float _Threshold;
        float _BlurSize;

        struct v2f
        {
            float4 pos : SV_POSITION;
            half2 uv : TEXCOORD0;
        };

        // 顶点着色器
        v2f vertExtractBright(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;


            return o;
        }

        // 将传入的颜色转换为亮度
        fixed luminance(fixed4 color)
        {
            return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
        }

        // 片元着色器
        fixed4 fragExtractBright(v2f i) : SV_Target
        {
            fixed4 c = tex2D(_MainTex, i.uv);
            fixed val = clamp(luminance(c) - _Threshold, 0.0, 1.0);

            return c * val;
        }

        struct v2fBloom
        {
            float4 pos : SV_POSITION;
            half4 uv : TEXCOORD0;
        };

        // 混合高斯模糊后的光亮区域纹理与原纹理的顶点着色器
        v2fBloom vertBloom(appdata_img v)
        {
            v2fBloom o;

            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv.xy = v.texcoord;
            o.uv.zw = v.texcoord;

            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0.0)
            {
                o.uv.w = 1.0 - o.uv.w;
            }
            #endif

            return o;
        }

        // 混合高斯模糊后的光亮区域纹理与原纹理的片元着色器
        fixed4 fragBloom(v2fBloom i) : SV_Target
        {
            return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);
        }

        ENDCG

        ZTest Always Cull Off ZWrite Off

        Pass        // Pass0 提取光亮区域
        {
            CGPROGRAM 

            #pragma vertex vertExtractBright        // 指定该Pass的顶点着色器
            #pragma fragment fragExtractBright      // 指定该Pass的片元着色器

            ENDCG
        }

        UsePass "Unlit/GaussianBlur/GAUSSIAN_BLUR_VERTICAL"     // Pass1 对纹理进行纵向的高斯模糊的处理

        UsePass "Unlit/GaussianBlur/GAUSSIAN_BLUR_HORIZONTAL"   // Pass2 对纹理进行横向的高斯模糊的处理 

        Pass        // Pass3 将进行过高斯模糊的光亮区域与原纹理混合
        {
            CGPROGRAM

            #pragma vertex vertBloom        // 指定该Pass的顶点着色器
            #pragma fragment fragBloom      // 指定该Pass的片元着色器

            ENDCG
        }
    }
    FallBack Off
}