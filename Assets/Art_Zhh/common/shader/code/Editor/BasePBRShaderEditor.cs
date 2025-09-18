using System.Collections.Generic;

using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor
{
    public class BasePBRShaderEditor : BaseMapShaderEditor
    {
#region Member

        protected MaterialProperty prop_NormalMap;
        protected MaterialProperty prop_DetailNormalMap;
        protected MaterialProperty prop_BlendNormalAmount;
        protected MaterialProperty prop_NormalScale;

        protected MaterialProperty prop_SOMMap;
        protected MaterialProperty prop_Smoothness;
        protected MaterialProperty prop_AO;
        protected MaterialProperty prop_Metallic;

        protected MaterialProperty prop_Matcap;
        protected MaterialProperty prop_MatcapColor;
        protected MaterialProperty prop_MatcapIntensity;

        protected MaterialProperty prop_SpecularAlgorithm;
        protected MaterialProperty prop_SpecularIntensity;

        protected MaterialProperty prop_Direct_Diffuse;
        protected MaterialProperty prop_Direct_Specular;
        protected MaterialProperty prop_GI_Diffuse;
        protected MaterialProperty prop_GI_Specular;
        protected MaterialProperty prop_GI_ShadowIntensity;

        protected MaterialProperty prop_Planar_Reflection;
        protected MaterialProperty prop_ReflectionAmount;

#endregion

#region KeyWorld

        protected static readonly string renderKey_DirectDiffuse = "_DIRECT_DIFFUSE";
        protected static readonly string renderKey_DirectSpecular = "_DIRECT_SPECULAR";
        protected static readonly string renderKey_GIDiffuse = "_GI_DIFFUSE";
        protected static readonly string renderKey_GISpecular = "_GI_SPECULAR";

        protected static readonly string renderKey_NormalMap = "_NORMALMAP";
        protected static readonly string renderKey_DetailNormalMap = "_DETAIL_NORMAL_MAP";
        protected static readonly string renderKey_Emission = "_EMISSION";
        protected static readonly string renderKey_SOMMap = "_SOMMAP";
        protected static readonly string renderKey_Matcap = "_MATCAP";

        protected static readonly string[] renderKey_SpecularAlgorithm = {"_SPECULAR_BRDF", "_SPECULAR_SSS"};

#endregion

        protected override void OnGUIEx(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            base.OnGUIEx(materialEditor, properties);
            m_comFuncBaseList = new List<ComFuncBase>();
            m_comFuncBaseList.Add(new ComFunc_Emission(this, m_material, m_materialEditor));
            m_comFuncBaseList.Add(new ComFunc_DirtyMap(this, m_material, m_materialEditor));
            m_comFuncBaseList.Add(new ComFunc_DistanceTransparency(this, m_material, m_materialEditor));
        }

        protected override void OnFindProperties(MaterialProperty[] properties)
        {
            base.OnFindProperties(properties);

            prop_NormalMap = WantFindProperty(m_material, "_NormalMap", properties);
            prop_DetailNormalMap = WantFindProperty(m_material, "_DetailNormalMap", properties);
            prop_BlendNormalAmount = WantFindProperty(m_material, "_BlendNormalAmount", properties);
            prop_NormalScale = WantFindProperty(m_material, "_NormalScale", properties);

            prop_SOMMap = WantFindProperty(m_material, "_SOMMap", properties);
            prop_Smoothness = WantFindProperty(m_material, "_Smoothness", properties);
            prop_AO = WantFindProperty(m_material, "_AO", properties);
            prop_Metallic = WantFindProperty(m_material, "_Metallic", properties);

            prop_Matcap = WantFindProperty(m_material, "_Matcap", properties);
            prop_MatcapColor = WantFindProperty(m_material, "_MatcapColor", properties);
            prop_MatcapIntensity = WantFindProperty(m_material, "_MatcapIntensity", properties);

            prop_SpecularAlgorithm = WantFindProperty(m_material, "_SpecularAlgorithm", properties);
            prop_SpecularIntensity = WantFindProperty(m_material, "_SpecularIntensity", properties);

            prop_Direct_Diffuse = WantFindProperty(m_material, "_Direct_Diffuse", properties);
            prop_Direct_Specular = WantFindProperty(m_material, "_Direct_Specular", properties);

            prop_GI_Diffuse = WantFindProperty(m_material, "_GI_Diffuse", properties);
            prop_GI_Specular = WantFindProperty(m_material, "_GI_Specular", properties);
            prop_GI_ShadowIntensity = WantFindProperty(m_material, "_GI_ShadowIntensity", properties);

            prop_Planar_Reflection = WantFindProperty(m_material, "_Planar_Reflection", properties);
            prop_ReflectionAmount = WantFindProperty(m_material, "_ReflectionAmount", properties);
        }

        protected override void OnDrawProperties(Material material, MaterialProperty[] properties)
        {
            base.OnDrawProperties(material, properties);

            DrawNormalMap(material, properties);
            DrawSOMMap(material, properties);
            DrawTillingAndOffset(material, properties);
            DrawMatcap(material, properties);
        }

        protected override void OnDrawAdvance(Material material, MaterialProperty[] properties)
        {
            DrawSpecularAlgorithm(material, properties);
            DrawLightingEnable(material, properties);
            DrawPlanarReflection(material, properties);
        }

        protected void DrawNormalMap(Material material, MaterialProperty[] properties)
        {
            m_materialEditor.TexturePropertySingleLine(new GUIContent(prop_NormalMap.displayName), prop_NormalMap);
            SetKeyword(material, renderKey_NormalMap, prop_NormalMap.textureValue != null);

            if (prop_DetailNormalMap != null)
            {
                m_materialEditor.TexturePropertySingleLine(new GUIContent(prop_DetailNormalMap.displayName), prop_DetailNormalMap);
                SetKeyword(material, renderKey_DetailNormalMap, prop_DetailNormalMap.textureValue != null);
            }

            if (material.IsKeywordEnabled(renderKey_DetailNormalMap))
            {
                m_materialEditor.TextureScaleOffsetProperty(prop_DetailNormalMap);
                DrawShaderProperties(prop_BlendNormalAmount);
            }

            if (material.IsKeywordEnabled(renderKey_NormalMap) || material.IsKeywordEnabled(renderKey_DetailNormalMap))
            {
                DrawShaderProperties(prop_NormalScale);
            }
        }

        protected virtual void DrawSOMMap(Material material, MaterialProperty[] properties)
        {
            m_materialEditor.TexturePropertySingleLine(new GUIContent(prop_SOMMap.displayName), prop_SOMMap);
            SetKeyword(material, renderKey_SOMMap, prop_SOMMap.textureValue != null);

            DrawShaderProperties(prop_Smoothness);
            DrawShaderProperties(prop_AO);
            DrawShaderProperties(prop_Metallic);

            EditorGUILayout.Space();
        }

        protected void DrawTillingAndOffset(Material material, MaterialProperty[] properties)
        {
            m_materialEditor.TextureScaleOffsetProperty(prop_BaseMap);
        }

        protected void DrawMatcap(Material material, MaterialProperty[] properties)
        {
            m_materialEditor.TexturePropertySingleLine(new GUIContent(prop_Matcap.displayName), prop_Matcap, prop_MatcapColor, prop_MatcapIntensity);

            SetKeyword(material, renderKey_Matcap, prop_Matcap.textureValue != null);
        }

        protected void DrawSpecularAlgorithm(Material material, MaterialProperty[] properties)
        {
            GUILayout.BeginVertical("box");

            var oldValue = prop_SpecularAlgorithm.floatValue;
            DrawShaderProperties(prop_SpecularAlgorithm);
            float nowValue = prop_SpecularAlgorithm.floatValue;

            if (oldValue != nowValue)
            {
                int count = renderKey_SpecularAlgorithm.Length;
                for (int i = 0; i < count; i++)
                {
                    var tmp = false;
                    if (nowValue == i)
                    {
                        tmp = true;
                    }

                    SetKeyword(material, renderKey_SpecularAlgorithm[i], tmp);
                }
            }

            GUILayout.EndVertical();
        }

        protected void DrawLightingEnable(Material material, MaterialProperty[] properties)
        {
            EditorGUILayout.Space();

            GUILayout.BeginVertical("box");
            EditorGUILayout.LabelField("Direct Lighting", new GUIStyle("BoldLabel"));
            GUILayout.BeginHorizontal();

            DrawShaderProperties(prop_Direct_Diffuse);
            DrawShaderProperties(prop_Direct_Specular);
            GUILayout.EndHorizontal();
            GUILayout.EndVertical();

            EditorGUILayout.Space();

            GUILayout.BeginVertical("box");
            EditorGUILayout.LabelField("GI Lighting", new GUIStyle("BoldLabel"));
            GUILayout.BeginHorizontal();

            DrawShaderProperties(prop_GI_Diffuse);
            DrawShaderProperties(prop_GI_Specular);

            //DrawShaderProperties(prop_GI_ShadowIntensity);

            GUILayout.EndHorizontal();
            DrawShaderProperties(prop_GI_ShadowIntensity);
            GUILayout.EndVertical();
        }

        protected void DrawPlanarReflection(Material material, MaterialProperty[] properties)
        {
            EditorGUILayout.Space();

            GUILayout.BeginVertical("box");

            DrawShaderProperties(prop_Planar_Reflection);
            DrawShaderProperties(prop_ReflectionAmount);

            GUILayout.EndVertical();
        }
    }
}