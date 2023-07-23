Shader "ChuckLee/ARShadow"
{
	Properties
	{
		_ShadowColor("Shadow Color", Color) = (0.1, 0.1, 0.1, 0.53)
        _ShadowInt("阴影强度",Range(0,1))=1
	}
		SubShader
	{
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }

		Cull Back
		AlphaToMask Off
 
		Pass
		{
			Tags{ "LightMode"="UniversalForward"  }
            Blend One Zero, One Zero
            ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
          
 
			HLSLPROGRAM
		
		//	#pragma multi_compile_fwdbase

            #define _ALPHATEST_ON 1
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_FRAG_SHADOWCOORDS

            #pragma vertex vert
			#pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile_fragment _ _SHADOWS_SOFT
            
          //  #pragma multi_compile_fog
 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
 
			struct appdata
			{                
				float4 vertex : POSITION;
                float4 shadowCoord : TEXCOORD1;
             
			};

            CBUFFER_START(UnityPerMaterial)
            float4 _ShadowColor;
            float _ShadowInt;
            CBUFFER_END  

			struct v2f
			{
              
				float4 clipPos : SV_POSITION;	
                float fogCoord : TEXCOOR1;			
			};
 			 
			v2f vert(appdata v)
			{
				v2f o;
				o.clipPos = TransformObjectToHClip(v.vertex.xyz);    
                 
				o.fogCoord = ComputeFogFactor(v.vertex.z); 
				return o;
			}

            
			float4 frag(v2f i) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

                float4 ShadowCoords = float4( 0, 0, 0, 0 );

				Light atten = GetMainLight(ShadowCoords);
                float LightAtten = atten.distanceAttenuation * atten.shadowAttenuation;
                float AlphaClipThreshold = (LightAtten * 2.0);
                float Alpha = _ShadowInt;

              //  float AlphaClipThresholdShadow = 0.5;

              #ifdef _ALPHATEST_ON
		    	clip( Alpha - AlphaClipThreshold );
		      #endif

                float3 Color = MixFog(_ShadowColor, i.fogCoord );
                float4 aaa = (AlphaClipThreshold.r,AlphaClipThreshold.r,AlphaClipThreshold.r,AlphaClipThreshold.r);
			//	return half4(Color.rgb,Alpha);

            return aaa;




            
               
			}
			ENDHLSL
		}
	}
		FallBack "Diffuse"
}