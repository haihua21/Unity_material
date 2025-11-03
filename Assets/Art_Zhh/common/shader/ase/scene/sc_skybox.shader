// Made with Amplify Shader Editor v1.9.1.5
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "sc_skybox"
{
	Properties
	{
		[NoScaleOffset]_CubeMap("CubeMap", CUBE) = "white" {}
		_TintColor("Tint Color", Color) = (0.4901961,0.4705883,0.4705883,1)
		[Gamma]_Exposure("Exposure", Range( 0 , 8)) = 1
		[Toggle(_ROTATION_ON_ON)] _Rotation_On("Rotation_On", Float) = 0
		_Speed_1("Speed_1", Float) = 0.78
		[IntRange]_Rotation("Rotation", Range( 0 , 360)) = 0
		[Toggle(_ENABLEFOG_ON)] _EnableFog("Enable Fog", Float) = 0
		_FogHeight("Fog Height", Range( 0 , 1)) = 0.5
		_FogSmoothness("Fog Smoothness", Range( 0.01 , 1)) = 0.33
		_FogFill("Fog Fill", Range( 0 , 1)) = 0.23
		[Toggle(_ENABLEBILLBOARD_ON)] _EnableBillboard("Enable  Billboard", Float) = 0
		_BaseColor("Base Color", Color) = (1,1,1,1)
		_BillboardMap("Billboard Map", 2D) = "white" {}
		_YTile("Y Tile", Range( 1 , 20)) = 1
		_XTile("X Tile", Range( 1 , 10)) = 1
		_Yposition("Y position", Range( -10 , 10)) = 0
		_Xposition("Xposition", Range( 0 , 10)) = 0
		_XSmooth("X Smooth", Range( 0.8 , 1)) = 1
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Off
		CGPROGRAM
		#include "UnityShaderVariables.cginc"
		#pragma target 2.0
		#pragma shader_feature_local _ENABLEBILLBOARD_ON
		#pragma shader_feature_local _ENABLEFOG_ON
		#pragma shader_feature_local _ROTATION_ON_ON
		#pragma surface surf Unlit keepalpha addshadow fullforwardshadows vertex:vertexDataFunc 
		struct Input
		{
			float3 vertexToFrag32;
			float3 worldPos;
		};

		uniform samplerCUBE _CubeMap;
		uniform float _Rotation;
		uniform float4 _TintColor;
		uniform float _Exposure;
		uniform float _FogHeight;
		uniform float _FogSmoothness;
		uniform float _FogFill;
		uniform sampler2D _BillboardMap;
		uniform float _Speed_1;
		uniform float _XTile;
		uniform float _YTile;
		uniform float _Yposition;
		uniform float4 _BaseColor;
		uniform float _XSmooth;
		uniform float _Xposition;

		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float3 ase_worldPos = mul( unity_ObjectToWorld, v.vertex );
			float lerpResult35 = lerp( 1.0 , ( unity_OrthoParams.y / unity_OrthoParams.x ) , unity_OrthoParams.w);
			float Camera_Mode37 = lerpResult35;
			float3 appendResult29 = (float3(ase_worldPos.x , ( ase_worldPos.y * Camera_Mode37 ) , ase_worldPos.z));
			float3 normalizeResult31 = normalize( appendResult29 );
			float temp_output_15_0 = radians( _Rotation );
			float3 appendResult19 = (float3(cos( temp_output_15_0 ) , 0.0 , ( sin( temp_output_15_0 ) * -1.0 )));
			float3 appendResult21 = (float3(0.0 , Camera_Mode37 , 0.0));
			float3 appendResult22 = (float3(sin( temp_output_15_0 ) , 0.0 , cos( temp_output_15_0 )));
			float3 normalizeResult28 = normalize( ase_worldPos );
			#ifdef _ROTATION_ON_ON
				float3 staticSwitch41 = mul( float3x3(appendResult19, appendResult21, appendResult22), normalizeResult28 );
			#else
				float3 staticSwitch41 = normalizeResult31;
			#endif
			o.vertexToFrag32 = staticSwitch41;
		}

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			float4 CubeMap82 = ( texCUBElod( _CubeMap, float4( i.vertexToFrag32, 0.0) ) * unity_ColorSpaceDouble * _TintColor * _Exposure );
			float3 ase_worldPos = i.worldPos;
			float3 normalizeResult85 = normalize( ase_worldPos );
			float3 break86 = normalizeResult85;
			float2 appendResult108 = (float2(break86.x , break86.y));
			float2 temp_cast_0 = (0.0).xx;
			float2 temp_cast_1 = (_FogHeight).xx;
			float2 temp_cast_2 = (0.0).xx;
			float2 temp_cast_3 = (1.0).xx;
			float2 temp_cast_4 = (( 1.0 - _FogSmoothness )).xx;
			float2 temp_cast_5 = (0.0).xx;
			float2 lerpResult97 = lerp( saturate( pow( (temp_cast_2 + (abs( appendResult108 ) - temp_cast_0) * (temp_cast_3 - temp_cast_2) / (temp_cast_1 - temp_cast_0)) , temp_cast_4 ) ) , temp_cast_5 , _FogFill);
			float2 Fog_Mask100 = lerpResult97;
			float4 lerpResult43 = lerp( UNITY_LIGHTMODEL_AMBIENT , CubeMap82 , float4( Fog_Mask100, 0.0 , 0.0 ));
			#ifdef _ENABLEFOG_ON
				float4 staticSwitch44 = lerpResult43;
			#else
				float4 staticSwitch44 = CubeMap82;
			#endif
			float3 FinalColor103 = (staticSwitch44).rgb;
			float mulTime287 = _Time.y * _Speed_1;
			float3 worldToObj182 = mul( unity_WorldToObject, float4( ase_worldPos, 1 ) ).xyz;
			float temp_output_222_0 = ( worldToObj182.x * _XTile );
			float3 normalizeResult113 = normalize( ase_worldPos );
			float3 break114 = normalizeResult113;
			float temp_output_145_0 = ( ( break114.y * _YTile ) - _Yposition );
			float clampResult144 = clamp( temp_output_145_0 , 0.0 , 1.0 );
			float YTile225 = clampResult144;
			float2 appendResult115 = (float2(temp_output_222_0 , YTile225));
			float2 CusUV270 = appendResult115;
			float2 panner286 = ( mulTime287 * float2( 1,0 ) + CusUV270);
			float4 temp_output_168_0 = ( tex2D( _BillboardMap, panner286 ) * _BaseColor );
			float clampResult158 = clamp( ( ceil( temp_output_145_0 ) * ( 1.0 - floor( temp_output_145_0 ) ) ) , 0.0 , 1.0 );
			float Alpha152 = abs( clampResult158 );
			float temp_output_242_0 = ( ( _XTile * _XSmooth ) / ( _XTile - 0.5 ) );
			float clampResult246 = clamp( ( ( break114.x * -1.0 ) * temp_output_242_0 ) , 0.0 , 1.0 );
			float clampResult205 = clamp( ( ( break114.x * 1.0 ) * temp_output_242_0 ) , 0.0 , 1.0 );
			float UVmask251 = saturate( ( 1.0 - (0.0 + (( ( clampResult246 + clampResult205 ) - _Xposition ) - 0.0) * (1.0 - 0.0) / (0.1 - 0.0)) ) );
			float3 lerpResult148 = lerp( FinalColor103 , (temp_output_168_0).rgb , saturate( ( (temp_output_168_0).a * ( Alpha152 * UVmask251 ) ) ));
			#ifdef _ENABLEBILLBOARD_ON
				float3 staticSwitch268 = lerpResult148;
			#else
				float3 staticSwitch268 = FinalColor103;
			#endif
			float3 test111106 = staticSwitch268;
			o.Emission = test111106;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19105
Node;AmplifyShaderEditor.CommentaryNode;269;-949.3648,1788.623;Inherit;False;2820.097;834.9868;Comment;19;170;117;271;268;148;167;264;250;150;166;171;174;173;172;168;286;287;288;106;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;165;-5550.535,3580.984;Inherit;False;2013.717;678.5;Y;13;118;146;120;163;162;153;164;158;160;152;145;144;225;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;101;-908.0869,897.1003;Inherit;False;2622.87;596.6007;Fog Coords on screen;16;99;96;93;95;89;92;84;100;98;97;94;90;88;87;86;85;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;68;-568,80;Inherit;False;2294.189;596.0556;Cubemap Coordinates;21;14;15;16;17;18;19;40;30;29;41;26;39;22;27;31;28;25;24;23;21;20;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;45;402.542,-856.3556;Inherit;False;1288.848;339.0184;Color;7;103;175;44;102;83;42;43;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;38;766.1328,-400.2614;Inherit;False;893.2548;295.8721;Camera_Mode;5;33;34;36;35;37;;1,1,1,1;0;0
Node;AmplifyShaderEditor.OrthoParams;33;816.1329,-263.3896;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;34;1071.388,-276.2615;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;36;1069.388,-350.2616;Inherit;False;Constant;_Float1;Float 1;4;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;35;1251.388,-281.2615;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;43;832.327,-778.1861;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FogAndAmbientColorsNode;42;452.5417,-791.0129;Inherit;False;UNITY_LIGHTMODEL_AMBIENT;0;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;37;1435.388,-287.2614;Inherit;False;Camera_Mode;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;20;27.96449,319.335;Inherit;False;Constant;_Float0;Float 0;4;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;21;357.9645,289.335;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SinOpNode;23;22.96449,436.3351;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CosOpNode;24;19.96449,513.3363;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.MatrixFromVectors;25;572.9646,188.335;Inherit;False;FLOAT3x3;True;4;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3x3;0
Node;AmplifyShaderEditor.DynamicAppendNode;22;357.1549,456.5258;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;39;154.5864,406.2888;Inherit;False;37;Camera_Mode;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;26;1073.865,134.2315;Inherit;False;2;2;0;FLOAT3x3;0,0,0,0,1,1,1,0,1;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;19;358.9645,162.335;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;18;129.4791,218.9987;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;17;-7.027205,218.7074;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CosOpNode;16;-6.027205,143.7074;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RadiansOpNode;15;-203.0272,315.7074;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;14;-529.0271,333.7074;Inherit;False;Property;_Rotation;Rotation;5;1;[IntRange];Create;True;0;0;0;False;0;False;0;0;0;360;0;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;41;1483.297,288.5267;Inherit;False;Property;_Rotation_On;Rotation_On;3;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;28;861.5,342.2215;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldPosInputsNode;27;584.4099,384.979;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;29;1009.72,415.3203;Inherit;True;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;30;828.9907,525.5847;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;40;584.4687,575.6437;Inherit;False;37;Camera_Mode;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;31;1243.207,411.4141;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.VertexToFragmentNode;32;1812.585,291.8508;Inherit;False;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;6;2133.121,256.3228;Inherit;True;Property;_CubeMap;CubeMap;0;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;LockedToCube;False;Object;-1;MipLevel;Cube;8;0;SAMPLERCUBE;;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;70;2901.114,280.5654;Inherit;False;4;4;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorSpaceDouble;69;2612.114,350.5654;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;72;2608.114,527.5656;Inherit;False;Property;_TintColor;Tint Color;1;0;Create;True;0;0;0;False;0;False;0.4901961,0.4705883,0.4705883,1;0.4901961,0.4705883,0.4705883,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;82;3086.951,363.2266;Inherit;False;CubeMap;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;83;515.9159,-710.8559;Inherit;False;82;CubeMap;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;13;2594.644,717.7689;Inherit;False;Property;_Exposure;Exposure;2;1;[Gamma];Create;True;0;0;0;False;0;False;1;0;0;8;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;88;568.5366,1001.101;Inherit;False;5;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT2;1,1;False;3;FLOAT2;0,0;False;4;FLOAT2;1,1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;90;357.5363,1246.101;Inherit;False;Constant;_Float4;Float 4;6;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;94;281.9025,1361.244;Inherit;False;Property;_FogSmoothness;Fog Smoothness;8;0;Create;True;0;0;0;False;0;False;0.33;0;0.01;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;97;1297.783,996.4495;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;98;1105.783,1094.45;Inherit;False;Constant;_Float5;Float 5;8;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;100;1490.783,991.4495;Inherit;False;Fog_Mask;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;102;520.1063,-622.98;Inherit;False;100;Fog_Mask;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StaticSwitch;44;1057.235,-705.356;Inherit;False;Property;_EnableFog;Enable Fog;6;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;92;-16.83937,1086.83;Inherit;False;Property;_FogHeight;Fog Height;7;0;Create;True;0;0;0;False;0;False;0.5;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;89;326.8338,1151.895;Inherit;False;Constant;_Float3;Float 3;6;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;95;645.3856,1343.954;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;93;801.049,1001.715;Inherit;False;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SaturateNode;96;993.2433,1000.798;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;99;1001.694,1203.927;Inherit;False;Property;_FogFill;Fog Fill;9;0;Create;True;0;0;0;False;0;False;0.23;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;110;-362.5566,791.2418;Inherit;False;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;109;-524.5566,739.2418;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WorldPosInputsNode;84;-752,944;Inherit;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NormalizeNode;85;-480,944;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;86;-256.1593,948.2745;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.DynamicAppendNode;108;-87.99023,753.875;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.AbsOpNode;87;104.5363,966.1006;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;104;2657.345,3484.801;Inherit;False;103;FinalColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;81;2982.061,3724.628;Float;False;True;-1;0;ASEMaterialInspector;0;0;Unlit;sc_skybox;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Off;0;False;;0;False;;False;0;False;;0;False;;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;0;0;False;;0;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.GetLocalVarNode;107;2659.842,3748.893;Inherit;False;106;test111;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;175;1278.729,-700.6844;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;103;1487.105,-701.98;Inherit;False;FinalColor;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldNormalVector;48;1233.412,3840.863;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;50;1235.076,4030.674;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DotProductOpNode;49;1501.277,3912.471;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;51;1644.076,3956.674;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;53;2211.308,3943.717;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LightColorNode;55;1923.448,4344.772;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.CustomExpressionNode;46;1389.723,4388.071;Inherit;False; ;1;Create;1;True;In0;FLOAT;0;In;;Inherit;False;My Custom Expression;True;False;0;;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;52;1494.648,4102.531;Inherit;False;Constant;_Float2;Float 2;5;0;Create;True;0;0;0;False;0;False;30;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.VertexToFragmentNode;47;1897.522,3949.548;Inherit;True;False;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LightAttenuation;54;1696.349,4327.37;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;168;191.8636,2157.838;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;172;684.5499,2276.551;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;173;838.6548,2315.807;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;174;388.8395,2101.874;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;171;391.7363,2234.644;Inherit;False;False;False;False;True;1;0;COLOR;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;166;796.8932,1838.623;Inherit;False;103;FinalColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;150;378.1787,2343.035;Inherit;False;152;Alpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;250;609.8761,2435.115;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;264;354.6796,2487.369;Inherit;False;251;UVmask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;167;800.8724,2005.384;Inherit;False;Constant;_Float8;Float 8;13;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;148;1017.17,2057.434;Inherit;True;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;268;1329.409,2015.77;Inherit;False;Property;_EnableBillboard;Enable  Billboard;10;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;204;-4540.038,2140.657;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.FloorOpNode;207;-4080.32,2140.543;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;205;-4293.275,2143.213;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;255;-4071.714,1919.769;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;254;-3614.911,1797.87;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;248;-3852.963,2050.318;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;259;-3435.948,1803.079;Inherit;True;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;260;-3127.948,1818.711;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;262;-2940.122,1815.646;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;251;-2775.02,1811.326;Inherit;False;UVmask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;256;-3729.517,1922.676;Inherit;False;Property;_Xposition;Xposition;17;0;Create;True;0;0;0;False;0;False;0;0;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;179;-4798.103,2103.428;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;242;-4955.525,2044.605;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;4;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;243;-5169.294,2137.541;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;266;-5171.451,2012.766;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.94;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;121;-5545.014,2155.988;Inherit;False;Property;_XTile;X Tile;15;0;Create;True;0;0;0;False;0;False;1;1;1;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;267;-5533.845,2034.664;Inherit;False;Property;_XSmooth;X Smooth;18;0;Create;True;0;0;0;False;0;False;1;1;0.8;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;118;-5165.524,3705.469;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;145;-4856.327,3708.253;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;120;-5500.535,3802.136;Inherit;False;Property;_YTile;Y Tile;14;0;Create;True;0;0;0;False;0;False;1;0;1;20;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;163;-4599.068,4043.95;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FloorOpNode;162;-4734.084,4036.355;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CeilOpNode;153;-4575.833,3936.912;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;164;-4423.776,3979.736;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;158;-4260.768,3976.548;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;160;-4020.074,3977.823;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;144;-4583.894,3676.665;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;152;-3848.607,3974.154;Inherit;False;Alpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;225;-4299.347,3691.073;Inherit;False;YTile;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;146;-5187.325,3945.249;Inherit;False;Property;_Yposition;Y position;16;0;Create;True;0;0;0;False;0;False;0;0;-10;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;112;-6080.884,3270.838;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NormalizeNode;113;-5841.883,3271.176;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;125;-5553.415,1302.519;Inherit;True;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;142;-5032.585,1308.938;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FractNode;141;-4693.375,1265.529;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;143;-5290.586,1405.938;Inherit;False;Constant;_Float7;Float 7;12;0;Create;True;0;0;0;False;0;False;5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;133;-4400.73,1250.462;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;135;-4363.218,1414.417;Inherit;False;Constant;_Float6;Float 6;12;0;Create;True;0;0;0;False;0;False;-1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;134;-4146.67,1294.408;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;226;-3569.859,3375.7;Inherit;False;225;YTile;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;115;-3364.323,3269.15;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;245;-4562.917,1829.532;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;244;-4864.657,1746.124;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.FloorOpNode;247;-4078.421,1809.423;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;114;-5632.169,3267.518;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SamplerNode;117;-219.971,2019.964;Inherit;True;Property;_BillboardMap;Billboard Map;12;0;Create;True;0;0;0;False;0;False;-1;0aed8cbdfac4eb34d8bdb6d8e6b28f89;0aed8cbdfac4eb34d8bdb6d8e6b28f89;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ClampOpNode;246;-4319.056,1846.957;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;278;-4513.093,3041.023;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;273;-4802.534,2631.054;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;222;-5040.842,3048.919;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;277;-4090.015,3006.643;Inherit;True;Property;_BillboardMap1;Billboard Map;13;0;Create;True;0;0;0;False;0;False;-1;0aed8cbdfac4eb34d8bdb6d8e6b28f89;0aed8cbdfac4eb34d8bdb6d8e6b28f89;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;276;-4311.592,3166.105;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CeilOpNode;275;-4200.758,2647.941;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;280;-4416.881,2507.105;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;279;-4447.881,2630.105;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;281;-4534.881,2852.105;Inherit;False;Property;_Float9;Float 9;19;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;283;-5088.311,2621.394;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RotatorNode;285;-4570.245,3319.667;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TransformPositionNode;182;-5688.463,2903.589;Inherit;False;World;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ColorNode;170;-26.35773,2298.142;Inherit;False;Property;_BaseColor;Base Color;11;0;Create;True;0;0;0;False;0;False;1,1,1,1;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;288;-852.8667,2233.99;Inherit;False;Property;_Speed_1;Speed_1;4;0;Create;True;0;0;0;False;0;False;0.78;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;287;-686.6697,2236.866;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;270;-3181.529,3250.55;Inherit;False;CusUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;106;1621.326,2016.414;Inherit;False;test111;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;271;-806.2932,2045.695;Inherit;False;270;CusUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;286;-448.2798,2064.317;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;1,0;False;1;FLOAT;1;False;1;FLOAT2;0
WireConnection;34;0;33;2
WireConnection;34;1;33;1
WireConnection;35;0;36;0
WireConnection;35;1;34;0
WireConnection;35;2;33;4
WireConnection;43;0;42;0
WireConnection;43;1;83;0
WireConnection;43;2;102;0
WireConnection;37;0;35;0
WireConnection;21;0;20;0
WireConnection;21;1;39;0
WireConnection;21;2;20;0
WireConnection;23;0;15;0
WireConnection;24;0;15;0
WireConnection;25;0;19;0
WireConnection;25;1;21;0
WireConnection;25;2;22;0
WireConnection;22;0;23;0
WireConnection;22;1;20;0
WireConnection;22;2;24;0
WireConnection;26;0;25;0
WireConnection;26;1;28;0
WireConnection;19;0;16;0
WireConnection;19;1;20;0
WireConnection;19;2;18;0
WireConnection;18;0;17;0
WireConnection;17;0;15;0
WireConnection;16;0;15;0
WireConnection;15;0;14;0
WireConnection;41;1;31;0
WireConnection;41;0;26;0
WireConnection;28;0;27;0
WireConnection;29;0;27;1
WireConnection;29;1;30;0
WireConnection;29;2;27;3
WireConnection;30;0;27;2
WireConnection;30;1;40;0
WireConnection;31;0;29;0
WireConnection;32;0;41;0
WireConnection;6;1;32;0
WireConnection;70;0;6;0
WireConnection;70;1;69;0
WireConnection;70;2;72;0
WireConnection;70;3;13;0
WireConnection;82;0;70;0
WireConnection;88;0;87;0
WireConnection;88;1;89;0
WireConnection;88;2;92;0
WireConnection;88;3;89;0
WireConnection;88;4;90;0
WireConnection;97;0;96;0
WireConnection;97;1;98;0
WireConnection;97;2;99;0
WireConnection;100;0;97;0
WireConnection;44;1;83;0
WireConnection;44;0;43;0
WireConnection;95;0;94;0
WireConnection;93;0;88;0
WireConnection;93;1;95;0
WireConnection;96;0;93;0
WireConnection;110;0;109;0
WireConnection;109;0;84;1
WireConnection;109;1;84;2
WireConnection;85;0;84;0
WireConnection;86;0;85;0
WireConnection;108;0;86;0
WireConnection;108;1;86;1
WireConnection;87;0;108;0
WireConnection;81;2;107;0
WireConnection;175;0;44;0
WireConnection;103;0;175;0
WireConnection;49;0;48;0
WireConnection;49;1;50;0
WireConnection;51;0;49;0
WireConnection;51;1;52;0
WireConnection;53;0;47;0
WireConnection;53;1;55;0
WireConnection;47;0;51;0
WireConnection;168;0;117;0
WireConnection;168;1;170;0
WireConnection;172;0;171;0
WireConnection;172;1;250;0
WireConnection;173;0;172;0
WireConnection;174;0;168;0
WireConnection;171;0;168;0
WireConnection;250;0;150;0
WireConnection;250;1;264;0
WireConnection;148;0;166;0
WireConnection;148;1;174;0
WireConnection;148;2;173;0
WireConnection;268;1;166;0
WireConnection;268;0;148;0
WireConnection;204;0;179;0
WireConnection;204;1;242;0
WireConnection;207;0;205;0
WireConnection;205;0;204;0
WireConnection;255;0;246;0
WireConnection;255;1;205;0
WireConnection;254;0;255;0
WireConnection;254;1;256;0
WireConnection;248;0;247;0
WireConnection;248;1;207;0
WireConnection;259;0;254;0
WireConnection;260;0;259;0
WireConnection;262;0;260;0
WireConnection;251;0;262;0
WireConnection;179;0;114;0
WireConnection;242;0;266;0
WireConnection;242;1;243;0
WireConnection;243;0;121;0
WireConnection;266;0;121;0
WireConnection;266;1;267;0
WireConnection;118;0;114;1
WireConnection;118;1;120;0
WireConnection;145;0;118;0
WireConnection;145;1;146;0
WireConnection;163;0;162;0
WireConnection;162;0;145;0
WireConnection;153;0;145;0
WireConnection;164;0;153;0
WireConnection;164;1;163;0
WireConnection;158;0;164;0
WireConnection;160;0;158;0
WireConnection;144;0;145;0
WireConnection;152;0;160;0
WireConnection;225;0;144;0
WireConnection;113;0;112;0
WireConnection;142;0;125;0
WireConnection;142;1;143;0
WireConnection;141;0;142;0
WireConnection;134;0;133;1
WireConnection;134;1;135;0
WireConnection;115;0;222;0
WireConnection;115;1;226;0
WireConnection;245;0;244;0
WireConnection;245;1;242;0
WireConnection;244;0;114;0
WireConnection;247;0;246;0
WireConnection;114;0;113;0
WireConnection;117;1;286;0
WireConnection;246;0;245;0
WireConnection;278;0;222;0
WireConnection;273;0;182;1
WireConnection;222;0;182;1
WireConnection;222;1;121;0
WireConnection;277;1;276;0
WireConnection;276;0;222;0
WireConnection;276;1;225;0
WireConnection;275;0;279;0
WireConnection;279;0;273;0
WireConnection;279;1;281;0
WireConnection;182;0;112;0
WireConnection;287;0;288;0
WireConnection;270;0;115;0
WireConnection;106;0;268;0
WireConnection;286;0;271;0
WireConnection;286;1;287;0
ASEEND*/
//CHKSM=A2C90E9B6A03E8EB84BB72A2D03CA943C2E0FE5A