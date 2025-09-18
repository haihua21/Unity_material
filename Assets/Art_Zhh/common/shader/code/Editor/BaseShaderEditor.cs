using System;
using System.Collections.Generic;

using UnityEditor;

using UnityEngine;
using UnityEngine.Rendering;

namespace CustomShaderEditor
{
    public class BaseShaderEditor : ShaderGUI
    {
#region Member

        protected List<ComFuncBase> m_comFuncBaseList;

        protected MaterialProperty propAlphaTest;
        protected MaterialProperty propAlphaCutoff;

        protected MaterialProperty prop_RenderingType;
        protected MaterialProperty prop_SrcBlend;
        protected MaterialProperty prop_DstBlend;
        protected MaterialProperty prop_CustomBlendMode;

        protected MaterialProperty prop_ZWrite;
        protected MaterialProperty prop_ZTest;
        protected MaterialProperty prop_Cull;
        protected MaterialProperty prop_ColorMask;

        protected MaterialProperty prop_StencilEnable;
        protected MaterialProperty prop_StencilID;
        protected MaterialProperty prop_StencilComp;
        protected MaterialProperty prop_StencilOp;
        protected MaterialProperty prop_StencilWriteMask;
        protected MaterialProperty prop_StencilReadMask;

        protected MaterialProperty prop_ReceiveShadows;

        protected MaterialEditor m_materialEditor;
        protected Material m_material;

        protected float m_texWidth = 70;
        protected float m_texHeight = 70;

#region Static Properties

        private static bool m_baseProperty = false;
        protected static bool m_stencil = false;
        protected static bool m_advance = false;

#endregion

#endregion

#region KeyWord

        protected static readonly string renderKey_RenderType = "RenderType";
        protected static readonly string renderKey_SrcBlend = "_SrcBlend";
        protected static readonly string renderKey_DstBlend = "_DstBlend";
        protected static readonly string renderKey_ZWrite = "_ZWrite";

#endregion

#region Virtual

        protected virtual void OnFindProperties(MaterialProperty[] properties)
        {
        }

        protected virtual void OnDrawProperties(Material material, MaterialProperty[] properties)
        {
        }

        protected virtual void OnDrawPropertiesAfterComFunc(Material material, MaterialProperty[] properties)
        {
        }

        protected virtual void OnDrawRendering(Material material, MaterialProperty[] properties)
        {
        }

        protected virtual void OnDrawAdvance(Material material, MaterialProperty[] properties)
        {
        }

        protected virtual void OnMaterialChange(Material material)
        {
        }

#endregion

#region Protected

        protected void FindProperties(MaterialProperty[] properties, Material material)
        {
            propAlphaTest = WantFindProperty(material, "_AlphaTest", properties);
            propAlphaCutoff = WantFindProperty(material, "_Cutoff", properties);
            prop_RenderingType = WantFindProperty(material, "_RenderingType", properties);
            prop_SrcBlend = WantFindProperty(material, "_SrcBlend", properties);
            prop_DstBlend = WantFindProperty(material, "_DstBlend", properties);
            prop_CustomBlendMode = WantFindProperty(material, "_CustomBlendMode", properties);

            prop_ZWrite = WantFindProperty(material, "_ZWrite", properties);
            prop_ZTest = WantFindProperty(material, "_ZTest", properties);
            prop_Cull = WantFindProperty(material, "_Cull", properties);
            prop_ColorMask = WantFindProperty(material, "_ColorMask", properties);

            prop_StencilEnable = WantFindProperty(material, "_StencilEnable", properties);
            prop_StencilID = WantFindProperty(material, "_StencilID", properties);
            prop_StencilComp = WantFindProperty(material, "_StencilComp", properties);
            prop_StencilOp = WantFindProperty(material, "_StencilOp", properties);
            prop_StencilWriteMask = WantFindProperty(material, "_StencilWriteMask", properties);
            prop_StencilReadMask = WantFindProperty(material, "_StencilReadMask", properties);

            prop_ReceiveShadows = WantFindProperty(material, "_ReceiveShadows", properties);
            OnFindProperties(properties);
            FindComFuncProperties(properties);
        }

