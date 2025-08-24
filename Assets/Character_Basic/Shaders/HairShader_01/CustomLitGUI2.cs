using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Scripting.APIUpdating;

namespace UnityEditor.Rendering.Universal.ShaderGUI
{
    [MovedFrom("UnityEditor.Rendering.LWRP.ShaderGUI")] public static class CustomLitGUI2
    {
        public enum WorkflowMode
        {
            Specular = 0,
            Metallic
        }

        public enum SmoothnessMapChannel
        {
            SpecularMetallicAlpha,
            AlbedoAlpha,
        }

        public enum AnisotrpyDirection//leo3
        {
            TangentDir,
            BiTangentDir,
        }

        public static class Styles
        {
            public static GUIContent workflowModeText = new GUIContent("Workflow Mode",
                "Select a workflow that fits your textures. Choose between Metallic or Specular.");

            public static GUIContent specularMapText =
                new GUIContent("Specular Map", "Sets and configures the map and color for the Specular workflow.");

            public static GUIContent metallicMapText =
                new GUIContent("Metallic Map", "Sets and configures the map for the Metallic workflow.");

            public static GUIContent smoothnessText = 
                new GUIContent("Smoothness","Controls the spread of highlights and reflections on the surface.");

            public static GUIContent v1Text = 
                new GUIContent("WidthTop","Power value of the specular");//leo

            public static GUIContent v2Text =
                new GUIContent("WidthBase", "Power value of the specular");//leo3

            public static GUIContent v3Text =
                new GUIContent("MoveTop", "Moving the specular along UV");//leo4

            public static GUIContent v4Text =
                new GUIContent("MoveBase", "Moving the specular along UV");//leo4

            public static GUIContent v5Text =
                new GUIContent("RimColorPower", "The pow value of Rim area");//leo5

            public static GUIContent c1Text =
               new GUIContent("RimColorHD", "The color value of Rim effect");//leo5

            public static GUIContent customMapIntensityText =
               new GUIContent("ShiftMapIntensity", "Intensity value of the shifting effect");//leo3

            public static GUIContent customTillingText =
                new GUIContent("ShiftMapTilling", "CustomMap UV Tilling");//leo2

            public static GUIContent customMap1Text =
                new GUIContent("ShiftMap", "CustomMap1");//leo2

            public static GUIContent anisotrpyDirectionText =
                new GUIContent("Specular Direction", "Choose one direction for specular");//leo3

            public static GUIContent smoothnessMapChannelText =
                new GUIContent("Source",
                    "Specifies where to sample a smoothness map from. By default, uses the alpha channel for your map.");

            public static GUIContent highlightsText = new GUIContent("Specular Highlights",
                "When enabled, the Material reflects the shine from direct lighting.");

            public static GUIContent reflectionsText =
                new GUIContent("Environment Reflections",
                    "When enabled, the Material samples reflections from the nearest Reflection Probes or Lighting Probe.");

            public static GUIContent occlusionText = new GUIContent("Occlusion Map",
                "Sets an occlusion map to simulate shadowing from ambient lighting.");

            public static readonly string[] metallicSmoothnessChannelNames = {"Metallic Alpha", "Albedo Alpha"};
            public static readonly string[] specularSmoothnessChannelNames = {"Specular Alpha", "Albedo Alpha"};
            public static readonly string[] stringDirectionChannelNames = {"Tangent", "Bitangent"};//leo3
        }

        public struct LitProperties
        {
            // Surface Option Props
            public MaterialProperty workflowMode;

            // Surface Input Props
            public MaterialProperty metallic;
            public MaterialProperty specColor;
            public MaterialProperty metallicGlossMap;
            public MaterialProperty specGlossMap;
            public MaterialProperty smoothness;
            public MaterialProperty v1;//leo
            public MaterialProperty customTilling;//leo2
            public MaterialProperty customMap1;//leo2
            public MaterialProperty anisotrpyDirection;//leo3
            public MaterialProperty v2;//leo3
            public MaterialProperty v3;//leo4
            public MaterialProperty v4;//leo4
            public MaterialProperty v5;//leo5
            public MaterialProperty c1;//leo5
            public MaterialProperty customMapIntensity;//leo3
            public MaterialProperty smoothnessMapChannel;
            public MaterialProperty bumpMapProp;
            public MaterialProperty bumpScaleProp;
            public MaterialProperty occlusionStrength;
            public MaterialProperty occlusionMap;

            // Advanced Props
            public MaterialProperty highlights;
            public MaterialProperty reflections;

            public LitProperties(MaterialProperty[] properties)
            {
                // Surface Option Props
                workflowMode = BaseShaderGUI.FindProperty("_WorkflowMode", properties, false);
                // Surface Input Props
                metallic = BaseShaderGUI.FindProperty("_Metallic", properties);
                specColor = BaseShaderGUI.FindProperty("_SpecColor", properties, false);
                metallicGlossMap = BaseShaderGUI.FindProperty("_MetallicGlossMap", properties);
                specGlossMap = BaseShaderGUI.FindProperty("_SpecGlossMap", properties, false);
                smoothness = BaseShaderGUI.FindProperty("_Smoothness", properties, false);
                v1 = BaseShaderGUI.FindProperty("_V1", properties, false);//leo
                customTilling = BaseShaderGUI.FindProperty("_CustomTilling", properties, false);//leo2
                customMap1 = BaseShaderGUI.FindProperty("_CustomMap1", properties, false);//leo2
                anisotrpyDirection = BaseShaderGUI.FindProperty("_AnisotrpyDirection", properties, false);//leo3
                v2 = BaseShaderGUI.FindProperty("_V2", properties, false);//leo3
                v3 = BaseShaderGUI.FindProperty("_V3", properties, false);//leo4
                v4 = BaseShaderGUI.FindProperty("_V4", properties, false);//leo4
                v5 = BaseShaderGUI.FindProperty("_V5", properties, false);//leo5
                c1 = BaseShaderGUI.FindProperty("_C1", properties, false);//leo5
                customMapIntensity = BaseShaderGUI.FindProperty("_CustomMapIntensity", properties, false);//leo3
                smoothnessMapChannel = BaseShaderGUI.FindProperty("_SmoothnessTextureChannel", properties, false);
                bumpMapProp = BaseShaderGUI.FindProperty("_BumpMap", properties, false);
                bumpScaleProp = BaseShaderGUI.FindProperty("_BumpScale", properties, false);
                occlusionStrength = BaseShaderGUI.FindProperty("_OcclusionStrength", properties, false);
                occlusionMap = BaseShaderGUI.FindProperty("_OcclusionMap", properties, false);
                // Advanced Props
                highlights = BaseShaderGUI.FindProperty("_SpecularHighlights", properties, false);
                reflections = BaseShaderGUI.FindProperty("_EnvironmentReflections", properties, false);
            }
        }

        public static void Inputs(LitProperties properties, MaterialEditor materialEditor, Material material)
        {
            DoMetallicSpecularArea(properties, materialEditor, material);
            BaseShaderGUI.DrawNormalArea(materialEditor, properties.bumpMapProp, properties.bumpScaleProp);

            if (properties.occlusionMap != null)
            {
                materialEditor.TexturePropertySingleLine(Styles.occlusionText, properties.occlusionMap,
                    properties.occlusionMap.textureValue != null ? properties.occlusionStrength : null);
            }
        }

        public static void DoMetallicSpecularArea(LitProperties properties, MaterialEditor materialEditor, Material material)
        {
            string[] smoothnessChannelNames;
            bool hasGlossMap = false;
            if (properties.workflowMode == null ||
                (WorkflowMode) properties.workflowMode.floatValue == WorkflowMode.Metallic)
            {
                hasGlossMap = properties.metallicGlossMap.textureValue != null;
                smoothnessChannelNames = Styles.metallicSmoothnessChannelNames;
                materialEditor.TexturePropertySingleLine(Styles.metallicMapText, properties.metallicGlossMap,
                    hasGlossMap ? null : properties.metallic);
                
                bool hasCustomMap = false;//leo2
                hasCustomMap = properties.customMap1.textureValue != null;//leo2
                materialEditor.TexturePropertySingleLine(Styles.customMap1Text, properties.customMap1);//leo2
            }
            else
            {
                hasGlossMap = properties.specGlossMap.textureValue != null;
                smoothnessChannelNames = Styles.specularSmoothnessChannelNames;
                BaseShaderGUI.TextureColorProps(materialEditor, Styles.specularMapText, properties.specGlossMap,
                    hasGlossMap ? null : properties.specColor);

                bool hasCustomMap = false;//leo2
                hasCustomMap = properties.customMap1.textureValue != null;//leo2
                materialEditor.TexturePropertySingleLine(Styles.customMap1Text, properties.customMap1);//leo2
            }
            EditorGUI.indentLevel++;//leo3
            EditorGUI.BeginChangeCheck();//leo3
            EditorGUI.showMixedValue = properties.customMapIntensity.hasMixedValue;//leo3
            var Intensity = EditorGUILayout.Slider(Styles.customMapIntensityText, properties.customMapIntensity.floatValue, 0f, 1f);//leo3
            if (EditorGUI.EndChangeCheck())//leo3
                properties.customMapIntensity.floatValue = Intensity;//leo3
            EditorGUI.showMixedValue = false;//leo3


            //EditorGUI.indentLevel++;//leo3
            DoSmoothness(properties, material, smoothnessChannelNames);
            //EditorGUI.indentLevel--;//leo3
        }

        public static void DoSmoothness(LitProperties properties, Material material, string[] smoothnessChannelNames)
        {
            var opaque = ((BaseShaderGUI.SurfaceType) material.GetFloat("_Surface") ==
                          BaseShaderGUI.SurfaceType.Opaque);
            //EditorGUI.indentLevel++;//leo2
            EditorGUI.BeginChangeCheck();//leo2
            EditorGUI.showMixedValue = properties.customTilling.hasMixedValue;//leo2
            var customTilling = EditorGUILayout.Vector2Field(Styles.customTillingText, new Vector2(properties.customTilling.vectorValue.x, properties.customTilling.vectorValue.y));//leo2

            if (EditorGUI.EndChangeCheck())//leo2
                properties.customTilling.vectorValue = customTilling;//leo2
            EditorGUI.showMixedValue = false;//leo2

            //EditorGUI.indentLevel++;//leo3
            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = properties.smoothness.hasMixedValue;
            var smoothness = EditorGUILayout.Slider(Styles.smoothnessText, properties.smoothness.floatValue, 0.0f, 2f);
            
            if (EditorGUI.EndChangeCheck())
                properties.smoothness.floatValue = smoothness;
            EditorGUI.showMixedValue = false;

            //EditorGUI.indentLevel++;//leo3
            EditorGUI.BeginChangeCheck();//leo
            EditorGUI.showMixedValue = properties.v1.hasMixedValue;//leo
            var v1 = EditorGUILayout.Slider(Styles.v1Text, properties.v1.floatValue, 200f, 2000f);//leo
            if (EditorGUI.EndChangeCheck())//leo
                properties.v1.floatValue = v1;//leo
            EditorGUI.showMixedValue = false;//leo

            //EditorGUI.indentLevel++;//leo3
            EditorGUI.BeginChangeCheck();//leo3
            EditorGUI.showMixedValue = properties.v2.hasMixedValue;//leo3
            var v2 = EditorGUILayout.Slider(Styles.v2Text, properties.v2.floatValue, 20f, 200f);//leo3
            if (EditorGUI.EndChangeCheck())//leo3
                properties.v2.floatValue = v2;//leo3
            EditorGUI.showMixedValue = false;//leo3

            EditorGUI.BeginChangeCheck();//leo4
            EditorGUI.showMixedValue = properties.v3.hasMixedValue;//leo4
            var v3 = EditorGUILayout.Slider(Styles.v3Text, properties.v3.floatValue, -1f, 1f);//leo4
            if (EditorGUI.EndChangeCheck())//leo4
                properties.v3.floatValue = v3;//leo4
            EditorGUI.showMixedValue = false;//leo4

            EditorGUI.BeginChangeCheck();//leo4
            EditorGUI.showMixedValue = properties.v4.hasMixedValue;//leo4
            var v4 = EditorGUILayout.Slider(Styles.v4Text, properties.v4.floatValue, -1f, 1f);//leo4
            if (EditorGUI.EndChangeCheck())//leo4
                properties.v4.floatValue = v4;//leo4
            EditorGUI.showMixedValue = false;//leo4

            string[] directionChannelNames;//leo3
            directionChannelNames = Styles.stringDirectionChannelNames;//leo3
            
            if (properties.anisotrpyDirection != null) //leo3
            {//leo3
                //EditorGUI.indentLevel++;//leo3
                EditorGUI.BeginDisabledGroup(!opaque);//leo3
                EditorGUI.BeginChangeCheck();//leo3
                EditorGUI.showMixedValue = properties.anisotrpyDirection.hasMixedValue;//leo3
                var DirSource = (int)properties.anisotrpyDirection.floatValue;//leo3
                if (opaque)
                    DirSource = EditorGUILayout.Popup(Styles.anisotrpyDirectionText, DirSource,
                        directionChannelNames);
                else
                    EditorGUILayout.Popup(Styles.anisotrpyDirectionText, 0, directionChannelNames);//leo3
                if (EditorGUI.EndChangeCheck())
                    properties.anisotrpyDirection.floatValue = DirSource;
                EditorGUI.showMixedValue = false;//leo3
                EditorGUI.EndDisabledGroup();//leo3
                //EditorGUI.indentLevel--;//leo3
            }//leo3

            if (properties.smoothnessMapChannel != null) // smoothness channel
            {
                EditorGUI.indentLevel++;
                EditorGUI.BeginDisabledGroup(!opaque);
                EditorGUI.BeginChangeCheck();
                EditorGUI.showMixedValue = properties.smoothnessMapChannel.hasMixedValue;
                var smoothnessSource = (int) properties.smoothnessMapChannel.floatValue;
                if (opaque)
                    smoothnessSource = EditorGUILayout.Popup(Styles.smoothnessMapChannelText, smoothnessSource,
                        smoothnessChannelNames);
                else
                    EditorGUILayout.Popup(Styles.smoothnessMapChannelText, 0, smoothnessChannelNames);
                if (EditorGUI.EndChangeCheck())
                    properties.smoothnessMapChannel.floatValue = smoothnessSource;
                EditorGUI.showMixedValue = false;
                EditorGUI.EndDisabledGroup();
                EditorGUI.indentLevel--;
            }

            EditorGUI.indentLevel--;
            EditorGUI.BeginChangeCheck();//leo5
            EditorGUI.showMixedValue = properties.c1.hasMixedValue;//leo5
            var c1 = EditorGUILayout.ColorField(Styles.c1Text, properties.c1.colorValue,true,true,true);//leo5
            if (EditorGUI.EndChangeCheck())//leo5
                properties.c1.colorValue = c1;//leo5
            EditorGUI.showMixedValue = false;//leo5

            EditorGUI.BeginChangeCheck();//leo5
            EditorGUI.showMixedValue = properties.v5.hasMixedValue;//leo5
            var v5 = EditorGUILayout.Slider(Styles.v5Text, properties.v5.floatValue, 1f, 6f);//leo5
            if (EditorGUI.EndChangeCheck())//leo5
                properties.v5.floatValue = v5;//leo5
            EditorGUI.showMixedValue = false;//leo5

            EditorGUI.indentLevel--;
        }

        public static SmoothnessMapChannel GetSmoothnessMapChannel(Material material)
        {
            int ch = (int) material.GetFloat("_SmoothnessTextureChannel");
            if (ch == (int) SmoothnessMapChannel.AlbedoAlpha)
                return SmoothnessMapChannel.AlbedoAlpha;

            return SmoothnessMapChannel.SpecularMetallicAlpha;
        }

        public static AnisotrpyDirection GetAnisotrpyDirection(Material material)//leo3
        {
            int ch = (int) material.GetFloat("_AnisotrpyDirection");
            if (ch == (int) AnisotrpyDirection.BiTangentDir)
                return AnisotrpyDirection.BiTangentDir;

            return AnisotrpyDirection.TangentDir;
        }//leo3
        public static void SetMaterialKeywords(Material material)
        {
            // Note: keywords must be based on Material value not on MaterialProperty due to multi-edit & material animation
            // (MaterialProperty value might come from renderer material property block)
            var hasGlossMap = false;
            var isSpecularWorkFlow = false;
            var opaque = ((BaseShaderGUI.SurfaceType) material.GetFloat("_Surface") ==
                          BaseShaderGUI.SurfaceType.Opaque);

            if (material.HasProperty("_WorkflowMode"))
            {
                isSpecularWorkFlow = (WorkflowMode) material.GetFloat("_WorkflowMode") == WorkflowMode.Specular;
                if (isSpecularWorkFlow)
                    hasGlossMap = material.GetTexture("_SpecGlossMap") != null;
                else
                    hasGlossMap = material.GetTexture("_MetallicGlossMap") != null;
            }
            else
            {
                hasGlossMap = material.GetTexture("_MetallicGlossMap") != null;
            }

            CoreUtils.SetKeyword(material, "_SPECULAR_SETUP", isSpecularWorkFlow);

            CoreUtils.SetKeyword(material, "_METALLICSPECGLOSSMAP", hasGlossMap);

            if (material.HasProperty("_SpecularHighlights"))
                CoreUtils.SetKeyword(material, "_SPECULARHIGHLIGHTS_OFF",
                    material.GetFloat("_SpecularHighlights") == 0.0f);
            if (material.HasProperty("_EnvironmentReflections"))
                CoreUtils.SetKeyword(material, "_ENVIRONMENTREFLECTIONS_OFF",
                    material.GetFloat("_EnvironmentReflections") == 0.0f);
            if (material.HasProperty("_OcclusionMap"))
                CoreUtils.SetKeyword(material, "_OCCLUSIONMAP", material.GetTexture("_OcclusionMap"));
            if (material.HasProperty("_CustomMap1"))
                CoreUtils.SetKeyword(material, "_CustomMap1", material.GetTexture("_CustomMap1"));//leo2

            if (material.HasProperty("_SmoothnessTextureChannel"))
            {
                CoreUtils.SetKeyword(material, "_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A",
                    GetSmoothnessMapChannel(material) == SmoothnessMapChannel.AlbedoAlpha && opaque);
            }
            if (material.HasProperty("_AnisotrpyDirection"))//leo3
            {
                CoreUtils.SetKeyword(material, "_AnisotrpyDirection_CHANNEL_A",
                    GetAnisotrpyDirection(material) == AnisotrpyDirection.BiTangentDir && opaque);
            }//leo3
        }
    }
}
