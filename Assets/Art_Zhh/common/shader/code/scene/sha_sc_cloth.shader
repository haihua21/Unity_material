Shader "code/scene/sha_sc_cloth" 
{
    Properties 
    {
        _MainTex ("Layer_A Albedo (RGB)", 2D) = "white" {} 
        _SelfIllum("Self Illumination", range(0, 1)) = 0

        //[NoScaleOffset] _DetailAlbedo ("DETAIL_Albedo", 2D) = "grey" {}
        //_DetailTiling("DETAIL_Tiling", float) = 2  

        _WaveFreq("Wave Frequency", float) = 20
        _WaveHeight("Wave Height", float) = 0.1  
        _WaveScale("Wave Scale", float) = 1
        
    }
  
    SubShader
    {        
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue" = "Geometry" }
        // LOD 400        
        Cull Back
        AlphaToMask Off
        LOD 400

    Pass
    {    
        HLSLPROGRAM

        #pragma vertex vert
        #pragma fragment frag
        #pragma target 3.0 

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"   
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        // #pragma surface surf Lambert vertex:vert addshadow noforwardadd nolightmap   

        struct appdata 
        {
            float4 vertex : POSITION;
            float2 uv: TEXCOORD0; 
            float4 color: COLOR;      
        };
        struct v2f
        {
            float2 uv:TEXCOORD0;
            float4 vertex: SV_POSITION;
            float4 color: COLOR;
        };
          
       CBUFFER_START(UnityPerMaterial)    
        float4 _MainTex_ST;
        //half _DetailTiling;
        half _SelfIllum;
        half _WaveFreq;
        half _WaveHeight; 
        half _WaveScale;   
       CBUFFER_END  

        sampler2D _MainTex;
        //sampler2D _DetailAlbedo;

        half3 windanim (half3 vertex_xyz, half2 color, half _WaveFreq, half _WaveHeight, half _WaveScale)
        {
			half phase_slow = _Time * _WaveFreq; 
	        half phase_med = _Time * 4 * _WaveFreq;
	           
	        half offset = (vertex_xyz.x + (vertex_xyz.z * _WaveScale)) * _WaveScale;
	        half offset2 = (vertex_xyz.x + (vertex_xyz.z * _WaveScale * 2)) * _WaveScale * 2;
	         
	        half sin1 = sin(phase_slow + offset);
	        half sin2 = sin(phase_med + offset2);          
	 
	        half sin_combined = (sin1 * 4) + sin2 ;
	           
	        half wind_x =  sin_combined * _WaveHeight * 0.1;
	        half3 wind_xyz = half3(wind_x, wind_x * 2, wind_x);

	        wind_xyz = wind_xyz * pow(color.r, 2);	     
			return wind_xyz;
		}

        v2f vert (appdata v)
        {                                                                      
            v2f o;  
            
            half3 aa = v.color;
            o.vertex.xyz = v.vertex.xyz + windanim(v.vertex.xyz, aa, _WaveFreq, _WaveHeight, _WaveScale);      
            o.vertex = TransformObjectToHClip(o.vertex.xyz);
            o.uv = v.uv;
        	o.color = v.color;
            return o;
        }
        
        half4 frag (v2f i) :SV_Target
        {
        	half4 color = half4(0,0,0,1);
            half4 albedo = tex2D (_MainTex, i.uv );  
            //// half detailAlbedo = tex2D(_DetailAlbedo, i.uv * _DetailTiling).r * unity_ColorSpaceDouble.rgb; 
            //half detailAlbedo = tex2D(_DetailAlbedo, i.uv * _DetailTiling).r ; 
            //albedo.rgb = albedo.rgb * LerpWhiteTo(detailAlbedo, 1);
            half3 emission = albedo.rgb * _SelfIllum;
        	color.rgb = albedo.rgb + emission;
            return half4(color.rgb, 1.h);
        }
        ENDHLSL
    }
    }    
}