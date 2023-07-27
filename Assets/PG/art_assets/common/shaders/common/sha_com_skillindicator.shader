// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Skill/ClipSkillIndicator"
{
Properties {
    _TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
    _MainTex ("Particle Texture", 2D) = "white" {}
	[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Float) = 4  //声明外部控制开关
}

Category {
    Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }
    Blend SrcAlpha OneMinusSrcAlpha
    Cull Off Lighting Off ZWrite Off
	ZTest [_ZTest] //获取值应用
    SubShader {
        Pass {

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"

            struct appdata_t {
                float4 vertex : POSITION;
                fixed4 color : COLOR;
                float2 texcoord : TEXCOORD0;
                float4 worldPos: TEXCOORD1;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float2 texcoord : TEXCOORD0;
                float4 worldPos: TEXCOORD1; 
            };
			
			sampler2D _MainTex;            
            float4 _MainTex_ST;
			fixed4 _TintColor;
			
            sampler2D _SkillIndicatorDepthTex;
            float4x4 _SkillIndicatorProjection;
            
            v2f vert (appdata_t v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.color = v.color * _TintColor;
                o.texcoord = TRANSFORM_TEX(v.texcoord,_MainTex);

			    float4 worldPos = mul(UNITY_MATRIX_M, v.vertex);
				o.worldPos.xyz = worldPos.xyz ;
				o.worldPos.w = 1 ;
				
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
		        // convert to light camera space
				fixed4 lightClipPos = mul(_SkillIndicatorProjection , i.worldPos);
			    lightClipPos.xyz = lightClipPos.xyz / lightClipPos.w ; //(-1 ~ 1)
				float3 pos = lightClipPos * 0.5 + 0.5 ; //(0 ~ 1)

			    //get depth
				float4 depthRGBA = tex2D(_SkillIndicatorDepthTex,pos.xy);

                //float depth = depthRGBA.r;
				float depth = DecodeFloatRGBA(depthRGBA);

                clip(lightClipPos.z + 0.005 - depth);
                
                fixed4 col = tex2D(_MainTex, i.texcoord);
             
                return col;
            }
            ENDCG
        }
    }
}

}
