using System;
using System.Collections.Generic;

using UnityEditor;

using UnityEngine;

namespace LodGroup
{
    public class LodGroupData : ScriptableObject
    {
        public List<LodData> m_lodData;

        private static LodGroupData _ins;

        public static LodGroupData m_ins
        {
            get
            {
                if (_ins == null)
                {
                    _ins = AssetDatabase.LoadAssetAtPath<LodGroupData>(Constants.m_settingDataPath);
                }

                if (_ins == null)
                {
                    _ins = CreateInstance<LodGroupData>();
                    AssetDatabase.CreateAsset(_ins, Constants.m_settingDataPath);
                    AssetDatabase.Refresh();
                }

                return _ins;
            }
        }
    }

    [Serializable]
    public class LodData
    {
        public string m_lodType = "";
        public int m_load1 = 60;
        public int m_load2 = 10;
        public int m_culled = 4;
        public int m_dis_lod1 = 20;
        public int m_dis_lod2 = 30;
        public int m_dis_culled = 40;

        public float GetLodValue(int index)
        {
            var val = 0;
            switch (index)
            {
                case 0:
                    val = m_load1;
                    break;
                case 1:
                    val = m_load2;
                    break;
                case 2:
                    val = m_culled;
                    break;
                default: 
                    val = 0;
                    break;
            }
            return val;
        }

        public float GetDistanceLodValue(int index)
        {
            var val = 0;
            switch (index)
            {
                case 0:
                    val = m_dis_lod1;
                    break;
                case 1:
                    val = m_dis_lod2;
                    break;
                case 2:
                    val = m_dis_culled;
                    break;
                default: 
                    val = 0;
                    break;
            }
            return val;
        }
    }
}
