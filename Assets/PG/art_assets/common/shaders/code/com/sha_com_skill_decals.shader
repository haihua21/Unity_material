Shader "code/common/skill_decals"
{
    Properties
    {
        _MainTex ("Base Map", 2D) = "white" {}
        [MaterialToggle(_TEX_ON)] _Maintex_Is_Circle ("Maintex_Is_Circle", float) = 0
        _Color ("Color:A通道为透明度",Color) = (1,1,1,1)
        _CircleScale("Circle Scale",Range(0,1)) = 0.5
        _CircleThickness("Circle thickness",Range(0,1)) =0.1

    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Transparent" 
            "Queue"="Transparent" 
            // "IgnoreProjector"="true" 
            "DisableBatching"="true"            
            //"LightMode" = "ForwardBase"
        }

		Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Ztest Off
		Cull Front

        Pass
        {
            HLSLPROGRAM            
            #pragma vertex vert
            #pragma fragment frag            
            #pragma multi_compile_fwdbase_fullshadows    
            #pragma multi_compile _TEX_OFF _TEX_ON


            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityLightingCommon.cginc"     


            sampler2D _CameraDepthTexture;
            sampler2D _CameraDepthNormalsTexture;   

            float3 DepthToWorldPosition(float4 screenPos)
            {
                float depth = Linear01Depth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture,screenPos)));
                float4 ndcPos = (screenPos/screenPos.w)*2-1;
                float3 clipPos = float3(ndcPos.x,ndcPos.y,1)* _ProjectionParams.z;
                float3 viewPos = mul(unity_CameraInvProjection,clipPos.xyzz).xyz * depth;
                float3 worldPos = mul(UNITY_MATRIX_I_V,float4(viewPos,1)).xyz;
                return worldPos;
           }    
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 screenPos : TEXCOORD1;
                float2 uv : TEXCOORD0;
                
               // float3 ray : TEXCOORD1;     
                SHADOW_COORDS(3)
                
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float _CircleScale;
            float _CircleThickness;
                                
            

            v2f vert (appdata v)
            {
                v2f o;
                
                o.pos = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.pos);
                o.uv = mul(unity_ObjectToWorld, v.vertex) - _WorldSpaceCameraPos;

               //#if _TEX_ON
               // o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);           
               // #endif 

              
                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {   
                            
                float3 pos = DepthToWorldPosition(i.screenPos);
                float3 localpos = mul(unity_WorldToObject, float4(pos,1)).xyz;               
                clip(0.5 - abs(localpos));                
                float2 decalUV = localpos.xy + 0.5;

                float2 circleUV = (i.uv -0.5) * (distance(i.uv - 0.5 ,float2( 0,0 ))* 0.0);

                 circleUV = decalUV + circleUV;
                 float2 circleUV1 = step(distance(circleUV,0.5), _CircleScale * 0.5);
                 float2 circleUV2 = step(distance(circleUV,0.5), (_CircleScale * 0.5 - _CircleThickness * 0.1));
                 float4 circleUV3 = (circleUV1 - circleUV2).xxxx;

                float4 col = circleUV3 *_Color;

             #if _TEX_ON
                   col = tex2D(_MainTex, decalUV);  
                   col *= _Color;                                
             #endif    

                UNITY_LIGHT_ATTENUATION(atten, i, i.pos);

                col *= atten;

                return col ;
            }
            ENDHLSL
        }
    }
}

