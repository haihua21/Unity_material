using System.Collections.Generic;

using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor.Drawer
{
    public class CustomDataPropertyDrawer : IShaderPropertyDrawer
    {
        private bool _customState;

        public CustomDataPropertyDrawer(string propertyName)
            : base(propertyName)
        {
        }

        public override void Draw(MaterialEditor materialEditor, Material material, Dictionary<string, MaterialProperty> propertyMap)
        {
            GUILayout.BeginHorizontal();
            _customState = GUILayout.Toggle(_customState, "Custom Data", EditorStyles.toolbarButton);

            EditorGUI.BeginChangeCheck();
            var isKeywordEnable = GUILayout.Toggle(material.IsKeywordEnabled("_USE_CUSTOM_DATA"), "", GUILayout.Width(20));
            if (EditorGUI.EndChangeCheck())
            {
                SetKeyword(material, "_USE_CUSTOM_DATA", isKeywordEnable);
            }

            GUILayout.EndHorizontal();

            if (_customState || isKeywordEnable)
            {
                if (propertyMap.TryGetValue("_CustomData1", out var propCustomData1))
                {
                    EditorGUI.BeginChangeCheck();
                    var labels = propCustomData1.displayName.Split(',');
                    var newValue = propCustomData1.vectorValue;
                    newValue.x = EditorGUILayout.Slider(labels[0], newValue.x, -10.0f, 10.0f);
                    newValue.y = EditorGUILayout.Slider(labels[1], newValue.y, -10.0f, 10.0f);
                    newValue.z = EditorGUILayout.Slider(labels[2], newValue.z, -10.0f, 10.0f);
                    newValue.w = EditorGUILayout.Slider(labels[3], newValue.w, -10.0f, 10.0f);
                    if (EditorGUI.EndChangeCheck())
                    {
                        propCustomData1.vectorValue = newValue;
                    }
                }

                if (propertyMap.TryGetValue("_CustomData2", out var propCustomData2))
                {
                    EditorGUI.BeginChangeCheck();
                    var labels = propCustomData2.displayName.Split(',');
                    var newValue = propCustomData2.vectorValue;
                    newValue.x = EditorGUILayout.Slider(labels[0], newValue.x, -10.0f, 10.0f);
                    newValue.y = EditorGUILayout.Slider(labels[1], newValue.y, -10.0f, 10.0f);
                    newValue.z = EditorGUILayout.Slider(labels[2], newValue.z, -10.0f, 10.0f);
                    newValue.w = EditorGUILayout.Slider(labels[3], newValue.w, -10.0f, 10.0f);
                    if (EditorGUI.EndChangeCheck())
                    {
                        propCustomData2.vectorValue = newValue;
                    }
                }
            }
        }
    }
}
