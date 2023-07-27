// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "scene/cover_trans/sha_sc_blend"
{
	Properties
	{
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin]_IDMap("ID Map", 2D) = "white" {}
		_NormalMap("Normal Map", 2D) = "bump" {}
		_Tex_Tile("Tex_Tile", Vector) = (0,0,0,0)
		_R_Color("R_Color", Color) = (1,1,1,0)
		_R_Color_Smoothness("R_Color_Smoothness", Range( 0 , 1)) = 0
		_R_Color_Metallic("R_Color_Metallic", Range( 0 , 1)) = 0
		_G_Color("G_Color", Color) = (1,1,1,0)
		_G_Color_Smoothness("G_Color_Smoothness", Range( 0 , 1)) = 0
		_G_Color_Metallic("G_Color_Metallic", Range( 0 , 1)) = 0
		_B_Color("B_Color", Color) = (1,1,1,0)
		_B_Color_Smoothness("B_Color_Smoothness", Range( 0 , 1)) = 0
		_B_Color_Metallic("B_Color_Metallic", Range( 0 , 1)) = 0
		_A_Color("A_Color", Color) = (1,1,1,0)
		_A_Color_Smoothness("A_Color_Smoothness", Range( 0 , 1)) = 0
		_A_Color_Metallic("A_Color_Metallic", Range( 0 , 1)) = 0
		_EmissionMap("Emission Map", 2D) = "black" {}
		[HDR]_EmissionColor("Emission Color", Color) = (1,1,1,0)
		_MatcapMap("Matcap Map", 2D) = "white" {}
		_MatcapIntensity("MatcapIntensity", Float) = 1.5
		_BlendMapcap("BlendMapcap", Range( 0 , 1)) = 0
		_ReflectionAmount("ReflectionAmount", Range( 0 , 1)) = 0
		[Toggle(_PLANARREFLECTION_ON_ON)] _PlanarReflection_On("PlanarReflection_On", Float) = 0
		[ASEEnd][Toggle(_SPECULARHIGHLIGHTS_ON)] _SpecularHighlights("Specular Highlights", Float) = 0

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
			#pragma shader_feature _ _SUBTRACTIVE_ADDITIONAL_LIGHTING


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_tangent : TANGENT;
				float4 texcoord1 : TEXCOORD1;
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
			float4 _R_Color;
			float4 _Tex_Tile;
			float4 _A_Color;
			float4 _B_Color;
			float4 _G_Color;
			float4 _EmissionColor;
			float _R_Color_Smoothness;
			float _G_Color_Smoothness;
			float _B_Color_Smoothness;
			float _A_Color_Smoothness;
			float _A_Color_Metallic;
			float _MatcapIntensity;
			float _R_Color_Metallic;
			float _G_Color_Metallic;
			float _B_Color_Metallic;
			float _BlendMapcap;
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
			float TransparencyRange;
			float TransparencyBaseAlpha;
			float TransparencySoft;
			sampler2D _IDMap;
			sampler2D _MatcapMap;
			sampler2D _NormalMap;
			sampler2D _EmissionMap;
			sampler2D _PlanarReflectionTexture;
			float4 PlayerPosition;
			float4 TransparencyRangeScaleOffset;


			real3 ASESafeNormalize(float3 inVec)
			{
				real dp3 = max(FLT_MIN, dot(inVec, inVec));
				return inVec* rsqrt( dp3);
			}
			
			float CalcSSAO23_g261( float2 position_cs, float3 main_light_color, float input_ao, out float3 main_light_color_ssao )
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
			
			float3 AdditionalLighting14_g260( float3 position_ws, float3 normal_ws, float3 normal_normalized_ws, float3 view_dir_ws, float3 diffuse, float3 specular, float roughness2_minus_one, float roughness2, float normalization_term, float shadow_mask )
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
			
			float3 MyCustomExpression16_g184( float direct_specular_color )
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
				OUTPUT_LIGHTMAP_UV( v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy );
				OUTPUT_SH( ase_worldNormal, o.lightmapUVOrVertexSH.xyz );
				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord8 = screenPos;
				
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;
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
				float4 ase_tangent : TANGENT;
				float4 texcoord1 : TEXCOORD1;

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
				o.ase_tangent = v.ase_tangent;
				o.texcoord1 = v.texcoord1;
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
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
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
				float2 appendResult9 = (float2(_Tex_Tile.x , _Tex_Tile.y));
				float2 appendResult10 = (float2(_Tex_Tile.z , _Tex_Tile.w));
				float2 texCoord7 = IN.ase_texcoord3.xy * appendResult9 + appendResult10;
				float2 uv11 = texCoord7;
				float4 tex2DNode33 = tex2D( _IDMap, uv11 );
				float id_b41 = tex2DNode33.b;
				float lerpResult50 = lerp( _A_Color_Metallic , _B_Color_Metallic , id_b41);
				float id_g40 = tex2DNode33.g;
				float lerpResult52 = lerp( lerpResult50 , _G_Color_Metallic , id_g40);
				float id_r39 = tex2DNode33.r;
				float lerpResult55 = lerp( lerpResult52 , _R_Color_Metallic , id_r39);
				float surface_metallic71 = saturate( lerpResult55 );
				float input_metallic11_g254 = surface_metallic71;
				float func_brdf_metallic9_g258 = input_metallic11_g254;
				float func_brdf_one_minus_reflectivity16_g258 = ( _kDielectricSpec.w - ( _kDielectricSpec.w * func_brdf_metallic9_g258 ) );
				float4 lerpResult42 = lerp( _A_Color , _B_Color , id_b41);
				float4 lerpResult45 = lerp( lerpResult42 , _G_Color , id_g40);
				float4 lerpResult46 = lerp( lerpResult45 , _R_Color , id_r39);
				float3 surface_base_color72 = (lerpResult46).rgb;
				float3 temp_output_15_0 = (UnpackNormalScale( tex2D( _NormalMap, uv11 ), 1.0f )).xyz;
				float3 surface_normal_ts14 = temp_output_15_0;
				float3 ase_worldTangent = IN.ase_texcoord4.xyz;
				float3 ase_worldNormal = IN.ase_texcoord5.xyz;
				float3 ase_worldBitangent = IN.ase_texcoord6.xyz;
				float3x3 ase_tangentToWorldFast = float3x3(ase_worldTangent.x,ase_worldBitangent.x,ase_worldNormal.x,ase_worldTangent.y,ase_worldBitangent.y,ase_worldNormal.y,ase_worldTangent.z,ase_worldBitangent.z,ase_worldNormal.z);
				float3 tangentToViewDir8_g183 = ASESafeNormalize( mul( UNITY_MATRIX_V, float4( mul( ase_tangentToWorldFast, surface_normal_ts14 ), 0 ) ).xyz );
				float3 matcap_uv20 = ( ( tangentToViewDir8_g183 * 0.5 ) + 0.5 );
				float lerpResult77 = lerp( 0.0 , surface_metallic71 , _BlendMapcap);
				float4 lerpResult80 = lerp( float4( surface_base_color72 , 0.0 ) , ( ( tex2D( _MatcapMap, matcap_uv20.xy ) * float4( surface_base_color72 , 0.0 ) ) * _MatcapIntensity ) , lerpResult77);
				float4 surface_albedo31 = lerpResult80;
				float3 input_albedo7_g254 = surface_albedo31.rgb;
				float3 func_brdf_albedo8_g258 = input_albedo7_g254;
				float3 func_brdf_diffuse23_g258 = ( func_brdf_one_minus_reflectivity16_g258 * func_brdf_albedo8_g258 );
				float3 brdf_diffuse61_g254 = func_brdf_diffuse23_g258;
				float3 func_brdf_dielectric_spec29_g258 = (_kDielectricSpec).xyz;
				float3 lerpResult24_g258 = lerp( func_brdf_dielectric_spec29_g258 , func_brdf_albedo8_g258 , func_brdf_metallic9_g258);
				float3 func_brdf_specular31_g258 = lerpResult24_g258;
				float3 brdf_specular41_g254 = func_brdf_specular31_g258;
				float lerpResult62 = lerp( _A_Color_Smoothness , _B_Color_Smoothness , id_b41);
				float lerpResult64 = lerp( lerpResult62 , _G_Color_Smoothness , id_g40);
				float lerpResult67 = lerp( lerpResult64 , _R_Color_Smoothness , id_r39);
				float surface_smoothness70 = saturate( lerpResult67 );
				float input_smoothness12_g254 = surface_smoothness70;
				float func_brdf_smoothness11_g258 = input_smoothness12_g254;
				float func_brdf_perceptual_roughness35_g258 = ( 1.0 - func_brdf_smoothness11_g258 );
				float func_brdf_roughness40_g258 = max( ( func_brdf_perceptual_roughness35_g258 * func_brdf_perceptual_roughness35_g258 ) , 0.0078125 );
				float func_brdf_roughness244_g258 = max( ( func_brdf_roughness40_g258 * func_brdf_roughness40_g258 ) , 6.103516E-05 );
				float brdf_roughness234_g254 = func_brdf_roughness244_g258;
				float3 tanToWorld0 = float3( ase_worldTangent.x, ase_worldBitangent.x, ase_worldNormal.x );
				float3 tanToWorld1 = float3( ase_worldTangent.y, ase_worldBitangent.y, ase_worldNormal.y );
				float3 tanToWorld2 = float3( ase_worldTangent.z, ase_worldBitangent.z, ase_worldNormal.z );
				float3 tanNormal87 = temp_output_15_0;
				float3 worldNormal87 = float3(dot(tanToWorld0,tanNormal87), dot(tanToWorld1,tanNormal87), dot(tanToWorld2,tanNormal87));
				float3 surface_normal_ws86 = worldNormal87;
				float3 temp_output_5_0_g254 = surface_normal_ws86;
				float3 normalizeResult10_g254 = ASESafeNormalize( temp_output_5_0_g254 );
				float3 input_normal_normalized_ws9_g254 = normalizeResult10_g254;
				float3 temp_output_21_0_g255 = input_normal_normalized_ws9_g254;
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = SafeNormalize( ase_worldViewDir );
				float3 temp_output_3_0_g255 = ase_worldViewDir;
				float3 temp_output_4_0_g255 = SafeNormalize(_MainLightPosition.xyz);
				float3 normalizeResult19_g255 = ASESafeNormalize( ( temp_output_3_0_g255 + temp_output_4_0_g255 ) );
				float dotResult13_g255 = dot( temp_output_21_0_g255 , normalizeResult19_g255 );
				float NoH11_g255 = saturate( dotResult13_g255 );
				float vector_NoH31_g254 = NoH11_g255;
				float temp_output_1_0_g257 = vector_NoH31_g254;
				float func_brdf_roughness2_minus_one52_g258 = ( func_brdf_roughness244_g258 - 1.0 );
				float brdf_roughness2_minus_one32_g254 = func_brdf_roughness2_minus_one52_g258;
				float temp_output_8_0_g257 = ( ( ( temp_output_1_0_g257 * temp_output_1_0_g257 ) * brdf_roughness2_minus_one32_g254 ) + 1.00001 );
				float dotResult8_g255 = dot( normalizeResult19_g255 , temp_output_4_0_g255 );
				float HoL1_g255 = saturate( dotResult8_g255 );
				float vector_HoL29_g254 = HoL1_g255;
				float temp_output_3_0_g257 = vector_HoL29_g254;
				float func_brdf_normalization_term49_g258 = ( ( func_brdf_roughness40_g258 * 4.0 ) + 2.0 );
				float brdf_normalization_term33_g254 = func_brdf_normalization_term49_g258;
				float direct_brdf_specular50_g254 = ( brdf_roughness234_g254 / ( ( temp_output_8_0_g257 * temp_output_8_0_g257 ) * ( max( ( temp_output_3_0_g257 * temp_output_3_0_g257 ) , 0.1 ) * brdf_normalization_term33_g254 ) ) );
				float3 temp_output_66_0_g254 = ( brdf_specular41_g254 * direct_brdf_specular50_g254 );
				#ifdef _SPECULARHIGHLIGHTS_ON
				float3 staticSwitch116_g254 = ( brdf_diffuse61_g254 + temp_output_66_0_g254 );
				#else
				float3 staticSwitch116_g254 = brdf_diffuse61_g254;
				#endif
				float4 input_position_cs139_g254 = half4(0,0,0,0);
				float2 position_cs23_g261 = input_position_cs139_g254.xy;
				float3 main_light_color23_g261 = _MainLightColor.rgb;
				float input_ao13_g254 = 1.0;
				float input_ao23_g261 = input_ao13_g254;
				float3 main_light_color_ssao23_g261 = float3( 1,1,1 );
				float localCalcSSAO23_g261 = CalcSSAO23_g261( position_cs23_g261 , main_light_color23_g261 , input_ao23_g261 , main_light_color_ssao23_g261 );
				float3 main_light_color_ssao144_g254 = main_light_color_ssao23_g261;
				float ase_lightAtten = 0;
				Light ase_lightAtten_mainLight = GetMainLight( ShadowCoords );
				ase_lightAtten = ase_lightAtten_mainLight.distanceAttenuation * ase_lightAtten_mainLight.shadowAttenuation;
				float dotResult16_g255 = dot( temp_output_21_0_g255 , temp_output_4_0_g255 );
				float NoL20_g255 = saturate( dotResult16_g255 );
				float vector_NoL52_g254 = NoL20_g255;
				float3 radiance73_g254 = ( main_light_color_ssao144_g254 * ase_lightAtten * vector_NoL52_g254 );
				float3 direct_color91_g254 = ( staticSwitch116_g254 * radiance73_g254 );
				float3 bakedGI108_g254 = ASEIndirectDiffuse( IN.lightmapUVOrVertexSH.xy, input_normal_normalized_ws9_g254);
				float input_ao_ssao143_g254 = localCalcSSAO23_g261;
				float3 indirect_diffuse_color78_g254 = ( bakedGI108_g254 * brdf_diffuse61_g254 * input_ao_ssao143_g254 );
				ase_worldViewDir = normalize(ase_worldViewDir);
				half3 reflectVector109_g254 = reflect( -ase_worldViewDir, input_normal_normalized_ws9_g254 );
				float3 indirectSpecular109_g254 = GlossyEnvironmentReflection( reflectVector109_g254, 1.0 - input_smoothness12_g254, input_ao_ssao143_g254 );
				float func_brdf_reflectivity20_g258 = ( 1.0 - func_brdf_one_minus_reflectivity16_g258 );
				float func_brdf_grazing_term57_g258 = saturate( ( func_brdf_smoothness11_g258 + func_brdf_reflectivity20_g258 ) );
				float brdf_grazing_term37_g254 = func_brdf_grazing_term57_g258;
				float3 temp_cast_6 = (brdf_grazing_term37_g254).xxx;
				float dotResult14_g255 = dot( temp_output_21_0_g255 , temp_output_3_0_g255 );
				float NoV2_g255 = saturate( dotResult14_g255 );
				float vector_NoV28_g254 = NoV2_g255;
				float temp_output_42_0_g254 = ( 1.0 - vector_NoV28_g254 );
				float3 lerpResult8_g256 = lerp( brdf_specular41_g254 , temp_cast_6 , ( temp_output_42_0_g254 * temp_output_42_0_g254 * temp_output_42_0_g254 * temp_output_42_0_g254 ));
				float3 indirect_specular_term59_g254 = ( ( 1.0 / ( brdf_roughness234_g254 + 1.0 ) ) * lerpResult8_g256 );
				float3 indirect_specular_color74_g254 = ( indirectSpecular109_g254 * indirect_specular_term59_g254 );
				float3 indirect_color92_g254 = ( indirect_diffuse_color78_g254 + indirect_specular_color74_g254 );
				float3 position_ws14_g260 = WorldPosition;
				float3 input_normal_ws8_g254 = temp_output_5_0_g254;
				float3 normal_ws14_g260 = input_normal_ws8_g254;
				float3 normal_normalized_ws14_g260 = input_normal_normalized_ws9_g254;
				float3 view_dir_ws14_g260 = ase_worldViewDir;
				float3 diffuse14_g260 = brdf_diffuse61_g254;
				float3 specular14_g260 = brdf_specular41_g254;
				float roughness2_minus_one14_g260 = brdf_roughness2_minus_one32_g254;
				float roughness214_g260 = brdf_roughness234_g254;
				float normalization_term14_g260 = brdf_normalization_term33_g254;
				float shadow_mask14_g260 = 1;
				float3 localAdditionalLighting14_g260 = AdditionalLighting14_g260( position_ws14_g260 , normal_ws14_g260 , normal_normalized_ws14_g260 , view_dir_ws14_g260 , diffuse14_g260 , specular14_g260 , roughness2_minus_one14_g260 , roughness214_g260 , normalization_term14_g260 , shadow_mask14_g260 );
				float3 additional_color90_g254 = localAdditionalLighting14_g260;
				float4 tex2DNode106 = tex2D( _EmissionMap, uv11 );
				float3 temp_output_123_0 = (( ( tex2DNode106 * tex2DNode106.a ) * _EmissionColor )).rgb;
				float4 screenPos = IN.ase_texcoord8;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float4 lerpResult116 = lerp( float4( 0,0,0,0 ) , ( tex2D( _PlanarReflectionTexture, ase_screenPosNorm.xy ) * surface_smoothness70 ) , _ReflectionAmount);
				float3 planar_reflection_color118 = (lerpResult116).rgb;
				#ifdef _PLANARREFLECTION_ON_ON
				float3 staticSwitch122 = ( temp_output_123_0 + planar_reflection_color118 );
				#else
				float3 staticSwitch122 = temp_output_123_0;
				#endif
				float3 surface_emission_color126 = staticSwitch122;
				float3 input_emission15_g254 = surface_emission_color126;
				float3 direct_specular_color127_g254 = temp_output_66_0_g254;
				float direct_specular_color16_g184 = direct_specular_color127_g254.x;
				float3 localMyCustomExpression16_g184 = MyCustomExpression16_g184( direct_specular_color16_g184 );
				
				float4 worldToClip3_g182 = TransformWorldToHClip(PlayerPosition.xyz);
				float3 worldToClip3_g182NDC = worldToClip3_g182.xyz/worldToClip3_g182.w;
				float4 appendResult2_g182 = (float4(WorldPosition , 1.0));
				float4 worldToClip4_g182 = TransformWorldToHClip(appendResult2_g182.xyz);
				float3 worldToClip4_g182NDC = worldToClip4_g182.xyz/worldToClip4_g182.w;
				float smoothstepResult12_g182 = smoothstep( min( 1.0 , TransparencySoft ) , 1.0 , ( distance( (worldToClip3_g182NDC).xy , ((worldToClip4_g182NDC).xy*(TransparencyRangeScaleOffset).xy + (TransparencyRangeScaleOffset).zw) ) / TransparencyRange ));
				float clampResult13_g182 = clamp( ( smoothstepResult12_g182 + TransparencyBaseAlpha ) , 0.0 , 1.0 );
				float surface_distance_alpha176 = clampResult13_g182;
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = ( ( direct_color91_g254 + indirect_color92_g254 + additional_color90_g254 + input_emission15_g254 ) + localMyCustomExpression16_g184 );
				float Alpha = surface_distance_alpha176;
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
			
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_SRP_VERSION 999999

			
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
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
			float4 _R_Color;
			float4 _Tex_Tile;
			float4 _A_Color;
			float4 _B_Color;
			float4 _G_Color;
			float4 _EmissionColor;
			float _R_Color_Smoothness;
			float _G_Color_Smoothness;
			float _B_Color_Smoothness;
			float _A_Color_Smoothness;
			float _A_Color_Metallic;
			float _MatcapIntensity;
			float _R_Color_Metallic;
			float _G_Color_Metallic;
			float _B_Color_Metallic;
			float _BlendMapcap;
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
			float TransparencyRange;
			float TransparencyBaseAlpha;
			float TransparencySoft;
			float4 PlayerPosition;
			float4 TransparencyRangeScaleOffset;


			
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

				float4 worldToClip3_g182 = TransformWorldToHClip(PlayerPosition.xyz);
				float3 worldToClip3_g182NDC = worldToClip3_g182.xyz/worldToClip3_g182.w;
				float4 appendResult2_g182 = (float4(WorldPosition , 1.0));
				float4 worldToClip4_g182 = TransformWorldToHClip(appendResult2_g182.xyz);
				float3 worldToClip4_g182NDC = worldToClip4_g182.xyz/worldToClip4_g182.w;
				float smoothstepResult12_g182 = smoothstep( min( 1.0 , TransparencySoft ) , 1.0 , ( distance( (worldToClip3_g182NDC).xy , ((worldToClip4_g182NDC).xy*(TransparencyRangeScaleOffset).xy + (TransparencyRangeScaleOffset).zw) ) / TransparencyRange ));
				float clampResult13_g182 = clamp( ( smoothstepResult12_g182 + TransparencyBaseAlpha ) , 0.0 , 1.0 );
				float surface_distance_alpha176 = clampResult13_g182;
				
				float Alpha = surface_distance_alpha176;
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
			
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_SRP_VERSION 999999

			
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
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
			float4 _R_Color;
			float4 _Tex_Tile;
			float4 _A_Color;
			float4 _B_Color;
			float4 _G_Color;
			float4 _EmissionColor;
			float _R_Color_Smoothness;
			float _G_Color_Smoothness;
			float _B_Color_Smoothness;
			float _A_Color_Smoothness;
			float _A_Color_Metallic;
			float _MatcapIntensity;
			float _R_Color_Metallic;
			float _G_Color_Metallic;
			float _B_Color_Metallic;
			float _BlendMapcap;
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
			float TransparencyRange;
			float TransparencyBaseAlpha;
			float TransparencySoft;
			float4 PlayerPosition;
			float4 TransparencyRangeScaleOffset;


			
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

				float4 worldToClip3_g182 = TransformWorldToHClip(PlayerPosition.xyz);
				float3 worldToClip3_g182NDC = worldToClip3_g182.xyz/worldToClip3_g182.w;
				float4 appendResult2_g182 = (float4(WorldPosition , 1.0));
				float4 worldToClip4_g182 = TransformWorldToHClip(appendResult2_g182.xyz);
				float3 worldToClip4_g182NDC = worldToClip4_g182.xyz/worldToClip4_g182.w;
				float smoothstepResult12_g182 = smoothstep( min( 1.0 , TransparencySoft ) , 1.0 , ( distance( (worldToClip3_g182NDC).xy , ((worldToClip4_g182NDC).xy*(TransparencyRangeScaleOffset).xy + (TransparencyRangeScaleOffset).zw) ) / TransparencyRange ));
				float clampResult13_g182 = clamp( ( smoothstepResult12_g182 + TransparencyBaseAlpha ) , 0.0 , 1.0 );
				float surface_distance_alpha176 = clampResult13_g182;
				
				float Alpha = surface_distance_alpha176;
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
2116;187;1251;838;436.0033;-25.70966;1;True;False
Node;AmplifyShaderEditor.WorldPosInputsNode;174;-3047.995,4353.805;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;175;-2818.892,4365.339;Inherit;False;sha_sc_func_distance_transparency;-1;;182;80cf33807ac05de449faa6aa4fced08d;0;1;17;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;75;-2776.376,3421.784;Inherit;False;875.6345;385.0005;ID Map;5;33;34;39;40;41;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;32;-3180.978,-554.681;Inherit;False;2515.06;536.9569;Matcap Albedo;13;24;79;78;23;29;80;81;77;22;31;100;102;101;;0.3876824,0.4957543,0.6792453,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;58;-3152.948,71.6939;Inherit;False;1943.271;549.7171;Base Color;12;72;73;46;47;38;45;37;44;42;43;36;35;;0.6509804,0.5956252,0.3176471,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;74;-3060.812,1472.186;Inherit;False;1897.948;463.7107;Surface Smoothness;12;70;68;67;69;66;64;65;61;62;60;63;83;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;59;-3082.932,807.8932;Inherit;False;1888.681;456.0115;Metallic;12;71;57;55;54;56;52;53;51;50;49;48;84;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;21;-2868.512,-1262.178;Inherit;False;798.4897;171.7532;Matcap UV;3;16;20;105;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;76;-3103.787,-1011.378;Inherit;False;1372.777;342.893;Normal Map;6;13;15;14;95;87;86;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;120;-3047.922,2767.965;Inherit;False;1987.682;411.9241;Emission Color;10;111;124;125;109;123;126;122;108;106;107;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;12;-2889.286,-1653.536;Inherit;False;975.7563;295;UV;5;6;9;10;7;11;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;176;-2472.892,4357.339;Inherit;False;surface_distance_alpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;121;-2986.244,2143.906;Inherit;False;1744.958;381.041;Planar Reflection;8;118;119;117;116;114;115;113;112;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;57;-2205.646,1033.002;Inherit;False;Property;_R_Color_Metallic;R_Color_Metallic;5;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;50;-2622.646,902.0018;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;127;-18.88525,51.65381;Inherit;False;126;surface_emission_color;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;119;-1718.138,2197.942;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;31;-1195.566,-411.4173;Inherit;False;surface_albedo;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;101;-2639.504,-284.3557;Inherit;False;72;surface_base_color;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;29;-2491.307,-457.8897;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;117;-2128.545,2370.106;Inherit;False;Property;_ReflectionAmount;ReflectionAmount;21;0;Create;True;0;0;0;False;0;False;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;62;-2655.753,1569.052;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;34;-2726.376,3588.61;Inherit;False;11;uv;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;51;-2824.646,1068.001;Inherit;False;41;id_b;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;20;-2294.022,-1212.178;Inherit;False;matcap_uv;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;41;-2124.742,3690.786;Inherit;False;id_b;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;108;-2385.249,2822.332;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;55;-1849.647,899.0018;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;112;-2936.244,2220.983;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;45;-2305.338,189.0489;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;7;-2402.326,-1588.336;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;53;-2483.646,1148.001;Inherit;False;40;id_g;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;109;-2208.947,2826.472;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;24;-2554.924,-181.0837;Inherit;False;Property;_MatcapIntensity;MatcapIntensity;19;0;Create;True;0;0;0;False;0;False;1.5;5.45;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;100;-2263.699,-460.4777;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;128;-4969.241,2958.169;Inherit;False;Property;_Color0;Color 0;17;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;68;-2165.528,1691.897;Inherit;False;Property;_R_Color_Smoothness;R_Color_Smoothness;4;0;Create;True;0;0;0;False;0;False;0;0.091;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;72;-1454.201,207.898;Inherit;False;surface_base_color;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;89;-11.41541,-126.0872;Inherit;False;31;surface_albedo;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;11;-2137.526,-1578.299;Inherit;False;uv;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;92;-27.90906,324.3369;Inherit;False;Constant;_AO;AO;20;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;64;-2228.204,1564.281;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;115;-2474.638,2427.906;Inherit;False;70;surface_smoothness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;177;395.4967,286.7097;Inherit;False;176;surface_distance_alpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;123;-2006.081,2829.805;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;54;-2571.646,1032.002;Inherit;False;Property;_G_Color_Metallic;G_Color_Metallic;8;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;91;-20.41541,225.9129;Inherit;False;70;surface_smoothness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;124;-1837.234,2933.463;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;172;313.4636,32.75439;Inherit;False;sha_sc_func_base_pbr_lighting;24;;184;b007fbbd74b41fb44ad54b3f89e16d09;0;7;2;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;6;FLOAT;0;False;1;FLOAT;0;False;5;FLOAT;0;False;39;FLOAT4;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;13;-2709.293,-961.3779;Inherit;True;Property;_NormalMap;Normal Map;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;63;-2906.753,1730.052;Inherit;False;41;id_b;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;60;-3010.812,1522.186;Inherit;False;Property;_A_Color_Smoothness;A_Color_Smoothness;13;0;Create;True;0;0;0;False;0;False;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;107;-2997.922,2858.8;Inherit;False;11;uv;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;173;388.6668,-140.1202;Inherit;False;118;planar_reflection_color;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;71;-1445.322,913.5056;Inherit;False;surface_metallic;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;52;-2222.646,901.0018;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;65;-2478.479,1781.136;Inherit;False;40;id_g;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;88;-24.41541,-40.08714;Inherit;False;86;surface_normal_ws;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;122;-1673.413,2830.876;Inherit;False;Property;_PlanarReflection_On;PlanarReflection_On;23;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;105;-2607.051,-1203.968;Inherit;False;sha_com_func_matcap_uv;-1;;183;b00a8b7be669c054e8bc5f643d726043;0;1;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;126;-1367.42,2831.753;Inherit;False;surface_emission_color;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;43;-2889.645,500.6079;Inherit;False;41;id_b;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;56;-2111.646,1146.001;Inherit;False;39;id_r;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;36;-3092.948,308.6938;Inherit;False;Property;_B_Color;B_Color;9;0;Create;True;0;0;0;False;0;False;1,1,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;6;-2839.286,-1593.649;Inherit;False;Property;_Tex_Tile;Tex_Tile;2;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;81;-1634.029,-461.6293;Inherit;False;72;surface_base_color;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;95;-2909.417,-935.6465;Inherit;False;11;uv;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WorldNormalVector;87;-2154.594,-849.5586;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;69;-2018.528,1818.897;Inherit;False;39;id_r;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;83;-1651.571,1568.063;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;14;-2194.01,-944.7476;Inherit;False;surface_normal_ts;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;47;-2091.827,521.9932;Inherit;False;39;id_r;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;70;-1482.864,1559.846;Inherit;False;surface_smoothness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;23;-3157.798,-432.9309;Inherit;False;20;matcap_uv;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;10;-2610.027,-1493.536;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;78;-1848.912,-220.9804;Inherit;False;71;surface_metallic;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;16;-2818.512,-1206.425;Inherit;False;14;surface_normal_ts;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;116;-1949.544,2203.106;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;48;-3032.932,857.8932;Inherit;False;Property;_A_Color_Metallic;A_Color_Metallic;14;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;90;-10.41541,140.9128;Inherit;False;71;surface_metallic;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;84;-1639.437,916.7397;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;22;-2940.727,-460.3513;Inherit;True;Property;_MatcapMap;Matcap Map;18;0;Create;True;0;0;0;False;0;False;-1;None;f4a50642fc231ad4e8907651e52d6ed6;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;38;-2091.01,309.3796;Inherit;False;Property;_R_Color;R_Color;3;0;Create;True;0;0;0;False;0;False;1,1,1,0;0.02830189,0.02830189,0.02830189,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;37;-2559.617,328.4278;Inherit;False;Property;_G_Color;G_Color;6;0;Create;True;0;0;0;False;0;False;1,1,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;77;-1583.912,-250.9804;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;86;-1958.594,-856.5586;Inherit;False;surface_normal_ws;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;40;-2124.742,3582.784;Inherit;False;id_g;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;39;-2128.742,3471.784;Inherit;False;id_r;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;44;-2449.692,529.6326;Inherit;False;40;id_g;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;106;-2770.056,2817.965;Inherit;True;Property;_EmissionMap;Emission Map;15;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;46;-1822.715,202.5919;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;49;-3022.646,956.0018;Inherit;False;Property;_B_Color_Metallic;B_Color_Metallic;11;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;111;-2423.788,2980.038;Inherit;False;Property;_EmissionColor;Emission Color;16;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,0;0.8679245,0.0614097,0.2096353,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;42;-2801.322,184.3923;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SwizzleNode;15;-2379.01,-923.7479;Inherit;False;FLOAT3;0;1;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;113;-2662.638,2193.906;Inherit;True;Global;_PlanarReflectionTexture;_PlanarReflectionTexture;22;0;Create;True;0;0;0;True;0;False;-1;None;None;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SwizzleNode;73;-1634.84,206.0979;Inherit;False;FLOAT3;0;1;2;3;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;67;-1841.528,1561.897;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;114;-2229.638,2210.906;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;35;-3102.948,121.6939;Inherit;False;Property;_A_Color;A_Color;12;0;Create;True;0;0;0;False;0;False;1,1,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;9;-2619.027,-1603.536;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;61;-3008.753,1608.052;Inherit;False;Property;_B_Color_Smoothness;B_Color_Smoothness;10;0;Create;True;0;0;0;False;0;False;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;79;-1864.912,-137.9805;Inherit;False;Property;_BlendMapcap;BlendMapcap;20;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;80;-1374.407,-414.8946;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;125;-2158.257,2959.749;Inherit;False;118;planar_reflection_color;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;118;-1514.038,2201.842;Inherit;False;planar_reflection_color;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;66;-2570.753,1687.052;Inherit;False;Property;_G_Color_Smoothness;G_Color_Smoothness;7;0;Create;True;0;0;0;False;0;False;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;33;-2500.023,3549.761;Inherit;True;Property;_IDMap;ID Map;0;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WireNode;102;-1882.031,-364.2162;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TemplateFragmentDataNode;178;39.9967,442.7097;Inherit;False;0;0;clipPos;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;674.196,-40.22582;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;scene/cover_trans/sha_sc_blend;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;2;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;5;False;-1;10;False;-1;1;1;False;-1;10;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;22;Surface;1;  Blend;0;Two Sided;1;Cast Shadows;1;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;0;LOD CrossFade;0;Built-in Fog;1;DOTS Instancing;0;Meta Pass;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;False;True;True;True;False;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;380.015,70.57423;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;5;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
WireConnection;175;17;174;0
WireConnection;176;0;175;0
WireConnection;50;0;48;0
WireConnection;50;1;49;0
WireConnection;50;2;51;0
WireConnection;119;0;116;0
WireConnection;31;0;80;0
WireConnection;29;0;22;0
WireConnection;29;1;101;0
WireConnection;62;0;60;0
WireConnection;62;1;61;0
WireConnection;62;2;63;0
WireConnection;20;0;105;0
WireConnection;41;0;33;3
WireConnection;108;0;106;0
WireConnection;108;1;106;4
WireConnection;55;0;52;0
WireConnection;55;1;57;0
WireConnection;55;2;56;0
WireConnection;45;0;42;0
WireConnection;45;1;37;0
WireConnection;45;2;44;0
WireConnection;7;0;9;0
WireConnection;7;1;10;0
WireConnection;109;0;108;0
WireConnection;109;1;111;0
WireConnection;100;0;29;0
WireConnection;100;1;24;0
WireConnection;72;0;73;0
WireConnection;11;0;7;0
WireConnection;64;0;62;0
WireConnection;64;1;66;0
WireConnection;64;2;65;0
WireConnection;123;0;109;0
WireConnection;124;0;123;0
WireConnection;124;1;125;0
WireConnection;172;2;89;0
WireConnection;172;4;88;0
WireConnection;172;3;127;0
WireConnection;172;6;90;0
WireConnection;172;1;91;0
WireConnection;172;5;92;0
WireConnection;172;39;178;0
WireConnection;13;1;95;0
WireConnection;71;0;84;0
WireConnection;52;0;50;0
WireConnection;52;1;54;0
WireConnection;52;2;53;0
WireConnection;122;1;123;0
WireConnection;122;0;124;0
WireConnection;105;1;16;0
WireConnection;126;0;122;0
WireConnection;87;0;15;0
WireConnection;83;0;67;0
WireConnection;14;0;15;0
WireConnection;70;0;83;0
WireConnection;10;0;6;3
WireConnection;10;1;6;4
WireConnection;116;1;114;0
WireConnection;116;2;117;0
WireConnection;84;0;55;0
WireConnection;22;1;23;0
WireConnection;77;1;78;0
WireConnection;77;2;79;0
WireConnection;86;0;87;0
WireConnection;40;0;33;2
WireConnection;39;0;33;1
WireConnection;106;1;107;0
WireConnection;46;0;45;0
WireConnection;46;1;38;0
WireConnection;46;2;47;0
WireConnection;42;0;35;0
WireConnection;42;1;36;0
WireConnection;42;2;43;0
WireConnection;15;0;13;0
WireConnection;113;1;112;0
WireConnection;73;0;46;0
WireConnection;67;0;64;0
WireConnection;67;1;68;0
WireConnection;67;2;69;0
WireConnection;114;0;113;0
WireConnection;114;1;115;0
WireConnection;9;0;6;1
WireConnection;9;1;6;2
WireConnection;80;0;81;0
WireConnection;80;1;102;0
WireConnection;80;2;77;0
WireConnection;118;0;119;0
WireConnection;33;1;34;0
WireConnection;102;0;100;0
WireConnection;2;2;172;0
WireConnection;2;3;177;0
ASEEND*/
//CHKSM=9AC356970107AD62875A9281117E3C308A3927C1