        protected void ShaderPropertiesGUI(Material material, MaterialProperty[] properties)
        {
            EditorGUIUtility.labelWidth = 0.0f;

            EditorGUI.BeginChangeCheck();
            {
                OnDrawProperties(material, properties);
                EditorGUILayout.Space();

                DrawComFuncProperties(material, properties);
                DrawComFuncProperties(material, properties, true);
                OnDrawPropertiesAfterComFunc(material, properties);
                DrawBaseProperties(material, properties);
                EditorGUILayout.Space();

                DrawAdvance(material, properties);
            }

            if (EditorGUI.EndChangeCheck())
            {
                OnMaterialChange(material);
            }
        }

        protected void DrawBaseProperties(Material material, MaterialProperty[] properties)
        {
            m_baseProperty = GUILayout.Toggle(m_baseProperty, "Base Properties", EditorStyles.toolbarButton);
            if (m_baseProperty)
            {
                DrawRendering(material, properties);
                DrawBlendMode(material, properties);
                DrawAlphaTest(material, properties);
                DrawRenderState(material, properties);
                DrawColorMask(material, properties);
                DrawStencil(material, properties);
            }

            EditorGUILayout.Space();
        }

        // 绘制渲染
        protected void DrawRendering(Material material, MaterialProperty[] properties)
        {
            RenderingType oldMode = (RenderingType)prop_RenderingType.floatValue;
            DrawShaderProperties(prop_RenderingType);

            RenderingType mode = (RenderingType)prop_RenderingType.floatValue;
            if (oldMode != mode)
            {
                OnRenderingTypeChange(material, mode);
            }

            // DoEnumPop(prop_SrcBlend, m_style_srcBlend, typeof(BlendMode));
            // DoEnumPop(prop_DstBlend, m_style_dstBlend, typeof(BlendMode));


            // DrawShaderProperties(prop_ZWrite, m_style_zWrite);

            // 裁剪
            // DoEnumPop(prop_Cull, m_style_cull, typeof(RenderFace));

            OnDrawRendering(material, properties);
        }

        private void DrawBlendMode(Material material, MaterialProperty[] properties)
        {
            var oldCustomBlend = prop_CustomBlendMode.floatValue;
            DrawShaderProperties(prop_CustomBlendMode);
            var newCustomBlend = prop_CustomBlendMode.floatValue;
            if (oldCustomBlend != newCustomBlend)
            {
                OnCustomBlendModeChange(material);
            }
        }

        protected void DrawAlphaTest(Material material, MaterialProperty[] properties)
        {
            if (propAlphaTest == null) return;

            DrawShaderProperties(propAlphaTest);
            if (propAlphaTest.floatValue > 0.0f)
            {
                DrawShaderProperties(propAlphaCutoff);
            }
        }

        protected void OnCustomBlendModeChange(Material material)
        {
            CustomBlendMode mode = (CustomBlendMode)(material.HasProperty("_CustomBlendMode") ? material.GetFloat("_CustomBlendMode") : 0);
            switch (mode)
            {
                case CustomBlendMode.Opaque:
                    material.SetInt("_SrcBlend", (int)BlendMode.One);
                    material.SetInt("_DstBlend", (int)BlendMode.Zero);
                    break;
                case CustomBlendMode.AlphaBlending:
                    material.SetInt("_SrcBlend", (int)BlendMode.SrcAlpha);
                    material.SetInt("_DstBlend", (int)BlendMode.OneMinusSrcAlpha);
                    break;
                case CustomBlendMode.WZ_Additive:
                    material.SetInt("_SrcBlend", (int)BlendMode.SrcAlpha);
                    material.SetInt("_DstBlend", (int)BlendMode.One);
                    break;
                case CustomBlendMode.Additive:
                    material.SetInt("_SrcBlend", (int)BlendMode.One);
                    material.SetInt("_DstBlend", (int)BlendMode.One);
                    break;
                case CustomBlendMode.SoftAdditive:
                    material.SetInt("_SrcBlend", (int)BlendMode.OneMinusDstColor);
                    material.SetInt("_DstBlend", (int)BlendMode.One);
                    break;
                case CustomBlendMode.Multiplicative:
                    material.SetInt("_SrcBlend", (int)BlendMode.DstColor);
                    material.SetInt("_DstBlend", (int)BlendMode.Zero);
                    break;
                case CustomBlendMode.Two_x_Multiplicative:
                    material.SetInt("_SrcBlend", (int)BlendMode.DstColor);
                    material.SetInt("_DstBlend", (int)BlendMode.SrcColor);
                    break;
            }
        }

