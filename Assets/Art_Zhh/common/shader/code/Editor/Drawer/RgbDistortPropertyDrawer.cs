using System.Collections.Generic;

using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor.Drawer
{
    public class RgbDistortPropertyDrawer : IShaderPropertyDrawer
    {
        public RgbDistortPropertyDrawer(string propertyName)
            : base(propertyName)
        {
        }

        public override void Draw(MaterialEditor materialEditor, Material material, Dictionary<string, MaterialProperty> propertyMap)
        {
            var propMaskMap = propertyMap[propertyName];
            DrawTexture(materialEditor, propMaskMap);
            DrawVector2(materialEditor, propertyMap["_RgbDistortIntensity"]);
            DrawVector2(materialEditor, propertyMap["_RgbDistortOffset"]);
        }
    }
}
