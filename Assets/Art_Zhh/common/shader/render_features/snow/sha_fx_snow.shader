// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/snow" {
    Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
    }
	SubShader {
   		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
		ZWrite Off
		Cull Off
		// alpha blending
		//float4 result = fragment_output.aaaa * fragment_output + (float4(1.0, 1.0, 1.0, 1.0) - fragment_output.aaaa) * pixel_color;
		//用前一个队列的输出的Alpha通道作为不透明度
		Blend SrcAlpha OneMinusSrcAlpha 
		
        Pass {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
 			#pragma target 3.0
 			
 			#include "UnityCG.cginc"

            uniform sampler2D _MainTex;

 			struct appdata_custom {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

 			struct v2f {
 				float4 pos:SV_POSITION;
				float2 uv:TEXCOORD0;
 			};
 			
 			float4x4 _PrevInvMatrix;
			float3   _TargetPosition;
			float    _Range;
			float    _RangeR;
			float    _Size;
			float3   _MoveTotal;
			float3   _CamUp;
   
			v2f vert(appdata_custom v)
			{
				//摄像机正前方距离为Range的位置
				float3 target = _TargetPosition;
				float3 trip;
				float3 mv = v.vertex.xyz;
				mv += _MoveTotal;
				//顶点分布的区域应该是-_Range到_Range,因此target-mv的范围应该也是这个，因此此处的trip值的范围为，0~1,计算的最终目的还是为了让雪花始终在摄像机的正前方
				trip = floor(((target - mv)*_RangeR + 1) * 0.5);
				//经过前面的坐标系的换算再次将范围扩大到2个_Range范围
				trip *= (_Range * 2);
				mv += trip;

				//让顶点始终保持在摄像机的正上方位置
				float3 diff = _CamUp * _Size;
				float3 finalposition;
				float3 tv0 = mv;
				
				//tv0.x += sin(mv.x*0.2) * sin(mv.y*0.3) * sin(mv.x*0.9) * sin(mv.y*0.8);
				//tv0.z += sin(mv.x*0.1) * sin(mv.y*0.2) * sin(mv.x*0.8) * sin(mv.y*1.2);
				
				//从给定的局部坐标到摄像机坐标进行转换，目的是让顶点始终朝向摄像机
				float3 eyeVector = ObjSpaceViewDir(float4(tv0, 0));
				//float3 eyeVector = mv;
				float3 sideVector = normalize(cross(eyeVector, diff));

				//最终的计算
				tv0 += (v.texcoord.x - 0.5f)*sideVector * _Size;
				tv0 += (v.texcoord.y - 0.5f)*diff;
				finalposition = tv0;
				
				//将其最终转换到屏幕上
				v2f o;
				o.pos = UnityObjectToClipPos(float4(finalposition, 1));
				o.uv = MultiplyUV(UNITY_MATRIX_TEXTURE0, v.texcoord);
				return o;
			}

            fixed4 frag(v2f i) : SV_Target
            {
				return tex2D(_MainTex, i.uv);
            }

            ENDCG
        }
    }
}
