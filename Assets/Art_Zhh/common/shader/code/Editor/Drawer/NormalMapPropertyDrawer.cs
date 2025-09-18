using System.Collections.Generic;

using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor.Drawer
{
    public class NormalMapPropertyDrawer : IShaderPropertyDrawer
    {
        public NormalMapPropertyDrawer(string propertyName)
            : base(propertyName)
        {
        }

        public override void Draw(MaterialEditor materialEditor, Material material, Dictionary<string, MaterialProperty> propertyMap)
        {
            DrawTexture(materialEditor, propertyMap[propertyName], false);
            DrawDefault(materialEditor, propertyMap["_NormalScale"]);
        }
    }
}
