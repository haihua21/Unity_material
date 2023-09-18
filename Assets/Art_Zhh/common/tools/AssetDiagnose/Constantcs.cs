using UnityEditor;

using UnityEngine;

namespace AssetDiagnose
{
    public class Constant
    {
        private static string m_assetDiagnoseRootName = "AssetDiagnoseRoot";

        private static string _root;

        public static string m_root
        {
            get
            {
                if (string.IsNullOrEmpty(_root))
                {
                    string[] rootGUIDs = AssetDatabase.FindAssets(m_assetDiagnoseRootName);
                    if (rootGUIDs.Length == 0)
                    {
                        Debug.LogError($"[AssetDiagnose] can not find the root");
                        return _root;
                    }

                    _root = AssetDatabase.GUIDToAssetPath(rootGUIDs[0]);

                    int lastIndex = _root.LastIndexOf("/");
                    _root = _root.Substring(0, lastIndex);
                }

                return _root;
            }
        }

        public static string m_dataDir = m_root + "/Data";

        public static string m_settingDataName = "AssetDiagnoseSetting";
        public static string m_settingDataPath = m_dataDir + $"/{m_settingDataName}.asset";

        public static string m_progressTitle = "正在处理";
        public static string m_errorTitle = "错误信息";
        public static string m_continueStr = "继续执行";
        public static string m_cancelStr = "取消";
        public static string m_sureStr = "确定";
        public static string m_progressFinish = "处理结束";
        public static string m_deleteFile = "正在删除文件...";
    }
}
