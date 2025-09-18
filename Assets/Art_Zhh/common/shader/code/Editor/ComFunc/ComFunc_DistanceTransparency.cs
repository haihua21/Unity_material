using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor
{
    public class ComFunc_DistanceTransparency : ComFuncBase
    {
#region KeyWord

        protected static readonly string renderKey_DistanceTransparency = "_DISTANCE_TRANSPARENCY";

#endregion

        public ComFunc_DistanceTransparency(BaseShaderEditor shaderGUI,
                                            Material material,
                                            MaterialEditor materialEditor)
            : base(shaderGUI, material, materialEditor)
        {
        }

        public override void OnFindProperties(MaterialProperty[] properties)
        {
            base.OnFindProperties(properties);
        }

        public override void OnDrawProperties(Material material, MaterialProperty[] properties)
        {
        }

        public override void OnDrawAdvance(Material material, MaterialProperty[] properties)
        {
            bool oldValue = material.IsKeywordEnabled(renderKey_DistanceTransparency);
            m_shaderGUI.DrawKeywordEnable(renderKey_DistanceTransparency);
            bool nowValue = material.IsKeywordEnabled(renderKey_DistanceTransparency);
            if (oldValue != nowValue)
            {
                RenderingType mode = nowValue ? RenderingType.Transparent : RenderingType.Opaque;
                m_shaderGUI.SetRenderingType(mode);
                m_shaderGUI.OnRenderingTypeChange(material, mode);
            }
        }
    }
}
