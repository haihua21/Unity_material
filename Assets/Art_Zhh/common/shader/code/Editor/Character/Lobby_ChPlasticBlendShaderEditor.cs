using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor
{
    public class Lobby_ChPlasticBlendShaderEditor : BasePBRShaderEditor
    {
#region Member

        protected MaterialProperty prop_SSSLutMap;
        protected MaterialProperty prop_SSSScale;
        protected MaterialProperty prop_SkyColor;
        protected MaterialProperty prop_EquatorColor;
        protected MaterialProperty prop_GroundColor;
        protected MaterialProperty prop_RimColor;

#endregion

#region KeyWorld

        private static readonly string renderKey_SSSLutMap = "_SSS_LUT_MAP";

        protected static readonly string renderKey_SOMSMap = "_SOMSMAP";

        private static readonly string renderKey_Rim = "_RIM";

#endregion

        protected override void OnFindProperties(MaterialProperty[] properties)
        {
            base.OnFindProperties(properties);

            // som图用处修改
            prop_SOMMap = WantFindProperty(m_material, "_SOMSMap", properties);

            prop_SSSLutMap = WantFindProperty(m_material, "_SSSLutMap", properties);
            prop_SSSScale = WantFindProperty(m_material, "_SSSScale", properties);
            prop_SkyColor = WantFindProperty(m_material, "_SkyColor", properties);
            prop_EquatorColor = WantFindProperty(m_material, "_EquatorColor", properties);
            prop_GroundColor = WantFindProperty(m_material, "_GroundColor", properties);
            prop_RimColor = WantFindProperty(m_material, "_RimColor", properties);
        }

        protected override void OnGUIEx(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            base.OnGUIEx(materialEditor, properties);
            m_comFuncBaseList.Add(new ComFunc_IDMap_Highlight(this, m_material, m_materialEditor));
        }

        protected override void OnDrawProperties(Material material, MaterialProperty[] properties)
        {
            DrawGIDiffuse(material, properties);
            base.OnDrawProperties(material, properties);

            DrawSSSLutMap(material, properties);
            DrawIDMapProperties(material, properties);
            DrawRim(material, properties);
        }

        protected void DrawGIDiffuse(Material material, MaterialProperty[] properties)
        {
            if (material.IsKeywordEnabled(renderKey_GIDiffuse))
            {
                DrawShaderProperties(prop_SkyColor);
                DrawShaderProperties(prop_EquatorColor);
                DrawShaderProperties(prop_GroundColor);
            }
        }

        protected void DrawSSSLutMap(Material material, MaterialProperty[] properties)
        {
            m_materialEditor.TexturePropertySingleLine(new GUIContent(prop_SSSLutMap.displayName), prop_SSSLutMap);
            SetKeyword(material, renderKey_SSSLutMap, prop_SSSLutMap.textureValue != null);
        }

        protected void DrawIDMapProperties(Material material, MaterialProperty[] properties)
        {
            EditorGUILayout.Space();
        }

        protected void DrawRim(Material material, MaterialProperty[] properties)
        {
            DrawKeywordEnable(renderKey_Rim);
            if (material.IsKeywordEnabled(renderKey_Rim))
            {
                DrawShaderProperties(prop_RimColor);
            }
        }

        protected void DrawIDMap(Material material, MaterialProperty[] properties)
        {

        }

        protected override void DrawSOMMap(Material material, MaterialProperty[] properties)
        {
            // SOM图 keyword 修改
            m_materialEditor.TexturePropertySingleLine(new GUIContent(prop_SOMMap.displayName), prop_SOMMap);
            SetKeyword(material, renderKey_SOMSMap, prop_SOMMap.textureValue != null);

            DrawShaderProperties(prop_Smoothness);
            DrawShaderProperties(prop_AO);
            DrawShaderProperties(prop_Metallic);
            DrawShaderProperties(prop_SSSScale);

            EditorGUILayout.Space();
        }
    }
}