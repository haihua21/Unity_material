using UnityEditor;

using UnityEngine;

namespace LodGroup
{
    public class Constants
    {
        private static string m_rootName = "LodGroupRoot";

        private static string _root;

        public static string m_root
        {
            get
            {
                if (string.IsNullOrEmpty(_root))
                {
                    string[] rootGUIDs = AssetDatabase.FindAssets(m_rootName);
                    if (rootGUIDs.Length == 0)
                    {
                        Debug.LogError($"[VFXGearGenerator] can not find the root");
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

        public static string m_settingDataName = "LodGroup";
        public static string m_settingDataPath = m_dataDir + $"/{m_settingDataName}.asset";
    }
}
