using System.Collections.Generic;

using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor.Drawer
{
    public class MatcapMapPropertyDrawer : IShaderPropertyDrawer
    {
        public MatcapMapPropertyDrawer(string propertyName)
            : base(propertyName)
        {
        }

        public override void Draw(MaterialEditor materialEditor, Material material, Dictionary<string, MaterialProperty> propertyMap)
        {
            DrawTextureWithColor(materialEditor, propertyMap[propertyName], propertyMap["_MatcapColor"], false);
            DrawDefault(materialEditor, propertyMap["_MatcapIntensity"]);
        }
    }
}
