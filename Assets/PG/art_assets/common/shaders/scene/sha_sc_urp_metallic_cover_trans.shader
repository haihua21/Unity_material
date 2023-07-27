// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "scene/cover_trans/sha_sc_urp_metallic"
{
	Properties
	{
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin]_BaseMap("Base Map", 2D) = "white" {}
		_BaseColor("Base Color", Color) = (1,1,1,0)
		_BaseColorIntensity("Base Color Intensity", Range( 0 , 3)) = 1
		_NormalMap("Normal Map", 2D) = "bump" {}
		_SEMMap("SEM Map (S=smoothness, e=emission, m=metallic)", 2D) = "white" {}
		_Smoothness("Smoothness", Range( 0 , 1)) = 0.5
		_Metallic("Metallic", Range( 0 , 1)) = 0
		[HDR]_EmissionColor("Emission Color", Color) = (1,1,1,0)
		_EmissionIntensity("Emission Intensity", Range( 0 , 3)) = 0
		_MatcapMap("Matcap Map", 2D) = "white" {}
		_MatcapAlbedoBlend("Matcap Albedo Blend", Range( 0 , 2)) = 0
		_MatcapIntensity("MatcapIntensity", Range( 0 , 8)) = 1
		_MatcapColor("Matcap Color", Color) = (1,1,1,0)
		[ASEEnd][Toggle(_SPECULARHIGHLIGHTS_ON)] _SpecularHighlights("Specular Highlights", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

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
		#pragma target 2.0

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
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _SEMMap_ST;
			float4 _BaseMap_ST;
			float4 _BaseColor;
			float4 _NormalMap_ST;
			float4 _MatcapColor;
			float4 _EmissionColor;
			float _Metallic;
			float _MatcapAlbedoBlend;
			float _BaseColorIntensity;
			float _MatcapIntensity;
			float _Smoothness;
			float _EmissionIntensity;
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
			sampler2D _SEMMap;
			sampler2D _BaseMap;
			sampler2D _MatcapMap;
			sampler2D _NormalMap;
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
			
			float3 MyCustomExpression16_g206( float direct_specular_color )
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
				float2 uv_SEMMap = IN.ase_texcoord3.xy * _SEMMap_ST.xy + _SEMMap_ST.zw;
				float4 tex2DNode32 = tex2D( _SEMMap, uv_SEMMap );
				float map_metallic38 = tex2DNode32.b;
				float clampResult56 = clamp( ( map_metallic38 * _MatcapAlbedoBlend ) , 0.0 , 1.0 );
				float surface_metallic_matcap60 = clampResult56;
				float lerpResult59 = lerp( ( _Metallic * map_metallic38 ) , 0.0 , surface_metallic_matcap60);
				float surface_metallic61 = lerpResult59;
				float input_metallic11_g254 = surface_metallic61;
				float func_brdf_metallic9_g258 = input_metallic11_g254;
				float func_brdf_one_minus_reflectivity16_g258 = ( _kDielectricSpec.w - ( _kDielectricSpec.w * func_brdf_metallic9_g258 ) );
				float2 uv_BaseMap = IN.ase_texcoord3.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;
				float3 map_base_color23 = (tex2D( _BaseMap, uv_BaseMap )).rgb;
				float3 surface_base_color28 = ( ( map_base_color23 * (_BaseColor).rgb ) * _BaseColorIntensity );
				float2 uv_NormalMap = IN.ase_texcoord3.xy * _NormalMap_ST.xy + _NormalMap_ST.zw;
				float3 tex2DNode7 = UnpackNormalScale( tex2D( _NormalMap, uv_NormalMap ), 1.0f );
				float3 surface_normal_ts9 = (tex2DNode7).xyz;
				float3 ase_worldTangent = IN.ase_texcoord4.xyz;
				float3 ase_worldNormal = IN.ase_texcoord5.xyz;
				float3 ase_worldBitangent = IN.ase_texcoord6.xyz;
				float3x3 ase_tangentToWorldFast = float3x3(ase_worldTangent.x,ase_worldBitangent.x,ase_worldNormal.x,ase_worldTangent.y,ase_worldBitangent.y,ase_worldNormal.y,ase_worldTangent.z,ase_worldBitangent.z,ase_worldNormal.z);
				float3 tangentToViewDir8_g262 = ASESafeNormalize( mul( UNITY_MATRIX_V, float4( mul( ase_tangentToWorldFast, surface_normal_ts9 ), 0 ) ).xyz );
				float3 surface_matcap_color29 = (( float4( ( (tex2D( _MatcapMap, ( ( tangentToViewDir8_g262 * 0.5 ) + 0.5 ).xy )).rgb * _MatcapIntensity ) , 0.0 ) * _MatcapColor )).rgb;
				float3 lerpResult64 = lerp( surface_base_color28 , surface_matcap_color29 , surface_metallic_matcap60);
				float3 surface_albedo68 = lerpResult64;
				float3 input_albedo7_g254 = surface_albedo68;
				float3 func_brdf_albedo8_g258 = input_albedo7_g254;
				float3 func_brdf_diffuse23_g258 = ( func_brdf_one_minus_reflectivity16_g258 * func_brdf_albedo8_g258 );
				float3 brdf_diffuse61_g254 = func_brdf_diffuse23_g258;
				float3 func_brdf_dielectric_spec29_g258 = (_kDielectricSpec).xyz;
				float3 lerpResult24_g258 = lerp( func_brdf_dielectric_spec29_g258 , func_brdf_albedo8_g258 , func_brdf_metallic9_g258);
				float3 func_brdf_specular31_g258 = lerpResult24_g258;
				float3 brdf_specular41_g254 = func_brdf_specular31_g258;
				float map_smoothness36 = tex2DNode32.r;
				float surface_smoothness43 = ( map_smoothness36 * _Smoothness );
				float input_smoothness12_g254 = surface_smoothness43;
				float func_brdf_smoothness11_g258 = input_smoothness12_g254;
				float func_brdf_perceptual_roughness35_g258 = ( 1.0 - func_brdf_smoothness11_g258 );
				float func_brdf_roughness40_g258 = max( ( func_brdf_perceptual_roughness35_g258 * func_brdf_perceptual_roughness35_g258 ) , 0.0078125 );
				float func_brdf_roughness244_g258 = max( ( func_brdf_roughness40_g258 * func_brdf_roughness40_g258 ) , 6.103516E-05 );
				float brdf_roughness234_g254 = func_brdf_roughness244_g258;
				float3 tanToWorld0 = float3( ase_worldTangent.x, ase_worldBitangent.x, ase_worldNormal.x );
				float3 tanToWorld1 = float3( ase_worldTangent.y, ase_worldBitangent.y, ase_worldNormal.y );
				float3 tanToWorld2 = float3( ase_worldTangent.z, ase_worldBitangent.z, ase_worldNormal.z );
				float3 tanNormal12 = tex2DNode7;
				float3 worldNormal12 = float3(dot(tanToWorld0,tanNormal12), dot(tanToWorld1,tanNormal12), dot(tanToWorld2,tanNormal12));
				float3 surface_normal_ws11 = worldNormal12;
				float3 temp_output_5_0_g254 = surface_normal_ws11;
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
				float3 temp_cast_4 = (brdf_grazing_term37_g254).xxx;
				float dotResult14_g255 = dot( temp_output_21_0_g255 , temp_output_3_0_g255 );
				float NoV2_g255 = saturate( dotResult14_g255 );
				float vector_NoV28_g254 = NoV2_g255;
				float temp_output_42_0_g254 = ( 1.0 - vector_NoV28_g254 );
				float3 lerpResult8_g256 = lerp( brdf_specular41_g254 , temp_cast_4 , ( temp_output_42_0_g254 * temp_output_42_0_g254 * temp_output_42_0_g254 * temp_output_42_0_g254 ));
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
				float map_emission37 = tex2DNode32.g;
				float3 surface_emission75 = ( (( float4( ( map_emission37 * map_base_color23 ) , 0.0 ) * _EmissionIntensity * _EmissionColor )).rgb + ( surface_albedo68 * 0.1 ) );
				float3 input_emission15_g254 = surface_emission75;
				float3 direct_specular_color127_g254 = temp_output_66_0_g254;
				float direct_specular_color16_g206 = direct_specular_color127_g254.x;
				float3 localMyCustomExpression16_g206 = MyCustomExpression16_g206( direct_specular_color16_g206 );
				
				float4 worldToClip3_g205 = TransformWorldToHClip(PlayerPosition.xyz);
				float3 worldToClip3_g205NDC = worldToClip3_g205.xyz/worldToClip3_g205.w;
				float4 appendResult2_g205 = (float4(WorldPosition , 1.0));
				float4 worldToClip4_g205 = TransformWorldToHClip(appendResult2_g205.xyz);
				float3 worldToClip4_g205NDC = worldToClip4_g205.xyz/worldToClip4_g205.w;
				float smoothstepResult12_g205 = smoothstep( min( 1.0 , TransparencySoft ) , 1.0 , ( distance( (worldToClip3_g205NDC).xy , ((worldToClip4_g205NDC).xy*(TransparencyRangeScaleOffset).xy + (TransparencyRangeScaleOffset).zw) ) / TransparencyRange ));
				float clampResult13_g205 = clamp( ( smoothstepResult12_g205 + TransparencyBaseAlpha ) , 0.0 , 1.0 );
				float surface_distance_alpha114 = clampResult13_g205;
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = ( ( direct_color91_g254 + indirect_color92_g254 + additional_color90_g254 + input_emission15_g254 ) + localMyCustomExpression16_g206 );
				float Alpha = surface_distance_alpha114;
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
			float4 _SEMMap_ST;
			float4 _BaseMap_ST;
			float4 _BaseColor;
			float4 _NormalMap_ST;
			float4 _MatcapColor;
			float4 _EmissionColor;
			float _Metallic;
			float _MatcapAlbedoBlend;
			float _BaseColorIntensity;
			float _MatcapIntensity;
			float _Smoothness;
			float _EmissionIntensity;
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

				float4 worldToClip3_g205 = TransformWorldToHClip(PlayerPosition.xyz);
				float3 worldToClip3_g205NDC = worldToClip3_g205.xyz/worldToClip3_g205.w;
				float4 appendResult2_g205 = (float4(WorldPosition , 1.0));
				float4 worldToClip4_g205 = TransformWorldToHClip(appendResult2_g205.xyz);
				float3 worldToClip4_g205NDC = worldToClip4_g205.xyz/worldToClip4_g205.w;
				float smoothstepResult12_g205 = smoothstep( min( 1.0 , TransparencySoft ) , 1.0 , ( distance( (worldToClip3_g205NDC).xy , ((worldToClip4_g205NDC).xy*(TransparencyRangeScaleOffset).xy + (TransparencyRangeScaleOffset).zw) ) / TransparencyRange ));
				float clampResult13_g205 = clamp( ( smoothstepResult12_g205 + TransparencyBaseAlpha ) , 0.0 , 1.0 );
				float surface_distance_alpha114 = clampResult13_g205;
				
				float Alpha = surface_distance_alpha114;
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
			float4 _SEMMap_ST;
			float4 _BaseMap_ST;
			float4 _BaseColor;
			float4 _NormalMap_ST;
			float4 _MatcapColor;
			float4 _EmissionColor;
			float _Metallic;
			float _MatcapAlbedoBlend;
			float _BaseColorIntensity;
			float _MatcapIntensity;
			float _Smoothness;
			float _EmissionIntensity;
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

				float4 worldToClip3_g205 = TransformWorldToHClip(PlayerPosition.xyz);
				float3 worldToClip3_g205NDC = worldToClip3_g205.xyz/worldToClip3_g205.w;
				float4 appendResult2_g205 = (float4(WorldPosition , 1.0));
				float4 worldToClip4_g205 = TransformWorldToHClip(appendResult2_g205.xyz);
				float3 worldToClip4_g205NDC = worldToClip4_g205.xyz/worldToClip4_g205.w;
				float smoothstepResult12_g205 = smoothstep( min( 1.0 , TransparencySoft ) , 1.0 , ( distance( (worldToClip3_g205NDC).xy , ((worldToClip4_g205NDC).xy*(TransparencyRangeScaleOffset).xy + (TransparencyRangeScaleOffset).zw) ) / TransparencyRange ));
				float clampResult13_g205 = clamp( ( smoothstepResult12_g205 + TransparencyBaseAlpha ) , 0.0 , 1.0 );
				float surface_distance_alpha114 = clampResult13_g205;
				
				float Alpha = surface_distance_alpha114;
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
2116;187;1251;838;538.7504;40.23972;1.116979;True;False
Node;AmplifyShaderEditor.WorldPosInputsNode;112;-2495.455,3485.26;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;113;-2284.856,3490.459;Inherit;False;sha_sc_func_distance_transparency;-1;;205;80cf33807ac05de449faa6aa4fced08d;0;1;17;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;77;-2641.894,2713.798;Inherit;False;1389.889;490.8933;Metallic;9;54;56;57;53;55;58;60;59;61;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;114;-1948.156,3487.859;Inherit;False;surface_distance_alpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;30;-2784.452,-1022.582;Inherit;False;1536.881;455.8389;Base Color;9;48;23;22;28;26;27;24;25;49;;0.8018868,0.3139462,0.3139462,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;69;-2635.26,-497.5804;Inherit;False;826.4879;411.2901;Albedo Color;5;64;67;62;63;68;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;13;-2608.788,335.8372;Inherit;False;1230.156;392.9999;Normal Map;6;7;6;10;9;12;11;;0.2748754,0.2997605,0.8207547,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;44;-2568.588,1470.645;Inherit;False;813.5293;301.0519;Smoothness;4;40;42;41;43;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;76;-2659.11,2000.719;Inherit;False;1497.143;509.4524;Emission Color;12;45;46;47;51;52;50;71;73;72;74;70;75;;0.03764683,0.8867924,0.5418643,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;31;-2846.538,-1565.208;Inherit;False;2120.911;486.5392;Matcap Color;10;29;20;21;17;19;18;16;14;15;66;;0.6771602,0.8301887,0.04307583,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;39;-2553.258,891.6345;Inherit;False;694.7085;391;SEM Map;4;32;36;37;38;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;27;-1893.669,-754.0432;Inherit;False;Property;_BaseColorIntensity;Base Color Intensity;5;0;Create;True;0;0;0;False;0;False;1;1;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;57;-2198.393,2820.752;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;79;-191.0141,-135.4985;Inherit;False;68;surface_albedo;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;55;-2591.894,3088.691;Inherit;False;Property;_MatcapAlbedoBlend;Matcap Albedo Blend;13;0;Create;True;0;0;0;False;0;False;0;0;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;80;-195.0141,-25.49854;Inherit;False;11;surface_normal_ws;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;50;-1970.314,2076.291;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;74;-1930.967,2384.129;Inherit;False;Constant;_Float1;Float 1;11;0;Create;True;0;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;14;-2516.092,-1472.861;Inherit;False;sha_com_func_matcap_uv;-1;;262;b00a8b7be669c054e8bc5f643d726043;0;1;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;73;-1710.967,2286.129;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;52;-2340.918,2181.066;Inherit;False;Property;_EmissionIntensity;Emission Intensity;11;0;Create;True;0;0;0;False;0;False;0;1.34;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;67;-2585.26,-202.2903;Inherit;False;60;surface_metallic_matcap;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;103;150.409,5.972779;Inherit;False;sha_com_base_pbr_lighting;16;;263;229646456265a5d449c8b62905588502;0;7;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;14;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;165;FLOAT4;0,0,0,0;False;2;FLOAT3;0;FLOAT3;135
Node;AmplifyShaderEditor.ColorNode;25;-2376.672,-793.0432;Inherit;False;Property;_BaseColor;Base Color;4;0;Create;True;0;0;0;False;0;False;1,1,1,0;0.1982159,0.09451757,0.3396226,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;32;-2503.258,980.0721;Inherit;True;Property;_SEMMap;SEM Map (S=smoothness, e=emission, m=metallic);7;0;Create;False;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;26;-1663.669,-958.0432;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;15;-2773.395,-1471.608;Inherit;False;9;surface_normal_ts;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;58;-2576.363,2763.798;Inherit;False;Property;_Metallic;Metallic;9;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;38;-2088.55,1166.635;Inherit;False;map_metallic;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;56;-2133.673,2982.55;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;36;-2097.55,941.6345;Inherit;False;map_smoothness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;81;-215.0142,180.5014;Inherit;False;61;surface_metallic;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;70;-1552.695,2071.928;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;63;-2580.136,-447.5804;Inherit;False;28;surface_base_color;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;60;-1935.772,2997.167;Inherit;False;surface_metallic_matcap;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;17;-1582.313,-1480.88;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;75;-1385.967,2074.129;Inherit;False;surface_emission;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;7;-2242.632,385.8371;Inherit;True;Property;_NormalMap;Normal Map;6;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;6;-2558.788,409.7904;Inherit;False;0;7;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;54;-2301.946,2982.55;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;40;-2518.588,1520.645;Inherit;False;36;map_smoothness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;90;-219.6753,89.48761;Inherit;False;75;surface_emission;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;45;-2599.525,2050.719;Inherit;False;37;map_emission;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;59;-1683.131,2825.324;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;51;-2321.818,2298.171;Inherit;False;Property;_EmissionColor;Emission Color;10;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,0;0.1176471,0.945098,0.9150109,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;47;-2609.11,2187.012;Inherit;False;23;map_base_color;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;111;166.8888,278.9183;Inherit;False;sha_sc_func_base_pbr_lighting;1;;206;b007fbbd74b41fb44ad54b3f89e16d09;0;7;2;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;6;FLOAT;0;False;1;FLOAT;0;False;5;FLOAT;0;False;39;FLOAT4;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;22;-2728.379,-973.6469;Inherit;True;Property;_BaseMap;Base Map;0;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;28;-1494.568,-958.646;Inherit;False;surface_base_color;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;21;-1555.248,-1318.553;Inherit;False;Property;_MatcapColor;Matcap Color;15;0;Create;True;0;0;0;False;0;False;1,1,1,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ComponentMaskNode;66;-1172.36,-1477.254;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;24;-1873.669,-956.0432;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;23;-2155.269,-961.0228;Inherit;False;map_base_color;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;53;-2546.589,2911.36;Inherit;False;38;map_metallic;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;18;-1859.171,-1479.839;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;9;-1625.632,412.8371;Inherit;False;surface_normal_ts;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;43;-2011.059,1533.714;Inherit;False;surface_smoothness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;71;-1813.005,2076.969;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;19;-1881.025,-1333.085;Inherit;False;Property;_MatcapIntensity;MatcapIntensity;14;0;Create;True;0;0;0;False;0;False;1;0;0;8;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;83;-182.0141,357.5016;Inherit;False;Constant;_Float2;Float 2;12;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;-1326.862,-1475.106;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;11;-1602.632,551.8374;Inherit;False;surface_normal_ws;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;10;-1886.632,409.837;Inherit;False;True;True;True;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;46;-2364.21,2061.366;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;115;228.2432,597.8655;Inherit;False;114;surface_distance_alpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;41;-2215.813,1535.892;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;48;-2375.593,-942.443;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;37;-2097.55,1056.635;Inherit;False;map_emission;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;12;-1864.632,545.8375;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ComponentMaskNode;49;-2094.788,-829.7516;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;29;-966.6261,-1476.921;Inherit;False;surface_matcap_color;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;72;-1954.967,2269.129;Inherit;False;68;surface_albedo;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;61;-1499.005,2820.362;Inherit;False;surface_metallic;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;62;-2582.674,-341.0199;Inherit;False;29;surface_matcap_color;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;68;-2034.773,-363.218;Inherit;False;surface_albedo;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;82;-211.0141,277.5015;Inherit;False;43;surface_smoothness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;16;-2214.193,-1495.406;Inherit;True;Property;_MatcapMap;Matcap Map;12;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;64;-2252.388,-364.2557;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;42;-2505.519,1655.696;Inherit;False;Property;_Smoothness;Smoothness;8;0;Create;True;0;0;0;False;0;False;0.5;0.507;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateFragmentDataNode;116;25.32385,502.6118;Inherit;False;0;0;clipPos;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;5;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;151.4152,-46.08288;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;576.5316,7.147087;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;scene/cover_trans/sha_sc_urp_metallic;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;5;False;-1;10;False;-1;1;1;False;-1;10;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;22;Surface;1;  Blend;0;Two Sided;1;Cast Shadows;1;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;1;LOD CrossFade;0;Built-in Fog;1;DOTS Instancing;0;Meta Pass;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;False;True;True;True;False;False;;False;0
WireConnection;113;17;112;0
WireConnection;114;0;113;0
WireConnection;57;0;58;0
WireConnection;57;1;53;0
WireConnection;50;0;46;0
WireConnection;50;1;52;0
WireConnection;50;2;51;0
WireConnection;14;1;15;0
WireConnection;73;0;72;0
WireConnection;73;1;74;0
WireConnection;103;4;79;0
WireConnection;103;5;80;0
WireConnection;103;14;90;0
WireConnection;103;1;81;0
WireConnection;103;2;82;0
WireConnection;103;3;83;0
WireConnection;26;0;24;0
WireConnection;26;1;27;0
WireConnection;38;0;32;3
WireConnection;56;0;54;0
WireConnection;36;0;32;1
WireConnection;70;0;71;0
WireConnection;70;1;73;0
WireConnection;60;0;56;0
WireConnection;17;0;18;0
WireConnection;17;1;19;0
WireConnection;75;0;70;0
WireConnection;7;1;6;0
WireConnection;54;0;53;0
WireConnection;54;1;55;0
WireConnection;59;0;57;0
WireConnection;59;2;60;0
WireConnection;111;2;79;0
WireConnection;111;4;80;0
WireConnection;111;3;90;0
WireConnection;111;6;81;0
WireConnection;111;1;82;0
WireConnection;111;5;83;0
WireConnection;111;39;116;0
WireConnection;28;0;26;0
WireConnection;66;0;20;0
WireConnection;24;0;23;0
WireConnection;24;1;49;0
WireConnection;23;0;48;0
WireConnection;18;0;16;0
WireConnection;9;0;10;0
WireConnection;43;0;41;0
WireConnection;71;0;50;0
WireConnection;20;0;17;0
WireConnection;20;1;21;0
WireConnection;11;0;12;0
WireConnection;10;0;7;0
WireConnection;46;0;45;0
WireConnection;46;1;47;0
WireConnection;41;0;40;0
WireConnection;41;1;42;0
WireConnection;48;0;22;0
WireConnection;37;0;32;2
WireConnection;12;0;7;0
WireConnection;49;0;25;0
WireConnection;29;0;66;0
WireConnection;61;0;59;0
WireConnection;68;0;64;0
WireConnection;16;1;14;0
WireConnection;64;0;63;0
WireConnection;64;1;62;0
WireConnection;64;2;67;0
WireConnection;2;2;111;0
WireConnection;2;3;115;0
ASEEND*/
//CHKSM=74F35AB109314BB30CAA0F73116CFDC13DADED82