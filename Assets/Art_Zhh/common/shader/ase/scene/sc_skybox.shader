// Made with Amplify Shader Editor v1.9.1.5
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "sc_skybox"
{
	Properties
	{
		[NoScaleOffset]_CubeMap("CubeMap", CUBE) = "white" {}
		_TintColor("Tint Color", Color) = (0.4901961,0.4705883,0.4705883,1)
		[Gamma]_Exposure("Exposure", Range( 0 , 8)) = 1
		_RotationSpeed("RotationSpeed", Range( -2 , 2)) = 0
		[IntRange]_Rotation("Rotation", Range( 0 , 360)) = 0
		[Toggle(_ENABLEBILLBOARD_ON)] _EnableBillboard("Enable  Billboard", Float) = 0
		[NoScaleOffset]_BillboardMap("Billboard Map", 2D) = "white" {}
		_BillboardColor("Billboard Color", Color) = (1,1,1,1)
		_Speed_1("Speed_1", Float) = 0.78
		_XTile("X Tile", Range( 2 , 10)) = 2
		_YTile("Y Tile", Range( 1 , 20)) = 1
		_XPosition("X Position", Range( 0.8 , 1)) = 0.9
		_XSmooth("X Smooth", Range( 0.8 , 1)) = 1
		_Yposition("Y position", Range( -10 , 10)) = 0
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Background"  "Queue" = "Background+0" "IgnoreProjector" = "True" "ForceNoShadowCasting" = "True" "IsEmissive" = "true"  }
		Cull Off
		ZWrite Off
		CGPROGRAM
		#include "UnityShaderVariables.cginc"
		#pragma target 2.0
		#pragma shader_feature_local _ENABLEBILLBOARD_ON
		#pragma surface surf Unlit keepalpha noshadow noambient novertexlights nolightmap  nodynlightmap nodirlightmap nofog nometa noforwardadd vertex:vertexDataFunc 
		struct Input
		{
			float3 vertexToFrag32;
			float3 worldPos;
		};

		uniform samplerCUBE _CubeMap;
		uniform float _Rotation;
		uniform float _RotationSpeed;
		uniform float4 _TintColor;
		uniform float _Exposure;
		uniform sampler2D _BillboardMap;
		uniform float _Speed_1;
		uniform float _XTile;
		uniform float _YTile;
		uniform float _Yposition;
		uniform float4 _BillboardColor;
		uniform float _XSmooth;
		uniform float _XPosition;

		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float temp_output_15_0 = radians( ( _Rotation + ( _Time.y * _RotationSpeed ) ) );
			float3 appendResult19 = (float3(cos( temp_output_15_0 ) , 0.0 , ( sin( temp_output_15_0 ) * -1.0 )));
			float lerpResult35 = lerp( 1.0 , ( unity_OrthoParams.y / unity_OrthoParams.x ) , unity_OrthoParams.w);
			float Camera_Mode37 = lerpResult35;
			float3 appendResult21 = (float3(0.0 , Camera_Mode37 , 0.0));
			float3 appendResult22 = (float3(sin( temp_output_15_0 ) , 0.0 , cos( temp_output_15_0 )));
			float3 ase_worldPos = mul( unity_ObjectToWorld, v.vertex );
			float3 normalizeResult28 = normalize( ase_worldPos );
			o.vertexToFrag32 = mul( float3x3(appendResult19, appendResult21, appendResult22), normalizeResult28 );
		}

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			float3 CubeMap82 = (( texCUBElod( _CubeMap, float4( i.vertexToFrag32, 0.0) ) * unity_ColorSpaceDouble * _TintColor * _Exposure )).rgb;
			float mulTime287 = _Time.y * _Speed_1;
			float3 ase_worldPos = i.worldPos;
			float3 normalizeResult113 = normalize( ase_worldPos );
			float3 WsPosition385 = normalizeResult113;
			float temp_output_310_0 = radians( 90.0 );
			float3 appendResult306 = (float3(cos( temp_output_310_0 ) , 0.0 , ( sin( temp_output_310_0 ) * -1.0 )));
			float lerpResult35 = lerp( 1.0 , ( unity_OrthoParams.y / unity_OrthoParams.x ) , unity_OrthoParams.w);
			float Camera_Mode37 = lerpResult35;
			float3 appendResult304 = (float3(0.0 , Camera_Mode37 , 0.0));
			float3 appendResult305 = (float3(sin( temp_output_310_0 ) , 0.0 , cos( temp_output_310_0 )));
			float XUv352 = mul( WsPosition385, float3x3(appendResult306, appendResult304, appendResult305) ).x;
			float temp_output_222_0 = ( _XTile * XUv352 );
			float3 break114 = WsPosition385;
			float clampResult335 = clamp( ceil( ( break114.x * 1.0 ) ) , 0.0 , 1.0 );
			float XMask329 = clampResult335;
			float lerpResult321 = lerp( temp_output_222_0 , ( temp_output_222_0 * -1.0 ) , XMask329);
			float XTile324 = lerpResult321;
			float temp_output_145_0 = ( ( break114.y * _YTile ) - _Yposition );
			float clampResult144 = clamp( temp_output_145_0 , 0.0 , 1.0 );
			float YTile225 = clampResult144;
			float2 appendResult115 = (float2(XTile324 , YTile225));
			float2 panner286 = ( mulTime287 * float2( 1,0 ) + appendResult115);
			float4 temp_output_168_0 = ( tex2D( _BillboardMap, panner286 ) * _BillboardColor );
			float clampResult158 = clamp( ( ceil( temp_output_145_0 ) * ( 1.0 - floor( temp_output_145_0 ) ) ) , 0.0 , 1.0 );
			float Alpha152 = abs( clampResult158 );
			float temp_output_242_0 = ( ( _XTile * _XSmooth ) / ( _XTile - 0.5 ) );
			float clampResult246 = clamp( ( ( XUv352 * -1.0 ) * temp_output_242_0 ) , 0.0 , 1.0 );
			float clampResult205 = clamp( ( temp_output_242_0 * XUv352 ) , 0.0 , 1.0 );
			float UVmask251 = saturate( ( 1.0 - (0.0 + (( ( clampResult246 + clampResult205 ) - _XPosition ) - 0.0) * (1.0 - 0.0) / (0.1 - 0.0)) ) );
			float3 lerpResult148 = lerp( CubeMap82 , (temp_output_168_0).rgb , saturate( ( (temp_output_168_0).a * ( Alpha152 * UVmask251 ) ) ));
			#ifdef _ENABLEBILLBOARD_ON
				float3 staticSwitch268 = lerpResult148;
			#else
				float3 staticSwitch268 = CubeMap82;
			#endif
			float3 Color106 = staticSwitch268;
			o.Emission = Color106;
			o.Alpha = 1;
		}

		ENDCG
	}
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19105
Node;AmplifyShaderEditor.CommentaryNode;387;-6927.875,1725.822;Inherit;False;2543.903;596.9033;X Tile;23;331;321;320;319;324;222;352;386;316;310;311;317;315;313;312;309;308;307;306;305;304;303;318;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;384;-6820.967,2450.459;Inherit;False;1680.598;309.3176;Comment;8;113;114;273;335;329;275;112;385;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;375;-6844.368,1015.564;Inherit;False;3035.177;622.8008;Comment;22;204;207;205;255;248;260;262;242;266;245;244;247;246;322;323;243;259;353;354;121;267;251;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;269;-1937.298,1595.475;Inherit;False;2820.097;834.9868;Comment;21;170;117;268;148;264;250;150;166;171;174;173;172;168;286;287;288;106;115;325;226;333;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;165;-6839.329,2875.649;Inherit;False;1910.784;673.7495;Y Tile;13;146;225;144;120;145;118;162;152;160;158;164;153;163;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;68;-2212.913,693.4283;Inherit;False;3329.599;695.4656;Cubemap Coordinates;32;383;14;382;381;380;15;377;378;379;39;376;27;6;82;13;72;69;70;32;28;26;25;23;24;16;17;18;19;22;21;20;388;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;38;-703.7806,213.1671;Inherit;False;1115.255;363.8721;Camera_Mode;5;34;33;37;35;36;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;36;-400.5256,263.1669;Inherit;False;Constant;_Float1;Float 1;4;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;35;-218.5252,332.167;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;171;-596.1974,2041.494;Inherit;False;False;False;False;True;1;0;COLOR;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;148;29.23719,1864.285;Inherit;True;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;268;341.4761,1822.621;Inherit;False;Property;_EnableBillboard;Enable  Billboard;6;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;288;-1840.8,2040.84;Inherit;False;Property;_Speed_1;Speed_1;9;0;Create;True;0;0;0;False;0;False;0.78;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;287;-1674.603,2043.716;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;286;-1436.214,1871.168;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;1,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;106;633.393,1827.265;Inherit;False;Color;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;20;-1441.949,932.7629;Inherit;False;Constant;_Float0;Float 0;4;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;21;-1111.949,902.763;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;22;-1112.759,1069.954;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;19;-1110.949,775.7632;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;18;-1340.434,832.4267;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;17;-1476.94,832.1354;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CosOpNode;16;-1475.94,757.1356;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CosOpNode;24;-1475.949,1127.764;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;23;-1472.949,1050.763;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.MatrixFromVectors;25;-870.2396,762.2189;Inherit;False;FLOAT3x3;True;4;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3x3;0
Node;AmplifyShaderEditor.DynamicAppendNode;115;-1641.543,1850.422;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;325;-1808.504,1786.835;Inherit;False;324;XTile;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;226;-1819.998,1905.723;Inherit;False;225;YTile;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;117;-1207.905,1826.815;Inherit;True;Property;_BillboardMap;Billboard Map;7;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;-1;0aed8cbdfac4eb34d8bdb6d8e6b28f89;0aed8cbdfac4eb34d8bdb6d8e6b28f89;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;168;-811.0701,1891.689;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;150;-605.7549,2137.884;Inherit;False;152;Alpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;264;-608.254,2217.219;Inherit;False;251;UVmask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;250;-437.0573,2155.964;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;172;-304.3831,2048.401;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;173;-158.2783,2070.656;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;174;-588.0941,1887.724;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;333;-176.808,1793.181;Inherit;False;Constant;_Float6;Float 6;19;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OrthoParams;33;-657.7806,347.0389;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;34;-397.5256,337.1671;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;37;-34.52487,326.1671;Inherit;False;Camera_Mode;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;26;-625.0619,763.9507;Inherit;False;2;2;0;FLOAT3x3;0,0,0,0,1,1,1,0,1;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;28;-622.1651,877.6434;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.VertexToFragmentNode;32;-455.3622,766.4775;Inherit;False;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;70;511.3631,769.309;Inherit;False;4;4;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorSpaceDouble;69;222.3673,839.3088;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;72;218.3669,1016.309;Inherit;False;Property;_TintColor;Tint Color;2;0;Create;True;0;0;0;False;0;False;0.4901961,0.4705883,0.4705883,1;0.4901961,0.4705883,0.4705883,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;13;204.8968,1206.511;Inherit;False;Property;_Exposure;Exposure;3;1;[Gamma];Create;True;0;0;0;False;0;False;1;0;0;8;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;6;-115.4711,749.2787;Inherit;True;Property;_CubeMap;CubeMap;1;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;LockedToCube;False;Object;-1;MipLevel;Cube;8;0;SAMPLERCUBE;;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldPosInputsNode;27;-660.0021,997.0984;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;376;-418.6412,1029.413;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;39;-1315.327,1019.717;Inherit;False;37;Camera_Mode;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;379;-684.3336,1206.057;Inherit;False;37;Camera_Mode;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;378;-451.965,1183.871;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;377;-253.4609,1032.074;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RadiansOpNode;15;-1792.941,848.1354;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;380;-1867.368,954.2139;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;381;-2149.367,1019.214;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;382;-1985.368,1088.214;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;14;-2195.94,849.1354;Inherit;False;Property;_Rotation;Rotation;5;1;[IntRange];Create;True;0;0;0;False;0;False;0;0;0;360;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;170;-1094.292,2029.991;Inherit;False;Property;_BillboardColor;Billboard Color;8;0;Create;True;0;0;0;False;0;False;1,1,1,1;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;383;-2180.367,1214.214;Inherit;False;Property;_RotationSpeed;RotationSpeed;4;0;Create;True;0;0;0;False;0;False;0;0;-2;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;204;-5797.192,1467.854;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.FloorOpNode;207;-5337.473,1467.74;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;205;-5550.43,1470.41;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;255;-5328.867,1246.973;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;248;-5110.114,1377.518;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;260;-4385.115,1145.914;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;262;-4197.287,1142.849;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;242;-6212.68,1371.805;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;4;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;266;-6428.606,1339.967;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.94;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;245;-5820.072,1156.735;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;244;-6121.812,1073.327;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.FloorOpNode;247;-5335.574,1136.626;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;246;-5576.211,1174.161;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;322;-4950.367,1117.691;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;323;-5090.358,1259.691;Inherit;False;Property;_XPosition;X Position;12;0;Create;True;0;0;0;False;0;False;0.9;1;0.8;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;243;-6432.948,1476.438;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;259;-4697.114,1118.282;Inherit;True;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;353;-6308.74,1065.564;Inherit;False;352;XUv;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;354;-6004.521,1522.366;Inherit;False;352;XUv;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;121;-6794.368,1499.685;Inherit;False;Property;_XTile;X Tile;10;0;Create;True;0;0;0;False;0;False;2;1;2;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;267;-6791,1361.865;Inherit;False;Property;_XSmooth;X Smooth;13;0;Create;True;0;0;0;False;0;False;1;1;0.8;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;251;-4033.184,1146.529;Inherit;False;UVmask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;318;-5375.269,1874.105;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RangedFloatNode;303;-6418.914,2018.886;Inherit;False;Constant;_Float10;Float 0;4;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;304;-6088.914,1988.886;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;305;-6089.723,2156.077;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;306;-6087.914,1861.887;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;307;-6317.399,1918.55;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;308;-6453.905,1918.259;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CosOpNode;309;-6452.905,1843.259;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CosOpNode;312;-6452.914,2213.887;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;313;-6449.914,2136.886;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.MatrixFromVectors;315;-5855.003,1871.743;Inherit;False;FLOAT3x3;True;4;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3x3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;317;-5541.753,1872.739;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3x3;0,0,0,0,1,0,0,0,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;311;-6292.292,2105.84;Inherit;False;37;Camera_Mode;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RadiansOpNode;310;-6706.905,2009.258;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;316;-6877.875,2002.559;Inherit;False;Constant;_Float12;Float 12;19;0;Create;True;0;0;0;False;0;False;90;91;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;386;-5844.589,1775.822;Inherit;False;385;WsPosition;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;81;1870.897,1927.065;Float;False;True;-1;0;ASEMaterialInspector;0;0;Unlit;sc_skybox;False;False;False;False;True;True;True;True;True;True;True;True;False;False;True;True;False;False;False;False;False;Off;2;False;;0;False;;False;0;False;;0;False;;False;0;Custom;0;True;False;0;False;Background;;Background;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;False;0;0;False;;0;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;0;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.ComponentMaskNode;388;648.9782,763.1781;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;82;850.3122,762.5419;Inherit;False;CubeMap;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;166;-191.0399,1645.475;Inherit;False;82;CubeMap;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldNormalVector;48;-652.4016,2873.833;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;50;-650.7377,3063.644;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DotProductOpNode;49;-384.5365,2945.442;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;51;-241.7373,2989.645;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;52;-391.1663,3135.5;Inherit;False;Constant;_Float2;Float 2;5;0;Create;True;0;0;0;False;0;False;30;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.VertexToFragmentNode;47;11.70818,2982.519;Inherit;True;False;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LightColorNode;55;54.63488,3218.741;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;53;340.4953,3093.687;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LightAttenuation;54;85.53607,3400.339;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;352;-5231.339,1864.992;Inherit;False;XUv;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;222;-5015.813,1775.448;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;324;-4600.119,1912.344;Inherit;False;XTile;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;319;-5020.875,2002.051;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;320;-5203.163,2035.272;Inherit;False;Constant;_Float9;Float 9;20;0;Create;True;0;0;0;False;0;False;-1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;321;-4803.594,1919.502;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;331;-4826.45,2070.467;Inherit;False;329;XMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;163;-5887.862,3338.601;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CeilOpNode;153;-5864.627,3231.565;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;164;-5712.571,3274.388;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;158;-5549.563,3271.2;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.FloorOpNode;162;-6022.879,3334.006;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;335;-5535.984,2503.425;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;329;-5364.369,2500.459;Inherit;False;XMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;112;-6770.967,2506.67;Inherit;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NormalizeNode;113;-6522.271,2506.408;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CeilOpNode;275;-5732.274,2505.721;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;273;-5953.218,2507.061;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;118;-6326.05,2998.55;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;145;-6016.853,3001.334;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;146;-6347.85,3238.319;Inherit;False;Property;_Yposition;Y position;14;0;Create;True;0;0;0;False;0;False;0;0;-10;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;160;-5376.962,3272.476;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;152;-5205.499,3268.806;Inherit;False;Alpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;120;-6622.061,3082.217;Inherit;False;Property;_YTile;Y Tile;11;0;Create;True;0;0;0;False;0;False;1;0;1;20;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;385;-6360.531,2501.685;Inherit;False;WsPosition;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;114;-6155.094,2506.225;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.ClampOpNode;144;-5759.796,3004.252;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;225;-5547.541,2999.214;Inherit;False;YTile;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FogAndAmbientColorsNode;42;1539.308,2119.605;Inherit;False;UNITY_LIGHTMODEL_AMBIENT;0;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;107;1607.677,1984.331;Inherit;False;106;Color;1;0;OBJECT;;False;1;FLOAT3;0
WireConnection;35;0;36;0
WireConnection;35;1;34;0
WireConnection;35;2;33;4
WireConnection;171;0;168;0
WireConnection;148;0;166;0
WireConnection;148;1;174;0
WireConnection;148;2;173;0
WireConnection;268;1;166;0
WireConnection;268;0;148;0
WireConnection;287;0;288;0
WireConnection;286;0;115;0
WireConnection;286;1;287;0
WireConnection;106;0;268;0
WireConnection;21;0;20;0
WireConnection;21;1;39;0
WireConnection;21;2;20;0
WireConnection;22;0;23;0
WireConnection;22;1;20;0
WireConnection;22;2;24;0
WireConnection;19;0;16;0
WireConnection;19;1;20;0
WireConnection;19;2;18;0
WireConnection;18;0;17;0
WireConnection;17;0;15;0
WireConnection;16;0;15;0
WireConnection;24;0;15;0
WireConnection;23;0;15;0
WireConnection;25;0;19;0
WireConnection;25;1;21;0
WireConnection;25;2;22;0
WireConnection;115;0;325;0
WireConnection;115;1;226;0
WireConnection;117;1;286;0
WireConnection;168;0;117;0
WireConnection;168;1;170;0
WireConnection;250;0;150;0
WireConnection;250;1;264;0
WireConnection;172;0;171;0
WireConnection;172;1;250;0
WireConnection;173;0;172;0
WireConnection;174;0;168;0
WireConnection;34;0;33;2
WireConnection;34;1;33;1
WireConnection;37;0;35;0
WireConnection;26;0;25;0
WireConnection;26;1;28;0
WireConnection;28;0;27;0
WireConnection;32;0;26;0
WireConnection;70;0;6;0
WireConnection;70;1;69;0
WireConnection;70;2;72;0
WireConnection;70;3;13;0
WireConnection;6;1;32;0
WireConnection;376;0;27;1
WireConnection;376;1;378;0
WireConnection;376;2;27;3
WireConnection;378;0;27;2
WireConnection;378;1;379;0
WireConnection;377;0;376;0
WireConnection;15;0;380;0
WireConnection;380;0;14;0
WireConnection;380;1;382;0
WireConnection;382;0;381;0
WireConnection;382;1;383;0
WireConnection;204;0;242;0
WireConnection;204;1;354;0
WireConnection;207;0;205;0
WireConnection;205;0;204;0
WireConnection;255;0;246;0
WireConnection;255;1;205;0
WireConnection;248;0;247;0
WireConnection;248;1;207;0
WireConnection;260;0;259;0
WireConnection;262;0;260;0
WireConnection;242;0;266;0
WireConnection;242;1;243;0
WireConnection;266;0;121;0
WireConnection;266;1;267;0
WireConnection;245;0;244;0
WireConnection;245;1;242;0
WireConnection;244;0;353;0
WireConnection;247;0;246;0
WireConnection;246;0;245;0
WireConnection;322;0;255;0
WireConnection;322;1;323;0
WireConnection;243;0;121;0
WireConnection;259;0;322;0
WireConnection;251;0;262;0
WireConnection;318;0;317;0
WireConnection;304;0;303;0
WireConnection;304;1;311;0
WireConnection;304;2;303;0
WireConnection;305;0;313;0
WireConnection;305;1;303;0
WireConnection;305;2;312;0
WireConnection;306;0;309;0
WireConnection;306;1;303;0
WireConnection;306;2;307;0
WireConnection;307;0;308;0
WireConnection;308;0;310;0
WireConnection;309;0;310;0
WireConnection;312;0;310;0
WireConnection;313;0;310;0
WireConnection;315;0;306;0
WireConnection;315;1;304;0
WireConnection;315;2;305;0
WireConnection;317;0;386;0
WireConnection;317;1;315;0
WireConnection;310;0;316;0
WireConnection;81;2;107;0
WireConnection;388;0;70;0
WireConnection;82;0;388;0
WireConnection;49;0;48;0
WireConnection;49;1;50;0
WireConnection;51;0;49;0
WireConnection;51;1;52;0
WireConnection;47;0;51;0
WireConnection;53;0;47;0
WireConnection;53;1;55;0
WireConnection;352;0;318;0
WireConnection;222;0;121;0
WireConnection;222;1;352;0
WireConnection;324;0;321;0
WireConnection;319;0;222;0
WireConnection;319;1;320;0
WireConnection;321;0;222;0
WireConnection;321;1;319;0
WireConnection;321;2;331;0
WireConnection;163;0;162;0
WireConnection;153;0;145;0
WireConnection;164;0;153;0
WireConnection;164;1;163;0
WireConnection;158;0;164;0
WireConnection;162;0;145;0
WireConnection;335;0;275;0
WireConnection;329;0;335;0
WireConnection;113;0;112;0
WireConnection;275;0;273;0
WireConnection;273;0;114;0
WireConnection;118;0;114;1
WireConnection;118;1;120;0
WireConnection;145;0;118;0
WireConnection;145;1;146;0
WireConnection;160;0;158;0
WireConnection;152;0;160;0
WireConnection;385;0;113;0
WireConnection;114;0;385;0
WireConnection;144;0;145;0
WireConnection;225;0;144;0
ASEEND*/
//CHKSM=154ECD4B04EC29E261D3AB5206028187CBBD6C20