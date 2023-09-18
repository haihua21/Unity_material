namespace AssetDiagnose
{
    public class AssetDependenciesWnd : AssetDiagnoseResultWnd
    {
        public static bool m_isOpened;

        protected override string[] m_title
        {
            get
            {
                if (_title == null)
                {
                    _title = new[] {"名称", "被引用的资源", "隶属"};
                }

                return _title;
            }
        }

        protected override void Init(AssetDiagnoseSettingData settingData)
        {
            base.Init(settingData);

            CollectDependenciesData(settingData.m_refPath, settingData.m_resPath);
            m_isOpened = true;
        }

        private void OnDestroy()
        {
            m_isOpened = false;
        }
    }

    public class AssetDependenciesWnd2 : AssetDiagnoseResultWnd
    {
        protected override string[] m_title
        {
            get
            {
                if (_title == null)
                {
                    _title = new[] {"名称", "被引用的资源", "隶属"};
                }

                return _title;
            }
        }

        protected override void Init(AssetDiagnoseSettingData settingData)
        {
            base.Init(settingData);

            CollectDependenciesData(settingData.m_refPath, settingData.m_resPath);
        }
    }
}
