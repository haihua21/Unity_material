using System;

using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor
{
    public static class HopeGUIUtils
    {
        public static float DrawEnum<T>(Rect position, string label, float value) where T : Enum
        {
            var enumType = typeof(T);
            return DrawEnum(enumType, position, value, new GUIContent(label));
        }

        public static float DrawEnum(Type enumType, Rect position, float value, GUIContent label)
        {
            var enumValue = (Enum)Enum.Parse(enumType, value.ToString());

            EditorGUI.BeginChangeCheck();
            enumValue = EditorGUI.EnumPopup(position, label, enumValue);

            EditorGUI.showMixedValue = false;
            if (EditorGUI.EndChangeCheck())
            {
                value = (int)Enum.ToObject(enumType, enumValue);
            }

            return value;
        }

        public static void DrawEnumWidthKeyword(MaterialProperty prop, string[] keyword, MaterialEditor materialEditor, Material material)
        {
            var oldValue = prop.floatValue;
            DrawShaderProperties(prop, materialEditor);
            var nowValue = prop.floatValue;

            if (Math.Abs(oldValue - nowValue) < 0.001f)
            {
                return;
            }

            var count = keyword.Length;
            for (var i = 0; i < count; i++)
            {
                var tmp = Math.Abs(nowValue - 1 - i) < 0.001f;

                SetKeyword(material, keyword[i], tmp);
            }
        }

        public static void DrawShaderProperties(MaterialProperty property, MaterialEditor materialEditor)
        {
            if (property != null)
            {
                materialEditor.ShaderProperty(property, property.displayName);
            }
        }

        public static void SetKeyword(Material material, string keyword, bool value)
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
    }
}
