using System.Collections.Generic;

using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor.Drawer
{
    public class KeywordPropertyDrawer : IShaderPropertyDrawer
    {
        public KeywordPropertyDrawer(string propertyName)
            : base(propertyName)
        {
        }

        public override void Draw(MaterialEditor materialEditor, Material material, Dictionary<string, MaterialProperty> propertyMap)
        {
            var prop = propertyMap[propertyName];
            DrawKeyword(material, prop.name, out _, prop.displayName);
        }
    }
}
