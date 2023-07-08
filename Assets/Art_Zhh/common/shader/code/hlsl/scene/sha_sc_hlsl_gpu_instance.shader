Shader "code/scene/sha_sc_hlsl_gpu_instance"
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
            #pragma multi_compile_fog             // add fog
            #pragma multi_compile_instancing            // GPU Instance   01

            // #include "UnityCG.cginc"           CG 改 HLSL
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"   
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

            


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID        // GPU Instance   02
             
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
           //  UNITY_FOG_COORDS(1)      CG 改 HLSL
                float fogCoord : TEXCOOR1;
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID      // GPU Instance   02
            };



           CBUFFER_START(UnityPerMaterial)     //  开启 SRP Batcher    
           float4 _MainTex_ST;      
           float4 _BaseColor; 
           CBUFFER_END
           sampler2D _MainTex;

            UNITY_INSTANCING_BUFFER_START(Props)                // GPU Instance   01

      //    UNITY_DEFINE_INSTANCED_PROP(half4, _BaseColor)     // 注意，添加需要实例化的属性后，就不需要再次声明_BaseColor的变量类型了，否则会报错为重复定义

            UNITY_INSTANCING_BUFFER_END(Props)                  // GPU Instance   01          

        
            v2f vert (appdata v)
            {
                
            UNITY_SETUP_INSTANCE_ID(v);     // GPU Instance   03         仅当您要访问片元着色器中的实例化属性时才需要。      

            v2f o;

            UNITY_TRANSFER_INSTANCE_ID(v,o);    // GPU Instance   04            

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
                UNITY_SETUP_INSTANCE_ID(i);     // GPU Instance   05   仅当要在片元着色器中访问任何实例化属性时才需要。 
                 
                // sample the texture
                half4 col = tex2D(_MainTex, i.uv) * _BaseColor ;
                // apply fog
          //   UNITY_APPLY_FOG(i.fogCoord, col);       CG 改 HLSL
                col.rgb = MixFog(col,i.fogCoord);
                return col;
            }
            ENDHLSL
        }
    }
}
