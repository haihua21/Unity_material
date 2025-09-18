using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace CustomShaderEditor {
    public class UnlitShaderEditor : BaseMapShaderEditor {

        #region Member

        protected MaterialProperty prop_NormalMap;
        protected MaterialProperty prop_NormalScale;

        protected MaterialProperty prop_ReflectionMap;
        protected MaterialProperty prop_ReflectionColor;
        protected MaterialProperty prop_ReflectionAmount;

        #endregion

        protected static readonly string renderKey_NormalMap = "_NORMALMAP";
        protected static readonly string renderKey_Reflection = "_REFLECTIONMAP";

        protected override void OnGUIEx(MaterialEditor materialEditor, MaterialProperty[] properties) {
            base.OnGUIEx(materialEditor, properties);
            m_comFuncBaseList = new List<ComFuncBase>();
            m_comFuncBaseList.Add(new ComFunc_Emission(this, m_material, m_materialEditor));
            m_comFuncBaseList.Add(new ComFunc_DirtyMap(this, m_material, m_materialEditor));
            m_comFuncBaseList.Add(new ComFunc_DistanceTransparency(this, m_material, m_materialEditor));
        }

        protected override void OnFindProperties(MaterialProperty[] properties) {
            base.OnFindProperties(properties);

            prop_NormalMap = WantFindProperty(m_material, "_NormalMap", properties);
            prop_NormalScale = WantFindProperty(m_material, "_NormalScale", properties);

            prop_ReflectionMap = WantFindProperty(m_material, "_ReflectionMap", properties);
            prop_ReflectionColor = WantFindProperty(m_material, "_ReflectionColor", properties);
            prop_ReflectionAmount = WantFindProperty(m_material, "_ReflectionAmount", properties);
        }

        protected override void OnDrawProperties(Material material, MaterialProperty[] properties) {
            base.OnDrawProperties(material, properties);
            DrawNormalMap(material, properties);
            DrawReflectionMap(material, properties);
        }

        protected override void OnDrawPropertiesAfterComFunc(Material material, MaterialProperty[] properties) {
            DrawTillingAndOffset(material, properties);
        }

        protected void DrawNormalMap(Material material, MaterialProperty[] properties) {
            m_materialEditor.TexturePropertySingleLine(new GUIContent(prop_NormalMap.displayName), prop_NormalMap);
            SetKeyword(material, renderKey_NormalMap, prop_NormalMap.textureValue != null);

            if (prop_NormalMap.textureValue != null) {
                DrawShaderProperties(prop_NormalScale);
            }
        }

        protected void DrawReflectionMap(Material material, MaterialProperty[] properties) {
            m_materialEditor.TexturePropertySingleLine(new GUIContent(prop_ReflectionMap.displayName),
                prop_ReflectionMap,
                prop_ReflectionColor,
                prop_ReflectionAmount);
            SetKeyword(material, renderKey_Reflection, prop_ReflectionMap.textureValue != null);
        }

        protected void DrawTillingAndOffset(Material material, MaterialProperty[] properties) {
            m_materialEditor.TextureScaleOffsetProperty(prop_BaseMap);
        }
    }
}