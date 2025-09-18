using System.Collections.Generic;

using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor.Drawer
{
    public class SmokePropertyDrawer : IShaderPropertyDrawer
    {
        public SmokePropertyDrawer(string propertyName)
            : base(propertyName)
        {
        }

        public override void Draw(MaterialEditor materialEditor, Material material, Dictionary<string, MaterialProperty> propertyMap)
        {
            DrawVector3(materialEditor, propertyMap["_SmokeLightDirOffset"]);
            DrawDefault(materialEditor, propertyMap["_SmokeHighLightColor"]);
            DrawDefault(materialEditor, propertyMap["_SmokeBackLightColor"]);

            if (DrawKeyword(material, "_SMOKE_REMAP", out _, "Smoke Remap"))
            {
                DrawTexture(materialEditor, propertyMap["_SmokeRemap"], false);
            }
        }
    }
}
