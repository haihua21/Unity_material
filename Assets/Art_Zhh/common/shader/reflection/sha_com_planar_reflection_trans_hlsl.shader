Shader "code/com/sha_com_planar_reflection_trans"
{
	Properties
	{
		_BaseColor("Base Color", Color) = (1,1,1,0)
		_Smoothness("Smoothness", Range( 0 , 1)) = 0.8
		[NoScaleOffset]_PlanarReflectionTexture("PlanarReflectionTexture", 2D) = "gray" {}
		_Alpha("Alpha", Range( 0 , 1)) = 0.8

	}
	SubShader
	{
		LOD 0		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" }

		Cull Back
		AlphaToMask Off	
		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }

			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite Off
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA			

			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			// #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"		

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;				

			};

			struct v2f
			{
				float4 clipPos : SV_POSITION;
				float4 texcoord3 : TEXCOORD3;
			};

			CBUFFER_START(UnityPerMaterial)
			     float4 _BaseColor;
			     float _Smoothness;
			     float _Alpha;

			CBUFFER_END

            TEXTURE2D(_PlanarReflectionTexture); 
            SAMPLER(sampler_PlanarReflectionTexture);       
			
			v2f VertexFunction ( appdata v  )
			{
				v2f o = (v2f)0;
				// UNITY_SETUP_INSTANCE_ID(v);
				// UNITY_TRANSFER_INSTANCE_ID(v, o);
				// UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(clipPos);
				o.texcoord3 = screenPos;	

				v.normal = v.normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				o.clipPos = positionCS;

				return o;
			}

			#if defined(TESSELLATION)
			struct v2f			
			v2f vert ( appdata v )
			{
				v2f o;
				// UNITY_SETUP_INSTANCE_ID(v);
				// UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.NORMAL = v.NORMAL;				
				return o;
			}
			#else
			v2f vert ( appdata v )
			{
				return VertexFunction(v);  //调用VertexFunction
			}
			#endif

			half4 frag ( v2f i) : SV_Target
			{
				// UNITY_SETUP_INSTANCE_ID( IN );
				// UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );	

				float4 screenPos = i.texcoord3;
				float4 ScreenPosNorm = screenPos / screenPos.w;	ScreenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ScreenPosNorm.z : ScreenPosNorm.z * 0.5 + 0.5;
				float2 appendUV = (float2(ScreenPosNorm.x , ScreenPosNorm.y));
				half4 PlanarRefTex = SAMPLE_TEXTURE2D( _PlanarReflectionTexture,sampler_PlanarReflectionTexture, appendUV ) * (_BaseColor +0.001) ;
				float4 lerpResult = lerp( _BaseColor , PlanarRefTex , saturate(( _Smoothness - 0.05 )));
							
				float Alpha = ( ( saturate( ( ( PlanarRefTex.r + PlanarRefTex.g + PlanarRefTex.b ) * 256.0 ) ) * _Alpha ) - 0.01 );
				
				float3 Color = lerpResult.rgb;	

				return half4( Color, Alpha );
			}
			ENDHLSL
		}	
	
	}
	
	CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
	Fallback "False"
	
}