        private void DrawRenderState(Material material, MaterialProperty[] properties)
        {
            DoEnumPop(prop_Cull, typeof(RenderFace));
            DrawShaderProperties(prop_ZWrite);
            DoEnumPop(prop_ZTest, typeof(CompareFunction));
        }

        private void DrawColorMask(Material material, MaterialProperty[] properties)
        {
            if (prop_ColorMask != null)
            {
                DoEnumPop(prop_ColorMask, typeof(ColorMask));
            }
        }

        private void DrawStencil(Material material, MaterialProperty[] properties)
        {
            prop_StencilEnable.floatValue = DoPropertiesEnable(prop_StencilEnable, ref m_stencil);

            if (m_stencil)
            {
                if (prop_StencilEnable.floatValue >= 1)
                {
                    DrawShaderProperties(prop_StencilID);
                    DoEnumPop(prop_StencilComp, typeof(CompareFunction));
                    DoEnumPop(prop_StencilOp, typeof(StencilOp));
                    DrawShaderProperties(prop_StencilWriteMask);
                    DrawShaderProperties(prop_StencilReadMask);
                }
                else
                {
                    prop_StencilID.floatValue = 0;
                    prop_StencilComp.floatValue = (float)CompareFunction.Disabled;
                    prop_StencilOp.floatValue = (float)StencilOp.Keep;
                    prop_StencilWriteMask.floatValue = 255;
                    prop_StencilReadMask.floatValue = 255;
                }
            }
        }

        protected void DrawAdvance(Material material, MaterialProperty[] properties)
        {
            m_advance = GUILayout.Toggle(m_advance, "Advance", EditorStyles.toolbarButton);
            if (m_advance)
            {
                OnDrawAdvance(material, properties);
                DrawComFuncAdvance(material, properties);
            }
        }

#endregion

#region Public Utils

        public MaterialProperty FindPropertyEx(string key, MaterialProperty[] properties)
        {
            return FindProperty(key, properties);
        }

        public void FindComFuncProperties(MaterialProperty[] properties)
        {
            if (m_comFuncBaseList != null)
            {
                int count = m_comFuncBaseList.Count;
                for (int i = 0; i < count; i++)
                {
                    m_comFuncBaseList[i].OnFindProperties(properties);
                }
            }
        }

        public void DrawComFuncProperties(Material material, MaterialProperty[] properties, bool drawCustomToolbar = false)
        {
            if (m_comFuncBaseList != null)
            {
                int count = m_comFuncBaseList.Count;
                for (int i = 0; i < count; i++)
                {
                    if (m_comFuncBaseList[i].m_isCustomToolbar == drawCustomToolbar)
                    {
                        m_comFuncBaseList[i].OnDrawProperties(material, properties);
                    }
                }
            }
        }

        public void DrawComFuncAdvance(Material material, MaterialProperty[] properties)
        {
            if (m_comFuncBaseList != null)
            {
                int count = m_comFuncBaseList.Count;
                for (int i = 0; i < count; i++)
                {
                    m_comFuncBaseList[i].OnDrawAdvance(material, properties);
                }
            }
        }

        public void SetKeyword(Material material, string keyword, bool value)
        {
            if (value)
            {
                material.EnableKeyword(keyword);
            }
            else
            {
                material.DisableKeyword(keyword);
            }
        }

        public void SetRenderingType(RenderingType mode)
        {
            prop_RenderingType.floatValue = (float)mode;
        }

        public void OnRenderingTypeChange(Material material, RenderingType mode)
        {
            switch (mode)
            {
                case RenderingType.Opaque:
                    prop_CustomBlendMode.floatValue = (float)CustomBlendMode.Opaque;
                    material.SetOverrideTag(renderKey_RenderType, "Opaque");
                    material.SetInt(renderKey_ZWrite, 1);
                    material.renderQueue = (int)RenderQueue.Geometry;
                    break;
                case RenderingType.Transparent:
                    prop_CustomBlendMode.floatValue = (float)CustomBlendMode.AlphaBlending;
                    material.SetOverrideTag(renderKey_RenderType, "Transparent");
                    material.SetInt(renderKey_ZWrite, 0);
                    if (propAlphaTest != null)
                    {
                        propAlphaTest.floatValue = 0.0f;
                    }
                    material.renderQueue = (int)RenderQueue.Transparent;
                    break;
            }

            OnCustomBlendModeChange(material);
        }

