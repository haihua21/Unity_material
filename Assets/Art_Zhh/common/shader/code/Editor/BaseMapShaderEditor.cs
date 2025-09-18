using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor
{
    public class BaseMapShaderEditor : BaseShaderEditor
    {
#region Member

        protected MaterialProperty prop_BaseMap;
        protected MaterialProperty prop_BaseColor;
        protected MaterialProperty propAlpha;

        protected static bool m_baseProperties = true;

#endregion

#region KeyWord

        protected static readonly string renderKey_BaseMap = "_BASEMAP";

#endregion

        protected override void OnFindProperties(MaterialProperty[] properties)
        {
            base.OnFindProperties(properties);

            prop_BaseMap = WantFindProperty(m_material, "_BaseMap", properties);
            prop_BaseColor = WantFindProperty(m_material, "_BaseColor", properties);
            propAlpha = WantFindProperty(m_material, "_Alpha", properties);
        }

        protected override void OnDrawProperties(Material material, MaterialProperty[] properties)
        {
            base.OnDrawProperties(material, properties);
            DrawBaseMap(material, properties);
        }

        protected void DrawBaseMap(Material material, MaterialProperty[] properties)
        {
            m_materialEditor.TexturePropertySingleLine(new GUIContent(prop_BaseMap.displayName), prop_BaseMap, prop_BaseColor);
            SetKeyword(material, renderKey_BaseMap, prop_BaseMap.textureValue != null);

            DrawShaderProperties(propAlpha);
            OnDrawBase(material, properties);
        }

        protected virtual void OnDrawBase(Material material, MaterialProperty[] properties)
        {
        }
    }
}
