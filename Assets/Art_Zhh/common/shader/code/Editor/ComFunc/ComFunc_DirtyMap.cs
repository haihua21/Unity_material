using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor
{
    public class ComFunc_DirtyMap : ComFuncBase
    {
        protected MaterialProperty prop_DirtyMap;
        protected MaterialProperty prop_DirtyColor;
        protected MaterialProperty prop_DirtyAmount;

#region KeyWord

        protected static readonly string renderKey_DirtyMap = "_DIRTY_MAP";

#endregion

        public ComFunc_DirtyMap(BaseShaderEditor shaderGUI, Material material, MaterialEditor materialEditor)
            : base(shaderGUI, material, materialEditor)
        {
        }

        public override void OnFindProperties(MaterialProperty[] properties)
        {
            base.OnFindProperties(properties);
            prop_DirtyMap = WantFindProperty(m_material, "_DirtyMap", properties);
            prop_DirtyColor = WantFindProperty(m_material, "_DirtyColor", properties);
            prop_DirtyAmount = WantFindProperty(m_material, "_DirtyAmount", properties);
        }

        public override void OnDrawAdvance(Material material, MaterialProperty[] properties)
        {
            if (prop_DirtyMap == null)
            {
                return;
            }

            GUILayout.BeginVertical("box");
            m_materialEditor.TexturePropertySingleLine(new GUIContent(prop_DirtyMap.displayName), prop_DirtyMap, prop_DirtyAmount);
            if (prop_DirtyMap.textureValue != null)
            {
                m_shaderGUI.DrawShaderProperties(prop_DirtyColor);
                m_materialEditor.TextureScaleOffsetProperty(prop_DirtyMap);
            }

            m_shaderGUI.SetKeyword(material, renderKey_DirtyMap, prop_DirtyMap.textureValue != null);
            GUILayout.EndVertical();
        }
    }
}
