using System.Collections.Generic;

using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor.Drawer
{
    public class DissolvePropertyDrawer : IShaderPropertyDrawer
    {
        public DissolvePropertyDrawer(string propertyName)
            : base(propertyName)
        {
        }

        public override void Draw(MaterialEditor materialEditor, Material material, Dictionary<string, MaterialProperty> propertyMap)
        {
            if (DrawToggleKeyword(material, "_DISSOLVE_ENABLE", "Dissolve Enable", out var changed))
            {
                var propDissolveMap = propertyMap[propertyName];
                DrawTexture(materialEditor, propDissolveMap);
                DrawVector2(materialEditor, propertyMap["_DissolveUvSpeed"]);
                DrawDefault(materialEditor, propertyMap["_DissolveSoftValue"]);
                DrawDefault(materialEditor, propertyMap["_DissolveEdgeWidth"]);
                DrawDefault(materialEditor, propertyMap["_DissolveEdgeColor"]);
            }
        }
    }
}
