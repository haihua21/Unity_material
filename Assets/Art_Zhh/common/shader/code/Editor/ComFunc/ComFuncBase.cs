using UnityEditor;

using UnityEngine;

namespace CustomShaderEditor
{
    public class ComFuncBase
    {
        protected MaterialEditor m_materialEditor;
        protected Material m_material;
        protected BaseShaderEditor m_shaderGUI;

        public virtual bool m_isCustomToolbar { get { return false; } }

        public ComFuncBase(BaseShaderEditor shaderGUI, Material material, MaterialEditor materialEditor)
        {
            m_materialEditor = materialEditor;
            m_material = material;
            m_shaderGUI = shaderGUI;
        }

        protected MaterialProperty WantFindProperty(Material material, string key, MaterialProperty[] properties)
        {
            if (material.HasProperty(key))
            {
                return m_shaderGUI.FindPropertyEx(key, properties);
            }

            return null;
        }

        public virtual void OnFindProperties(MaterialProperty[] properties)
        {
        }

        public virtual void OnDrawProperties(Material material, MaterialProperty[] properties)
        {
        }

        public virtual void OnDrawAdvance(Material material, MaterialProperty[] properties)
        {
        }
    }
}
