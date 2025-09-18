using System.Collections.Generic;

using UnityEditor;

using UnityEngine;
using UnityEngine.Rendering;

namespace CustomShaderEditor.Drawer
{
    public class RenderStatePropertyDrawer : IShaderPropertyDrawer
    {
        private static bool _renderState;

        public RenderStatePropertyDrawer(string propertyName)
            : base(propertyName)
        {
        }

        public override void Draw(MaterialEditor materialEditor, Material material, Dictionary<string, MaterialProperty> propertyMap)
        {
            _renderState = GUILayout.Toggle(_renderState, "Render State", EditorStyles.toolbarButton);
            if (_renderState)
            {
                DrawOpaqueTransparent(materialEditor, material, propertyMap);
                DrawBlendMode(materialEditor, material, propertyMap);

                DrawEnum(materialEditor, propertyMap["_CullFace"], typeof(RenderFace), out _);
                DrawToggle(materialEditor, propertyMap["_ZWrite"], out _);
                DrawEnum(materialEditor, propertyMap["_ZTest"], typeof(CompareFunction), out _);
                DrawStencil(materialEditor, material, propertyMap);
            }
        }

        private void DrawOpaqueTransparent(MaterialEditor materialEditor, Material material, Dictionary<string, MaterialProperty> propertyMap)
        {
            var propRenderingType = propertyMap[propertyName];
            var oldType = (RenderingType)propRenderingType.floatValue;
            var newType = (RenderingType)DrawEnum(materialEditor, propRenderingType, typeof(RenderingType), out var changed);
            if (changed && oldType != newType)
            {
                var propZWrite = propertyMap["_ZWrite"];
                switch (newType)
                {
                    case RenderingType.Opaque:
                        OnCustomBlendModeChange(CustomBlendMode.Opaque, propertyMap);
                        propZWrite.floatValue = 1;
                        material.renderQueue = (int)RenderQueue.Geometry;
                        break;
                    case RenderingType.Transparent:
                        OnCustomBlendModeChange(CustomBlendMode.AlphaBlending, propertyMap);
                        propZWrite.floatValue = 0;
                        material.renderQueue = (int)RenderQueue.Transparent;
                        break;
                }
            }
        }

        private void DrawBlendMode(MaterialEditor materialEditor, Material material, Dictionary<string, MaterialProperty> propertyMap)
        {
            var oldCustomBlend = GetCustomBlendMode(propertyMap);
            EditorGUI.BeginChangeCheck();
            var newCustomBlend = (CustomBlendMode)EditorGUILayout.EnumPopup("Blend Mode", oldCustomBlend);
            if (EditorGUI.EndChangeCheck())
            {
                if (newCustomBlend != CustomBlendMode.Custom && oldCustomBlend != newCustomBlend)
                {
                    OnCustomBlendModeChange(newCustomBlend, propertyMap);
                }
            }

            var propSrcBlend = propertyMap["_SrcBlend"];
            var propDstBlend = propertyMap["_DstBlend"];
            DrawEnum(materialEditor, propSrcBlend, typeof(BlendMode), out _);
            DrawEnum(materialEditor, propDstBlend, typeof(BlendMode), out _);
        }

        private static CustomBlendMode GetCustomBlendMode(Dictionary<string, MaterialProperty> propertyMap)
        {
            var propSrcBlend = propertyMap["_SrcBlend"];
            var propDstBlend = propertyMap["_DstBlend"];
            var srcBlend = (BlendMode)(int)propSrcBlend.floatValue;
            var dstBlend = (BlendMode)(int)propDstBlend.floatValue;

            if (srcBlend == BlendMode.One && dstBlend == BlendMode.Zero) return CustomBlendMode.Opaque;
            if (srcBlend == BlendMode.SrcAlpha && dstBlend == BlendMode.OneMinusSrcAlpha) return CustomBlendMode.AlphaBlending;
            if (srcBlend == BlendMode.SrcAlpha && dstBlend == BlendMode.One) return CustomBlendMode.WZ_Additive;
            if (srcBlend == BlendMode.One && dstBlend == BlendMode.One) return CustomBlendMode.Additive;
            if (srcBlend == BlendMode.OneMinusDstColor && dstBlend == BlendMode.One) return CustomBlendMode.SoftAdditive;
            if (srcBlend == BlendMode.DstColor && dstBlend == BlendMode.Zero) return CustomBlendMode.Multiplicative;
            if (srcBlend == BlendMode.DstColor && dstBlend == BlendMode.SrcColor) return CustomBlendMode.Two_x_Multiplicative;

            return CustomBlendMode.Custom;
        }

        private void OnCustomBlendModeChange(CustomBlendMode mode, Dictionary<string, MaterialProperty> propertyMap)
        {
            var propSrcBlend = propertyMap["_SrcBlend"];
            var propDstBlend = propertyMap["_DstBlend"];

            switch (mode)
            {
                case CustomBlendMode.Opaque:
                    propSrcBlend.floatValue = (float)BlendMode.One;
                    propDstBlend.floatValue = (float)BlendMode.Zero;
                    break;
                case CustomBlendMode.AlphaBlending:
                    propSrcBlend.floatValue = (float)BlendMode.SrcAlpha;
                    propDstBlend.floatValue = (float)BlendMode.OneMinusSrcAlpha;
                    break;
                case CustomBlendMode.WZ_Additive:
                    propSrcBlend.floatValue = (float)BlendMode.SrcAlpha;
                    propDstBlend.floatValue = (float)BlendMode.One;
                    break;
                case CustomBlendMode.Additive:
                    propSrcBlend.floatValue = (float)BlendMode.One;
                    propDstBlend.floatValue = (float)BlendMode.One;
                    break;
                case CustomBlendMode.SoftAdditive:
                    propSrcBlend.floatValue = (float)BlendMode.OneMinusDstColor;
                    propDstBlend.floatValue = (float)BlendMode.One;
                    break;
                case CustomBlendMode.Multiplicative:
                    propSrcBlend.floatValue = (float)BlendMode.DstColor;
                    propDstBlend.floatValue = (float)BlendMode.Zero;
                    break;
                case CustomBlendMode.Two_x_Multiplicative:
                    propSrcBlend.floatValue = (float)BlendMode.DstColor;
                    propDstBlend.floatValue = (float)BlendMode.SrcColor;
                    break;
            }
        }

        private void DrawStencil(MaterialEditor materialEditor, Material material, Dictionary<string, MaterialProperty> propertyMap)
        {
            if (DrawToggle(materialEditor, propertyMap["_StencilEnable"], out var changed))
            {
                DrawDefault(materialEditor, propertyMap["_StencilID"]);
                DrawEnum(materialEditor, propertyMap["_StencilComp"], typeof(CompareFunction), out _);
                DrawEnum(materialEditor, propertyMap["_StencilOp"], typeof(StencilOp), out _);
                DrawDefault(materialEditor, propertyMap["_StencilWriteMask"]);
                DrawDefault(materialEditor, propertyMap["_StencilReadMask"]);
            }
            else
            {
                if (changed)
                {
                    propertyMap["_StencilID"].floatValue = 0;
                    propertyMap["_StencilComp"].floatValue = (float)CompareFunction.Disabled;
                    propertyMap["_StencilOp"].floatValue = (float)StencilOp.Keep;
                    propertyMap["_StencilWriteMask"].floatValue = 255;
                    propertyMap["_StencilReadMask"].floatValue = 255;
                }
            }
        }
    }
}
