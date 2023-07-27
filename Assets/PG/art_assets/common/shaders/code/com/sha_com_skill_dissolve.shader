Shader "code/common/skill_dissolve"
{
	Properties
	{
		_EdgeRange("Edge Range", Range( 0 , 1)) = 1
		_EdgeColorIntensity("Edge Color Intensity", Float) = 2
		[NoScaleOffset]_BaseMap("Base Map", 2D) = "white" {}
		_BaseColor("Base Color", Color) = (0,0,0,0)
		_Tex_Noise("Tex_Noise", 2D) = "white" {}
		_TexNoisepower("Tex Noise power", Float) = 1
		_TexNoiseIntensity("Tex Noise Intensity", Range( 0 , 1)) = 1
		_OffsetPosition("Offset Position", Float) = 2
		[Toggle(_DIRECTION_ON)] _Direction("Direction", Float) = 0
		_OffsetIntensity("Offset Intensity", Range( 0.01 , 0.3)) = 0.04969278
		_OffsetDensity("Offset Density", Range( 0.9 , 1.1)) = 0.9
		_Speed("Speed", Range( 0 , 1)) = 0
		_DurationTime("DurationTime", Range( 0.01 , 0.99)) = 0.01
	}

	SubShader
	{
		LOD 0

		
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
		
		Cull Back
		AlphaToMask Off
		HLSLINCLUDE
		#pragma target 2.0

		#pragma prefer_hlslcc gles
		#pragma exclude_renderers d3d11_9x 
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        CBUFFER_START(UnityPerMaterial)
            float4 _Tex_Noise_ST;
            float4 _BaseColor;
            float _OffsetPosition;
            float _OffsetDensity;
            float _OffsetIntensity;
            float _Speed;
            float _DurationTime;
            float _TexNoisepower;
            float _TexNoiseIntensity;
            float _EdgeColorIntensity;
            float _EdgeRange;
        CBUFFER_END
        TEXTURE2D(_Tex_Noise);SAMPLER(sampler_Tex_Noise);
        TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
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

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#pragma shader_feature_local _DIRECTION_ON


			struct Attributes
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float2 texcoord : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				float3 positionWS:TEXCOORD0;
				float4 uv : TEXCOORD3;
				float3 normalWS : TEXCOORD4;
				float4 positionOS : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			
			float getClip(float2 uv, float3 positionOS){
                #if defined(_DIRECTION_ON)
				    float swit = frac( ( ( _Speed * -1.0 ) * _DurationTime ) );
				#else
				    float swit = frac( ( _Speed * _DurationTime ) );
				#endif
			    float textNoise = pow(SAMPLE_TEXTURE2D_LOD(_Tex_Noise, sampler_Tex_Noise, uv, 0).r, _TexNoisepower) * _TexNoiseIntensity;
			    float positionY =  positionOS.y * 0.4 + 0.4;
			    float offset = positionY -  (-1.0 + (( swit / 2.0 ) - 0.0) * (1.0 - -1.0) / (1.0 - 0.0));
			    float clip = textNoise * offset + offset;
			    return clip;
			}
			
			float3 HSVToRGB( float3 c )
			{
				float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
				float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
				return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
			}
			
			Varyings vert ( Attributes i)
			{
				Varyings o = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_TRANSFER_INSTANCE_ID(i, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				
				o.uv.xy = i.texcoord.xy;
				o.uv.zw = i.texcoord1.xy;
				o.positionOS = i.positionOS;
				
				float2 noiseUV = i.texcoord1 * _Tex_Noise_ST.xy + _Tex_Noise_ST.zw;
				float Clip = getClip(noiseUV, i.positionOS);
				
				float y = smoothstep( _OffsetDensity , _OffsetDensity + _OffsetIntensity , Clip) * _OffsetPosition;
				float3 pos = float3(0,y,0);
				float3 vertexOffset = TransformWorldToObject(pos) - TransformWorldToObject(float3(0,0,0));
				i.positionOS.xyz += vertexOffset;
				float3 positionWS = TransformObjectToWorld(i.positionOS.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );
				float3 normalWS = TransformObjectToWorldNormal(i.normalOS);
				
				o.normalWS = normalWS;
				o.positionWS = positionWS;
				o.positionCS = positionCS;
				return o;
			}

			half4 frag ( Varyings i  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

				#ifdef _DIRECTION_ON
				float swi = frac( ( ( _Speed * -1.0 ) * _DurationTime ) );
				#else
				float swi = frac( ( _Speed * _DurationTime ) );
				#endif
				float3 egdeColor = HSVToRGB( float3(swi,1.0,1.0) ) * _EdgeColorIntensity;
				
				float nDotL = dot( i.normalWS , _MainLightPosition.xyz ) * 0.5 + 0.6;
				float4 baseMap = lerp(SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv.xy), _BaseColor, nDotL);
				
				float2 noiseUV = i.uv.zw * _Tex_Noise_ST.xy + _Tex_Noise_ST.zw;
				float Clip = getClip(noiseUV, i.positionOS);
				
				float4 color = lerp( float4( egdeColor , 0.0 ) , baseMap , saturate( ( ( 1.0 - Clip ) / _EdgeRange ) ));
				
				float alpha = 1;
				clip( alpha - Clip );
				return half4( color.rgb, alpha );
			}

			ENDHLSL
		}
		
		Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
			ZTest LEqual
			AlphaToMask Off

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            //--------------------------------------
            // GPU Instancing
            //#pragma multi_compile_instancing

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			
			#pragma shader_feature_local _DIRECTION_ON
            
            float3 _LightDirection;
            
			struct Attributes
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float2 texcoord : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				float3 positionWS:TEXCOORD0;
				float4 uv : TEXCOORD1;
				float3 normalWS : TEXCOORD2;
				float4 positionOS : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
            
            float getClip(float2 uv, float3 positionOS){
                #if defined(_DIRECTION_ON)
				    float swit = frac( ( ( _Speed * -1.0 ) * _DurationTime ) );
				#else
				    float swit = frac( ( _Speed * _DurationTime ) );
				#endif
			    float textNoise = pow(SAMPLE_TEXTURE2D_LOD(_Tex_Noise, sampler_Tex_Noise, uv, 0).r, _TexNoisepower) * _TexNoiseIntensity;
			    float positionY =  positionOS.y * 0.4 + 0.4;
			    float offset = positionY -  (-1.0 + (( swit / 2.0 ) - 0.0) * (1.0 - -1.0) / (1.0 - 0.0));
			    float clip = textNoise * offset + offset;
			    return clip;
			}
            
            Varyings ShadowPassVertex(Attributes i)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(i);
				UNITY_TRANSFER_INSTANCE_ID(i, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
            
                output.uv.xy = i.texcoord;
                output.uv.zw = i.texcoord1;
                output.positionOS = i.positionOS;
                float2 noiseUV = i.texcoord1 * _Tex_Noise_ST.xy + _Tex_Noise_ST.zw;
				float Clip = getClip(noiseUV, i.positionOS);
				
				float y = smoothstep( _OffsetDensity , _OffsetDensity + _OffsetIntensity , Clip) * _OffsetPosition;
				float3 pos = float3(0,y,0);
				float3 vertexOffset = TransformWorldToObject(pos) - TransformWorldToObject(float3(0,0,0));
				i.positionOS.xyz += vertexOffset;
				
                float3 positionWS = TransformObjectToWorld(i.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(i.normalOS);
            
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
            
                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif
                output.positionCS = positionCS;
                return output;
            }
            
            half4 ShadowPassFragment(Varyings i) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                float2 noiseUV = i.uv.zw * _Tex_Noise_ST.xy + _Tex_Noise_ST.zw;
				float Clip = getClip(noiseUV, i.positionOS);
				float alpha = 1;
				clip( alpha - Clip );
                return 0;
            }
            ENDHLSL
        }
        
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
			ColorMask 0
			AlphaToMask Off

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            //--------------------------------------
            // GPU Instancing
            //#pragma multi_compile_instancing

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            
            #pragma shader_feature_local _DIRECTION_ON

            struct Attributes
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float2 texcoord1 : TEXCOORD1;
				float2 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				float3 positionWS:TEXCOORD0;
				float4 uv : TEXCOORD3;
				float3 normalWS : TEXCOORD4;
				float4 positionOS : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
            
            float getClip(float2 uv, float3 positionOS){
                #if defined(_DIRECTION_ON)
				    float swit = frac( ( ( _Speed * -1.0 ) * _DurationTime ) );
				#else
				    float swit = frac( ( _Speed * _DurationTime ) );
				#endif
			    float textNoise = pow(SAMPLE_TEXTURE2D_LOD(_Tex_Noise, sampler_Tex_Noise, uv, 0).r, _TexNoisepower) * _TexNoiseIntensity;
			    float positionY =  positionOS.y * 0.4 + 0.4;
			    float offset = positionY -  (-1.0 + (( swit / 2.0 ) - 0.0) * (1.0 - -1.0) / (1.0 - 0.0));
			    float clip = textNoise * offset + offset;
			    return clip;
			}
            
            Varyings DepthOnlyVertex(Attributes i)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(i);
				UNITY_TRANSFER_INSTANCE_ID(i, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
            
                output.uv.xy = i.texcoord;
                output.uv.zw = i.texcoord1;
                output.positionOS = i.positionOS;
                
                float2 noiseUV = i.texcoord1 * _Tex_Noise_ST.xy + _Tex_Noise_ST.zw;
				float Clip = getClip(noiseUV, i.positionOS);
				
				float y = smoothstep( _OffsetDensity , _OffsetDensity + _OffsetIntensity , Clip) * _OffsetPosition;
				float3 pos = float3(0,y,0);
				float3 vertexOffset = TransformWorldToObject(pos) - TransformWorldToObject(float3(0,0,0));
				i.positionOS.xyz += vertexOffset;
				output.positionCS = TransformObjectToHClip(i.positionOS);
				
                return output;
            }
            
            half4 DepthOnlyFragment(Varyings i) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                float2 noiseUV = i.uv.zw * _Tex_Noise_ST.xy + _Tex_Noise_ST.zw;
				float Clip = getClip(noiseUV, i.positionOS);
                float alpha = 1;
				clip( alpha - Clip );
                return 0;
            }
            ENDHLSL
        }
	}
	FallBack "Hidden/Universal Render Pipeline/FallbackError"
}