        public void DrawShaderProperties(MaterialProperty property)
        {
            if (property != null)
            {
                m_materialEditor.ShaderProperty(property, property.displayName);
            }
        }

        public MaterialProperty WantFindProperty(Material material, string key, MaterialProperty[] properties)
        {
            if (material.HasProperty(key))
            {
                try
                {
                    return FindProperty(key, properties);
                }
                catch (Exception)
                {
                    return null;
                }
            }

            return null;
        }

        public void DoEnumPop(MaterialProperty property, Type enumType)
        {
            EditorGUI.BeginChangeCheck();
            Enum value = (Enum)Enum.Parse(enumType, property.floatValue.ToString());
            value = EditorGUILayout.EnumPopup(property.displayName, value);

            if (EditorGUI.EndChangeCheck())
            {
                m_materialEditor.RegisterPropertyChangeUndo(property.displayName);
                property.floatValue = (int)Enum.ToObject(enumType, value);
            }
        }

        public float DoPropertiesEnable(MaterialProperty prop, ref bool btnValue)
        {
            GUILayout.BeginHorizontal();
            var toggleValue = EditorGUILayout.Toggle(prop.floatValue > 0, GUILayout.Width(18)) ? 1 : 0;

            btnValue = GUILayout.Toggle(btnValue, prop.displayName, EditorStyles.toolbarButton);
            GUILayout.EndHorizontal();
            return toggleValue;
        }

        public bool DrawKeywordEnable(string keyword)
        {
            bool isEnable = m_material.IsKeywordEnabled(keyword);
            isEnable = EditorGUILayout.Toggle(keyword, isEnable);
            SetKeyword(m_material, keyword, isEnable);
            return isEnable;
        }

        public void DrawPropTexture(GUIContent guiContent, MaterialProperty property)
        {
            GUILayout.BeginHorizontal();
            GUILayout.BeginVertical();
            EditorGUILayout.LabelField(guiContent, GUILayout.Width(150));
            GUILayout.Space(10);
            EditorGUI.indentLevel += 1;
            m_materialEditor.TextureScaleOffsetProperty(property);
            EditorGUI.indentLevel -= 1;
            GUILayout.EndVertical();
            property.textureValue = (Texture)EditorGUILayout.ObjectField(property.textureValue,
                                                                         typeof(Texture),
                                                                         false,
                                                                         GUILayout.Width(m_texWidth),
                                                                         GUILayout.Height(m_texHeight));
            GUILayout.EndHorizontal();
        }

#endregion

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            m_material = materialEditor.target as Material;
            m_materialEditor = materialEditor;
            OnGUIEx(materialEditor, properties);

            FindProperties(properties, m_material);


            ShaderPropertiesGUI(m_material, properties);

            materialEditor.RenderQueueField();
            materialEditor.EnableInstancingField();
        }

        public override void AssignNewShaderToMaterial(Material material, Shader oldShader, Shader newShader)
        {
            if (material == null)
                throw new ArgumentNullException("material");
            
            base.AssignNewShaderToMaterial(material, oldShader, newShader);
            
            if (material.HasProperty("_RenderingType"))
            {
                RenderingType renderingType = (RenderingType)material.GetFloat("_RenderingType");
                if (renderingType == RenderingType.Opaque)
                {
                    material.SetOverrideTag(renderKey_RenderType, "Opaque");
                    material.SetInt(renderKey_ZWrite, 1);
                    material.renderQueue = (int)RenderQueue.Geometry;
                }
                else
                {
                    material.SetOverrideTag(renderKey_RenderType, "Transparent");
                    material.SetInt(renderKey_ZWrite, 0);
                    material.renderQueue = (int)RenderQueue.Transparent;
                }
                
                OnCustomBlendModeChange(material);
            }
        }

        protected virtual void OnGUIEx(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
        }
    }
}
