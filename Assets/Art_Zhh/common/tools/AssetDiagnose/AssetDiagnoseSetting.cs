using System;
using System.Collections.Generic;

using UnityEditor;

using UnityEngine;

namespace AssetDiagnose
{
    [Serializable]
    public class AssetDiagnoseSettingData
    {
        [SerializeField]
        private string _remark = "";

        [SerializeField]
        private string _refPath = "";

        [SerializeField]
        private string _resPath = "";

        [SerializeField, HideInInspector]
        private AssetDiagnoseSetting m_setting;

        public AssetDiagnoseSettingData(AssetDiagnoseSetting setting)
        {
            m_setting = setting;
        }

        public void Init(AssetDiagnoseSetting setting)
        {
            m_setting = setting;
        }

        public string m_remark
        {
            get => _remark;
            set
            {
                if (_remark != value)
                {
                    m_setting.RecordValueChange(() => { _remark = value; });
                }
            }
        }

        public string m_refPath
        {
            get => _refPath;
            set
            {
                if (_refPath != value)
                {
                    _refPath = value;
                }
            }
        }

        public string m_resPath
        {
            get => _resPath;
            set
            {
                if (_resPath != value)
                {
                    _resPath = value;
                }
            }
        }
    }

    public class AssetDiagnoseSetting : ScriptableObject
    {
        private CustomUndo m_customUndo = new CustomUndo("AssetDiagnoseSetting");
        public List<AssetDiagnoseSettingData> m_settingDataList = new List<AssetDiagnoseSettingData>();

        private static AssetDiagnoseSetting _ins;

        public static AssetDiagnoseSetting m_ins
        {
            get
            {
                if (_ins == null)
                {
                    var tmp = AssetDatabase.LoadAssetAtPath<AssetDiagnoseSetting>(Constant.m_settingDataPath);
                    if (tmp != null)
                    {
                        _ins = Instantiate(tmp);
                    }
                }

                if (_ins == null)
                {
                    _ins = CreateInstance<AssetDiagnoseSetting>();
                    AssetDatabase.CreateAsset(_ins, Constant.m_settingDataPath);
                    AssetDatabase.Refresh();
                }

                return _ins;
            }
        }

        public static void ClearIns()
        {
            _ins = null;
        }

        internal void RecordValueChange(CustomUndo.Callback callback)
        {
            m_customUndo.RecordObject(this, callback);
            m_customUndo.Flush();
        }

        public void CreateNewSetting()
        {
            RecordValueChange(() =>
            {
                AssetDiagnoseSettingData data = new AssetDiagnoseSettingData(this);
                m_settingDataList.Add(data);
            });
        }

        public void DelSetting(int index)
        {
            if (index < m_settingDataList.Count)
            {
                RecordValueChange(() => { m_settingDataList.RemoveAt(index); });
            }
        }

        public void Init()
        {
            int count = m_settingDataList.Count;
            for (int i = 0; i < count; i++)
            {
                m_settingDataList[i].Init(this);
            }

            m_customUndo = new CustomUndo("AssetDiagnoseSetting");
        }
    }
}
