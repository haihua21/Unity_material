// Made with Amplify Shader Editor v1.9.1.5
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "sc_skybox"
{
	Properties
	{
		[NoScaleOffset]_CubeMap("CubeMap", CUBE) = "white" {}
		[IntRange]_Rotation("Rotation", Range( 0 , 360)) = 0
		[Toggle(_ROTATION_ON_ON)] _Rotation_On("Rotation_On", Float) = 0
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGPROGRAM
		#include "UnityShaderVariables.cginc"
		#pragma target 3.0
		#pragma shader_feature_local _ROTATION_ON_ON
		#pragma surface surf Unlit keepalpha addshadow fullforwardshadows vertex:vertexDataFunc 
		struct Input
		{
			float3 vertexToFrag32;
			float3 worldPos;
		};

		uniform samplerCUBE _CubeMap;
		uniform float _Rotation;

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
			o.Emission = texCUBElod( _CubeMap, float4( i.vertexToFrag32, 0.0) ).rgb;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19105
Node;AmplifyShaderEditor.CommentaryNode;45;-453.6885,1941.171;Inherit;False;896.6979;237.1707;Fog;3;43;42;44;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;38;-500.687,1226.75;Inherit;False;893.2548;295.8721;Camera_Mode;5;33;34;36;35;37;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RadiansOpNode;15;-190,252;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;18;134.5063,281.2913;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;20;37.9917,405.6276;Inherit;False;Constant;_Float0;Float 0;4;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;19;364.9917,159.6276;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;21;367.9917,375.6276;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SinOpNode;17;-2,281;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;23;32.9917,522.6276;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CosOpNode;16;1,130;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CosOpNode;24;29.9917,599.6276;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.MatrixFromVectors;25;582.9917,274.6276;Inherit;False;FLOAT3x3;True;4;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3x3;0
Node;AmplifyShaderEditor.NormalizeNode;28;941.5271,431.5141;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;14;-516,270;Inherit;False;Property;_Rotation;Rotation;2;1;[IntRange];Create;True;0;0;0;False;0;False;0;0;0;360;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;31;1304.234,504.7067;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldPosInputsNode;27;664.437,474.2716;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;22;367.1821,542.818;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.OrthoParams;33;-450.687,1363.622;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;34;-195.4321,1350.75;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;36;-197.4321,1276.75;Inherit;False;Constant;_Float1;Float 1;4;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;35;-15.43213,1345.75;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;39;164.6136,492.5814;Inherit;False;37;Camera_Mode;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;26;1083.892,220.5241;Inherit;False;2;2;0;FLOAT3x3;0,0,0,1,0,0,1,0,1;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;6;2096.731,251.1229;Inherit;True;Property;_CubeMap;CubeMap;0;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;LockedToCube;False;Object;-1;MipLevel;Cube;8;0;SAMPLERCUBE;;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexToFragmentNode;32;1743.195,250.4318;Inherit;False;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;41;1488.484,392.5681;Inherit;False;Property;_Rotation_On;Rotation_On;3;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;13;-512.2913,129.0823;Inherit;False;Property;_Exposure;Exposure;1;1;[Gamma];Create;True;0;0;0;False;0;False;1;0;0;8;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;29;1089.747,504.6129;Inherit;True;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;30;909.0178,614.876;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;40;664.4958,664.935;Inherit;False;37;Camera_Mode;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;43;-23.9002,2019.341;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FogAndAmbientColorsNode;42;-403.6885,2006.514;Inherit;False;UNITY_LIGHTMODEL_AMBIENT;0;1;COLOR;0
Node;AmplifyShaderEditor.StaticSwitch;44;206.0093,1991.171;Inherit;False;Property;_EnableFog;Enable Fog;4;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CustomExpressionNode;46;1107.918,2179.453;Inherit;False; ;1;Create;1;True;In0;FLOAT;0;In;;Inherit;False;My Custom Expression;True;False;0;;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;48;1042.077,1128.308;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;50;1043.741,1318.118;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;52;1314.741,1397.118;Inherit;False;Constant;_Float2;Float 2;5;0;Create;True;0;0;0;False;0;False;30;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LightColorNode;55;1657.141,1657.318;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.LightAttenuation;54;1646.041,1516.917;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;49;1309.942,1199.916;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;51;1452.741,1244.118;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;53;1942.341,1453.318;Inherit;True;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.VertexToFragmentNode;47;1706.188,1236.992;Inherit;True;True;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;67;2662.432,522.144;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;sc_skybox;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;;0;False;;False;0;False;;0;False;;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;0;0;False;;0;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;37;168.5679,1339.75;Inherit;False;Camera_Mode;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
WireConnection;15;0;14;0
WireConnection;18;0;17;0
WireConnection;19;0;16;0
WireConnection;19;1;20;0
WireConnection;19;2;18;0
WireConnection;21;0;20;0
WireConnection;21;1;39;0
WireConnection;21;2;20;0
WireConnection;17;0;15;0
WireConnection;23;0;15;0
WireConnection;16;0;15;0
WireConnection;24;0;15;0
WireConnection;25;0;19;0
WireConnection;25;1;21;0
WireConnection;25;2;22;0
WireConnection;28;0;27;0
WireConnection;31;0;29;0
WireConnection;22;0;23;0
WireConnection;22;1;20;0
WireConnection;22;2;24;0
WireConnection;34;0;33;2
WireConnection;34;1;33;1
WireConnection;35;0;36;0
WireConnection;35;1;34;0
WireConnection;35;2;33;4
WireConnection;26;0;25;0
WireConnection;26;1;28;0
WireConnection;6;1;32;0
WireConnection;32;0;41;0
WireConnection;41;1;31;0
WireConnection;41;0;26;0
WireConnection;29;0;27;1
WireConnection;29;1;30;0
WireConnection;29;2;27;3
WireConnection;30;0;27;2
WireConnection;30;1;40;0
WireConnection;43;0;42;0
WireConnection;44;0;43;0
WireConnection;49;0;48;0
WireConnection;49;1;50;0
WireConnection;51;0;49;0
WireConnection;51;1;52;0
WireConnection;53;0;47;0
WireConnection;53;1;55;0
WireConnection;53;2;54;0
WireConnection;47;0;51;0
WireConnection;67;2;6;0
WireConnection;37;0;35;0
ASEEND*/
//CHKSM=8525092D806BECCA0E347BCC0B60C44682BA071B