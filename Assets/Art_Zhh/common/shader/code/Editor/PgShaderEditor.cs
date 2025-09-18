using System.Collections.Generic;

using CustomShaderEditor.Drawer;

using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor
{
    public class PgShaderEditor : ShaderGUI
    {
        private static Dictionary<string, IShaderPropertyDrawer> _propertyDrawers;

        private static void InitializeDrawers()
        {
            _propertyDrawers = new Dictionary<string, IShaderPropertyDrawer>();

            // base map
            AddDrawer(_propertyDrawers, new BaseMapPropertyDrawer("_MainTex"));

            // mask map
            AddDrawer(_propertyDrawers, new MaskMapPropertyDrawer("_MaskMap"));

            // normal map
            AddDrawer(_propertyDrawers, new NormalMapPropertyDrawer("_NormalMap"));
            
            // matcap map
            AddDrawer(_propertyDrawers, new MatcapMapPropertyDrawer("_MatcapMap"));

            // rgb distort map
            AddDrawer(_propertyDrawers, new RgbDistortPropertyDrawer("_RgbDistortMap"));
            AddDrawer(_propertyDrawers, new DistortPropertyDrawer("_DistortMap"));
            AddDrawer(_propertyDrawers, new DissolvePropertyDrawer("_DissolveMap"));
            AddDrawer(_propertyDrawers, new SmokePropertyDrawer("_SmokeLightDirOffset"));
            AddDrawer(_propertyDrawers, new ExtrudePropertyDrawer("_ExtrudeMode"));
            AddDrawer(_propertyDrawers, new RingMaskPropertyDrawer("_RingInnerRadius"));

            // rim
            AddDrawer(_propertyDrawers, new RimPropertyDrawer("_RimColor"));
            
            // custom data
            AddDrawer(_propertyDrawers, new CustomDataPropertyDrawer("_CustomData1"));

            // render state
            AddDrawer(_propertyDrawers, new RenderStatePropertyDrawer("_RenderingType"));
            
            // keywords
            AddDrawer(_propertyDrawers, new KeywordPropertyDrawer("_USE_RED_CHANNEL"));
            AddDrawer(_propertyDrawers, new KeywordPropertyDrawer("_USE_VERTEX_COLOR"));
            AddDrawer(_propertyDrawers, new KeywordPropertyDrawer("_DISTORT_ENABLE"));
            AddDrawer(_propertyDrawers, new KeywordPropertyDrawer("_POLAR_UV_REMAP_ENABLE"));
        }

        private static void AddDrawer(Dictionary<string, IShaderPropertyDrawer> map, IShaderPropertyDrawer drawer)
        {
            map.Add(drawer.propertyName, drawer);
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            if (_propertyDrawers == null)
            {
                InitializeDrawers();
            }

            if (_propertyDrawers == null) return;

            var propertyMap = new Dictionary<string, MaterialProperty>();
            foreach (var property in properties)
            {
                propertyMap.Add(property.name, property);
            }

            var material = materialEditor.target as Material;

            foreach (var property in properties)
            {
                if (_propertyDrawers.TryGetValue(property.name, out var drawer))
                {
                    drawer.Draw(materialEditor, material, propertyMap);
                }
            }

            materialEditor.RenderQueueField();
            materialEditor.EnableInstancingField();
        }
    }
}
