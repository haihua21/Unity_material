using System;
using System.Collections.Generic;
using System.IO;

using UnityEditor;

using UnityEngine;

using Object = UnityEngine.Object;

namespace AssetDiagnose
{
    public class AssetInfoBase : IAssetInfoBase, IComparable<AssetInfoBase>
    {
        private string _targetAssetPath;
        private Object _target;
        public List<Object> _assetPathList = new List<Object>();

        private string _name;
        private bool _fold;

        private Texture _icon;

        public string m_targetAssetPath { get => _targetAssetPath; }

        public Object m_target { get => _target; }

        public List<Object> m_assetPathList { get => _assetPathList; }

        public string m_name { get => _name; }

        public bool m_fold { get => _fold; set => _fold = value; }

        public Texture m_icon
        {
            get
            {
                if (_icon == null)
                {
                    _icon = AssetDatabase.GetCachedIcon(m_targetAssetPath);
                }

                return _icon;
            }
        }

        public AssetInfoBase(string targetAssetPath, List<string> assetPathList)
        {
            _targetAssetPath = targetAssetPath;

            _name = Path.GetFileNameWithoutExtension(m_targetAssetPath);
            _target = AssetDatabase.LoadAssetAtPath<Object>(m_targetAssetPath);

            m_assetPathList.Clear();
            int count = assetPathList.Count;
            for (int i = 0; i < count; i++)
            {
                string assetPath = AssetDatabase.GUIDToAssetPath(assetPathList[i]);
                m_assetPathList.Add(AssetDatabase.LoadAssetAtPath<Object>(assetPath));
            }
        }

        public void AddAssetByPath(string assetPath)
        {
            m_assetPathList.Add(AssetDatabase.LoadAssetAtPath<Object>(assetPath));
        }

        public int CompareTo(AssetInfoBase other)
        {
            return m_name.CompareTo(other.m_name);
        }
    }
}
