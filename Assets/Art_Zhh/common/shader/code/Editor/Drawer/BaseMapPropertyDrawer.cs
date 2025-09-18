using System.Collections.Generic;

using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor.Drawer
{
    public class BaseMapPropertyDrawer : IShaderPropertyDrawer
    {
        public BaseMapPropertyDrawer(string propertyName)
            : base(propertyName)
        {
        }

        public override void Draw(MaterialEditor materialEditor, Material material, Dictionary<string, MaterialProperty> propertyMap)
        {
            DrawTextureWithColor(materialEditor, propertyMap[propertyName], propertyMap["_BaseColor"]);
            if (propertyMap.ContainsKey("_BaseColorIntensity"))
            {
                DrawDefault(materialEditor, propertyMap["_BaseColorIntensity"]);
            }

            DrawDefault(materialEditor, propertyMap["_BaseMapAngle"]);
            if (propertyMap.TryGetValue("_BaseUvSpeed", out var propBaseUvSpeed))
            {
                EditorGUI.BeginChangeCheck();
                var newValue = propBaseUvSpeed.vectorValue;
                newValue.x = EditorGUILayout.Slider("MainUV Speed x", newValue.x, -1.0f, 1.0f);
                newValue.y = EditorGUILayout.Slider("MainUV Speed y", newValue.y, -1.0f, 1.0f);
                if (EditorGUI.EndChangeCheck())
                {
                    propBaseUvSpeed.vectorValue = newValue;
                }
            }
        }
    }
}
