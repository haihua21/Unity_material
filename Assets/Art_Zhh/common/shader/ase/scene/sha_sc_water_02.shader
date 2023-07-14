// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "ase/scene/sha_sc_water_1"
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
		_Fogstart("Fogstart (雾起始位置)", Float) = 20
		_FogEnd("FogEnd (雾结束位置)", Float) = 200
		[NoScaleOffset]_NormalMap("NormalMap", 2D) = "bump" {}
		_NormalScale("NormalScale", Vector) = (5,5,0,0)
		_NormalSpeed("NormalSpeed", Vector) = (1,1,0,0)
		_NormalMapIntensity("NormalMap Intensity", Range( 0.1 , 3)) = 1
		[HDR]_WaterSprayColor("Water Spray Color （水花颜色）", Color) = (0.1409754,0.5660378,0.5199202,0)
		_SpecSpeed("Spec Speed (高光速度)", Vector) = (5,2,0,0)
		_SpecScale("Spec Scale (高光大小)", Float) = 6
		_SpecIntensity("Spec Intensity (高光强度)", Float) = 1
		_UnderWaterDistort("UnderWaterDistort", Float) = 1
		_UnderWaterNormalIntensity("UnderWater Normal Intensity", Range( 0.1 , 1)) = 0.5
		[NoScaleOffset]_CausticsMap("Caustics Map (焦散)", 2D) = "white" {}
		_CausticsSpeed("Caustics Speed (焦散速度)", Vector) = (5,2,0,0)
		_CausticsRange("Caustics Range (焦散范围)", Float) = 1
		_CausticsScale("Caustics Scale (焦散大小)", Float) = 6
		_CausticsIntensity("Caustics Intensity (焦散强度)", Float) = 1
		_ShoreEdgeColor("Shore Edge Color (海岸线)", Color) = (1,1,1,0)
		_ShoreEdgeRange("Shore Edge Range", Float) = 1
		_ShoreEdgeWidth("Shore Edge Width", Range( 0 , 2)) = 0.3
		_ShoreEdgeIntensity("Shore Edge Intensity", Range( 0 , 1)) = 0.15
		_ShoreDissolve("Shore Dissolve", Range( 0 , 2)) = 1
		_ShoreEdgeSpeed("Shore Edge Speed", Float) = 0.2
		[NoScaleOffset]_FoamNoiseMap("Foam Noise Map (泡沫)", 2D) = "white" {}
		_NoiseMapTile("Noise Map Tile", Vector) = (0,0,0,0)
		_FoamRange("Foam Range", Float) = 1
		_FoamFrequency("Foam Frequency", Float) = 10
		_FoamSpeed("Foam Speed", Float) = 1
		_FoamBlend("Foam Blend", Range( 0 , 1)) = 1
		_FoamEdgeIntensity("Foam Edge Intensity", Range( 0 , 1)) = 0.5
		[ASEEnd]_FoamDissolve("FoamDissolve", Range( 0 , 2)) = 0

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
		#pragma target 3.0

		#pragma prefer_hlslcc gles
		#pragma exclude_renderers d3d11_9x 

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
			
			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 999999
			#define REQUIRE_OPAQUE_TEXTURE 1
			#define REQUIRE_DEPTH_TEXTURE 1

			
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#if ASE_SRP_VERSION <= 70108
			#define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
			#endif

			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_VERT_NORMAL


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 ase_texcoord : TEXCOORD0;
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
				float4 ase_texcoord8 : TEXCOORD8;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ShoreEdgeColor;
			float4 _WaterSprayColor;
			float4 _FresnelColor;
			float4 _DeepColor;
			float4 _ShallowColor;
			float2 _NoiseMapTile;
			float2 _SpecSpeed;
			float2 _CausticsSpeed;
			float2 _NormalScale;
			float2 _NormalSpeed;
			float _FoamDissolve;
			float _FoamSpeed;
			float _FoamFrequency;
			float _FoamRange;
			float _FoamBlend;
			float _ShoreEdgeIntensity;
			float _ShoreDissolve;
			float _ShoreEdgeSpeed;
			float _ShoreEdgeRange;
			float _DeepRange_1;
			float _ShoreEdgeWidth;
			float _CausticsRange;
			float _CausticsIntensity;
			float _FoamEdgeIntensity;
			float _CausticsScale;
			float _UnderWaterNormalIntensity;
			float _NormalMapIntensity;
			float _SpecIntensity;
			float _UnderWaterDistort;
			float _SpecScale;
			float _Fogstart;
			float _EdgeAlpha;
			float _FogEnd;
			#ifdef TESSELLATION_ON
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
			
			float3 InvertDepthDirURP75_g1( float3 In )
			{
				float3 result = In;
				#if !defined(ASE_SRP_VERSION) || ASE_SRP_VERSION <= 70301 || ASE_SRP_VERSION == 70503 || ASE_SRP_VERSION >= 80301 
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
				float ase_vertexTangentSign = v.ase_tangent.w * unity_WorldTransformParams.w;
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord7.xyz = ase_worldBitangent;
				
				o.ase_texcoord4 = v.vertex;
				o.ase_texcoord8.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord5.w = 0;
				o.ase_texcoord6.w = 0;
				o.ase_texcoord7.w = 0;
				o.ase_texcoord8.zw = 0;
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

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 ase_texcoord : TEXCOORD0;

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
				o.ase_texcoord = v.ase_texcoord;
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
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
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
				float2 temp_output_295_0 = (ase_grabScreenPosNorm).xy;
				float2 scrPos297 = temp_output_295_0;
				float2 break269 = (WorldPosition).xz;
				float2 appendResult272 = (float2(( break269.x / _NormalScale.x ) , ( break269.y / _NormalScale.y )));
				float2 temp_output_56_0 = ( _NormalSpeed * _TimeParameters.x * 0.01 );
				float2 temp_output_54_0 = ( appendResult272 + temp_output_56_0 );
				float3 unpack263 = UnpackNormalScale( tex2D( _NormalMap, temp_output_54_0 ), _UnderWaterNormalIntensity );
				unpack263.z = lerp( 1, unpack263.z, saturate(_UnderWaterNormalIntensity) );
				float2 temp_output_68_0 = ( ( appendResult272 * 2.0 ) + ( temp_output_56_0 * -0.4 ) );
				float3 unpack265 = UnpackNormalScale( tex2D( _NormalMap, temp_output_68_0 ), _UnderWaterNormalIntensity );
				unpack265.z = lerp( 1, unpack265.z, saturate(_UnderWaterNormalIntensity) );
				float3 UnderWaterNormal268 = BlendNormal( unpack263 , unpack265 );
				float eyeDepth315 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( float4( scrPos297, 0.0 , 0.0 ).xy ),_ZBufferParams);
				float Depth316 = eyeDepth315;
				float4 unityObjectToClipPos312 = TransformWorldToHClip(TransformObjectToWorld(IN.ase_texcoord4.xyz));
				float4 computeScreenPos313 = ComputeScreenPos( unityObjectToClipPos312 );
				float SurfaceDepth281 = (computeScreenPos313).w;
				float DepthDiffer328 = ( Depth316 - SurfaceDepth281 );
				float2 uvOffset283 = ( (UnderWaterNormal268).xy * _UnderWaterDistort * 0.01 * saturate( DepthDiffer328 ) );
				float eyeDepth277 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( float4( ( scrPos297 + uvOffset283 ), 0.0 , 0.0 ).xy ),_ZBufferParams);
				float offsetPosDepth278 = eyeDepth277;
				float4 fetchOpaqueVal90 = float4( SHADERGRAPH_SAMPLE_SCENE_COLOR( ( scrPos297 + ( uvOffset283 * step( SurfaceDepth281 , offsetPosDepth278 ) ) ) ), 1.0 );
				float4 UnderWaterColor96 = fetchOpaqueVal90;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth373 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth373 = abs( ( screenDepth373 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _DeepRange_1 ) );
				float WaterDepth14 = distanceDepth373;
				float4 lerpResult30 = lerp( _DeepColor , _ShallowColor , exp( -WaterDepth14 ));
				float clampResult368 = clamp( ( ( _FogEnd - distance( WorldPosition , _WorldSpaceCameraPos ) ) / ( _FogEnd - _Fogstart ) ) , 0.0 , 1.0 );
				float LinearFogMask369 = clampResult368;
				float4 lerpResult31 = lerp( _FresnelColor , lerpResult30 , LinearFogMask369);
				float4 WaterColor25 = lerpResult31;
				float2 UV398 = appendResult272;
				float2 temp_output_409_0 = ( UV398 / _SpecScale );
				float2 temp_output_403_0 = ( _SpecSpeed * _TimeParameters.x * 0.01 );
				float Spec419 = ( (min( tex2D( _CausticsMap, ( temp_output_409_0 + temp_output_403_0 ) ) , tex2D( _CausticsMap, ( -temp_output_409_0 + temp_output_403_0 ) ) )).r * _SpecIntensity );
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
				float3 SurfaceNormal_WS331 = worldNormal330;
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 normalizeResult353 = normalize( ( _MainLightPosition.xyz + ase_worldViewDir ) );
				float dotResult337 = dot( SurfaceNormal_WS331 , normalizeResult353 );
				float temp_output_339_0 = max( dotResult337 , 0.0 );
				float temp_output_422_0 = ( Spec419 * temp_output_339_0 );
				float4 WaterShoreColor385 = _WaterSprayColor;
				float4 Spec_all346 = saturate( ( temp_output_422_0 * WaterShoreColor385 ) );
				float2 UV22_g3 = ase_screenPosNorm.xy;
				float2 localUnStereo22_g3 = UnStereo( UV22_g3 );
				float2 break64_g1 = localUnStereo22_g3;
				float clampDepth69_g1 = SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy );
				#ifdef UNITY_REVERSED_Z
				float staticSwitch38_g1 = ( 1.0 - clampDepth69_g1 );
				#else
				float staticSwitch38_g1 = clampDepth69_g1;
				#endif
				float3 appendResult39_g1 = (float3(break64_g1.x , break64_g1.y , staticSwitch38_g1));
				float4 appendResult42_g1 = (float4((appendResult39_g1*2.0 + -1.0) , 1.0));
				float4 temp_output_43_0_g1 = mul( unity_CameraInvProjection, appendResult42_g1 );
				float3 temp_output_46_0_g1 = ( (temp_output_43_0_g1).xyz / (temp_output_43_0_g1).w );
				float3 In75_g1 = temp_output_46_0_g1;
				float3 localInvertDepthDirURP75_g1 = InvertDepthDirURP75_g1( In75_g1 );
				float4 appendResult49_g1 = (float4(localInvertDepthDirURP75_g1 , 1.0));
				float3 PositionFormDepth10 = (mul( unity_CameraToWorld, appendResult49_g1 )).xyz;
				float2 temp_output_106_0 = ( (PositionFormDepth10).xz / _CausticsScale );
				float2 temp_output_110_0 = ( _CausticsSpeed * _TimeParameters.x * 0.01 );
				float clampResult123 = clamp( exp( ( -WaterDepth14 / _CausticsRange ) ) , 0.0 , 1.0 );
				float4 CausticsColor115 = ( min( tex2D( _CausticsMap, ( temp_output_106_0 + temp_output_110_0 ) ) , tex2D( _CausticsMap, ( -temp_output_106_0 + temp_output_110_0 ) ) ) * _CausticsIntensity * clampResult123 );
				float clampResult38 = clamp( ( -WaterDepth14 / _EdgeAlpha ) , 0.0 , 1.0 );
				float Alpha35 = saturate( min( (lerpResult31).a , clampResult38 ) );
				float4 lerpResult99 = lerp( UnderWaterColor96 , ( WaterColor25 + Spec_all346 + CausticsColor115 ) , Alpha35);
				float clampResult145 = clamp( exp( ( -WaterDepth14 / _ShoreEdgeRange ) ) , 0.0 , 1.0 );
				float myVarName148 = clampResult145;
				float smoothstepResult149 = smoothstep( ( 1.0 - _ShoreEdgeWidth ) , 1.0 , myVarName148);
				float2 appendResult224 = (float2(( IN.ase_texcoord8.xy.x * _NoiseMapTile.x ) , ( IN.ase_texcoord8.xy.y * _NoiseMapTile.y )));
				float temp_output_151_0 = ( smoothstepResult149 * step( 0.0 , ( ( smoothstepResult149 + tex2D( _FoamNoiseMap, ( ( _ShoreEdgeSpeed * _TimeParameters.x ) + appendResult224 ) ).r ) - _ShoreDissolve ) ) * _ShoreEdgeIntensity );
				float clampResult161 = clamp( ( WaterDepth14 / _FoamRange ) , 0.0 , 1.0 );
				float smoothstepResult171 = smoothstep( _FoamBlend , 1.0 , ( clampResult161 + 0.1 ));
				float temp_output_162_0 = ( 1.0 - clampResult161 );
				float4 FoamColor188 = ( saturate( ( temp_output_151_0 + ( ( 1.0 - smoothstepResult171 ) * step( 0.0 , ( ( sin( ( ( temp_output_162_0 * _FoamFrequency ) + ( _FoamSpeed * _TimeParameters.x ) ) ) + tex2D( _FoamNoiseMap, appendResult224 ).r ) - _FoamDissolve ) ) * _FoamEdgeIntensity ) ) ) * _ShoreEdgeColor );
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = max( ( lerpResult99 + ( FoamColor188 * ( LinearFogMask369 * LinearFogMask369 ) ) ) , float4( 0,0,0,0 ) ).rgb;
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
			
			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 999999

			
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
			float4 _ShoreEdgeColor;
			float4 _WaterSprayColor;
			float4 _FresnelColor;
			float4 _DeepColor;
			float4 _ShallowColor;
			float2 _NoiseMapTile;
			float2 _SpecSpeed;
			float2 _CausticsSpeed;
			float2 _NormalScale;
			float2 _NormalSpeed;
			float _FoamDissolve;
			float _FoamSpeed;
			float _FoamFrequency;
			float _FoamRange;
			float _FoamBlend;
			float _ShoreEdgeIntensity;
			float _ShoreDissolve;
			float _ShoreEdgeSpeed;
			float _ShoreEdgeRange;
			float _DeepRange_1;
			float _ShoreEdgeWidth;
			float _CausticsRange;
			float _CausticsIntensity;
			float _FoamEdgeIntensity;
			float _CausticsScale;
			float _UnderWaterNormalIntensity;
			float _NormalMapIntensity;
			float _SpecIntensity;
			float _UnderWaterDistort;
			float _SpecScale;
			float _Fogstart;
			float _EdgeAlpha;
			float _FogEnd;
			#ifdef TESSELLATION_ON
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

			#if defined(TESSELLATION_ON)
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
Version=18912
2072.8;116;2048;995.8;-843.041;-949.2249;1;True;True
Node;AmplifyShaderEditor.CommentaryNode;347;-5441.72,1153.11;Inherit;False;2087.895;687.2224;Comment;24;346;246;339;340;329;352;341;337;345;356;351;338;353;344;335;358;334;385;420;421;422;425;426;427;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;69;-2994.124,1210.915;Inherit;False;2561.79;1313.14;Surface  Normal;30;331;330;61;268;66;265;52;68;244;272;270;271;64;63;54;266;51;269;263;49;267;55;56;65;60;67;59;58;62;398;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;26;-2733.653,88.112;Inherit;False;2012.154;1020.793;Water Color;19;16;23;19;20;30;32;17;42;38;48;39;46;35;40;43;25;31;44;370;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;155;-2778.778,4728.225;Inherit;False;2109.002;614.1143;Shore （海岸线）;18;145;150;149;146;200;198;199;197;148;144;153;154;151;201;143;147;142;152;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;359;-5336.565,2856.602;Inherit;False;1465.677;485.5289;LinearFogMask;10;369;368;367;366;365;364;363;362;361;360;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;187;-3253.79,5645.4;Inherit;False;3085.614;1006.673;Foam Color;30;222;183;161;178;224;166;180;179;158;173;160;159;170;176;221;169;165;167;163;185;172;162;175;174;171;186;177;168;164;220;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;260;194.6809,5747.975;Inherit;False;1245.564;797.4565;Reflect （没用到）;11;255;253;259;251;250;73;252;249;256;247;258;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;15;-2710.042,-603.4832;Inherit;False;977.8206;327.7764;Depth;6;14;373;372;9;8;10;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;323;-366.3303,-1188.409;Inherit;False;1987.56;1111.465;Comment;36;5;3;4;328;94;288;93;289;281;287;312;321;277;322;313;278;297;316;393;89;88;90;96;284;314;91;92;286;285;283;311;315;296;295;396;397;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;114;-2763.394,2733.107;Inherit;False;2331.64;849.9849;Caustics;24;116;115;119;113;129;120;123;112;122;111;108;105;125;117;110;107;121;126;104;127;109;106;124;118;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;220;-1503.88,6026.628;Inherit;False;Property;_FoamEdgeIntensity;Foam Edge Intensity;39;0;Create;True;0;0;0;False;0;False;0.5;0.5;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;200;-1599.98,4969.859;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;61;-1160.703,1393.201;Inherit;False;SurfaceNormal_TS;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;124;-1814.156,3079.959;Inherit;True;Property;_TextureSample1;Texture Sample 1;20;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;113;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ClampOpNode;145;-2080.689,4797.707;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;105;-2464.493,2784.578;Inherit;False;FLOAT2;0;2;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;165;-2002.722,6125.146;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;222;-2918.081,6189.957;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;154;-947.2902,4837.868;Inherit;False;ShoreEdge;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;67;-2352.73,1887.685;Inherit;False;Constant;_Float2;Float 2;9;0;Create;True;0;0;0;False;0;False;-0.4;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;178;-1786.412,6422.51;Inherit;False;Property;_FoamDissolve;FoamDissolve;41;0;Create;True;0;0;0;False;0;False;0;1.2;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;212;-574.3494,5424.124;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClampOpNode;255;712.4448,6277.974;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;116;-1047.796,3041.957;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;164;-2355.584,6065.994;Inherit;False;Property;_FoamFrequency;Foam Frequency;35;0;Create;True;0;0;0;False;0;False;10;14.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;349;984.1482,1063.962;Inherit;False;346;Spec_all;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SmoothstepOpNode;149;-1661.83,4804.867;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;183;-1302.228,6211.006;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;398;-2173.354,1259.776;Inherit;False;UV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;417;-1495.805,3974.309;Inherit;False;Property;_SpecIntensity;Spec Intensity (高光强度);16;0;Create;False;0;0;0;False;0;False;1;15;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;175;-2422.659,6389.597;Inherit;True;Property;_FoamNoiseMap;Foam Noise Map (泡沫);32;1;[NoScaleOffset];Create;False;0;0;0;False;0;False;-1;None;fac9b703bd98bda47a0c9c24785198f4;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ExpOpNode;143;-2213.688,4798.707;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;271;-2478.227,1407.568;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;162;-2307.131,5926.456;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;198;-1355.92,4929.893;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;174;-1116.392,5811.225;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;270;-2736.827,1435.468;Inherit;False;Property;_NormalScale;NormalScale;8;0;Create;True;0;0;0;False;0;False;5,5;80,20;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleAddOpNode;205;-2313.609,5449.184;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;92;139.8729,-702.0889;Inherit;False;4;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;288;85.21311,-361.3189;Inherit;False;281;SurfaceDepth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;108;-1971.493,2869.578;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SinOpNode;169;-1865.379,6133.626;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;201;-2150.882,5121.328;Inherit;True;Property;_TextureSample2;Texture Sample 2;32;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;175;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;185;-1620.591,5925.87;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;111;-2455.493,3179.578;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;210;-963.9352,5394.828;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;173;-1518.084,5735.166;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;168;-2411.989,6278.192;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;9;-2343.875,-385.7841;Inherit;False;FLOAT3;0;1;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;148;-1877.812,4791.376;Inherit;False;myVarName;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;115;-866.3735,3039.045;Inherit;False;CausticsColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;152;-1472.504,5244.197;Inherit;False;Property;_ShoreEdgeIntensity;Shore Edge Intensity;29;0;Create;True;0;0;0;False;0;False;0.15;0.604;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;118;-2213.431,3358.904;Inherit;False;14;WaterDepth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;281;1049.932,-1066.867;Inherit;False;SurfaceDepth;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;129;-1405.437,3153.952;Inherit;False;Property;_CausticsColor;Caustics Color;25;0;Create;True;0;0;0;False;0;False;1,1,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;146;-2731.778,4793.225;Inherit;False;14;WaterDepth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;259;243.681,6431.029;Inherit;False;Property;_ReflectPower;Reflect Power;42;0;Create;True;0;0;0;False;0;False;5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;167;-2392.989,6178.192;Inherit;False;Property;_FoamSpeed;Foam Speed;36;0;Create;True;0;0;0;False;0;False;1;-2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;246;-4568.615,1667.408;Inherit;False;Property;_WaterSprayColor;Water Spray Color （水花颜色）;11;1;[HDR];Create;False;0;0;0;False;0;False;0.1409754,0.5660378,0.5199202,0;0.8572327,0.7981132,0.8867924,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;268;-1179.91,1929.232;Inherit;False;UnderWaterNormal;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;186;-1820.321,6007.887;Inherit;False;Property;_FoamWidth;Foam Width;38;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;123;-1535.764,3371.527;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;286;479.6432,-442.0411;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;176;-1663.937,6173.324;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;161;-2451.131,5925.456;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenDepthNode;315;393.7268,-914.6832;Inherit;False;0;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;121;-2097.764,3454.527;Inherit;False;Property;_CausticsRange;Caustics Range (焦散范围);22;0;Create;False;0;0;0;False;0;False;1;1.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;252;225.4458,6051.975;Inherit;False;Constant;_ReflectDistort;Reflect Distort;35;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;64;-2170.525,1439.648;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;297;161.15,-897.3809;Inherit;False;scrPos;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SmoothstepOpNode;171;-1695.096,5712.937;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;109;-2532.493,3025.578;Inherit;False;Property;_CausticsSpeed;Caustics Speed (焦散速度);21;0;Create;False;0;0;0;False;0;False;5,2;5,5;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RegisterLocalVarNode;385;-4237.983,1696.037;Inherit;False;WaterShoreColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;422;-4257.325,1238.142;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMinOpNode;127;-1403.287,2943.325;Inherit;False;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;420;-3838.469,1524.302;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;199;-1748.214,5120.273;Inherit;False;Property;_ShoreDissolve;Shore Dissolve;30;0;Create;True;0;0;0;False;0;False;1;1.228;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;358;-4463.878,1499.911;Inherit;False;Property;_SpecPower;Spec Power;13;0;Create;True;0;0;0;False;0;False;1;0;0.01;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;179;-3172.831,6097.764;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;346;-3543.159,1363.909;Inherit;False;Spec_all;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;151;-1194.098,4825.058;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;166;-2184.99,6218.192;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;159;-2583.131,5925.456;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;156;-870.4733,5520.053;Inherit;False;Property;_ShoreEdgeColor;Shore Edge Color (海岸线);26;0;Create;False;0;0;0;False;0;False;1,1,1,0;0.7092959,0.6414382,0.735849,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleTimeNode;202;-2747.341,5500.014;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;58;-2670.029,1772.112;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;144;-2353.777,4798.225;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;172;-1977.295,5842.137;Inherit;False;Property;_FoamBlend;Foam Blend;37;0;Create;True;0;0;0;False;0;False;1;0.761;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;106;-2281.493,2824.578;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.OneMinusNode;153;-1835.484,4933.285;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;425;-4173.582,1418.151;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;188;-387.9904,5414.619;Inherit;False;FoamColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;344;-3862.125,1361.791;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;426;-3999.964,1398.343;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;424;-4660.151,1027.8;Inherit;False;Property;_Float7;Float 7;44;0;Create;True;0;0;0;False;0;False;0.04888244;0.04888244;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;160;-2792.131,5977.456;Inherit;False;Property;_FoamRange;Foam Range;34;0;Create;True;0;0;0;False;0;False;1;1.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;345;-3721.576,1363.973;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StepOpNode;356;-4225.05,1361.227;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;430;1630.451,1511.237;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;112;-2436.493,3269.578;Inherit;False;Constant;_Float3;Float 3;14;0;Create;True;0;0;0;False;0;False;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;177;-1462.974,6223.595;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;258;248.681,6336.029;Inherit;False;Property;_ReflectScale;Reflect Scale;43;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;147;-2593.688,4881.707;Inherit;False;Property;_ShoreEdgeRange;Shore Edge Range;27;0;Create;True;0;0;0;False;0;False;1;2.3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;150;-2142.021,4935.961;Inherit;False;Property;_ShoreEdgeWidth;Shore Edge Width;28;0;Create;True;0;0;0;False;0;False;0.3;0.276;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;44;-1413.33,651.588;Inherit;False;FLOAT;3;1;2;3;1;0;COLOR;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;113;-1816.362,2843.503;Inherit;True;Property;_CausticsMap;Caustics Map (焦散);20;1;[NoScaleOffset];Create;False;0;0;0;False;0;False;-1;None;bb456ae26f5d8ab4bbbc2d9fd4331997;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.IndirectSpecularLight;247;877.7087,5992.596;Inherit;True;Tangent;3;0;FLOAT3;0,0,1;False;1;FLOAT;0.5;False;2;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;335;-5390.173,1203.11;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;110;-2202.493,3092.578;Inherit;False;3;3;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BlendNormalsNode;266;-1408.425,1932.322;Inherit;False;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PowerNode;340;-4495.377,1388.931;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;251;319.4458,5791.975;Inherit;False;Constant;_Vector0;Vector 0;35;0;Create;True;0;0;0;False;0;False;0,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleDivideOpNode;120;-1808.853,3372.045;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;158;-2805.715,5863.699;Inherit;False;14;WaterDepth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;182;-807.0466,5409.989;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;197;-1466.228,5050.204;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;163;-2144.572,6000.608;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;68;-2004.716,1681.527;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;39;-1953.075,905.4381;Inherit;False;14;WaterDepth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;125;-2136.287,2953.325;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.NegateNode;142;-2522.777,4797.225;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;107;-2543.465,2889.589;Inherit;False;Property;_CausticsScale;Caustics Scale (焦散大小);23;0;Create;False;0;0;0;False;0;False;6;5.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;117;-1421.62,3060.393;Inherit;False;Property;_CausticsIntensity;Caustics Intensity (焦散强度);24;0;Create;False;0;0;0;False;0;False;1;15;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;126;-1978.287,3080.325;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;170;-1857.296,5708.836;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;55;-2648.029,1630.111;Inherit;False;Property;_NormalSpeed;NormalSpeed;9;0;Create;True;0;0;0;False;0;False;1,1;3,5;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;204;-2728.341,5400.014;Inherit;False;Property;_ShoreEdgeSpeed;Shore Edge Speed;31;0;Create;True;0;0;0;False;0;False;0.2;0.08;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;60;-1738.971,1333.116;Inherit;True;Property;_NormalMap;NormalMap;7;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;-1;None;91432070d55ea5a4e9325dd2d0d42e8c;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;236;2381.835,1408.612;Inherit;False;35;Alpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;224;-2708.081,6237.957;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;256;1215.445,5982.975;Inherit;False;Reflect;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;263;-1744.369,1815.845;Inherit;True;Property;_TextureSample3;Texture Sample 3;7;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;bump;Auto;True;Instance;60;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;249;447.5531,6165.09;Inherit;False;Property;_Smoothness;Smoothness;40;0;Create;True;0;0;0;False;0;False;0.5;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;353;-5011.852,1233.629;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;180;-2919.809,6305.448;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;10;-2160.875,-384.7841;Inherit;False;PositionFormDepth;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;341;-4939.101,1523.481;Inherit;False;Property;_SpecSmoothness;SpecSmoothness;12;0;Create;True;0;0;0;False;0;False;0.5;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;330;-904.6362,1395.476;Inherit;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleDivideOpNode;40;-1629.245,928.2651;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;334;-5148.446,1219.656;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DepthFade;373;-2388.68,-529.3196;Inherit;False;True;False;True;2;1;FLOAT3;0,0,0;False;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;46;-1111.177,743.8273;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;52;-2477.892,1289.915;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;314;817.9877,-1099.205;Inherit;False;False;False;False;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;97;1407.808,798.2906;Inherit;False;96;UnderWaterColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.NegateNode;119;-2002.851,3364.045;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;99;1785.917,1003.693;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;1,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;339;-4665.571,1388.11;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;363;-4999.042,3007.874;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;100;1423.483,1033.205;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;321;63.01562,-501.3984;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;367;-4510.729,3045.128;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;91;-332.4432,-722.4235;Inherit;False;268;UnderWaterNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ScreenDepthNode;277;825.9888,-728.4411;Inherit;False;0;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;284;746.1527,-494.2784;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;405;-2525.18,3962.589;Inherit;False;Property;_SpecSpeed;Spec Speed (高光速度);14;0;Create;False;0;0;0;False;0;False;5,2;5,5;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.GetLocalVarNode;73;289.4438,5948.297;Inherit;False;61;SurfaceNormal_TS;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ClampOpNode;368;-4375.5,3042.998;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;43;-1766.797,910.9881;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;16;-2287.891,137.9634;Inherit;False;Property;_ShallowColor;ShallowColor（水岸线颜色）;0;0;Create;False;0;0;0;False;0;False;0.2191527,0.5507062,0.764151,0;0.758954,0.6758277,0.7924528,0.4784314;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;104;-2713.394,2783.107;Inherit;False;10;PositionFormDepth;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldPosInputsNode;360;-5260.671,2930.871;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;94;-192.7459,-622.3337;Inherit;False;Property;_UnderWaterDistort;UnderWaterDistort;18;0;Create;True;0;0;0;False;0;False;1;6;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;393;1280.301,-498.0871;Inherit;False;FLOAT;3;1;2;3;1;0;COLOR;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;352;-4827.824,1607.017;Inherit;False;Constant;_Float4;Float 4;42;0;Create;True;0;0;0;False;0;False;256;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;269;-2647.227,1280.568;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SamplerNode;62;-1737.682,1575.355;Inherit;True;Property;_TextureSample0;Texture Sample 0;7;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;bump;Auto;True;Instance;60;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;93;-170.182,-543.5262;Inherit;False;Constant;_Float5;Float 5;14;0;Create;True;0;0;0;False;0;False;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;20;-2396.893,728.323;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;364;-4926.708,2926.602;Inherit;False;Property;_FogEnd;FogEnd (雾结束位置);6;0;Create;False;0;0;0;False;0;False;200;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;130;1124.178,1181.14;Inherit;False;115;CausticsColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;351;-4648.823,1539.847;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;253;444.446,6268.974;Inherit;False;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;36;1562.066,1170.918;Inherit;False;35;Alpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;192;2330.296,1197.592;Inherit;False;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ComputeScreenPosHlpNode;313;501.0425,-1111.864;Inherit;False;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;328;-140.7136,-449.0035;Inherit;False;DepthDiffer;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;59;-2635.029,1863.112;Inherit;False;Constant;_Float0;Float 0;8;0;Create;True;0;0;0;False;0;False;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;96;1326.347,-336.2768;Inherit;False;UnderWaterColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;42;-2035.271,995.0563;Inherit;False;Property;_EdgeAlpha;EdgeAlpha（岸边透明度）;3;0;Create;False;0;0;0;False;0;False;-0.1;-2.249458;-5;-0.1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;51;-2795.772,1273.938;Inherit;False;FLOAT2;0;2;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;265;-1739.478,2016.695;Inherit;True;Property;_TextureSample4;Texture Sample 4;7;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;bump;Auto;True;Instance;60;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;365;-4706.868,3113.804;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;278;1086.189,-733.8412;Inherit;False;offsetPosDepth;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;318;-475.7247,-442.6831;Inherit;False;316;Depth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;244;-2146.968,1566.027;Inherit;False;Property;_NormalMapIntensity;NormalMap Intensity;10;0;Create;True;0;0;0;False;0;False;1;1.6;0.1;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.ExpOpNode;23;-2238.706,708.2469;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;295;-167.2731,-896.3314;Inherit;False;True;True;False;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;56;-2394.029,1684.112;Inherit;False;3;3;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;203;-2520.342,5440.014;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;250;550.446,5898.975;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StepOpNode;287;293.6456,-333.0231;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;396;-381.2224,-1135.268;Inherit;True;Property;_DeepMap1;Deep Map （水底贴图）;1;0;Create;False;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;338;-5346.399,1391.828;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;27;1137.54,946.7095;Inherit;False;25;WaterColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.Vector2Node;221;-3171.267,6271.523;Inherit;False;Property;_NoiseMapTile;Noise Map Tile;33;0;Create;True;0;0;0;False;0;False;0,0;10,8;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.GetLocalVarNode;289;80.5192,-261.1153;Inherit;False;278;offsetPosDepth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;427;-4290.793,1585.772;Inherit;False;Property;_Spec1_Intensity;Spec1_Intensity;17;0;Create;True;0;0;0;False;0;False;1;0.01;0.01;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;366;-4713.854,2992.742;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceCameraPos;361;-5286.565,3161.531;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;283;332.9916,-671.6748;Inherit;False;uvOffset;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMinOpNode;48;-1255.325,723.1068;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;65;-2329.833,1502.973;Inherit;False;Constant;_Float1;Float 1;9;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;397;12.94131,-1070.035;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT2;0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ComponentMaskNode;296;-90.85942,-721.1624;Inherit;False;True;True;False;True;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;66;-2184.73,1814.685;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;30;-1944.677,281.7447;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;322;-286.2733,-441.6831;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;372;-2698.614,-509.0472;Float;False;Property;_DeepRange_1;Deep Range（水底水岸线范围）;2;0;Create;False;0;0;0;False;0;False;1;5.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;8;-2703.875,-381.7841;Inherit;False;Reconstruct World Position From Depth;-1;;1;e7094bcbcc80eb140b2a3dbe6a861de8;0;0;1;FLOAT4;0
Node;AmplifyShaderEditor.DynamicAppendNode;272;-2330.342,1324.797;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;285;267.6432,-483.0411;Inherit;False;283;uvOffset;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;189;1588.892,1375.3;Inherit;False;188;FoamColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;331;-678.2182,1387.399;Inherit;False;SurfaceNormal_WS;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;267;-2278.82,1999.974;Inherit;False;Property;_UnderWaterNormalIntensity;UnderWater Normal Intensity;19;0;Create;True;0;0;0;False;0;False;0.5;0.15;0.1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GrabScreenPosition;88;-385.3305,-940.4611;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;316;643.7266,-899.6832;Inherit;False;Depth;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;329;-5101.168,1389.821;Inherit;False;331;SurfaceNormal_WS;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;404;-2435.18,4194.59;Inherit;False;Constant;_Float6;Float 6;14;0;Create;True;0;0;0;False;0;False;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;416;-1203.342,3854.3;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;411;-2531.141,3722.364;Inherit;False;398;UV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;407;-2009.974,3972.336;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;406;-2010.18,3826.589;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ExpOpNode;122;-1668.764,3372.527;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;428;1388.026,1512.915;Inherit;True;369;LinearFogMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;194;1971.876,1213.032;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WorldPosInputsNode;49;-2975.515,1281.551;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;413;-1866.536,3962.323;Inherit;True;Property;_TextureSample6;Texture Sample 6;20;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;113;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.UnityObjToClipPosHlpNode;312;276.237,-1138.409;Inherit;False;1;0;FLOAT3;0,0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;362;-4940.888,3172.383;Inherit;False;Property;_Fogstart;Fogstart (雾起始位置);5;0;Create;False;0;0;0;False;0;False;20;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;320;-504.8966,-355.59;Inherit;False;281;SurfaceDepth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMinOpNode;414;-1518.149,3855.695;Inherit;False;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.PosVertexDataNode;311;81.9697,-1262.961;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;31;-1614.343,466.3836;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SwizzleNode;415;-1374.591,3849.311;Inherit;False;FLOAT;0;1;2;3;1;0;COLOR;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;14;-2016.323,-537.1736;Inherit;False;WaterDepth;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;423;-4329.914,1052.667;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;403;-2195.18,4029.589;Inherit;False;3;3;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;54;-2004.339,1392.915;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ClampOpNode;38;-1475.351,905.8167;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;421;-4546.854,1176.887;Inherit;False;419;Spec;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;408;-2183.974,3908.336;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DotProductOpNode;337;-4835.235,1350.688;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;402;-2448.18,4109.591;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;409;-2320.18,3781.589;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;89;555.4378,-772.5366;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BlendNormalsNode;63;-1398.682,1401.355;Inherit;False;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;19;-2596.046,722.0105;Inherit;False;14;WaterDepth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;90;914.238,-486.9364;Inherit;False;Global;_GrabScreen0;Grab Screen 0;14;0;Create;True;0;0;0;False;0;False;Object;-1;False;False;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;369;-4197.489,3037.165;Inherit;False;LinearFogMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;370;-1908.599,672.3784;Inherit;False;369;LinearFogMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;35;-962.4487,740.9172;Inherit;False;Alpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;32;-1938.758,485.4471;Inherit;False;Property;_FresnelColor;FresnelColor（远处颜色）;4;0;Create;False;0;0;0;False;0;False;0.5275899,0.7256795,0.8962264,0;0.6156863,0.7284409,0.8679245,0.05098039;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;17;-2346.762,351.9022;Inherit;False;Property;_DeepColor;Deep Color（水底颜色）;1;0;Create;False;0;0;0;False;0;False;0.08971161,0.3932571,0.6603774,0;0.6981132,0.601958,0.6500356,0.9647059;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;412;-1865.339,3726.581;Inherit;True;Property;_TextureSample5;Texture Sample 5;20;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;113;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;419;-1045.016,3848.048;Inherit;False;Spec;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;401;-2551.559,3852.128;Inherit;False;Property;_SpecScale;Spec Scale (高光大小);15;0;Create;False;0;0;0;False;0;False;6;5.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;25;-1403.006,364.4174;Inherit;False;WaterColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;429;1794.451,1450.237;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;5;-7,-139;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;1491.736,1729.125;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;2707.914,1200.077;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;ase/scene/sha_sc_water_1;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;True;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;2;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;5;False;-1;10;False;-1;1;1;False;-1;10;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;22;Surface;1;  Blend;0;Two Sided;1;Cast Shadows;0;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;1;LOD CrossFade;0;Built-in Fog;0;DOTS Instancing;0;Meta Pass;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;False;True;False;True;False;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;-7,-139;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;-7,-139;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
WireConnection;200;0;149;0
WireConnection;200;1;201;1
WireConnection;61;0;63;0
WireConnection;124;1;126;0
WireConnection;145;0;143;0
WireConnection;105;0;104;0
WireConnection;165;0;163;0
WireConnection;165;1;166;0
WireConnection;222;0;179;1
WireConnection;222;1;221;1
WireConnection;154;0;151;0
WireConnection;212;0;182;0
WireConnection;212;1;156;0
WireConnection;255;0;253;0
WireConnection;116;0;127;0
WireConnection;116;1;117;0
WireConnection;116;2;123;0
WireConnection;149;0;148;0
WireConnection;149;1;153;0
WireConnection;183;1;177;0
WireConnection;398;0;272;0
WireConnection;175;1;224;0
WireConnection;143;0;144;0
WireConnection;271;0;269;1
WireConnection;271;1;270;2
WireConnection;162;0;161;0
WireConnection;198;1;197;0
WireConnection;174;0;173;0
WireConnection;174;1;183;0
WireConnection;174;2;220;0
WireConnection;205;0;203;0
WireConnection;205;1;224;0
WireConnection;92;0;296;0
WireConnection;92;1;94;0
WireConnection;92;2;93;0
WireConnection;92;3;321;0
WireConnection;108;0;106;0
WireConnection;108;1;110;0
WireConnection;169;0;165;0
WireConnection;201;1;205;0
WireConnection;185;0;162;0
WireConnection;185;1;186;0
WireConnection;210;0;151;0
WireConnection;210;1;174;0
WireConnection;173;0;171;0
WireConnection;9;0;8;0
WireConnection;148;0;145;0
WireConnection;115;0;116;0
WireConnection;281;0;314;0
WireConnection;268;0;266;0
WireConnection;123;0;122;0
WireConnection;286;0;285;0
WireConnection;286;1;287;0
WireConnection;176;0;169;0
WireConnection;176;1;175;1
WireConnection;161;0;159;0
WireConnection;315;0;297;0
WireConnection;64;0;272;0
WireConnection;64;1;65;0
WireConnection;297;0;295;0
WireConnection;171;0;170;0
WireConnection;171;1;172;0
WireConnection;385;0;246;0
WireConnection;422;0;421;0
WireConnection;422;1;339;0
WireConnection;127;0;113;0
WireConnection;127;1;124;0
WireConnection;420;0;426;0
WireConnection;420;1;422;0
WireConnection;346;0;345;0
WireConnection;151;0;149;0
WireConnection;151;1;198;0
WireConnection;151;2;152;0
WireConnection;166;0;167;0
WireConnection;166;1;168;0
WireConnection;159;0;158;0
WireConnection;159;1;160;0
WireConnection;144;0;142;0
WireConnection;144;1;147;0
WireConnection;106;0;105;0
WireConnection;106;1;107;0
WireConnection;153;0;150;0
WireConnection;425;0;340;0
WireConnection;425;1;358;0
WireConnection;188;0;212;0
WireConnection;344;0;422;0
WireConnection;344;1;385;0
WireConnection;426;0;425;0
WireConnection;426;1;427;0
WireConnection;345;0;344;0
WireConnection;356;0;358;0
WireConnection;356;1;340;0
WireConnection;430;0;428;0
WireConnection;430;1;428;0
WireConnection;177;0;176;0
WireConnection;177;1;178;0
WireConnection;44;0;31;0
WireConnection;113;1;108;0
WireConnection;247;0;250;0
WireConnection;247;1;249;0
WireConnection;247;2;255;0
WireConnection;110;0;109;0
WireConnection;110;1;111;0
WireConnection;110;2;112;0
WireConnection;266;0;263;0
WireConnection;266;1;265;0
WireConnection;340;0;339;0
WireConnection;340;1;351;0
WireConnection;120;0;119;0
WireConnection;120;1;121;0
WireConnection;182;0;210;0
WireConnection;197;0;200;0
WireConnection;197;1;199;0
WireConnection;163;0;162;0
WireConnection;163;1;164;0
WireConnection;68;0;64;0
WireConnection;68;1;66;0
WireConnection;125;0;106;0
WireConnection;142;0;146;0
WireConnection;126;0;125;0
WireConnection;126;1;110;0
WireConnection;170;0;161;0
WireConnection;60;1;54;0
WireConnection;60;5;244;0
WireConnection;224;0;222;0
WireConnection;224;1;180;0
WireConnection;256;0;247;0
WireConnection;263;1;54;0
WireConnection;263;5;267;0
WireConnection;353;0;334;0
WireConnection;180;0;179;2
WireConnection;180;1;221;2
WireConnection;10;0;9;0
WireConnection;330;0;61;0
WireConnection;40;0;43;0
WireConnection;40;1;42;0
WireConnection;334;0;335;0
WireConnection;334;1;338;0
WireConnection;373;0;372;0
WireConnection;46;0;48;0
WireConnection;52;0;269;0
WireConnection;52;1;270;1
WireConnection;314;0;313;0
WireConnection;119;0;118;0
WireConnection;99;0;97;0
WireConnection;99;1;100;0
WireConnection;99;2;36;0
WireConnection;339;0;337;0
WireConnection;363;0;360;0
WireConnection;363;1;361;0
WireConnection;100;0;27;0
WireConnection;100;1;349;0
WireConnection;100;2;130;0
WireConnection;321;0;328;0
WireConnection;367;0;366;0
WireConnection;367;1;365;0
WireConnection;277;0;89;0
WireConnection;284;0;297;0
WireConnection;284;1;286;0
WireConnection;368;0;367;0
WireConnection;43;0;39;0
WireConnection;393;0;90;0
WireConnection;269;0;51;0
WireConnection;62;1;68;0
WireConnection;62;5;244;0
WireConnection;20;0;19;0
WireConnection;351;0;341;0
WireConnection;351;1;352;0
WireConnection;253;2;258;0
WireConnection;253;3;259;0
WireConnection;192;0;194;0
WireConnection;313;0;312;0
WireConnection;328;0;322;0
WireConnection;96;0;90;0
WireConnection;51;0;49;0
WireConnection;265;1;68;0
WireConnection;265;5;267;0
WireConnection;365;0;364;0
WireConnection;365;1;362;0
WireConnection;278;0;277;0
WireConnection;23;0;20;0
WireConnection;295;0;88;0
WireConnection;56;0;55;0
WireConnection;56;1;58;0
WireConnection;56;2;59;0
WireConnection;203;0;204;0
WireConnection;203;1;202;0
WireConnection;250;0;251;0
WireConnection;250;1;73;0
WireConnection;250;2;252;0
WireConnection;287;0;288;0
WireConnection;287;1;289;0
WireConnection;366;0;364;0
WireConnection;366;1;363;0
WireConnection;283;0;92;0
WireConnection;48;0;44;0
WireConnection;48;1;38;0
WireConnection;397;0;396;0
WireConnection;397;1;295;0
WireConnection;296;0;91;0
WireConnection;66;0;56;0
WireConnection;66;1;67;0
WireConnection;30;0;17;0
WireConnection;30;1;16;0
WireConnection;30;2;23;0
WireConnection;322;0;318;0
WireConnection;322;1;320;0
WireConnection;272;0;52;0
WireConnection;272;1;271;0
WireConnection;331;0;330;0
WireConnection;316;0;315;0
WireConnection;416;0;415;0
WireConnection;416;1;417;0
WireConnection;407;0;408;0
WireConnection;407;1;403;0
WireConnection;406;0;409;0
WireConnection;406;1;403;0
WireConnection;122;0;120;0
WireConnection;194;0;99;0
WireConnection;194;1;429;0
WireConnection;413;1;407;0
WireConnection;312;0;311;0
WireConnection;414;0;412;0
WireConnection;414;1;413;0
WireConnection;31;0;32;0
WireConnection;31;1;30;0
WireConnection;31;2;370;0
WireConnection;415;0;414;0
WireConnection;14;0;373;0
WireConnection;423;0;424;0
WireConnection;423;1;421;0
WireConnection;403;0;405;0
WireConnection;403;1;402;0
WireConnection;403;2;404;0
WireConnection;54;0;272;0
WireConnection;54;1;56;0
WireConnection;38;0;40;0
WireConnection;408;0;409;0
WireConnection;337;0;329;0
WireConnection;337;1;353;0
WireConnection;409;0;411;0
WireConnection;409;1;401;0
WireConnection;89;0;297;0
WireConnection;89;1;283;0
WireConnection;63;0;60;0
WireConnection;63;1;62;0
WireConnection;90;0;284;0
WireConnection;369;0;368;0
WireConnection;35;0;46;0
WireConnection;412;1;406;0
WireConnection;419;0;416;0
WireConnection;25;0;31;0
WireConnection;429;0;189;0
WireConnection;429;1;430;0
WireConnection;2;2;192;0
ASEEND*/
//CHKSM=30F59C857FF3367BB8CA73C12A09A42A50754562