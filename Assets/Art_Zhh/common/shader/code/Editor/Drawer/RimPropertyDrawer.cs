using System.Collections.Generic;

using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor.Drawer
{
    public class RimPropertyDrawer : IShaderPropertyDrawer
    {
        public RimPropertyDrawer(string propertyName)
            : base(propertyName)
        {
        }

        public override void Draw(MaterialEditor materialEditor, Material material, Dictionary<string, MaterialProperty> propertyMap)
        {
            if (DrawToggleKeyword(material, "_RIM_ENABLE", "Rim Enable", out var changed))
            {
                DrawDefault(materialEditor, propertyMap["_RimColor"]);
                DrawDefault(materialEditor, propertyMap["_RimBias"]);
                DrawDefault(materialEditor, propertyMap["_RimPower"]);
                DrawDefault(materialEditor, propertyMap["_RimIntensity"]);
                DrawKeyword(material, "_RIM_REVERSE", out _, "Rim Reverse");
                DrawKeyword(material, "_RIM_REVERSE_COLOR", out _, "Rim Reverse Color");
                DrawKeyword(material, "_RIM_MULTIPLY_ALPHA", out _, "Rim Multiply Alpha");
            }
            else
            {
                if (changed)
                {
                    SetKeyword(material, "_RIM_REVERSE", false);
                    SetKeyword(material, "_RIM_REVERSE_COLOR", false);
                    SetKeyword(material, "_RIM_MULTIPLY_ALPHA", false);
                }
            }
        }
    }
}
