using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor
{
    public class ComFunc_Emission : ComFuncBase
    {
#region Member

        protected MaterialProperty prop_EmissionColor;
        protected MaterialProperty prop_EmissionMap;
        protected MaterialProperty prop_EmissionNeedAtten;
        protected MaterialProperty prop_EmissionLightAffect;

#endregion

#region KeyWord

        protected static readonly string renderKey_Emission = "_EMISSION";

#endregion

        public ComFunc_Emission(BaseShaderEditor shaderGUI, Material material, MaterialEditor materialEditor)
            : base(shaderGUI, material, materialEditor)
        {
        }

        public override void OnFindProperties(MaterialProperty[] properties)
        {
            base.OnFindProperties(properties);

            prop_EmissionColor = WantFindProperty(m_material, "_EmissionColor", properties);
            prop_EmissionMap = WantFindProperty(m_material, "_EmissionMap", properties);
            prop_EmissionNeedAtten = WantFindProperty(m_material, "_Emission_Need_Atten", properties);
            prop_EmissionLightAffect = WantFindProperty(m_material, "_Emission_Light_Affect", properties);
        }

        public override void OnDrawProperties(Material material, MaterialProperty[] properties)
        {
            DrawEmission(material, properties);
        }

        protected void DrawEmission(Material material, MaterialProperty[] properties)
        {
            if (material.globalIlluminationFlags != MaterialGlobalIlluminationFlags.AnyEmissive)
            {
                material.globalIlluminationFlags = MaterialGlobalIlluminationFlags.AnyEmissive;
            }

            m_materialEditor.TexturePropertySingleLine(new GUIContent(prop_EmissionMap.displayName), prop_EmissionMap, prop_EmissionColor);
            m_shaderGUI.SetKeyword(material, renderKey_Emission, prop_EmissionMap.textureValue != null);
            m_shaderGUI.DrawShaderProperties(prop_EmissionNeedAtten);
            if (prop_EmissionNeedAtten != null && prop_EmissionNeedAtten.floatValue > 0)
            {
                m_shaderGUI.DrawShaderProperties(prop_EmissionLightAffect);
            }
        }
    }
}
