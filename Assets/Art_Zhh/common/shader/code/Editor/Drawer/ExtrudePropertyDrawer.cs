using System.Collections.Generic;

using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor.Drawer
{
    public class ExtrudePropertyDrawer : IShaderPropertyDrawer
    {
        public ExtrudePropertyDrawer(string propertyName)
            : base(propertyName)
        {
        }

        public override void Draw(MaterialEditor materialEditor, Material material, Dictionary<string, MaterialProperty> propertyMap)
        {
            if (DrawToggleKeyword(material, "_EXTRUDE_ENABLE", "Extrude Enable", out var toggleChanged))
            {
                var mode = (ExtrudeMode)(int)DrawEnum(materialEditor, propertyMap["_ExtrudeMode"], typeof(ExtrudeMode), out var modeChanged);
                if (modeChanged)
                {
                    if (mode == ExtrudeMode.NormalOS)
                    {
                        SetKeyword(material, "_EXTRUDE_VS_NORMAL", false);
                        SetKeyword(material, "_EXTRUDE_OS_NORMAL", true);
                    }
                    else
                    {
                        SetKeyword(material, "_EXTRUDE_VS_NORMAL", true);
                        SetKeyword(material, "_EXTRUDE_OS_NORMAL", false);
                    }
                }

                DrawDefault(materialEditor, propertyMap["_ExtrudeAmount"]);
            }
            else
            {
                if (toggleChanged)
                {
                    SetKeyword(material, "_EXTRUDE_VS_NORMAL", false);
                    SetKeyword(material, "_EXTRUDE_OS_NORMAL", false);
                }
            }
        }
    }
}
