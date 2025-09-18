using System;

using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor
{
    public class CustomEnumDrawer : MaterialPropertyDrawer
    {
        private Type enumType;

        public CustomEnumDrawer(string typeName)
        {
            enumType = Type.GetType(typeName);
        }

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            if (enumType == null)
            {
                base.OnGUI(position, prop, label, editor);
            }
            else
            {
                prop.floatValue = HopeGUIUtils.DrawEnum(enumType, position, prop.floatValue, label);
            }
        }
    }
}
