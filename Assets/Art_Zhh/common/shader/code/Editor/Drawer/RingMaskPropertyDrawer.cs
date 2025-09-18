using System.Collections.Generic;

using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor.Drawer
{
    public class RingMaskPropertyDrawer : IShaderPropertyDrawer
    {
        public RingMaskPropertyDrawer(string propertyName)
            : base(propertyName)
        {
        }

        public override void Draw(MaterialEditor materialEditor, Material material, Dictionary<string, MaterialProperty> propertyMap)
        {
            if (DrawToggleKeyword(material, "_RING_MASK_ENABLE", "Ring Mask Enable", out _))
            {
                DrawDefault(materialEditor, propertyMap["_RingInnerRadius"]);
                DrawDefault(materialEditor, propertyMap["_RingOuterRadius"]);
                DrawRadian(materialEditor, propertyMap["_RingStartRadian"]);
                DrawRadian(materialEditor, propertyMap["_RingEndRadian"]);
            }
        }
    }
}
