// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "ase/scene/sha_sc_urp_metallic"
{
	Properties
	{
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin][NoScaleOffset]_BaseMap("Base Map", 2D) = "white" {}
		[Toggle(_SPECULARHIGHLIGHTS_ON)] _SpecularHighlights("Specular Highlights", Float) = 0
		_BaseColor("Base Color", Color) = (1,1,1,0)
		[NoScaleOffset]_NormalMap("Normal Map", 2D) = "bump" {}
		[NoScaleOffset]_SEMMap("SOM Map (S=smoothness, O=AO, M=metallic)", 2D) = "white" {}
		_Tile_UV("Tile_UV", Vector) = (1,1,0,0)
		_AO_Int("AO_Int", Range( 0 , 1)) = 0.5
		_Smoothness("Smoothness", Range( 0 , 1)) = 0.5
		_Metallic("Metallic", Range( 0 , 1)) = 0
		[HDR]_EmissionColor("Emission Color", Color) = (1,1,1,0)
		_EmissionIntensity("Emission Intensity", Range( 0 , 3)) = 0
		_MatcapMap("Matcap Map", 2D) = "white" {}
		_MatcapAlbedoBlend("Matcap Albedo Blend", Range( 0 , 2)) = 0
		_MatcapIntensity("MatcapIntensity", Range( 0 , 8)) = 1
		_MatcapColor("Matcap Color", Color) = (1,1,1,0)
		[NoScaleOffset]_DamagedMap("Damaged Map", 2D) = "black" {}
		_ReflectionAmount("ReflectionAmount", Range( 0 , 1)) = 0
		[NoScaleOffset]_DamagedMap_N("Damaged Map_N", 2D) = "bump" {}
		_DamagedTile("DamagedTile", Float) = 2
		[Toggle(_PLANARREFLECTION_ON_ON)] _PlanarReflection_On("PlanarReflection_On", Float) = 0
		_Damaged_Color("Damaged_Color", Color) = (0.3960784,0.2745098,0.1764706,0)
		[ASEEnd]_damaged("damaged(0~4 state)", Float) = 0

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

		
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
		
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
			
			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
			
			#pragma multi_compile_instancing
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_SRP_VERSION 999999

			
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

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_FRAG_SHADOWCOORDS
			#define ASE_NEEDS_VERT_TEXTURE_COORDINATES1
			#pragma shader_feature_local _SPECULARHIGHLIGHTS_ON
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma shader_feature_local _PLANARREFLECTION_ON_ON
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma shader_feature _ _SUBTRACTIVE_ADDITIONAL_LIGHTING


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
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
				float4 lightmapUVOrVertexSH : TEXCOORD7;
				float4 ase_texcoord8 : TEXCOORD8;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _BaseColor;
			float4 _Damaged_Color;
			float4 _MatcapColor;
			float4 _EmissionColor;
			float2 _Tile_UV;
			float _Metallic;
			float _MatcapAlbedoBlend;
			float _damaged;
			float _DamagedTile;
			float _MatcapIntensity;
			float _Smoothness;
			float _AO_Int;
			float _EmissionIntensity;
			float _ReflectionAmount;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D _SEMMap;
			sampler2D _BaseMap;
			sampler2D _DamagedMap;
			sampler2D _MatcapMap;
			sampler2D _NormalMap;
			sampler2D _DamagedMap_N;
			sampler2D _PlanarReflectionTexture;


			real3 ASESafeNormalize(float3 inVec)
			{
				real dp3 = max(FLT_MIN, dot(inVec, inVec));
				return inVec* rsqrt( dp3);
			}
			
			float CalcSSAO23_g735( float2 position_cs, float3 main_light_color, float input_ao, out float3 main_light_color_ssao )
			{
				float ao_ssao = input_ao;
				main_light_color_ssao = main_light_color;
				#if defined(_SCREEN_SPACE_OCCLUSION)
					float2 normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(position_cs);
					AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(normalizedScreenSpaceUV);
					main_light_color_ssao = main_light_color * aoFactor.directAmbientOcclusion;
					ao_ssao = min(input_ao, aoFactor.indirectAmbientOcclusion);
				#endif
				return ao_ssao;
			}
			
			float3 ASEIndirectDiffuse( float2 uvStaticLightmap, float3 normalWS )
			{
			#ifdef LIGHTMAP_ON
				return SampleLightmap( uvStaticLightmap, normalWS );
			#else
				return SampleSH(normalWS);
			#endif
			}
			
			float3 MixRealtimeAndBakedGI167_g734( float3 normalWS, float3 bakedGI, float3 positionWS )
			{
				#if defined(LIGHTMAP_ON) && defined(_MIXED_LIGHTING_SUBTRACTIVE)
					float4 shadowCoord = float4(0,0,0,0);
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						shadowCoord = TransformWorldToShadowCoord(positionWS);
						//shadowCoord = float4(1,0,0,0);
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						shadowCoord = TransformWorldToShadowCoord( positionWS );
						//shadowCoord = float4(0,0,1,0);
					#endif
					Light mainLight = GetMainLight(shadowCoord);
					
					
				    half shadowStrength = GetMainLightShadowStrength() * _ShadowIntensity;
				    half contributionTerm = saturate(dot(mainLight.direction, normalWS));
				    half3 lambert = mainLight.color * contributionTerm;
				    half3 estimatedLightContributionMaskedByInverseOfShadow = lambert * (1.0 - mainLight.shadowAttenuation);
				    half3 subtractedLightmap = bakedGI - estimatedLightContributionMaskedByInverseOfShadow;
				    // 2) Allows user to define overall ambient of the scene and control situation when realtime shadow becomes too dark.
				    half3 realtimeShadow = max(subtractedLightmap, _SubtractiveShadowColor.xyz);
				    realtimeShadow = lerp(bakedGI, realtimeShadow, shadowStrength);
				    // 3) Pick darkest color
				    return min(bakedGI, realtimeShadow);
				#else
					
					return bakedGI;
				#endif
			}
			
			float3 CustomDirectBRDFSpecular( float roughness2_minus_one, float roughness2, float normalization_term, float NoH, float LoH )
			{
				float d = NoH * NoH * roughness2_minus_one + 1.00001f;
				half LoH2 = LoH * LoH;
				half specularTerm = roughness2 / ((d * d) * max(0.1h, LoH2) * normalization_term);
				return specularTerm;
			}
			
			float3 CustomLightingPhysicallyBased( float3 diffuse, float3 specular, float3 radiance, float roughness2_minus_one, float roughness2, float normalization_term, float NoH, float LoH )
			{
				float3 color = diffuse;
				#ifndef _SPECULARHIGHLIGHTS_OFF
					color += specular * CustomDirectBRDFSpecular(roughness2_minus_one, roughness2, normalization_term, NoH, LoH);
				#endif // _SPECULARHIGHLIGHTS_OFF
				return color * radiance;
			}
			
			float3 AdditionalLighting14_g736( float3 position_ws, float3 normal_ws, float3 normal_normalized_ws, float3 view_dir_ws, float3 diffuse, float3 specular, float roughness2_minus_one, float roughness2, float normalization_term, float shadow_mask )
			{
				float3 color = 0;
				// 像素光
				#ifdef _ADDITIONAL_LIGHTS
				int numLights = GetAdditionalLightsCount();
				for(int lightIndex = 0; lightIndex < numLights; lightIndex++){
					Light light = GetAdditionalLight(lightIndex, position_ws, shadow_mask);
					
					half3 light_color = light.color;
					half3 light_dir_ws = light.direction;
					half light_attenuation = light.distanceAttenuation * light.shadowAttenuation;
					
					half NoL = saturate(dot(normal_normalized_ws, light_dir_ws));
					half3 radiance = light.color * (light_attenuation * NoL);
					
					float3 half_dir_ws = SafeNormalize(float3(light_dir_ws) + float3(view_dir_ws));
					float NoH = saturate(dot(normal_normalized_ws, half_dir_ws));
					half LoH = saturate(dot(light_dir_ws, half_dir_ws));
					
					color += CustomLightingPhysicallyBased(diffuse, specular, radiance, roughness2_minus_one, roughness2, normalization_term, NoH, LoH);
				}
				#endif
				// 顶点光
				#ifdef _ADDITIONAL_LIGHTS_VERTEX
					half3 vertexLight = VertexLighting(position_ws, normal_ws);
				    color += vertexLight * diffuse;
				#endif
				return color;
			}
			
			float3 MyCustomExpression16_g733( float direct_specular_color )
			{
				half3 color = half3(0,0,0);
				#ifdef _SUBTRACTIVE_ADDITIONAL_LIGHTING
				    color += direct_specular_color;
				#endif
				return color;
			}
			
			
			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord4.xyz = ase_worldTangent;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord5.xyz = ase_worldNormal;
				float ase_vertexTangentSign = v.ase_tangent.w * unity_WorldTransformParams.w;
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord6.xyz = ase_worldBitangent;
				OUTPUT_LIGHTMAP_UV( v.ase_texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy );
				OUTPUT_SH( ase_worldNormal, o.lightmapUVOrVertexSH.xyz );
				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord8 = screenPos;
				
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				o.ase_texcoord3.zw = v.ase_texcoord1.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord4.w = 0;
				o.ase_texcoord5.w = 0;
				o.ase_texcoord6.w = 0;
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
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
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
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord1 = v.ase_texcoord1;
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
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
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
				float4 _kDielectricSpec = float4(0.04,0.04,0.04,0.96);
				float2 appendResult323 = (float2(( IN.ase_texcoord3.xy.x * _Tile_UV.x ) , ( IN.ase_texcoord3.xy.y * _Tile_UV.y )));
				float2 AlbedoUV324 = appendResult323;
				float4 tex2DNode32 = tex2D( _SEMMap, AlbedoUV324 );
				float map_metallic38 = tex2DNode32.b;
				float clampResult56 = clamp( ( map_metallic38 * _MatcapAlbedoBlend ) , 0.0 , 1.0 );
				float surface_metallic_matcap60 = clampResult56;
				float lerpResult59 = lerp( ( _Metallic * map_metallic38 ) , 0.0 , surface_metallic_matcap60);
				float surface_metallic61 = lerpResult59;
				float input_metallic11_g734 = surface_metallic61;
				float func_brdf_metallic9_g740 = input_metallic11_g734;
				float func_brdf_one_minus_reflectivity16_g740 = ( _kDielectricSpec.w - ( _kDielectricSpec.w * func_brdf_metallic9_g740 ) );
				float4 tex2DNode22 = tex2D( _BaseMap, AlbedoUV324 );
				float3 map_base_color23 = (tex2DNode22).rgb;
				float3 temp_output_24_0 = ( map_base_color23 * (_BaseColor).rgb );
				float4 temp_output_18_0_g743 = float4( temp_output_24_0 , 0.0 );
				float damaged247 = _damaged;
				float clampResult9_g743 = clamp( ( damaged247 * 0.25 ) , 0.0 , 1.0 );
				float4 lerpResult11_g743 = lerp( temp_output_18_0_g743 , ( temp_output_18_0_g743 * 0.7 ) , clampResult9_g743);
				float2 damagedUV258 = ( IN.ase_texcoord3.zw * _DamagedTile );
				float4 temp_output_20_0_g743 = tex2D( _DamagedMap, damagedUV258 );
				float4 lerpResult3_g743 = lerp( lerpResult11_g743 , ( temp_output_20_0_g743.r * _Damaged_Color ) , temp_output_20_0_g743.r);
				float4 surface_base_color28 = lerpResult3_g743;
				float3 temp_output_257_0 = BlendNormalRNM( UnpackNormalScale( tex2D( _NormalMap, AlbedoUV324 ), 1.0f ) , UnpackNormalScale( tex2D( _DamagedMap_N, damagedUV258 ), 1.0f ) );
				float3 surface_normal_ts9 = (temp_output_257_0).xyz;
				float3 ase_worldTangent = IN.ase_texcoord4.xyz;
				float3 ase_worldNormal = IN.ase_texcoord5.xyz;
				float3 ase_worldBitangent = IN.ase_texcoord6.xyz;
				float3x3 ase_tangentToWorldFast = float3x3(ase_worldTangent.x,ase_worldBitangent.x,ase_worldNormal.x,ase_worldTangent.y,ase_worldBitangent.y,ase_worldNormal.y,ase_worldTangent.z,ase_worldBitangent.z,ase_worldNormal.z);
				float3 tangentToViewDir8_g744 = ASESafeNormalize( mul( UNITY_MATRIX_V, float4( mul( ase_tangentToWorldFast, surface_normal_ts9 ), 0 ) ).xyz );
				float3 surface_matcap_color29 = (( float4( ( (tex2D( _MatcapMap, ( ( tangentToViewDir8_g744 * 0.5 ) + 0.5 ).xy )).rgb * _MatcapIntensity ) , 0.0 ) * _MatcapColor )).rgb;
				float4 lerpResult64 = lerp( surface_base_color28 , float4( surface_matcap_color29 , 0.0 ) , surface_metallic_matcap60);
				float4 surface_albedo68 = lerpResult64;
				float3 input_albedo7_g734 = surface_albedo68.rgb;
				float3 func_brdf_albedo8_g740 = input_albedo7_g734;
				float3 func_brdf_diffuse23_g740 = ( func_brdf_one_minus_reflectivity16_g740 * func_brdf_albedo8_g740 );
				float3 brdf_diffuse61_g734 = func_brdf_diffuse23_g740;
				float3 func_brdf_dielectric_spec29_g740 = (_kDielectricSpec).xyz;
				float3 lerpResult24_g740 = lerp( func_brdf_dielectric_spec29_g740 , func_brdf_albedo8_g740 , func_brdf_metallic9_g740);
				float3 func_brdf_specular31_g740 = lerpResult24_g740;
				float3 brdf_specular41_g734 = func_brdf_specular31_g740;
				float map_smoothness36 = tex2DNode32.r;
				float surface_smoothness43 = ( map_smoothness36 * _Smoothness );
				float input_smoothness12_g734 = surface_smoothness43;
				float func_brdf_smoothness11_g740 = input_smoothness12_g734;
				float func_brdf_perceptual_roughness35_g740 = ( 1.0 - func_brdf_smoothness11_g740 );
				float func_brdf_roughness40_g740 = max( ( func_brdf_perceptual_roughness35_g740 * func_brdf_perceptual_roughness35_g740 ) , 0.0078125 );
				float func_brdf_roughness244_g740 = max( ( func_brdf_roughness40_g740 * func_brdf_roughness40_g740 ) , 6.103516E-05 );
				float brdf_roughness234_g734 = func_brdf_roughness244_g740;
				float3 tanToWorld0 = float3( ase_worldTangent.x, ase_worldBitangent.x, ase_worldNormal.x );
				float3 tanToWorld1 = float3( ase_worldTangent.y, ase_worldBitangent.y, ase_worldNormal.y );
				float3 tanToWorld2 = float3( ase_worldTangent.z, ase_worldBitangent.z, ase_worldNormal.z );
				float3 tanNormal12 = temp_output_257_0;
				float3 worldNormal12 = float3(dot(tanToWorld0,tanNormal12), dot(tanToWorld1,tanNormal12), dot(tanToWorld2,tanNormal12));
				float3 surface_normal_ws11 = worldNormal12;
				float3 temp_output_5_0_g734 = surface_normal_ws11;
				float3 normalizeResult10_g734 = ASESafeNormalize( temp_output_5_0_g734 );
				float3 input_normal_normalized_ws9_g734 = normalizeResult10_g734;
				float3 temp_output_21_0_g739 = input_normal_normalized_ws9_g734;
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = SafeNormalize( ase_worldViewDir );
				float3 temp_output_3_0_g739 = ase_worldViewDir;
				float3 temp_output_4_0_g739 = SafeNormalize(_MainLightPosition.xyz);
				float3 normalizeResult19_g739 = ASESafeNormalize( ( temp_output_3_0_g739 + temp_output_4_0_g739 ) );
				float dotResult13_g739 = dot( temp_output_21_0_g739 , normalizeResult19_g739 );
				float NoH11_g739 = saturate( dotResult13_g739 );
				float vector_NoH31_g734 = NoH11_g739;
				float temp_output_1_0_g742 = vector_NoH31_g734;
				float func_brdf_roughness2_minus_one52_g740 = ( func_brdf_roughness244_g740 - 1.0 );
				float brdf_roughness2_minus_one32_g734 = func_brdf_roughness2_minus_one52_g740;
				float temp_output_8_0_g742 = ( ( ( temp_output_1_0_g742 * temp_output_1_0_g742 ) * brdf_roughness2_minus_one32_g734 ) + 1.00001 );
				float dotResult8_g739 = dot( normalizeResult19_g739 , temp_output_4_0_g739 );
				float HoL1_g739 = saturate( dotResult8_g739 );
				float vector_HoL29_g734 = HoL1_g739;
				float temp_output_3_0_g742 = vector_HoL29_g734;
				float func_brdf_normalization_term49_g740 = ( ( func_brdf_roughness40_g740 * 4.0 ) + 2.0 );
				float brdf_normalization_term33_g734 = func_brdf_normalization_term49_g740;
				float direct_brdf_specular50_g734 = ( brdf_roughness234_g734 / ( ( temp_output_8_0_g742 * temp_output_8_0_g742 ) * ( max( ( temp_output_3_0_g742 * temp_output_3_0_g742 ) , 0.1 ) * brdf_normalization_term33_g734 ) ) );
				float3 temp_output_66_0_g734 = ( brdf_specular41_g734 * direct_brdf_specular50_g734 );
				#ifdef _SPECULARHIGHLIGHTS_ON
				float3 staticSwitch116_g734 = ( brdf_diffuse61_g734 + temp_output_66_0_g734 );
				#else
				float3 staticSwitch116_g734 = brdf_diffuse61_g734;
				#endif
				float4 input_position_cs139_g734 = IN.clipPos;
				float2 position_cs23_g735 = input_position_cs139_g734.xy;
				float3 main_light_color23_g735 = _MainLightColor.rgb;
				float lerpResult328 = lerp( 1.0 , tex2DNode32.g , _AO_Int);
				float map_ao37 = lerpResult328;
				float input_ao13_g734 = map_ao37;
				float input_ao23_g735 = input_ao13_g734;
				float3 main_light_color_ssao23_g735 = float3( 1,1,1 );
				float localCalcSSAO23_g735 = CalcSSAO23_g735( position_cs23_g735 , main_light_color23_g735 , input_ao23_g735 , main_light_color_ssao23_g735 );
				float3 main_light_color_ssao144_g734 = main_light_color_ssao23_g735;
				float ase_lightAtten = 0;
				Light ase_lightAtten_mainLight = GetMainLight( ShadowCoords );
				ase_lightAtten = ase_lightAtten_mainLight.distanceAttenuation * ase_lightAtten_mainLight.shadowAttenuation;
				float func_attenuation171_g734 = ase_lightAtten;
				float dotResult16_g739 = dot( temp_output_21_0_g739 , temp_output_4_0_g739 );
				float NoL20_g739 = saturate( dotResult16_g739 );
				float vector_NoL52_g734 = NoL20_g739;
				float3 radiance73_g734 = ( main_light_color_ssao144_g734 * func_attenuation171_g734 * vector_NoL52_g734 );
				float3 direct_color91_g734 = ( staticSwitch116_g734 * radiance73_g734 );
				float3 normalWS167_g734 = input_normal_normalized_ws9_g734;
				float3 bakedGI108_g734 = ASEIndirectDiffuse( IN.lightmapUVOrVertexSH.xy, input_normal_normalized_ws9_g734);
				float3 bakedGI167_g734 = bakedGI108_g734;
				float3 positionWS167_g734 = WorldPosition;
				float3 localMixRealtimeAndBakedGI167_g734 = MixRealtimeAndBakedGI167_g734( normalWS167_g734 , bakedGI167_g734 , positionWS167_g734 );
				float input_ao_ssao143_g734 = localCalcSSAO23_g735;
				float3 indirect_diffuse_color78_g734 = ( localMixRealtimeAndBakedGI167_g734 * brdf_diffuse61_g734 * input_ao_ssao143_g734 );
				ase_worldViewDir = normalize(ase_worldViewDir);
				half3 reflectVector109_g734 = reflect( -ase_worldViewDir, input_normal_normalized_ws9_g734 );
				float3 indirectSpecular109_g734 = GlossyEnvironmentReflection( reflectVector109_g734, 1.0 - input_smoothness12_g734, input_ao_ssao143_g734 );
				float func_brdf_reflectivity20_g740 = ( 1.0 - func_brdf_one_minus_reflectivity16_g740 );
				float func_brdf_grazing_term57_g740 = saturate( ( func_brdf_smoothness11_g740 + func_brdf_reflectivity20_g740 ) );
				float brdf_grazing_term37_g734 = func_brdf_grazing_term57_g740;
				float3 temp_cast_7 = (brdf_grazing_term37_g734).xxx;
				float dotResult14_g739 = dot( temp_output_21_0_g739 , temp_output_3_0_g739 );
				float NoV2_g739 = saturate( dotResult14_g739 );
				float vector_NoV28_g734 = NoV2_g739;
				float temp_output_42_0_g734 = ( 1.0 - vector_NoV28_g734 );
				float3 lerpResult8_g738 = lerp( brdf_specular41_g734 , temp_cast_7 , ( temp_output_42_0_g734 * temp_output_42_0_g734 * temp_output_42_0_g734 * temp_output_42_0_g734 ));
				float3 indirect_specular_term59_g734 = ( ( 1.0 / ( brdf_roughness234_g734 + 1.0 ) ) * lerpResult8_g738 );
				float3 indirect_specular_color74_g734 = ( indirectSpecular109_g734 * indirect_specular_term59_g734 );
				float3 indirect_color92_g734 = ( indirect_diffuse_color78_g734 + indirect_specular_color74_g734 );
				float3 position_ws14_g736 = WorldPosition;
				float3 input_normal_ws8_g734 = temp_output_5_0_g734;
				float3 normal_ws14_g736 = input_normal_ws8_g734;
				float3 normal_normalized_ws14_g736 = input_normal_normalized_ws9_g734;
				float3 view_dir_ws14_g736 = ase_worldViewDir;
				float3 diffuse14_g736 = brdf_diffuse61_g734;
				float3 specular14_g736 = brdf_specular41_g734;
				float roughness2_minus_one14_g736 = brdf_roughness2_minus_one32_g734;
				float roughness214_g736 = brdf_roughness234_g734;
				float normalization_term14_g736 = brdf_normalization_term33_g734;
				float shadow_mask14_g736 = 1;
				float3 localAdditionalLighting14_g736 = AdditionalLighting14_g736( position_ws14_g736 , normal_ws14_g736 , normal_normalized_ws14_g736 , view_dir_ws14_g736 , diffuse14_g736 , specular14_g736 , roughness2_minus_one14_g736 , roughness214_g736 , normalization_term14_g736 , shadow_mask14_g736 );
				float3 additional_color90_g734 = localAdditionalLighting14_g736;
				float4 surface_emission_from_base379 = ( tex2DNode22 * tex2DNode22.a * _EmissionColor );
				float3 temp_output_50_0 = ( (surface_emission_from_base379).rgb * _EmissionIntensity );
				float4 screenPos = IN.ase_texcoord8;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float4 lerpResult366 = lerp( float4( 0,0,0,0 ) , ( tex2D( _PlanarReflectionTexture, ase_screenPosNorm.xy ) * surface_smoothness43 ) , _ReflectionAmount);
				float3 planar_reflection_color368 = (lerpResult366).rgb;
				#ifdef _PLANARREFLECTION_ON_ON
				float3 staticSwitch374 = ( temp_output_50_0 + planar_reflection_color368 );
				#else
				float3 staticSwitch374 = temp_output_50_0;
				#endif
				float3 surface_emission75 = staticSwitch374;
				float3 input_emission15_g734 = surface_emission75;
				float3 direct_specular_color127_g734 = temp_output_66_0_g734;
				float direct_specular_color16_g733 = direct_specular_color127_g734.x;
				float3 localMyCustomExpression16_g733 = MyCustomExpression16_g733( direct_specular_color16_g733 );
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = ( ( direct_color91_g734 + indirect_color92_g734 + additional_color90_g734 + input_emission15_g734 ) + localMyCustomExpression16_g733 );
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
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off

			HLSLPROGRAM
			
			#pragma multi_compile_instancing
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_SRP_VERSION 999999

			
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma shader_feature _ _SUBTRACTIVE_ADDITIONAL_LIGHTING


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
			float4 _BaseColor;
			float4 _Damaged_Color;
			float4 _MatcapColor;
			float4 _EmissionColor;
			float2 _Tile_UV;
			float _Metallic;
			float _MatcapAlbedoBlend;
			float _damaged;
			float _DamagedTile;
			float _MatcapIntensity;
			float _Smoothness;
			float _AO_Int;
			float _EmissionIntensity;
			float _ReflectionAmount;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			

			
			float3 _LightDirection;

			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				
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

				float3 normalWS = TransformObjectToWorldDir( v.ase_normal );

				float4 clipPos = TransformWorldToHClip( ApplyShadowBias( positionWS, normalWS, _LightDirection ) );

				#if UNITY_REVERSED_Z
					clipPos.z = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
				#else
					clipPos.z = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				o.clipPos = clipPos;

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

				
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					#ifdef _ALPHATEST_SHADOW_ON
						clip(Alpha - AlphaClipThresholdShadow);
					#else
						clip(Alpha - AlphaClipThreshold);
					#endif
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
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
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_SRP_VERSION 999999

			
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma shader_feature _ _SUBTRACTIVE_ADDITIONAL_LIGHTING


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
			float4 _BaseColor;
			float4 _Damaged_Color;
			float4 _MatcapColor;
			float4 _EmissionColor;
			float2 _Tile_UV;
			float _Metallic;
			float _MatcapAlbedoBlend;
			float _damaged;
			float _DamagedTile;
			float _MatcapIntensity;
			float _Smoothness;
			float _AO_Int;
			float _EmissionIntensity;
			float _ReflectionAmount;
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
2041.6;162.4;2048;962.2;-823.61;-212.3954;1;True;True
Node;AmplifyShaderEditor.CommentaryNode;317;-1073.08,-679.7861;Inherit;False;1024.94;574.3911;damaged;5;249;112;259;161;316;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;30;-2952.93,-1022.582;Inherit;False;1765.156;628.0167;Base Color;12;378;379;51;25;27;23;49;22;26;48;24;325;;0.8018868,0.3139462,0.3139462,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;31;-2846.538,-1565.208;Inherit;False;2120.911;486.5392;Matcap Color;10;29;20;21;17;19;18;16;14;15;66;;0.6771602,0.8301887,0.04307583,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;39;-2609.352,2421.469;Inherit;False;754.8623;477.759;SEM Map;4;36;38;32;329;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;365;-2868.045,4988.377;Inherit;False;1744.958;381.041;Planar Reflection;8;373;372;371;370;369;368;367;366;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;13;-2664.882,1865.672;Inherit;False;1487.556;394.3;Normal Map;7;10;9;7;12;6;11;327;;0.2748754,0.2997605,0.8207547,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;76;-2713.204,3530.553;Inherit;False;1366.848;377.0713;Emission Color;8;375;71;380;50;52;376;75;374;;0.03764683,0.8867924,0.5418643,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;77;-2697.988,4243.633;Inherit;False;1389.889;490.8933;Metallic;9;54;56;57;53;55;58;60;59;61;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;44;-2624.682,3000.48;Inherit;False;813.5293;301.0519;Smoothness;4;40;42;41;43;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;69;-3948.258,-1064.741;Inherit;False;826.4879;411.2901;Albedo Color;5;64;67;62;63;68;;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;82;1396.938,911.056;Inherit;False;43;surface_smoothness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;15;-2773.395,-1471.608;Inherit;False;9;surface_normal_ts;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;42;-2561.613,3185.531;Inherit;False;Property;_Smoothness;Smoothness;12;0;Create;True;0;0;0;False;0;False;0.5;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;29;-966.6261,-1476.921;Inherit;False;surface_matcap_color;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;81;1404.938,818.0559;Inherit;False;61;surface_metallic;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;83;1418.938,1003.056;Inherit;False;Constant;_Float2;Float 2;12;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;22;-2728.379,-973.6469;Inherit;True;Property;_BaseMap;Base Map;3;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;324;-2947.007,150.6621;Inherit;False;AlbedoUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ColorNode;21;-1555.248,-1318.553;Inherit;False;Property;_MatcapColor;Matcap Color;19;0;Create;True;0;0;0;False;0;False;1,1,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;321;-3305.073,226.771;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;225;-3532.405,-278.5883;Inherit;False;1;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;80;1424.938,612.056;Inherit;False;11;surface_normal_ws;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;318;-3558.592,70.93976;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;32;-2558.352,2508.907;Inherit;True;Property;_SEMMap;SOM Map (S=smoothness, O=AO, M=metallic);9;1;[NoScaleOffset];Create;False;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;331;1419.816,1094.696;Inherit;False;37;map_ao;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;10;-1720.726,1936.772;Inherit;False;True;True;True;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;328;-1888.579,2567.728;Inherit;False;3;0;FLOAT;1;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;367;-2543.439,5038.377;Inherit;True;Global;_PlanarReflectionTexture;_PlanarReflectionTexture;27;0;Create;True;0;0;0;True;0;False;-1;None;None;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;26;-1592.32,-958.0432;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;58;-2632.457,4293.633;Inherit;False;Property;_Metallic;Metallic;13;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;366;-1829.28,5043.445;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;68;-3347.771,-930.3785;Inherit;False;surface_albedo;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;260;-2585.667,1636.842;Inherit;False;258;damagedUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;112;-813.9421,-629.7861;Inherit;True;Property;_DamagedMap;Damaged Map;20;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;-1;d3d029f04d593c349bdd90495d0b50a2;d3d029f04d593c349bdd90495d0b50a2;True;1;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;23;-2155.269,-961.0228;Inherit;False;map_base_color;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;79;1428.938,502.056;Inherit;False;68;surface_albedo;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;9;-1486.726,1938.772;Inherit;False;surface_normal_ts;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;379;-2197.373,-658.9411;Inherit;False;surface_emission_from_base;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;376;-2317.47,3809.268;Inherit;False;368;planar_reflection_color;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;25;-2631.701,-782.417;Inherit;False;Property;_BaseColor;Base Color;7;0;Create;True;0;0;0;False;0;False;1,1,1,0;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;51;-2625.799,-580.2484;Inherit;False;Property;_EmissionColor;Emission Color;14;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,0;0,0,0,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StaticSwitch;374;-1877.474,3607.268;Inherit;False;Property;_PlanarReflection_On;PlanarReflection_On;24;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;50;-2142.487,3636.721;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;71;-2364.177,3591.399;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;75;-1578.642,3599.959;Inherit;False;surface_emission;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;380;-2665.139,3595.626;Inherit;False;379;surface_emission_from_base;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;53;-2602.683,4441.195;Inherit;False;38;map_metallic;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;378;-2352.895,-665.1728;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;161;-757.1568,-416.8411;Inherit;False;Property;_Damaged_Color;Damaged_Color;25;0;Create;True;0;0;0;False;0;False;0.3960784,0.2745098,0.1764706,0;0.3960782,0.2745095,0.1764703,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;38;-2139.676,2675.881;Inherit;False;map_metallic;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;90;1397.277,715.0422;Inherit;False;75;surface_emission;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;14;-2516.092,-1472.861;Inherit;False;sha_com_func_matcap_uv;-1;;744;b00a8b7be669c054e8bc5f643d726043;0;1;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;372;-1599.94,5042.414;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;57;-2254.487,4350.586;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;322;-3541.073,198.771;Inherit;False;Property;_Tile_UV;Tile_UV;10;0;Create;True;0;0;0;False;0;False;1,1;1,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.GetLocalVarNode;67;-3898.258,-769.4509;Inherit;False;60;surface_metallic_matcap;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;49;-2094.788,-829.7516;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;36;-2143.128,2464.897;Inherit;False;map_smoothness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;375;-2022.474,3766.268;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;27;-1935.162,-730.4653;Inherit;False;Constant;_BaseColorIntensity;Base Color Intensity;8;0;Create;True;0;0;0;False;0;False;1;1;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;259;-1033.48,-603.1757;Inherit;False;258;damagedUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;-1326.862,-1475.106;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;54;-2358.04,4512.385;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;320;-3306.073,84.77101;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;64;-3565.386,-931.4162;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;7;-2340.726,1916.672;Inherit;True;Property;_NormalMap;Normal Map;8;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;-1;None;None;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;28;589.7744,-881.5928;Inherit;False;surface_base_color;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;24;-1873.669,-956.0432;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;63;-3893.134,-1014.741;Inherit;False;28;surface_base_color;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;371;-2066.145,5213.544;Inherit;False;Property;_ReflectionAmount;ReflectionAmount;21;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;66;-1172.36,-1477.254;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;369;-2111.44,5055.377;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ComponentMaskNode;48;-2380.593,-964.443;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;11;-1463.726,2077.772;Inherit;False;surface_normal_ws;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;325;-2917.021,-952.9814;Inherit;False;324;AlbedoUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;258;-3112.8,-261.6873;Inherit;False;damagedUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;43;-2067.153,3063.549;Inherit;False;surface_smoothness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;327;-2598.851,1967.633;Inherit;False;324;AlbedoUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;61;-1555.099,4350.197;Inherit;False;surface_metallic;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;59;-1739.225,4355.159;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;18;-1859.171,-1479.839;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;247;-3251.3,-430.5603;Inherit;False;damaged;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;56;-2189.767,4512.385;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;55;-2647.988,4618.526;Inherit;False;Property;_MatcapAlbedoBlend;Matcap Albedo Blend;17;0;Create;True;0;0;0;False;0;False;0;0;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;256;-2370.984,1611.607;Inherit;True;Property;_DamagedMap_N;Damaged Map_N;22;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;-1;0e441557edfed2b4a9aec9a6e93aa0a3;0e441557edfed2b4a9aec9a6e93aa0a3;True;1;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;40;-2574.682,3050.48;Inherit;False;36;map_smoothness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;117;-3480.954,-430.9917;Inherit;False;Property;_damaged;damaged(0~4 state);26;0;Create;False;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;52;-2552.089,3708.496;Inherit;False;Property;_EmissionIntensity;Emission Intensity;15;0;Create;True;0;0;0;False;0;False;0;0;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;323;-3104.073,153.771;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FunctionNode;316;-415.1401,-628.2369;Inherit;False;sha_sc_func_damaged;0;;743;348ed7f1b74ac6245a7c087abc509282;0;4;18;COLOR;0,0,0,0;False;20;COLOR;0,0,0,0;False;13;COLOR;0,0,0,0;False;16;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.WorldNormalVector;12;-1735.726,2069.772;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TextureCoordinatesNode;6;-2612.882,2056.625;Inherit;False;0;7;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;60;-1991.866,4527.001;Inherit;False;surface_metallic_matcap;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;370;-2818.045,5065.455;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BlendNormalsNode;257;-1991.603,1689.767;Inherit;False;1;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;326;-2799.788,2535.529;Inherit;False;324;AlbedoUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;37;-1630.523,2558.816;Inherit;False;map_ao;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;224;-3293.405,-259.1584;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;368;-1395.84,5046.313;Inherit;False;planar_reflection_color;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;373;-2356.439,5272.377;Inherit;False;43;surface_smoothness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateFragmentDataNode;361;1445.042,1211.03;Inherit;False;0;1;clipPos;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;19;-1881.025,-1333.085;Inherit;False;Property;_MatcapIntensity;MatcapIntensity;18;0;Create;True;0;0;0;False;0;False;1;1;0;8;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;17;-1582.313,-1480.88;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;329;-2205.58,2778.728;Inherit;False;Property;_AO_Int;AO_Int;11;0;Create;True;0;0;0;False;0;False;0.5;0.5;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;41;-2271.907,3065.727;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;16;-2214.193,-1495.406;Inherit;True;Property;_MatcapMap;Matcap Map;16;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;249;-682.1533,-221.3949;Inherit;False;247;damaged;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;226;-3530.933,-146.2302;Inherit;False;Property;_DamagedTile;DamagedTile;23;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;377;1848.021,386.5345;Inherit;False;368;planar_reflection_color;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;384;1779.841,660.4728;Inherit;False;sha_sc_func_base_pbr_lighting;4;;733;b007fbbd74b41fb44ad54b3f89e16d09;0;7;2;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;6;FLOAT;0;False;1;FLOAT;0;False;5;FLOAT;0;False;39;FLOAT4;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;62;-3895.672,-908.1804;Inherit;False;29;surface_matcap_color;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;5;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;1771.368,591.4717;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;2196.484,644.7017;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;ase/scene/sha_sc_urp_metallic;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;2;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;22;Surface;0;  Blend;0;Two Sided;1;Cast Shadows;1;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;1;LOD CrossFade;0;Built-in Fog;1;DOTS Instancing;0;Meta Pass;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;False;True;True;True;False;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
WireConnection;29;0;66;0
WireConnection;22;1;325;0
WireConnection;324;0;323;0
WireConnection;321;0;318;2
WireConnection;321;1;322;2
WireConnection;32;1;326;0
WireConnection;10;0;257;0
WireConnection;328;1;32;2
WireConnection;328;2;329;0
WireConnection;367;1;370;0
WireConnection;26;0;24;0
WireConnection;26;1;27;0
WireConnection;366;1;369;0
WireConnection;366;2;371;0
WireConnection;68;0;64;0
WireConnection;112;1;259;0
WireConnection;23;0;48;0
WireConnection;9;0;10;0
WireConnection;379;0;378;0
WireConnection;374;1;50;0
WireConnection;374;0;375;0
WireConnection;50;0;71;0
WireConnection;50;1;52;0
WireConnection;71;0;380;0
WireConnection;75;0;374;0
WireConnection;378;0;22;0
WireConnection;378;1;22;4
WireConnection;378;2;51;0
WireConnection;38;0;32;3
WireConnection;14;1;15;0
WireConnection;372;0;366;0
WireConnection;57;0;58;0
WireConnection;57;1;53;0
WireConnection;49;0;25;0
WireConnection;36;0;32;1
WireConnection;375;0;50;0
WireConnection;375;1;376;0
WireConnection;20;0;17;0
WireConnection;20;1;21;0
WireConnection;54;0;53;0
WireConnection;54;1;55;0
WireConnection;320;0;318;1
WireConnection;320;1;322;1
WireConnection;64;0;63;0
WireConnection;64;1;62;0
WireConnection;64;2;67;0
WireConnection;7;1;327;0
WireConnection;28;0;316;0
WireConnection;24;0;23;0
WireConnection;24;1;49;0
WireConnection;66;0;20;0
WireConnection;369;0;367;0
WireConnection;369;1;373;0
WireConnection;48;0;22;0
WireConnection;11;0;12;0
WireConnection;258;0;224;0
WireConnection;43;0;41;0
WireConnection;61;0;59;0
WireConnection;59;0;57;0
WireConnection;59;2;60;0
WireConnection;18;0;16;0
WireConnection;247;0;117;0
WireConnection;56;0;54;0
WireConnection;256;1;260;0
WireConnection;323;0;320;0
WireConnection;323;1;321;0
WireConnection;316;18;24;0
WireConnection;316;20;112;0
WireConnection;316;13;161;0
WireConnection;316;16;249;0
WireConnection;12;0;257;0
WireConnection;60;0;56;0
WireConnection;257;0;7;0
WireConnection;257;1;256;0
WireConnection;37;0;328;0
WireConnection;224;0;225;0
WireConnection;224;1;226;0
WireConnection;368;0;372;0
WireConnection;17;0;18;0
WireConnection;17;1;19;0
WireConnection;41;0;40;0
WireConnection;41;1;42;0
WireConnection;16;1;14;0
WireConnection;384;2;79;0
WireConnection;384;4;80;0
WireConnection;384;3;90;0
WireConnection;384;6;81;0
WireConnection;384;1;82;0
WireConnection;384;5;331;0
WireConnection;384;39;361;0
WireConnection;2;2;384;0
ASEEND*/
//CHKSM=9F7D27B1AF3B4AC1E6E246EDABB67D5AA6AA8E54