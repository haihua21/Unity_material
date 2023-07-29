// Made with Amplify Shader Editor v1.9.1.5
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "ase/scene/sha_sc_water"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin]_ShallowColor("ShallowColor（水岸线颜色）", Color) = (0.2191527,0.5507062,0.764151,0)
		_DeepColor("Deep Color（水底颜色）", Color) = (0.08971161,0.3932571,0.6603774,0)
		_DeepRange_1("Deep Range（水底水岸线范围）", Float) = 1
		_EdgeAlpha("EdgeAlpha（岸边透明度）", Range( -5 , -0.1)) = -0.1
		_FresnelColor("FresnelColor（远处颜色）", Color) = (0.5275899,0.7256795,0.8962264,0)
		_Fogstart("Fogstart (远处雾起始位置)", Float) = 20
		_FogEnd("FogEnd (远处雾结束位置)", Float) = 200
		[NoScaleOffset]_NormalMap("NormalMap （水波纹贴图）", 2D) = "bump" {}
		_NormalScale("NormalScale（波纹大小）", Vector) = (5,5,0,0)
		_NormalSpeed("NormalSpeed（波纹速度）", Vector) = (1,1,0,0)
		_NormalMapIntensity("NormalMap Intensity（波纹强度）", Range( 0.1 , 3)) = 1
		[HDR]_WaterSprayColor("Water Spray Color （水波纹颜色）", Color) = (0.1409754,0.5660378,0.5199202,0)
		_Specular("Specular (水面高光强度)", Range( 0 , 0.99)) = 0.8
		_SpecularStep("Specular（高光块状）", Range( 0 , 1)) = 0
		_UnderWaterDistort("UnderWaterDistort（水底扭曲幅度）", Float) = 1
		[NoScaleOffset]_CausticsMap("Caustics Map (水底焦散贴图)", 2D) = "white" {}
		_CausticsRange("Caustics Range (焦散范围)", Float) = 1
		_CausticsScale("Caustics Scale (焦散大小)", Float) = 6
		_CausticsIntensity("Caustics Intensity (水底焦散强度)", Float) = 1
		_ShoreIntensity("Shore Intensity（泡沫强度）", Range( 0.01 , 1)) = 0.5
		_ShoreDissolve("Shore Dissolve (泡沫溶解)", Range( 0.1 , 1)) = 0.4
		[NoScaleOffset]_FoamNoiseMap("Foam Noise Map (岸边涟漪溶解贴图)", 2D) = "white" {}
		_FoamRange("Foam Range （岸边涟漪范围）", Range( 0 , 5)) = 1
		_FoamFrequency("Foam Frequency（涟漪频率）", Float) = 10
		_FoamSpeed("Foam Speed（岸边涟漪速度）", Float) = 1
		_FoamBlend("Foam Blend （岸边涟漪过渡）", Range( 0 , 1)) = 1
		_NoiseMapTile1("Noise Map Tile（涟漪贴图大小）", Range( 2 , 15)) = 2
		_FoamIntensity("Foam Intensity（岸边涟漪强度）", Range( 0 , 1)) = 0.5
		[ASEEnd]_FoamDissolve("FoamDissolve（岸边涟漪溶解）", Range( 0 , 1)) = 0.21


		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" }

		Cull Back
		AlphaToMask Off

		

		HLSLINCLUDE
		#pragma target 3.5
		#pragma prefer_hlslcc gles
		// ensure rendering platforms toggle list is visible

		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}

		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS
		ENDHLSL

		
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

			#define _SURFACE_TYPE_TRANSPARENT 1
			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 101001
			#define REQUIRE_OPAQUE_TEXTURE 1
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_VERT_NORMAL


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef ASE_FOG
					float fogFactor : TEXCOORD2;
				#endif
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				float4 ase_texcoord6 : TEXCOORD6;
				float4 ase_texcoord7 : TEXCOORD7;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _FresnelColor;
			float4 _DeepColor;
			float4 _ShallowColor;
			float4 _WaterSprayColor;
			float2 _NormalScale;
			float2 _NormalSpeed;
			float _SpecularStep;
			float _ShoreIntensity;
			float _ShoreDissolve;
			float _FoamDissolve;
			float _NoiseMapTile1;
			float _FoamSpeed;
			float _FoamFrequency;
			float _FoamIntensity;
			float _FoamRange;
			float _EdgeAlpha;
			float _Specular;
			float _CausticsRange;
			float _CausticsIntensity;
			float _CausticsScale;
			float _Fogstart;
			float _FogEnd;
			float _DeepRange_1;
			float _UnderWaterDistort;
			float _FoamBlend;
			float _NormalMapIntensity;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _NormalMap;
			uniform float4 _CameraDepthTexture_TexelSize;
			sampler2D _CausticsMap;
			sampler2D _FoamNoiseMap;


			inline float4 ASE_ComputeGrabScreenPos( float4 pos )
			{
				#if UNITY_UV_STARTS_AT_TOP
				float scale = -1.0;
				#else
				float scale = 1.0;
				#endif
				float4 o = pos;
				o.y = pos.w * 0.5f;
				o.y = ( pos.y - o.y ) * _ProjectionParams.x * scale + o.y;
				return o;
			}
			
			float2 UnStereo( float2 UV )
			{
				#if UNITY_SINGLE_PASS_STEREO
				float4 scaleOffset = unity_StereoScaleOffset[ unity_StereoEyeIndex ];
				UV.xy = (UV.xy - scaleOffset.zw) / scaleOffset.xy;
				#endif
				return UV;
			}
			
			float3 InvertDepthDirURP75_g21( float3 In )
			{
				float3 result = In;
				#if !defined(ASE_SRP_VERSION) || ASE_SRP_VERSION <= 70301 || ASE_SRP_VERSION == 70503 || ASE_SRP_VERSION == 70600 || ASE_SRP_VERSION == 70700 || ASE_SRP_VERSION == 70701 || ASE_SRP_VERSION >= 80301
				result *= float3(1,1,-1);
				#endif
				return result;
			}
			

			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord3 = screenPos;
				float3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord5.xyz = ase_worldTangent;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord6.xyz = ase_worldNormal;
				float ase_vertexTangentSign = v.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord7.xyz = ase_worldBitangent;
				
				o.ase_texcoord4 = v.vertex;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord5.w = 0;
				o.ase_texcoord6.w = 0;
				o.ase_texcoord7.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				#ifdef ASE_FOG
					o.fogFactor = ComputeFogFactor( positionCS.z );
				#endif

				o.clipPos = positionCS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_tangent = v.ase_tangent;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float4 screenPos = IN.ase_texcoord3;
				float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( screenPos );
				float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
				float2 scrPos297 = (ase_grabScreenPosNorm).xy;
				float2 break269 = (WorldPosition).xz;
				float2 appendResult272 = (float2(( break269.x / _NormalScale.x ) , ( break269.y / _NormalScale.y )));
				float2 WorldSpaceTile398 = appendResult272;
				float2 NormalSpeed630 = _NormalSpeed;
				float2 temp_output_56_0 = ( NormalSpeed630 * _TimeParameters.x * 0.01 );
				float2 temp_output_54_0 = ( WorldSpaceTile398 + temp_output_56_0 );
				float2 temp_output_68_0 = ( ( WorldSpaceTile398 * 2.0 ) + ( temp_output_56_0 * -0.4 ) );
				float2 UnderWaterNormal268 = (BlendNormal( UnpackNormalScale( tex2D( _NormalMap, temp_output_54_0 ), 1.0f ) , UnpackNormalScale( tex2D( _NormalMap, temp_output_68_0 ), 1.0f ) )).xy;
				float2 uvOffset283 = ( UnderWaterNormal268 * _UnderWaterDistort * 0.01 );
				float4 unityObjectToClipPos312 = TransformWorldToHClip(TransformObjectToWorld(IN.ase_texcoord4.xyz));
				float4 computeScreenPos313 = ComputeScreenPos( unityObjectToClipPos312 );
				float SurfaceDepth281 = (computeScreenPos313).w;
				float eyeDepth277 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( float4( ( scrPos297 + uvOffset283 ), 0.0 , 0.0 ).xy ),_ZBufferParams);
				float offsetPosDepth278 = eyeDepth277;
				float4 fetchOpaqueVal90 = float4( SHADERGRAPH_SAMPLE_SCENE_COLOR( ( scrPos297 + ( uvOffset283 * step( SurfaceDepth281 , offsetPosDepth278 ) ) ) ), 1.0 );
				float3 UnderWaterColor96 = (fetchOpaqueVal90).rgb;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth373 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth373 = abs( ( screenDepth373 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _DeepRange_1 ) );
				float WaterDepth14 = distanceDepth373;
				float4 lerpResult30 = lerp( _DeepColor , _ShallowColor , exp( -WaterDepth14 ));
				float temp_output_11_0_g20 = _FogEnd;
				float clampResult1_g20 = clamp( ( ( temp_output_11_0_g20 - distance( WorldPosition , _WorldSpaceCameraPos ) ) / ( temp_output_11_0_g20 - _Fogstart ) ) , 0.0 , 1.0 );
				float LinearFogMask369 = clampResult1_g20;
				float4 lerpResult31 = lerp( _FresnelColor , lerpResult30 , LinearFogMask369);
				float4 WaterColor25 = lerpResult31;
				float2 UV22_g22 = ase_screenPosNorm.xy;
				float2 localUnStereo22_g22 = UnStereo( UV22_g22 );
				float2 break64_g21 = localUnStereo22_g22;
				float clampDepth69_g21 = SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy );
				#ifdef UNITY_REVERSED_Z
				float staticSwitch38_g21 = ( 1.0 - clampDepth69_g21 );
				#else
				float staticSwitch38_g21 = clampDepth69_g21;
				#endif
				float3 appendResult39_g21 = (float3(break64_g21.x , break64_g21.y , staticSwitch38_g21));
				float4 appendResult42_g21 = (float4((appendResult39_g21*2.0 + -1.0) , 1.0));
				float4 temp_output_43_0_g21 = mul( unity_CameraInvProjection, appendResult42_g21 );
				float3 temp_output_46_0_g21 = ( (temp_output_43_0_g21).xyz / (temp_output_43_0_g21).w );
				float3 In75_g21 = temp_output_46_0_g21;
				float3 localInvertDepthDirURP75_g21 = InvertDepthDirURP75_g21( In75_g21 );
				float4 appendResult49_g21 = (float4(localInvertDepthDirURP75_g21 , 1.0));
				float3 PositionFormDepth10 = (mul( unity_CameraToWorld, appendResult49_g21 )).xyz;
				float2 temp_output_106_0 = ( (PositionFormDepth10).xz / _CausticsScale );
				float2 temp_output_110_0 = ( NormalSpeed630 * _TimeParameters.x * 0.02 );
				float clampResult123 = clamp( exp( ( -WaterDepth14 / _CausticsRange ) ) , 0.0 , 1.0 );
				float4 CausticsColor115 = ( min( tex2D( _CausticsMap, ( temp_output_106_0 + temp_output_110_0 ) ) , tex2D( _CausticsMap, ( -temp_output_106_0 + temp_output_110_0 ) ) ) * _CausticsIntensity * clampResult123 );
				float clampResult38 = clamp( ( -WaterDepth14 / _EdgeAlpha ) , 0.0 , 1.0 );
				float Alpha35 = saturate( min( (lerpResult31).a , clampResult38 ) );
				float4 lerpResult99 = lerp( float4( UnderWaterColor96 , 0.0 ) , ( WaterColor25 + CausticsColor115 ) , Alpha35);
				float clampResult161 = clamp( ( WaterDepth14 / _FoamRange ) , 0.0 , 1.0 );
				float smoothstepResult171 = smoothstep( _FoamBlend , 1.0 , ( clampResult161 + 0.1 ));
				float2 NoiseMapTile604 = ( UnderWaterNormal268 / _NoiseMapTile1 );
				float Shore612 = ( ( 1.0 - smoothstepResult171 ) * _FoamIntensity * step( 0.0 , ( ( sin( ( ( ( 1.0 - clampResult161 ) * _FoamFrequency ) + ( _FoamSpeed * _TimeParameters.x ) ) ) * tex2D( _FoamNoiseMap, NoiseMapTile604 ).r ) - _FoamDissolve ) ) );
				float temp_output_582_0 = ( tex2D( _FoamNoiseMap, NoiseMapTile604 ).r - _ShoreDissolve );
				float Foam599 = ( step( 0.0 , temp_output_582_0 ) * ( _ShoreIntensity - 0.05 ) );
				float temp_output_29_0_g23 = _Specular;
				float temp_output_9_0_g23 = ( 1.0 - temp_output_29_0_g23 );
				float temp_output_15_0_g23 = ( temp_output_9_0_g23 * temp_output_9_0_g23 );
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 normalizeResult4_g24 = normalize( ( ase_worldViewDir + _MainLightPosition.xyz ) );
				float3 unpack60 = UnpackNormalScale( tex2D( _NormalMap, temp_output_54_0 ), _NormalMapIntensity );
				unpack60.z = lerp( 1, unpack60.z, saturate(_NormalMapIntensity) );
				float3 unpack62 = UnpackNormalScale( tex2D( _NormalMap, temp_output_68_0 ), _NormalMapIntensity );
				unpack62.z = lerp( 1, unpack62.z, saturate(_NormalMapIntensity) );
				float3 SurfaceNormal_TS61 = BlendNormal( unpack60 , unpack62 );
				float3 ase_worldTangent = IN.ase_texcoord5.xyz;
				float3 ase_worldNormal = IN.ase_texcoord6.xyz;
				float3 ase_worldBitangent = IN.ase_texcoord7.xyz;
				float3 tanToWorld0 = float3( ase_worldTangent.x, ase_worldBitangent.x, ase_worldNormal.x );
				float3 tanToWorld1 = float3( ase_worldTangent.y, ase_worldBitangent.y, ase_worldNormal.y );
				float3 tanToWorld2 = float3( ase_worldTangent.z, ase_worldBitangent.z, ase_worldNormal.z );
				float3 tanNormal330 = SurfaceNormal_TS61;
				float3 worldNormal330 = normalize( float3(dot(tanToWorld0,tanNormal330), dot(tanToWorld1,tanNormal330), dot(tanToWorld2,tanNormal330)) );
				float3 normalizeResult419 = normalize( worldNormal330 );
				float3 SurfaceNormal_WS331 = normalizeResult419;
				float dotResult17_g23 = dot( normalizeResult4_g24 , SurfaceNormal_WS331 );
				float temp_output_13_0_g23 = ( ( ( temp_output_15_0_g23 - 1.0 ) * ( dotResult17_g23 * dotResult17_g23 ) ) + 1.0 );
				float temp_output_18_0_g23 = ( 1.0 - temp_output_29_0_g23 );
				float temp_output_20_0_g23 = ( temp_output_18_0_g23 * temp_output_18_0_g23 );
				float3 normalizeResult4_g25 = normalize( ( ase_worldViewDir + _MainLightPosition.xyz ) );
				float dotResult23_g23 = dot( normalizeResult4_g25 , ase_worldNormal );
				float temp_output_11_0_g23 = ( ( ( temp_output_20_0_g23 - 1.0 ) * ( dotResult23_g23 * dotResult23_g23 ) ) + 1.0 );
				float smoothstepResult632 = smoothstep( _SpecularStep , 1.0 , ( ( temp_output_15_0_g23 / ( ( temp_output_13_0_g23 * temp_output_13_0_g23 ) * 3.142 ) ) * saturate( ( temp_output_20_0_g23 / ( ( temp_output_11_0_g23 * temp_output_11_0_g23 ) * 128.0 ) ) ) ));
				float Specule346 = smoothstepResult632;
				float4 FoamShore188 = ( _WaterSprayColor * ( saturate( max( Shore612 , Foam599 ) ) + Specule346 ) );
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = max( ( lerpResult99 + FoamShore188 ) , float4( 0,0,0,0 ) ).rgb;
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
				#endif

				return half4( Color, Alpha );
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0
			AlphaToMask Off

			HLSLPROGRAM

			#define _SURFACE_TYPE_TRANSPARENT 1
			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 101001


			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _FresnelColor;
			float4 _DeepColor;
			float4 _ShallowColor;
			float4 _WaterSprayColor;
			float2 _NormalScale;
			float2 _NormalSpeed;
			float _SpecularStep;
			float _ShoreIntensity;
			float _ShoreDissolve;
			float _FoamDissolve;
			float _NoiseMapTile1;
			float _FoamSpeed;
			float _FoamFrequency;
			float _FoamIntensity;
			float _FoamRange;
			float _EdgeAlpha;
			float _Specular;
			float _CausticsRange;
			float _CausticsIntensity;
			float _CausticsScale;
			float _Fogstart;
			float _FogEnd;
			float _DeepRange_1;
			float _UnderWaterDistort;
			float _FoamBlend;
			float _NormalMapIntensity;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			

			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				o.clipPos = TransformWorldToHClip( positionWS );
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = o.clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				

				float Alpha = 1;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}
			ENDHLSL
		}

	
	}
	
	CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
	Fallback "Hidden/InternalErrorShader"
	
}
/*ASEBEGIN
Version=19105
Node;AmplifyShaderEditor.CommentaryNode;614;46.35996,4145.041;Inherit;False;1039.246;492.81;Comment;9;188;246;349;650;182;613;531;212;611;Shore + Foam + Specular;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;69;-2805.001,1306.672;Inherit;False;2629.554;1053.425;Surface  Normal;25;331;62;263;265;64;65;54;244;68;66;541;67;59;58;55;56;268;296;419;60;330;61;63;266;630;Surface  Normal;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;525;-5208.146,3386.301;Inherit;False;1112.915;475.602;;8;52;269;51;49;270;271;272;398;World Space Tile;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;15;-2813.301,-601.7986;Inherit;False;977.8206;327.7764;Depth;6;14;373;372;9;8;10;Depth;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;359;-5213.448,2589.552;Inherit;False;909.677;391.5289;LinearFogMask;4;369;577;364;362;LinearFogMask;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;581;-2720.59,5249.59;Inherit;False;1880.972;622.9264;foam（泡沫）;11;599;628;593;583;520;610;649;505;582;605;591;foam（泡沫）;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;114;-2809.879,2737.793;Inherit;False;2445.914;939.1187;Caustics;24;118;119;121;115;127;122;129;116;123;113;120;117;124;112;106;126;104;110;111;125;107;105;108;631;Caustics;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;187;-2767.671,4000.886;Inherit;False;2544.586;961.7985;Shore（海岸线）;28;167;165;168;220;173;162;612;175;164;171;163;170;178;166;159;158;174;604;172;160;169;161;177;183;622;623;624;625;Shore;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;26;-2805.595,-25.09348;Inherit;False;2012.154;1020.793;Water Color;21;16;23;19;20;30;32;17;42;38;48;39;46;35;40;43;25;31;44;370;394;400;Water Color;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;502;-5214.55,1650.294;Inherit;False;1347.976;610.3708;Water specular;7;346;648;632;430;494;358;633;Water specular;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;323;868.6071,-396.7975;Inherit;False;1732.312;1586.476;Comment;26;281;314;311;313;312;571;289;288;96;284;286;285;287;393;90;278;277;89;283;93;94;91;92;297;88;295;UnderWaterColor;1,1,1,1;0;0
Node;AmplifyShaderEditor.ComponentMaskNode;314;1843.233,-322.5209;Inherit;False;False;False;False;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;192;2127.004,2227.538;Inherit;False;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;124;-1652.662,3075.504;Inherit;True;Property;_TextureSample1;Texture Sample 1;21;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;113;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;100;1206.216,2155.33;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;89;1866.983,159.9397;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;271;-4620.805,3665.811;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;171;-1208.978,4068.424;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.BlendNormalsNode;266;-1289.654,2051.212;Inherit;False;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BlendNormalsNode;63;-1296.929,1524.911;Inherit;False;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PosVertexDataNode;311;1176.365,-320.8702;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SwizzleNode;105;-2510.978,2789.264;Inherit;False;FLOAT2;0;2;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SwizzleNode;51;-4937.35,3504.181;Inherit;False;FLOAT2;0;2;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;170;-1478.178,4068.323;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;121;-1729.803,3456.236;Inherit;False;Property;_CausticsRange;Caustics Range (焦散范围);22;0;Create;False;0;0;0;False;0;False;1;1.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;400;-2383.346,221.5217;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SwizzleNode;44;-1485.269,538.3824;Inherit;False;FLOAT;3;1;2;3;1;0;COLOR;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ExpOpNode;23;-2310.648,595.0413;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;118;-1845.47,3360.613;Inherit;False;14;WaterDepth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;112;-2482.978,3274.264;Inherit;False;Constant;_Float3;Float 3;14;0;Create;True;0;0;0;False;0;False;0.02;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;129;-1243.943,3149.497;Inherit;False;Property;_CausticsColor;Caustics Color;25;0;Create;True;0;0;0;False;0;False;1,1,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;577;-4841.68,2731.197;Inherit;False;sha_com_func_linear_fog;0;;20;a0d8291c0358c484bba3c6b7a8a70d71;0;2;10;FLOAT;0;False;11;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenDepthNode;277;2018.14,103.8839;Inherit;False;0;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;119;-1634.891,3365.754;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;163;-1682.453,4281.094;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.UnityObjToClipPosHlpNode;312;1368.632,-320.3182;Inherit;False;1;0;FLOAT3;0,0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScreenColorNode;90;1858.885,740.5234;Inherit;False;Global;_GrabScreen0;Grab Screen 0;14;0;Create;True;0;0;0;False;0;False;Object;-1;False;False;False;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NegateNode;43;-1838.736,797.7825;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;117;-1260.126,3055.938;Inherit;False;Property;_CausticsIntensity;Caustics Intensity (水底焦散强度);24;0;Create;False;0;0;0;False;0;False;1;15;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;125;-2182.772,2958.011;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ClampOpNode;38;-1547.291,792.6111;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;19;-2667.987,608.8049;Inherit;False;14;WaterDepth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;40;-1701.184,815.0594;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;283;1613.771,255.5361;Inherit;False;uvOffset;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GrabScreenPosition;88;1163.19,3.813058;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;394;-2721.687,146.2739;Inherit;True;Property;_DeepMap;Deep Map （水底贴图）;6;0;Create;False;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;106;-2327.978,2829.264;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.OneMinusNode;173;-1012.966,4067.652;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;39;-2025.015,792.2325;Inherit;False;14;WaterDepth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;270;-4877.405,3638.711;Inherit;False;Property;_NormalScale;NormalScale（波纹大小）;14;0;Create;False;0;0;0;False;0;False;5,5;80,20;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SinOpNode;169;-1372.061,4412.011;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;220;-1085.841,4213.989;Inherit;False;Property;_FoamIntensity;Foam Intensity（岸边涟漪强度）;34;0;Create;False;0;0;0;False;0;False;0.5;0.5;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;622;-1142.94,4613.552;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;165;-1531.721,4394.161;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;183;-768.1104,4514.492;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;8;-2779.134,-389.0995;Inherit;False;Reconstruct World Position From Depth;-1;;21;e7094bcbcc80eb140b2a3dbe6a861de8;0;0;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;364;-5140.59,2806.552;Inherit;False;Property;_FogEnd;FogEnd (远处雾结束位置);12;0;Create;False;0;0;0;False;0;False;200;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;116;-886.3021,3037.502;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;126;-2024.773,3085.011;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;372;-2801.873,-507.3626;Float;False;Property;_DeepRange_1;Deep Range（水底水岸线范围）;8;0;Create;False;0;0;0;False;0;False;1;5.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;93;1200.177,409.4264;Inherit;False;Constant;_Float5;Float 5;14;0;Create;True;0;0;0;False;0;False;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;162;-1845.012,4206.942;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;32;-2010.698,372.2415;Inherit;False;Property;_FresnelColor;FresnelColor（远处颜色）;10;0;Create;False;0;0;0;False;0;False;0.5275899,0.7256795,0.8962264,0;0.6156863,0.7284409,0.8679245,0.05098039;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ClampOpNode;123;-1167.803,3373.236;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;284;1695.715,739.5475;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SwizzleNode;393;2061.863,741.739;Inherit;False;FLOAT3;0;1;2;3;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;52;-4612.47,3523.158;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;97;1187.541,1931.415;Inherit;False;96;UnderWaterColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;94;1082.614,310.619;Inherit;False;Property;_UnderWaterDistort;UnderWaterDistort（水底扭曲幅度）;20;0;Create;False;0;0;0;False;0;False;1;6;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;272;-4462.92,3562.04;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;194;1929.585,2227.978;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DepthFade;373;-2491.938,-527.635;Inherit;False;True;False;True;2;1;FLOAT3;0,0,0;False;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;16;-2359.833,24.75791;Inherit;False;Property;_ShallowColor;ShallowColor（水岸线颜色）;3;0;Create;False;0;0;0;False;0;False;0.2191527,0.5507062,0.764151,0;0.758954,0.6758277,0.7924528,0.4784314;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleTimeNode;111;-2501.978,3184.264;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;96;2229.908,740.5493;Inherit;False;UnderWaterColor;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;99;1565.651,2136.818;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;1,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;158;-2361.596,4050.186;Inherit;False;14;WaterDepth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMinOpNode;127;-1241.794,2938.87;Inherit;False;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;362;-5141.771,2706.333;Inherit;False;Property;_Fogstart;Fogstart (远处雾起始位置);11;0;Create;False;0;0;0;False;0;False;20;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;61;-1058.95,1516.757;Inherit;False;SurfaceNormal_TS;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;281;2250.736,-321.7872;Inherit;False;SurfaceDepth;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;49;-5145.093,3510.794;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;288;1060.429,877.6356;Inherit;False;281;SurfaceDepth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;285;1286.205,762.785;Inherit;False;283;uvOffset;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;110;-2248.978,3097.264;Inherit;False;3;3;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;31;-1686.282,353.178;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;36;1341.799,2304.043;Inherit;False;35;Alpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;330;-794.8827,1521.032;Inherit;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;297;1615.671,71.89322;Inherit;False;scrPos;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;107;-2599.978,2890.264;Inherit;False;Property;_CausticsScale;Caustics Scale (焦散大小);23;0;Create;False;0;0;0;False;0;False;6;5.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;289;1046.641,992.3229;Inherit;False;278;offsetPosDepth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;269;-4783.805,3509.809;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SamplerNode;60;-1637.218,1456.672;Inherit;True;Property;_NormalMap;NormalMap （水波纹贴图）;13;1;[NoScaleOffset];Create;False;0;0;0;False;0;False;-1;None;91432070d55ea5a4e9325dd2d0d42e8c;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;17;-2672.203,353.0966;Inherit;False;Property;_DeepColor;Deep Color（水底颜色）;7;0;Create;False;0;0;0;False;0;False;0.08971161,0.3932571,0.6603774,0;0.6981132,0.601958,0.6500356,0.9647059;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;571;1460.263,677.433;Inherit;False;297;scrPos;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;120;-1440.892,3373.754;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;25;-1474.945,251.2118;Inherit;False;WaterColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;35;-1034.388,627.7115;Inherit;False;Alpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;10;-2213.134,-391.0995;Inherit;False;PositionFormDepth;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;113;-1654.868,2839.048;Inherit;True;Property;_CausticsMap;Caustics Map (水底焦散贴图);21;1;[NoScaleOffset];Create;False;0;0;0;False;0;False;-1;None;bb456ae26f5d8ab4bbbc2d9fd4331997;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ComponentMaskNode;295;1415.248,53.94267;Inherit;False;True;True;False;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SaturateNode;46;-1183.116,630.6216;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;14;-2182.582,-534.489;Inherit;False;WaterDepth;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;286;1498.205,803.785;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;159;-2148.012,4066.942;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;9;-2419.134,-393.0995;Inherit;False;FLOAT3;0;1;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;419;-589.2584,1521.865;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;130;906.9108,2303.265;Inherit;False;115;CausticsColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;92;1434.232,265.8636;Inherit;False;3;3;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;174;-726.6526,4190.853;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ExpOpNode;122;-1300.803,3374.236;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;20;-2468.835,615.1174;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;369;-4558.372,2728.115;Inherit;False;LinearFogMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;30;-2016.616,168.5392;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ComputeScreenPosHlpNode;313;1582.703,-318.3104;Inherit;False;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.StepOpNode;287;1312.208,912.8033;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;278;2229.339,83.36766;Inherit;False;offsetPosDepth;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;42;-2107.212,881.8506;Inherit;False;Property;_EdgeAlpha;EdgeAlpha（岸边透明度）;9;0;Create;False;0;0;0;False;0;False;-0.1;-2.249458;-5;-0.1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;27;920.2731,2068.834;Inherit;False;25;WaterColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;370;-1980.538,559.1728;Inherit;False;369;LinearFogMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;108;-2017.978,2874.264;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;160;-2446.945,4131.023;Inherit;False;Property;_FoamRange;Foam Range （岸边涟漪范围）;29;0;Create;False;0;0;0;False;0;False;1;1.5;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;172;-1535.016,4175.194;Inherit;False;Property;_FoamBlend;Foam Blend （岸边涟漪过渡）;32;0;Create;False;0;0;0;False;0;False;1;0.761;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;177;-986.8564,4640.082;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMinOpNode;48;-1327.265,609.9012;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;161;-2016.012,4066.942;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;178;-1331.315,4801.234;Inherit;False;Property;_FoamDissolve;FoamDissolve（岸边涟漪溶解）;35;0;Create;False;0;0;0;False;0;False;0.21;1.2;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;456;2502.623,2240.023;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;3;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;0;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;458;2707.914,1200.077;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;460;2707.914,1200.077;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;459;2707.914,1200.077;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.ComponentMaskNode;296;-1078.673,2046.348;Inherit;False;True;True;False;True;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;115;-704.8801,3034.59;Inherit;False;CausticsColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;167;-2639.683,4281.47;Inherit;False;Property;_FoamSpeed;Foam Speed（岸边涟漪速度）;31;0;Create;False;0;0;0;False;0;False;1;-2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;168;-2548.014,4380.57;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;166;-2320.015,4304.57;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;175;-1683.107,4557.587;Inherit;True;Property;_FoamNoiseMap;Foam Noise Map (岸边涟漪溶解贴图);28;1;[NoScaleOffset];Create;False;0;0;0;False;0;False;-1;None;fac9b703bd98bda47a0c9c24785198f4;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;56;-2440.782,1838.128;Inherit;False;3;3;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;58;-2694.782,1925.128;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;59;-2681.782,2017.128;Inherit;False;Constant;_Float0;Float 0;8;0;Create;True;0;0;0;False;0;False;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;67;-2399.483,2041.701;Inherit;False;Constant;_Float2;Float 2;9;0;Create;True;0;0;0;False;0;False;-0.4;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;541;-2602.112,1480.004;Inherit;False;398;WorldSpaceTile;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;66;-2213.483,1977.701;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;68;-1995.485,1888.701;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;54;-1988.094,1519.93;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;65;-2426.586,1642.988;Inherit;False;Constant;_Float1;Float 1;9;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;64;-2206.278,1588.663;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;62;-1634.629,1692.411;Inherit;True;Property;_TextureSample0;Texture Sample 0;13;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;bump;Auto;True;Instance;60;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;263;-1658.598,1928.734;Inherit;True;Property;_TextureSample3;Texture Sample 3;13;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;bump;Auto;True;Instance;60;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;265;-1662.707,2150.585;Inherit;True;Property;_TextureSample4;Texture Sample 4;13;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;bump;Auto;True;Instance;60;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;244;-2095.722,1711.042;Inherit;False;Property;_NormalMapIntensity;NormalMap Intensity（波纹强度）;16;0;Create;False;0;0;0;False;0;False;1;1.6;0.1;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;268;-862.139,2047.122;Inherit;False;UnderWaterNormal;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;91;935.9165,193.5291;Inherit;False;268;UnderWaterNormal;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;189;1704.6,2340.246;Inherit;False;188;FoamShore;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;611;314.8499,4400.967;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;604;-1949.852,4640.088;Inherit;False;NoiseMapTile;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;623;-2476.741,4623.869;Inherit;False;268;UnderWaterNormal;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;624;-2132.164,4646.288;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;625;-2488.949,4742.717;Inherit;False;Property;_NoiseMapTile1;Noise Map Tile（涟漪贴图大小）;33;0;Create;False;0;0;0;False;0;False;2;0;2;15;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;531;99.35999,4489.665;Inherit;False;599;Foam;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;612;-498.5596,4187.003;Inherit;False;Shore;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;398;-4312.233,3560.506;Inherit;False;WorldSpaceTile;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;613;108.1984,4347.94;Inherit;False;612;Shore;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;55;-2976.41,1749.485;Inherit;False;Property;_NormalSpeed;NormalSpeed（波纹速度）;15;0;Create;False;0;0;0;False;0;False;1,1;3,5;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RegisterLocalVarNode;630;-2684.705,1756.757;Inherit;False;NormalSpeed;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;104;-2759.879,2787.793;Inherit;False;10;PositionFormDepth;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;631;-2480.737,3060.7;Inherit;False;630;NormalSpeed;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;331;-421.4648,1516.955;Inherit;False;SurfaceNormal_WS;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;457;2561.908,2225.023;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;13;ase/scene/sha_sc_water;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;3;True;12;all;0;False;True;1;5;False;;10;False;;1;1;False;;10;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;2;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;22;Surface;1;0;  Blend;0;0;Two Sided;1;0;Cast Shadows;0;0;  Use Shadow Threshold;0;0;Receive Shadows;1;0;GPU Instancing;1;0;LOD CrossFade;0;0;Built-in Fog;0;0;DOTS Instancing;0;0;Meta Pass;0;0;Extra Pre Pass;0;0;Tessellation;0;0;  Phong;0;0;  Strength;0.5,False,;0;  Type;0;0;  Tess;16,False,;0;  Min;10,False,;0;  Max;25,False,;0;  Edge Length;16,False,;0;  Max Displacement;25,False,;0;Vertex Position,InvertActionOnDeselection;1;0;0;5;False;True;False;True;False;False;;False;0
Node;AmplifyShaderEditor.RangedFloatNode;164;-1971.466,4307.48;Inherit;False;Property;_FoamFrequency;Foam Frequency（涟漪频率）;30;0;Create;False;0;0;0;False;0;False;10;14.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;606;2110.743,2473.51;Inherit;False;612;Shore;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;627;2109.788,2391.175;Inherit;False;599;Foam;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;633;-4838.744,1741.65;Inherit;False;Property;_SpecularStep;Specular（高光块状）;19;0;Create;False;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;358;-5134.193,1950.957;Inherit;False;Property;_Specular;Specular (水面高光强度);18;0;Create;False;0;0;0;False;0;False;0.8;0;0;0.99;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;494;-4850.732,1865.229;Inherit;False;sha_com_func_pbr_specular;4;;23;1fcd9deb260a8ea4a8b7ca17325784ee;0;2;28;FLOAT3;0,0,0;False;29;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;430;-5130.241,1827.752;Inherit;False;331;SurfaceNormal_WS;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;182;464.1165,4399.563;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;650;597.2185,4469.725;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;349;431.7349,4522.463;Inherit;False;346;Specule;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;246;328.7217,4194.748;Inherit;False;Property;_WaterSprayColor;Water Spray Color （水波纹颜色）;17;1;[HDR];Create;False;0;0;0;False;0;False;0.1409754,0.5660378,0.5199202,0;0.8572327,0.7981132,0.8867924,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;212;730.5818,4315.949;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;188;874.694,4314.977;Inherit;False;FoamShore;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SmoothstepOpNode;632;-4434.555,1791.415;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;346;-4178.653,1791.498;Inherit;False;Specule;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;648;-4419.877,1687.601;Inherit;False;SpecularStep;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;591;-2451.676,5471.944;Inherit;True;Property;_TextureSample2;Texture Sample 2;28;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;175;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;605;-2679.232,5492.479;Inherit;False;604;NoiseMapTile;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;582;-1912.89,5520.389;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;505;-2218.058,5672.828;Inherit;False;Property;_ShoreDissolve;Shore Dissolve (泡沫溶解);27;0;Create;False;0;0;0;False;0;False;0.4;0.392;0.1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;610;-1650.38,5377.713;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;583;-1659.909,5547.425;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;593;-1238.859,5527.006;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;628;-1406.436,5642.327;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0.05;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;599;-1088.302,5536.307;Inherit;False;Foam;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;520;-1714.631,5686.299;Inherit;False;Property;_ShoreIntensity;Shore Intensity（泡沫强度）;26;0;Create;False;0;0;0;False;0;False;0.5;0.7;0.01;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;649;-1983.905,5345.996;Inherit;False;648;SpecularStep;1;0;OBJECT;;False;1;FLOAT;0
WireConnection;314;0;313;0
WireConnection;192;0;194;0
WireConnection;124;1;126;0
WireConnection;100;0;27;0
WireConnection;100;1;130;0
WireConnection;89;0;297;0
WireConnection;89;1;283;0
WireConnection;271;0;269;1
WireConnection;271;1;270;2
WireConnection;171;0;170;0
WireConnection;171;1;172;0
WireConnection;266;0;263;0
WireConnection;266;1;265;0
WireConnection;63;0;60;0
WireConnection;63;1;62;0
WireConnection;105;0;104;0
WireConnection;51;0;49;0
WireConnection;170;0;161;0
WireConnection;400;0;394;0
WireConnection;400;1;17;0
WireConnection;44;0;31;0
WireConnection;23;0;20;0
WireConnection;577;10;362;0
WireConnection;577;11;364;0
WireConnection;277;0;89;0
WireConnection;119;0;118;0
WireConnection;163;0;162;0
WireConnection;163;1;164;0
WireConnection;312;0;311;0
WireConnection;90;0;284;0
WireConnection;43;0;39;0
WireConnection;125;0;106;0
WireConnection;38;0;40;0
WireConnection;40;0;43;0
WireConnection;40;1;42;0
WireConnection;283;0;92;0
WireConnection;106;0;105;0
WireConnection;106;1;107;0
WireConnection;173;0;171;0
WireConnection;169;0;165;0
WireConnection;622;0;169;0
WireConnection;622;1;175;1
WireConnection;165;0;163;0
WireConnection;165;1;166;0
WireConnection;183;1;177;0
WireConnection;116;0;127;0
WireConnection;116;1;117;0
WireConnection;116;2;123;0
WireConnection;126;0;125;0
WireConnection;126;1;110;0
WireConnection;162;0;161;0
WireConnection;123;0;122;0
WireConnection;284;0;571;0
WireConnection;284;1;286;0
WireConnection;393;0;90;0
WireConnection;52;0;269;0
WireConnection;52;1;270;1
WireConnection;272;0;52;0
WireConnection;272;1;271;0
WireConnection;194;0;99;0
WireConnection;194;1;189;0
WireConnection;373;0;372;0
WireConnection;96;0;393;0
WireConnection;99;0;97;0
WireConnection;99;1;100;0
WireConnection;99;2;36;0
WireConnection;127;0;113;0
WireConnection;127;1;124;0
WireConnection;61;0;63;0
WireConnection;281;0;314;0
WireConnection;110;0;631;0
WireConnection;110;1;111;0
WireConnection;110;2;112;0
WireConnection;31;0;32;0
WireConnection;31;1;30;0
WireConnection;31;2;370;0
WireConnection;330;0;61;0
WireConnection;297;0;295;0
WireConnection;269;0;51;0
WireConnection;60;1;54;0
WireConnection;60;5;244;0
WireConnection;120;0;119;0
WireConnection;120;1;121;0
WireConnection;25;0;31;0
WireConnection;35;0;46;0
WireConnection;10;0;9;0
WireConnection;113;1;108;0
WireConnection;295;0;88;0
WireConnection;46;0;48;0
WireConnection;14;0;373;0
WireConnection;286;0;285;0
WireConnection;286;1;287;0
WireConnection;159;0;158;0
WireConnection;159;1;160;0
WireConnection;9;0;8;0
WireConnection;419;0;330;0
WireConnection;92;0;91;0
WireConnection;92;1;94;0
WireConnection;92;2;93;0
WireConnection;174;0;173;0
WireConnection;174;1;220;0
WireConnection;174;2;183;0
WireConnection;122;0;120;0
WireConnection;20;0;19;0
WireConnection;369;0;577;0
WireConnection;30;0;17;0
WireConnection;30;1;16;0
WireConnection;30;2;23;0
WireConnection;313;0;312;0
WireConnection;287;0;288;0
WireConnection;287;1;289;0
WireConnection;278;0;277;0
WireConnection;108;0;106;0
WireConnection;108;1;110;0
WireConnection;177;0;622;0
WireConnection;177;1;178;0
WireConnection;48;0;44;0
WireConnection;48;1;38;0
WireConnection;161;0;159;0
WireConnection;296;0;266;0
WireConnection;115;0;116;0
WireConnection;166;0;167;0
WireConnection;166;1;168;0
WireConnection;175;1;604;0
WireConnection;56;0;630;0
WireConnection;56;1;58;0
WireConnection;56;2;59;0
WireConnection;66;0;56;0
WireConnection;66;1;67;0
WireConnection;68;0;64;0
WireConnection;68;1;66;0
WireConnection;54;0;541;0
WireConnection;54;1;56;0
WireConnection;64;0;541;0
WireConnection;64;1;65;0
WireConnection;62;1;68;0
WireConnection;62;5;244;0
WireConnection;263;1;54;0
WireConnection;265;1;68;0
WireConnection;268;0;296;0
WireConnection;611;0;613;0
WireConnection;611;1;531;0
WireConnection;604;0;624;0
WireConnection;624;0;623;0
WireConnection;624;1;625;0
WireConnection;612;0;174;0
WireConnection;398;0;272;0
WireConnection;630;0;55;0
WireConnection;331;0;419;0
WireConnection;457;2;192;0
WireConnection;494;28;430;0
WireConnection;494;29;358;0
WireConnection;182;0;611;0
WireConnection;650;0;182;0
WireConnection;650;1;349;0
WireConnection;212;0;246;0
WireConnection;212;1;650;0
WireConnection;188;0;212;0
WireConnection;632;0;494;0
WireConnection;632;1;633;0
WireConnection;346;0;632;0
WireConnection;648;0;633;0
WireConnection;591;1;605;0
WireConnection;582;0;591;1
WireConnection;582;1;505;0
WireConnection;610;0;582;0
WireConnection;610;1;649;0
WireConnection;583;1;582;0
WireConnection;593;0;583;0
WireConnection;593;1;628;0
WireConnection;628;0;520;0
WireConnection;599;0;593;0
ASEEND*/
//CHKSM=8D92AF98B218EB464A844C882E75C07C8D0F4EFB