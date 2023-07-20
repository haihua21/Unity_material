Shader "code/fx/decals"
{
    Properties
    {
        _MainTex ("Base Map", 2D) = "black" {}        
        [HDR]_BaseColor ("Base Color", Color) = (1,1,1,1)
        [MaterialToggle(_Red_ON)] _USE_RED_CHANNEL ("Use Red Channel", float) = 0
        _BaseMapRotateSpeed("BaseMap Rotate Speed",float) = 0
        _MaskTex ("Mask Map",2D) = "black" {}
        [HDR]_MaskColor ("Mask Color", Color) = (1,1,1,1)  
        [MaterialToggle(_MaskRed_ON)] _USE_MaskRED_CHANNEL ("Use MaskRed Channel", float) = 0      
        _MRotateSpeed("MaskMap Rotate Speed",float) = 10          
        _smoothstepStart ("SmoothstepStart", Range(0,0.2)) = 0
        _smoothstepRange ("SmoothstepRange", Range(0.01,0.2)) = 0.1 
        
       	
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry+1"
            "RenderType" = "Transparent"
        }
        ZWrite off
        ZTest Always
        Cull Front
        
        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"      
	 
          
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_MaskTex);
        SAMPLER(sampler_MaskTex);  
       
        //
        float smoothStepMaskRange(float x, float start, float fade)
        {
            return  smoothstep(start, start + fade, x) * smoothstep(1, 1 - start -fade, x);
        }
        //
        ENDHLSL
    

        Pass
        {
            Name "decal" 
            Tags{"LightMode"="UniversalForward"}
            Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
            HLSLPROGRAM            

            #pragma vertex vert
            #pragma fragment frag      
            #pragma multi_compile _Red_OFF _Red_ON  
            #pragma multi_compile _MaskRed_OFF _MaskRed_ON     
           
           
           // #pragma multi_compile_instancing

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)        
			UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
            UNITY_DEFINE_INSTANCED_PROP(float4, _MaskColor)
            UNITY_DEFINE_INSTANCED_PROP(float, _BaseMapRotateSpeed)
            UNITY_DEFINE_INSTANCED_PROP(float, _MRotateSpeed)
			UNITY_DEFINE_INSTANCED_PROP(float, _smoothstepStart)
			UNITY_DEFINE_INSTANCED_PROP(float, _smoothstepRange)        
		    UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)                  

            //
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;           
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varings
            {
                float4 positionCS : SV_POSITION;
                float4 positionSS : TEXCOORD0;
                float2 uv : TEXCOORD1;

                #if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD2;
				#endif	

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
           
            

            Varings vert(Attributes IN)
            {
                Varings OUT;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
                VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                
                OUT.positionCS = positionInputs.positionCS;
                OUT.positionSS = ComputeScreenPos(OUT.positionCS);
                OUT.uv = IN.texcoord;               
                
                return OUT;
            }
            
            float4 frag(Varings IN):SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);              
             
                // UV 采样
                float2 texcoordSS = IN.positionSS.xy / IN.positionSS.w;
                float depth = SampleSceneDepth(texcoordSS);
                float3 positionWS = ComputeWorldSpacePosition(texcoordSS, depth, UNITY_MATRIX_I_VP);
                //
                float3 positionOS = TransformWorldToObject(positionWS);
                clip(0.5 - abs(positionOS));  
                float2 texcoordOS = positionOS.xz + 0.5;
               
                //  加入UV旋转
                float angle = _Time.xy * _BaseMapRotateSpeed;
                float angleMask = _Time.xy * _MRotateSpeed;
                texcoordOS -= float2(0.5,0.5);
                float2 texcoordOS_B = float2(texcoordOS.x*cos(angle)-texcoordOS.y*sin(angle),texcoordOS.y*cos(angle)+texcoordOS.x*sin(angle)); 
                float2 texcoordOS_M = float2(texcoordOS.x*cos(angleMask)-texcoordOS.y*sin(angleMask),texcoordOS.y*cos(angleMask)+texcoordOS.x*sin(angleMask));               
                texcoordOS_B += float2(0.5,0.5);                
                texcoordOS_M += float2(0.5,0.5);


                // 采用 _MainTex \ _maskMap
                float4 baseMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, texcoordOS_B);
                float4 maskMap = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, texcoordOS_M);              
                
               
                #if defined(_Red_ON)
                    baseMap = half4(baseMap.r, baseMap.r, baseMap.r, baseMap.r);
                #endif        

                #if defined(_MaskRed_ON)
                    maskMap = half4(maskMap.r, maskMap.r, maskMap.r, maskMap.r);
                #endif                  
                //
                positionOS += 0.5;
                float sStart = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _smoothstepStart); float sEnd = _smoothstepStart + UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _smoothstepRange);
                float smoothMask = smoothStepMaskRange(positionOS.x, sStart, sEnd) * smoothStepMaskRange(positionOS.y, sStart, sEnd) * smoothStepMaskRange(positionOS.z, sStart, sEnd);
                //           

                maskMap = float4(maskMap.xyz, maskMap.w *smoothMask * saturate( 1 - positionOS.y))*_MaskColor*1.5;             
                float4 finalColor = float4 (baseMap.xyz,baseMap.w * saturate( 1 - positionOS.y) * smoothMask)*_BaseColor*1.5;  



                 // finalColor = min(finalColor , maskMap);    //变暗
                 finalColor = max (finalColor , maskMap);    //变亮
                 // finalColor = saturate(finalColor * maskMap);   //正片叠底
                 //  finalColor = saturate(finalColor + maskMap - 1);   
                 // finalColor = finalColor / (1- maskMap);  
              
                return finalColor;           
            }
            ENDHLSL            
        }
    }
}