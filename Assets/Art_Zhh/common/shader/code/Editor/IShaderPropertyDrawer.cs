using System;
using System.Collections.Generic;

using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor
{
    public abstract class IShaderPropertyDrawer
    {
        private const int TextureWidth = 58;
        private const int TextureHeight = 58;
        private const int ColorWidth = 70;
        private const int TextureSpace = 0;

        public string propertyName { get; }

        protected IShaderPropertyDrawer(string propertyName)
        {
            this.propertyName = propertyName;
        }

        public abstract void Draw(MaterialEditor materialEditor, Material material, Dictionary<string, MaterialProperty> propertyMap);

        public static void DrawDefault(MaterialEditor materialEditor, MaterialProperty prop)
        {
            if (prop != null)
            {
                materialEditor.ShaderProperty(prop, prop.displayName);
            }
        }

        public static void DrawRadian(MaterialEditor materialEditor, MaterialProperty prop)
        {
            if (prop != null)
            {
                var newValue = prop.floatValue * Mathf.Rad2Deg;
                EditorGUI.BeginChangeCheck();
                newValue = EditorGUILayout.Slider("MainUV Speed x", newValue, 0.0f, 360.0f);
                if (EditorGUI.EndChangeCheck())
                {
                    prop.floatValue = newValue * Mathf.Deg2Rad;
                }
            }
        }

        public static bool DrawToggleKeyword(Material material, string keyword, string label, out bool changed)
        {
            changed = false;
            var enable = material.IsKeywordEnabled(keyword);

            EditorGUI.BeginChangeCheck();

            GUILayout.BeginHorizontal();
            GUILayout.Toggle(enable, label, EditorStyles.toolbarButton);
            enable = GUILayout.Toggle(enable, string.Empty, GUILayout.Width(20));
            GUILayout.EndHorizontal();

            if (EditorGUI.EndChangeCheck())
            {
                SetKeyword(material, keyword, enable);
                changed = true;
            }

            return enable;
        }

        public static bool DrawToggle(MaterialEditor materialEditor, MaterialProperty propToggle, out bool changed)
        {
            changed = false;
            EditorGUI.BeginChangeCheck();

            var oldValue = propToggle.floatValue > 0.0f;
            var newValue = EditorGUILayout.Toggle(propToggle.displayName, oldValue);

            if (EditorGUI.EndChangeCheck())
            {
                changed = true;
                if (newValue != oldValue)
                {
                    materialEditor.RegisterPropertyChangeUndo(propToggle.displayName);
                }

                propToggle.floatValue = newValue ? 1.0f : 0.0f;
            }

            return newValue;
        }

        public static bool DrawKeyword(Material material, string keyword, out bool changed, string label = null)
        {
            changed = false;
            if (string.IsNullOrEmpty(label)) label = keyword;

            EditorGUI.BeginChangeCheck();

            var isEnable = material.IsKeywordEnabled(keyword);
            isEnable = EditorGUILayout.Toggle(label, isEnable);

            if (EditorGUI.EndChangeCheck())
            {
                SetKeyword(material, keyword, isEnable);
                changed = true;
            }

            return isEnable;
        }

        public static void SetKeyword(Material material, string keyword, bool enable)
        {
            if (enable)
            {
                material.EnableKeyword(keyword);
            }
            else
            {
                material.DisableKeyword(keyword);
            }
        }

        public static float DrawEnum(MaterialEditor materialEditor, MaterialProperty propEnum, Type enumType, out bool changed)
        {
            changed = false;
            EditorGUI.BeginChangeCheck();
            var value = (Enum)Enum.Parse(enumType, propEnum.floatValue.ToString());
            value = EditorGUILayout.EnumPopup(propEnum.displayName, value);
            if (EditorGUI.EndChangeCheck())
            {
                changed = true;
                materialEditor.RegisterPropertyChangeUndo(propEnum.displayName);
                propEnum.floatValue = (int)Enum.ToObject(enumType, value);
            }

            return propEnum.floatValue;
        }

        public static Vector2 DrawVector2(MaterialEditor materialEditor, MaterialProperty propVec)
        {
            EditorGUI.BeginChangeCheck();
            var newValue = EditorGUILayout.Vector2Field(propVec.displayName, propVec.vectorValue);
            if (EditorGUI.EndChangeCheck())
            {
                propVec.vectorValue = newValue;
            }

            return newValue;
        }

        public static Vector3 DrawVector3(MaterialEditor materialEditor, MaterialProperty propVec)
        {
            EditorGUI.BeginChangeCheck();
            var newValue = EditorGUILayout.Vector3Field(propVec.displayName, propVec.vectorValue);
            if (EditorGUI.EndChangeCheck())
            {
                propVec.vectorValue = newValue;
            }

            return newValue;
        }

        public static void DrawTexture(MaterialEditor materialEditor, MaterialProperty propTex, bool showTilingOffset = true)
        {
            GUILayout.Space(TextureSpace);
            GUILayout.BeginHorizontal();
            GUILayout.BeginVertical();
            EditorGUILayout.LabelField(new GUIContent(propTex.displayName), GUILayout.ExpandWidth(true));

            if (showTilingOffset)
            {
                EditorGUI.indentLevel += 1;
                materialEditor.TextureScaleOffsetProperty(propTex);
                EditorGUI.indentLevel -= 1;
            }

            GUILayout.EndVertical();
            EditorGUI.BeginChangeCheck();
            var texture = (Texture)EditorGUILayout.ObjectField(propTex.textureValue,
                                                               typeof(Texture),
                                                               false,
                                                               GUILayout.Width(TextureWidth),
                                                               GUILayout.Height(TextureHeight));
            if (EditorGUI.EndChangeCheck())
            {
                propTex.textureValue = texture;
            }

            GUILayout.EndHorizontal();
        }

        public static void DrawTextureWithColor(MaterialEditor materialEditor,
                                                MaterialProperty propTex,
                                                MaterialProperty propColor = null,
                                                bool showTilingOffset = true)
        {
            GUILayout.Space(TextureSpace);
            GUILayout.BeginHorizontal();
            GUILayout.BeginVertical();
            if (propColor != null)
            {
                GUILayout.BeginHorizontal();
                EditorGUILayout.LabelField(new GUIContent(propTex.displayName));
                EditorGUI.BeginChangeCheck();
                var color = EditorGUILayout.ColorField(new GUIContent(), propColor.colorValue, true, true, true, GUILayout.Width(ColorWidth));
                if (EditorGUI.EndChangeCheck())
                {
                    propColor.colorValue = color;
                }

                GUILayout.EndHorizontal();
            }
            else
            {
                EditorGUILayout.LabelField(new GUIContent(propTex.displayName), GUILayout.ExpandWidth(true));
            }

            if (showTilingOffset)
            {
                EditorGUI.indentLevel += 1;
                materialEditor.TextureScaleOffsetProperty(propTex);
                EditorGUI.indentLevel -= 1;
            }

            GUILayout.EndVertical();
            EditorGUI.BeginChangeCheck();
            var texture = (Texture)EditorGUILayout.ObjectField(propTex.textureValue,
                                                               typeof(Texture),
                                                               false,
                                                               GUILayout.Width(TextureWidth),
                                                               GUILayout.Height(TextureHeight));
            if (EditorGUI.EndChangeCheck())
            {
                propTex.textureValue = texture;
            }

            GUILayout.EndHorizontal();
        }

        public static void DrawTextureWithCustomScaleOffset(MaterialEditor materialEditor,
                                                            MaterialProperty propTex,
                                                            MaterialProperty propScale = null,
                                                            MaterialProperty propOffset = null)
        {
            GUILayout.Space(TextureSpace);
            GUILayout.BeginHorizontal();
            GUILayout.BeginVertical();
            EditorGUILayout.LabelField(new GUIContent(propTex.displayName), GUILayout.ExpandWidth(true));

            EditorGUI.indentLevel += 1;
            if (propScale != null)
            {
                DrawDefault(materialEditor, propScale);
            }

            if (propOffset != null)
            {
                DrawDefault(materialEditor, propOffset);
            }

            EditorGUI.indentLevel -= 1;

            GUILayout.EndVertical();
            EditorGUI.BeginChangeCheck();
            var texture = (Texture)EditorGUILayout.ObjectField(propTex.textureValue,
                                                               typeof(Texture),
                                                               false,
                                                               GUILayout.Width(TextureWidth),
                                                               GUILayout.Height(TextureHeight));
            if (EditorGUI.EndChangeCheck())
            {
                propTex.textureValue = texture;
            }

            GUILayout.EndHorizontal();
        }
    }
}
