Shader "code/test/boxblur"
{
    CGINCLUDE     //通用代码给下方调用
    #include "UnityCG.cginc"      

           
            sampler2D _MainTex;            
            float4 _MainTex_TexelSize;            
            float _BlurOffset;

            

            fixed4 frag_BoxFilter_4Tap (v2f_img i) : SV_Target   //命名调用
            {
               // half3 refraction = SAMPLE_TEXTURE2D(_CameraOpaqueTexture,sampler_CameraOpaqueTexture,ScreenUV.xy).rgb;  
                half4 d= _MainTex_TexelSize.xyxy * half4(-1,-1,1,1) * _BlurOffset;               
                half4 s = 0;
                s += tex2D(_MainTex,i.uv + d.xy);
                s += tex2D(_MainTex,i.uv + d.zy);
                s += tex2D(_MainTex,i.uv + d.xw);
                s += tex2D(_MainTex,i.uv + d.zw);
                s *= 0.25;                        
                return s;
            }

            
           

            fixed4 frag_BoxFilter_4Tap_bak (v2f_img i) : SV_Target   //命名调用
            {

                half4 d= _MainTex_TexelSize.xyxy * half4(-1,-1,1,1) * _BlurOffset;               
                half4 s = 0;
                s += tex2D(_MainTex,i.uv + d.xy);
                s += tex2D(_MainTex,i.uv + d.zy);
                s += tex2D(_MainTex,i.uv + d.xw);
                s += tex2D(_MainTex,i.uv + d.zw);
                s *= 0.25;                        
                return s;
            }

            fixed4 frag_BoxFilter_9Tap (v2f_img i) : SV_Target   //命名调用
            {

                half4 d= _MainTex_TexelSize.xyxy * half4(-1,-1,1,1) * _BlurOffset;               
                half4 s = 0;

                s = tex2D(_MainTex,i.uv);  //中心点

                s += tex2D(_MainTex,i.uv + d.xy);
                s += tex2D(_MainTex,i.uv + d.zy);
                s += tex2D(_MainTex,i.uv + d.xw);
                s += tex2D(_MainTex,i.uv + d.zw);

                s += tex2D(_MainTex,i.uv+ half2(0.0,d.w));
                s += tex2D(_MainTex,i.uv+ half2(0.0,d.y));
                s += tex2D(_MainTex,i.uv+ half2(0.0,d.z));
                s += tex2D(_MainTex,i.uv+ half2(0.0,d.x));


                s = s/9.0;                        
                return s;
            }
    ENDCG       //结束调用

    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurOffset("BlurOffset",float) = 1
    }
    SubShader
    {
        tags {
            
            "RenderType"="Transparent"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Transparent" 

            }
         
        cull off ZWrite off Ztest Always

       
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_BoxFilter_9Tap     //调用 frag_BoxFilter_4Tap      
      
            ENDCG
        }
       // Pass
       // {
       //      CGPROGRAM
       //      #pragma vertex vert_img
       //      #pragma fragment frag_BoxFilter_9Tap     //调用 frag_BoxFilter_4Tap       
       //   ENDCG
       // }
    }
}
