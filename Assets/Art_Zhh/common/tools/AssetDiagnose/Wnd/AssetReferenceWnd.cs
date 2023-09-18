using UnityEditor;

using UnityEngine;

namespace AssetDiagnose
{
    public class AssetReferenceWnd : AssetDiagnoseResultWnd
    {
        public static bool m_isOpened = false;

        protected override void Init(AssetDiagnoseSettingData settingData)
        {
            base.Init(settingData);

            CollectReferenceData(settingData.m_refPath, settingData.m_resPath);
            m_isOpened = true;
        }

        void OnDestroy()
        {
            m_isOpened = false;
        }
    }

    public class AssetReferenceWnd2 : AssetDiagnoseResultWnd
    {
        protected override void Init(AssetDiagnoseSettingData settingData)
        {
            base.Init(settingData);

            CollectReferenceData(settingData.m_refPath, settingData.m_resPath);
        }
    }
}
