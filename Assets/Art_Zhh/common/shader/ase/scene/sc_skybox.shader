// Made with Amplify Shader Editor v1.9.1.5
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "sc_skybox"
{
	Properties
	{
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Off
		CGPROGRAM
		#pragma target 2.0
		#pragma surface surf Unlit keepalpha addshadow fullforwardshadows 
		struct Input
		{
			float3 worldPos;
		};

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			float3 ase_worldPos = i.worldPos;
			float3 normalizeResult85 = normalize( ase_worldPos );
			float3 break86 = normalizeResult85;
			float2 appendResult108 = (float2(break86.x , break86.y));
			float2 test111106 = appendResult108;
			o.Emission = float3( test111106 ,  0.0 );
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19105
Node;AmplifyShaderEditor.CommentaryNode;101;-283.6161,897.1003;Inherit;False;1998.399;586.0333;Fog Coords on screen;16;84;85;86;87;88;89;90;93;92;95;94;96;97;98;99;100;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;68;-568,80;Inherit;False;2294.189;596.0556;Cubemap Coordinates;21;14;15;16;17;18;19;40;30;29;41;26;39;22;27;31;28;25;24;23;21;20;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;45;402.542,-856.3556;Inherit;False;1282.848;342.0184;Color;6;102;83;44;42;43;103;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;38;766.1328,-400.2614;Inherit;False;893.2548;295.8721;Camera_Mode;5;33;34;36;35;37;;1,1,1,1;0;0
Node;AmplifyShaderEditor.OrthoParams;33;816.1329,-263.3896;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;34;1071.388,-276.2615;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;36;1069.388,-350.2616;Inherit;False;Constant;_Float1;Float 1;4;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;35;1251.388,-281.2615;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;43;832.327,-778.1861;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
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
Node;AmplifyShaderEditor.RangedFloatNode;14;-529.0271,333.7074;Inherit;False;Property;_Rotation;Rotation;4;1;[IntRange];Create;True;0;0;0;False;0;False;0;0;0;360;0;1;FLOAT;0
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
Node;AmplifyShaderEditor.WorldNormalVector;48;1357.32,2654.437;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;50;1358.984,2844.248;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;52;1629.984,2923.248;Inherit;False;Constant;_Float2;Float 2;5;0;Create;True;0;0;0;False;0;False;30;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LightColorNode;55;1972.385,3183.448;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.LightAttenuation;54;1961.285,3043.048;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;49;1625.186,2726.045;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;51;1767.984,2770.248;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexToFragmentNode;47;2021.432,2763.122;Inherit;True;True;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;85;-5.463471,949.1003;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;86;212.5365,947.1003;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.AbsOpNode;87;384.5363,974.1006;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;88;568.5366,1001.101;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;90;357.5363,1246.101;Inherit;False;Constant;_Float4;Float 4;6;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;94;281.9025,1361.244;Inherit;False;Property;_FogSmoothness;Fog Smoothness;7;0;Create;True;0;0;0;False;0;False;0.33;0;0.01;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;97;1297.783,996.4495;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;98;1105.783,1094.45;Inherit;False;Constant;_Float5;Float 5;8;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;100;1490.783,991.4495;Inherit;False;Fog_Mask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;102;520.1063,-622.98;Inherit;False;100;Fog_Mask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;44;1057.235,-705.356;Inherit;False;Property;_EnableFog;Enable Fog;5;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;103;1347.105,-704.98;Inherit;False;FinalColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CustomExpressionNode;46;1438.658,3226.747;Inherit;False; ;1;Create;1;True;In0;FLOAT;0;In;;Inherit;False;My Custom Expression;True;False;0;;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;53;2260.584,2967.448;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WorldPosInputsNode;84;-233.616,948.5405;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;104;2559.475,2525.676;Inherit;False;103;FinalColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;81;2884.191,2765.503;Float;False;True;-1;0;ASEMaterialInspector;0;0;Unlit;sc_skybox;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Off;0;False;;0;False;;False;0;False;;0;False;;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;0;0;False;;0;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.GetLocalVarNode;107;2561.972,2789.768;Inherit;False;106;test111;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;92;-16.83937,1086.83;Inherit;False;Property;_FogHeight;Fog Height;6;0;Create;True;0;0;0;False;0;False;0.5;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;89;326.8338,1151.895;Inherit;False;Constant;_Float3;Float 3;6;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;95;645.3856,1343.954;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;93;801.049,1001.715;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;96;993.2433,1000.798;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;99;1001.694,1203.927;Inherit;False;Property;_FogFill;Fog Fill;8;0;Create;True;0;0;0;False;0;False;0.23;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;106;597.0471,743.5518;Inherit;False;test111;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;108;382.4557,762.9728;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
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
WireConnection;49;0;48;0
WireConnection;49;1;50;0
WireConnection;51;0;49;0
WireConnection;51;1;52;0
WireConnection;47;0;51;0
WireConnection;85;0;84;0
WireConnection;86;0;85;0
WireConnection;87;0;86;1
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
WireConnection;103;0;44;0
WireConnection;53;0;47;0
WireConnection;53;1;55;0
WireConnection;81;2;107;0
WireConnection;95;0;94;0
WireConnection;93;0;88;0
WireConnection;93;1;95;0
WireConnection;96;0;93;0
WireConnection;106;0;108;0
WireConnection;108;0;86;0
WireConnection;108;1;86;1
ASEEND*/
//CHKSM=C735A8BFB90EAA3A3CCE89611E5F73B2BD4D938E