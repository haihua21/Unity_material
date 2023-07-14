Shader "code/fx/decals"
{
    Properties
    {
        _MainTex ("Base Map", 2D) = "black" {}        
        [HDR]_BaseColor ("Base Color", Color) = (1,1,1,1)
        [MaterialToggle(_Red_ON)] _USE_RED_CHANNEL ("Use Red Channel", float) = 0
        [MaterialToggle(_Gradient_ON)] _Gradient_CHANNEL ("Gradient Channel", float) = 0
         _Power("Power", Range(1,2)) = 1	
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
           //shadow
           // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
           // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
           // #pragma multi_compile _ _ADDITIONAL_LIGHTS
           // #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
           // #pragma multi_compile _ _SHADOWS_SOFT    
            #pragma multi_compile _Red_OFF _Red_ON     
            #pragma multi_compile _Gradient_OFF _Gradient_ON
           
           // #pragma multi_compile_instancing

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)        
			UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
			UNITY_DEFINE_INSTANCED_PROP(float, _smoothstepStart)
			UNITY_DEFINE_INSTANCED_PROP(float, _smoothstepRange)        
		    UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
            UNITY_DEFINE_INSTANCED_PROP(float, _Power)           

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
             
                //

                float2 texcoordSS = IN.positionSS.xy / IN.positionSS.w;
                float depth = SampleSceneDepth(texcoordSS);
                float3 positionWS = ComputeWorldSpacePosition(texcoordSS, depth, UNITY_MATRIX_I_VP);
                //
                float3 positionOS = TransformWorldToObject(positionWS);
                clip(0.5 - abs(positionOS));   //<========
                float2 texcoordOS = positionOS.xz + 0.5;
                float4 baseMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, texcoordOS);
               
                #if defined(_Red_ON)
                    baseMap = half4(baseMap.r, baseMap.r, baseMap.r, baseMap.r);
                #endif               

                //
                float4 mainShadowCoord = TransformWorldToShadowCoord(positionWS);
            	Light mainLight = GetMainLight(mainShadowCoord);
            	float mainAtten = mainLight.shadowAttenuation * mainLight.distanceAttenuation;
                //
                float3 additionalAtten = 0;
                #ifdef _ADDITIONAL_LIGHTS
                int additionalLightCount = GetAdditionalLightsCount();
                for(int i = 0; i < additionalLightCount; i++)
                {
                    Light additionalLight = GetAdditionalLight(0, positionWS, float4(1, 1, 1, 1));
				    additionalAtten += additionalLight.shadowAttenuation * additionalLight.distanceAttenuation * additionalLight.color;
                }
                #endif
             
                //
                positionOS += 0.5;
                float sStart = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _smoothstepStart); float sEnd = _smoothstepStart + UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _smoothstepRange);
                float smoothMask = smoothStepMaskRange(positionOS.x, sStart, sEnd) * smoothStepMaskRange(positionOS.y, sStart, sEnd) * smoothStepMaskRange(positionOS.z, sStart, sEnd);
                //
                float4 finalColor = (float4(baseMap.xyz * min(1, mainAtten + 0.5) + additionalAtten, baseMap.w * smoothMask) * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor))* 1.5;
                
                #if defined(_Gradient_ON)               
                float finalColor_A = finalColor.w * saturate( 1 - positionOS.y * _Power);
                finalColor = float4 (finalColor.xyz,finalColor_A);               
                #endif

                return finalColor;            
               
            }
            ENDHLSL            
        }
    }
}