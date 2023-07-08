Shader "code/scene/sha_sc_water"
{
	Properties
	{
		_Distortion("Distortion",Range(0,3)) = 2
		_FlowSpeed("FlowSpeed",Range(0.1,5)) = 1
		_FoamTex("FoamTex",2D) = "White"{}
		_WaveSpeed("WaveSpeed",Range(0.1,5)) = 1
		_Edge("Edge",Range(0.9,1.5)) = 1
		_SpecularColor("SpecularColor",Color) = (1,1,1,1)
		_SpecularRange("SpecularRange",Range(0.1,200)) = 1
		_SpecularStrenght("SpecularStrenght",Range(0.1,2)) = 1
		_SpecularX("SpecularX",Range(0,1))=0
		_SpecularY("SpecularY",Range(0,1))=0
	}
	
	SubShader
	{
		Tags { "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent"}
		LOD 100
		Blend SrcAlpha OneMinusSrcAlpha 

		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

			

			struct appdata
			{
				float4 vertex : POSITION;
				float4 normal : NORMAL;
				float2 uv : TEXCOORD;
			};

			struct v2f
			{
				
				float4 vertex : SV_POSITION;
				float4 screenPos : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float2 uv : TEXCOORD3;
				float3 worldNormal : TEXCOOORD4;
			};
			CBUFFER_START(UnityPerMaterial)
                float _FlowSpeed;
				TEXTURE2D(_FoamTex) ;
				SAMPLER(sampler_FoamTex);
				float4 _FoamTex_ST;
				TEXTURE2D(_ReflectionTex) ;
				half4 _ReflectionTex_TexelSize;
				float _Distortion;
				float _WaveSpeed;
				float _Edge;
				float4 _SpecularColor;
				float _SpecularRange;
				float _SpecularStrenght;
				float _SpecularX;
				float _SpecularY;
            CBUFFER_END
			

			

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);				
				
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;	
				o.screenPos = ComputeScreenPos(o.vertex);		
				o.uv = TRANSFORM_TEX(v.uv,_FoamTex) ;
				o.worldNormal = TransformObjectToWorldNormal(v.normal);
				return o;
			}
			//利用cos生成的渐变色
			real4 cosine_gradient(float x,  real4 phase, real4 amp, real4 freq, real4 offset){
				float TAU = 2. * 3.14159265;
  				phase *= TAU;
  				x *= TAU;

  				return real4(
    				offset.r + amp.r * 0.5 * cos(x * freq.r + phase.r) + 0.5,
    				offset.g + amp.g * 0.5 * cos(x * freq.g + phase.g) + 0.5,
    				offset.b + amp.b * 0.5 * cos(x * freq.b + phase.b) + 0.5,
    				offset.a + amp.a * 0.5 * cos(x * freq.a + phase.a) + 0.5
  				);
			}
			real3 toRGB(real3 grad){
  				 return grad.rgb;
			}
			//噪声图生成
			float2 rand(float2 st, int seed)
			{
				float2 s = float2(dot(st, float2(127.1, 311.7)) + seed, dot(st, float2(269.5, 183.3)) + seed);
				return -1 + 2 * frac(sin(s) * 43758.5453123);
			}
			float noise(float2 st, int seed)
			{
				st.y += _Time.y*_FlowSpeed;

				float2 p = floor(st);
				float2 f = frac(st);
 
				float w00 = dot(rand(p, seed), f);
				float w10 = dot(rand(p + float2(1, 0), seed), f - float2(1, 0));
				float w01 = dot(rand(p + float2(0, 1), seed), f - float2(0, 1));
				float w11 = dot(rand(p + float2(1, 1), seed), f - float2(1, 1));
				
				float2 u = f * f * (3 - 2 * f);

				return lerp(lerp(w00, w10, u.x), lerp(w01, w11, u.x), u.y);
			}
			//海浪的涌起法线计算
			float3 swell( float3 pos , float anisotropy){
				float3 normal;
				float height = noise(pos.xz * 0.1,0);
				height *= anisotropy ;//使距离地平线近的区域的海浪高度降低
				normal = normalize(
					cross ( 
						float3(0,ddy(height),1),
						float3(1,ddx(height),0)
					)//两片元间高度差值得到梯度
				);
				return normal;
			}

			real4 blendSeaColor(real4 col1,real4 col2)
			{
				real4 col = min(1,1.5-col2.a)*col1+col2.a*col2;
				return col;
			}
			
			
			real4 frag (v2f i) : SV_Target
			{
				real4 col = (1,1,1,1);
				float sceneZ = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, i.screenPos.xy/i.screenPos.w);				
				sceneZ = LinearEyeDepth(sceneZ, _ZBufferParams);
				float partZ = i.screenPos.w;
				float diffZ =  (sceneZ - partZ)/5.0f;//片元深度与场景深度的差值
				float ratioZ = sceneZ/partZ;//场景深度与片元深度的比值
				const real4 phases = real4(0.28, 0.50, 0.07, 0);//周期
				const real4 amplitudes = real4(4.02, 0.34, 0.65, 0);//振幅
				const real4 frequencies = real4(0.00, 0.48, 0.08, 0);//频率
				const real4 offsets = real4(0.00, 0.16, 0.00, 0);//相位
				//按照距离海滩远近叠加渐变色
				real4 cos_grad = cosine_gradient(saturate(1.5-diffZ), phases, amplitudes, frequencies, offsets);
  				cos_grad = clamp(cos_grad, 0, 1);
  				col.rgb = toRGB(cos_grad);

				//海浪波动
				half3 worldViewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
				float3 v = i.worldPos - _WorldSpaceCameraPos;
				float anisotropy = saturate(1/ddy(length(v.xz))/10);//通过临近像素点间摄像机到片元位置差值来计算哪里是接近地平线的部分
				float3 swelledNormal = swell( i.worldPos , anisotropy);

				// 反射天空盒
                half3 reflDir = reflect(-worldViewDir, swelledNormal);
				real4 reflectionColor = SAMPLE_TEXTURECUBE(unity_SpecCube0,samplerunity_SpecCube0, reflDir);

				
				//其余物体的平面反射
				float height = noise(i.worldPos.xz * 0.1,0);
				float offset = height * _Distortion ;
				i.screenPos.x += pow(offset,2) * saturate(diffZ)  ;
				real4 reflectionColor2 = SAMPLE_TEXTURE2D(_ReflectionTex,sampler_FoamTex,i.screenPos.xy / i.screenPos.w);//tex2D(_ReflectionTex, i.screenPos.xy / i.screenPos.w);
				reflectionColor = blendSeaColor(reflectionColor,reflectionColor2);
				
				//海面高光
				float3 L = normalize(_MainLightPosition.xyz -i.worldPos);
				float3 H = normalize(worldViewDir+L+float3(_SpecularX,0,_SpecularY));
				real3 specular = _SpecularColor.rgb * _SpecularStrenght * pow(max(0,dot(swelledNormal,H)),_SpecularRange);
				col += real4(specular,1);
				
				//岸边浪花
				i.uv.y -= _Time.y*_WaveSpeed;
				real4 foamTexCol = SAMPLE_TEXTURE2D(_FoamTex,sampler_FoamTex,i.uv);
				real4 foamCol = saturate((0.8-height) * (foamTexCol.r  +foamTexCol.g )* diffZ) * step(diffZ,_Edge) * step(ratioZ,_Edge);
				foamCol = step(0.5,foamCol);
				col += foamCol;
				
				// 菲涅尔反射
				float f0 = 0.02;
    			float vReflect = f0 + (1-f0) * pow(1 - dot(worldViewDir,swelledNormal),5);
				vReflect = saturate(vReflect * 2.0);				
				col = lerp(col , reflectionColor , vReflect);

				//地平线处边缘光，使海水更通透
				col += ddy(length(v.xz))/200;
				//接近海滩部分更透明
				float alpha = saturate(diffZ);			
                col.a = alpha;

				return col;
			}
			ENDHLSL
		}
	}
}