Shader "code/pp/Bloom"
{
 Properties
 {
        _MainTex ("Texture", 2D) = "white" {}
    }

 SubShader
 {
 Tags
 {
 "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"
 }
 LOD 100

 Cull Off ZWrite Off ZTest Always

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

 CBUFFER_START(UnityPerMaterial)
 float4 _MainTex_ST;
 float4 _MainTex_TexelSize;
 float _Threshold;
 float4 _BloomColor;
 float _Intensity;
 float _ThresholdKnee;
 float4 _BlurOffset;
 float _bloomFactor;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_SourceTex);
        SAMPLER(sampler_SourceTex);

 struct appdata
 {
 float4 positionOS : POSITION;
 float2 texcoord : TEXCOORD0;
        };

 struct v2f
 {
 float2 uv : TEXCOORD0;
 float4 positionCS : SV_POSITION;
        };


 v2f vert(appdata v)
        {
 v2f o;
 VertexPositionInputs PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
 o.positionCS = PositionInputs.positionCS;
 o.uv = v.texcoord;

 return o;
        }

 half3 Sample(float2 uv)
        {
 return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv).rgb;
        }

 //核卷积模糊
 half3 SampleBox(float2 uv, float2 delta)
        {
 float4 o = 0;
 o = delta.xyxy * float4(-1.0, -1.0, 1.0, 1.0);
 half3 s = 0;
 s = Sample(uv + o.xy) + Sample(uv + o.zy) +
 Sample(uv + o.xw) + Sample(uv + o.zw);
 return s * 0.25f;
        }

 // 提取亮部信息
 half3 PreFilter(half3 color)
        {
 half brightness = Max3(color.r, color.g, color.b);//得到rgb最大值
 
 half softness = clamp(brightness - _Threshold + _ThresholdKnee, 0.0, 2.0 * _ThresholdKnee);
 softness = (softness * softness) / (4.0 * _ThresholdKnee + 1e-4);
 half multiplier = max(brightness - _Threshold, softness) / max(brightness, 1e-4);
 
 color *= multiplier;//相乘后得到阈值
 color = max(color, 0);
 return color;
        }
 ENDHLSL


 // PASS0：拿阈值
 pass
 {
 HLSLPROGRAM
            #pragma vertex vert
 #pragma fragment PreFilterfrag
 half4 PreFilterfrag(v2f i) : SV_Target
            {
 //return  half4(PreFilter(SampleBox(i.uv,_BlurOffset)),1);
 half3 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
 return half4(PreFilter(tex), 1);
            }
 ENDHLSL
 }

 // Pass1：模糊，在脚本里配合后效果做降采样
 pass
 {
 HLSLPROGRAM
            #pragma vertex vert
 #pragma fragment BoxBlurfrag
 half4 BoxBlurfrag(v2f i) : SV_Target
            {
 half4 col = half4(SampleBox(i.uv, _BlurOffset).rgb, 1);

 return col;
            }
 ENDHLSL
 }

 // Pass2：模糊并叠加，在脚本里配合后效果做升采样
 pass
 {
 blend one one // 加法（Bloom发光的关键！）
 //blend OneMinusDstColor one // 软加法

 HLSLPROGRAM
            #pragma vertex vert
 #pragma fragment AddBlurfrag
 half4 AddBlurfrag(v2f i) : SV_Target
            {
 half4 col = half4(SampleBox(i.uv, _BlurOffset).rgb, 1);
 return col;
            }
 ENDHLSL
 }

 // Pass3：合并两张图
 pass
 {
 HLSLPROGRAM
            #pragma vertex vert
 #pragma fragment Mergefrag
 half4 Mergefrag(v2f i) : SV_Target
            {
 half4 soure = SAMPLE_TEXTURE2D(_SourceTex, sampler_SourceTex, i.uv);
 half4 blur = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _BloomColor * _Intensity;
 half4 final = soure + blur;
 return final;
            }
 ENDHLSL
 }

 Pass
 {
 // Pass4 :  debug
 HLSLPROGRAM
            #pragma vertex vert
 #pragma fragment FragmentProgram

 half4 FragmentProgram(v2f i) : SV_Target
            {
 half4 blue = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
 return blue * _Intensity * _BloomColor;
            }
 ENDHLSL
 }

    }

}