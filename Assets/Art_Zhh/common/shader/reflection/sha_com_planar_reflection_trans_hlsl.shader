Shader "code/com/sha_com_planar_reflection_trans"
{
	Properties
	{
		_BaseColor("Base Color", Color) = (1,1,1,0)
		_Smoothness("Smoothness", Range( 0 , 1)) = 0.8
		[NoScaleOffset]_PlanarReflectionTexture("PlanarReflectionTexture", 2D) = "gray" {}
		_Alpha("Alpha", Range( 0 , 1)) = 0.8
		_Scatter("Scatter",Range(0,5)) = 1.0

	}
	SubShader
	{
		LOD 0		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" }

		Pass
		{			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
		    Cull Back	
			ZWrite Off
			ZTest LEqual		

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
				 float _Scatter;
				 float4 _PlanarReflectionTexture_TexelSize;

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
				// half4 PlanarRefTex = SAMPLE_TEXTURE2D( _PlanarReflectionTexture,sampler_PlanarReflectionTexture, appendUV ) * (_BaseColor +0.001) ;

				half4 PRefTex_test = SAMPLE_TEXTURE2D( _PlanarReflectionTexture,sampler_PlanarReflectionTexture, appendUV );
                float Alpha_A = (saturate(ceil( PRefTex_test.r + PRefTex_test.g + PRefTex_test.b)) - 0.01 );
				
                half4 d = _PlanarReflectionTexture_TexelSize.xyxy * half4(-1,-1,1,1) * _Scatter;               
                half4 PlanarRefTex = 0;
				PlanarRefTex += SAMPLE_TEXTURE2D( _PlanarReflectionTexture,sampler_PlanarReflectionTexture, appendUV +d.xy);
				PlanarRefTex += SAMPLE_TEXTURE2D( _PlanarReflectionTexture,sampler_PlanarReflectionTexture, appendUV +d.zy);
				PlanarRefTex += SAMPLE_TEXTURE2D( _PlanarReflectionTexture,sampler_PlanarReflectionTexture, appendUV +d.xw);
				PlanarRefTex += SAMPLE_TEXTURE2D( _PlanarReflectionTexture,sampler_PlanarReflectionTexture, appendUV +d.zw);

				PlanarRefTex *= 0.25 *(_BaseColor+0.01);

				float4 lerpResult = lerp( _BaseColor , PlanarRefTex ,  _Smoothness - 0.05);
							
				// float Alpha = ( ( saturate( ( ( PlanarRefTex.r + PlanarRefTex.g + PlanarRefTex.b ) *128 ) ) * _Alpha ) - 0.01 );
                float Alpha_B = ( saturate(( PlanarRefTex.r + PlanarRefTex.g + PlanarRefTex.b) ) - 0.01 );
				float Alpha = saturate(Alpha_A + Alpha_B);
				Alpha = lerp(0,Alpha,_Alpha);

				return half4( lerpResult.rgb, Alpha );
			}
			ENDHLSL
		}	
	
	}
	
	CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
	Fallback "False"
	
}
