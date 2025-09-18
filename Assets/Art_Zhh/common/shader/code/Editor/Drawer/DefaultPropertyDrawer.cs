using System.Collections.Generic;

using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor.Drawer
{
    public class DefaultPropertyDrawer : IShaderPropertyDrawer
    {
        public DefaultPropertyDrawer(string propertyName)
            : base(propertyName)
        {
        }

        public override void Draw(MaterialEditor materialEditor, Material material, Dictionary<string, MaterialProperty> propertyMap)
        {
            var prop = propertyMap[propertyName];
            materialEditor.ShaderProperty(prop, new GUIContent(prop.displayName));
        }
    }
}
