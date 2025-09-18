using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor
{
    public class ComFunc_IDMap_Highlight : ComFuncBase
    {
#region Member

        protected MaterialProperty prop_HighlightArea;
        protected MaterialProperty prop_HighlightColor;
        protected MaterialProperty prop_HighlightBlinkSpeed;

#endregion

#region KeyWord

        protected static readonly string[] renderKey_HighlightArea = new[] {"_HIGHLIGHT_ONE", "_HIGHLIGHT_TWO", "_HIGHLIGHT_THREE"};

#endregion

        public ComFunc_IDMap_Highlight(BaseShaderEditor shaderGUI, Material material, MaterialEditor materialEditor)
            : base(shaderGUI, material, materialEditor)
        {
        }

        public override void OnFindProperties(MaterialProperty[] properties)
        {
            base.OnFindProperties(properties);

            prop_HighlightArea = WantFindProperty(m_material, "_HighlightArea", properties);
            prop_HighlightColor = WantFindProperty(m_material, "_HighlightColor", properties);
            prop_HighlightBlinkSpeed = WantFindProperty(m_material, "_HighlightBlinkSpeed", properties);
        }

        public override void OnDrawAdvance(Material material, MaterialProperty[] properties)
        {
            DrawHighlightArea(material, properties);
        }

        protected void DrawHighlightArea(Material material, MaterialProperty[] properties)
        {
            GUILayout.BeginVertical("box");
            HopeGUIUtils.DrawEnumWidthKeyword(prop_HighlightArea, renderKey_HighlightArea, m_materialEditor, m_material);
            m_shaderGUI.DrawShaderProperties(prop_HighlightColor);
            m_shaderGUI.DrawShaderProperties(prop_HighlightBlinkSpeed);
            GUILayout.EndVertical();
        }
    }
}
