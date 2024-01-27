using System.Collections.Generic;

using Sirenix.OdinInspector;

using UnityEditor;

namespace Assets.Editor.Dependency
{
    public class AssetsReferenceMapData : SerializedScriptableObject
    {
        private const string AssetPath = "Assets/Art_Zhh/common/tools/Dependency/AssetsReferenceMapData.asset";

        private static AssetsReferenceMapData _instance;

        public readonly Dictionary<string, HashSet<string>> assetsReferenceMap = new Dictionary<string, HashSet<string>>();

        public static AssetsReferenceMapData instance
        {
            get
            {
                if (_instance != null)
                {
                    return _instance;
                }

                var tmp = AssetDatabase.LoadAssetAtPath<AssetsReferenceMapData>(AssetPath);
                if (tmp != null)
                {
                    _instance = tmp;
                    return _instance;
                }

                _instance = CreateInstance<AssetsReferenceMapData>();
                AssetDatabase.CreateAsset(_instance, AssetPath);
                AssetDatabase.SaveAssets();
                AssetDatabase.Refresh();
                return _instance;
            }
        }

        public void Save()
        {
            EditorUtility.SetDirty(this);
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
        }
    }
}
