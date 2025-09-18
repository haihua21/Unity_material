using System.Collections.Generic;

using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor.Drawer
{
    public class DistortPropertyDrawer : IShaderPropertyDrawer
    {
        public DistortPropertyDrawer(string propertyName)
            : base(propertyName)
        {
        }

        public override void Draw(MaterialEditor materialEditor, Material material, Dictionary<string, MaterialProperty> propertyMap)
        {
            if (DrawToggleKeyword(material, "_DISTORT_ENABLE", "Distort Enable", out var changed))
            {
                var propDistortMap = propertyMap[propertyName];
                DrawTexture(materialEditor, propDistortMap);
                DrawVector2(materialEditor, propertyMap["_DistortFrequency"]);
                DrawVector2(materialEditor, propertyMap["_DistortSwing"]);
            }
        }
    }
}
