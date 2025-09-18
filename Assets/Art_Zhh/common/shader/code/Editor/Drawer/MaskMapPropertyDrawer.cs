using System.Collections.Generic;

using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor.Drawer
{
    public class MaskMapPropertyDrawer : IShaderPropertyDrawer
    {
        public MaskMapPropertyDrawer(string propertyName)
            : base(propertyName)
        {
        }

        public override void Draw(MaterialEditor materialEditor, Material material, Dictionary<string, MaterialProperty> propertyMap)
        {
            if (DrawToggleKeyword(material, "_USE_MASK", "Mask Enable", out var changed))
            {
                var propMaskMap = propertyMap[propertyName];
                DrawTexture(materialEditor, propMaskMap);
                DrawDefault(materialEditor, propertyMap["_MaskMapAngle"]);
            }
        }
    }
}
