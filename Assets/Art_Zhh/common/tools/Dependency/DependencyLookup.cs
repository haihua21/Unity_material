using System.IO;

using UnityEditor;

using UnityEngine;

namespace Assets.Editor.Dependency
{
    public static class DependencyLookup
    {
        [MenuItem("Assets/Find Dependencies", false, 10)]
        private static void FindDependencies()
        {
            Debug.Log("查找开始");
            var path = AssetDatabase.GetAssetPath(Selection.activeObject);
            var files = AssetDatabase.GetDependencies(path);
            foreach (var file in files)
            {
                if (file.Equals(path))
                {
                    continue; //排除自身
                }

                Debug.Log(file, AssetDatabase.LoadAssetAtPath<Object>(GetRelativeAssetsPath(file)));
            }

            Debug.Log("查找结束");
        }

        private static string GetRelativeAssetsPath(string path)
        {
            return "Assets" + Path.GetFullPath(path).Replace(Path.GetFullPath(Application.dataPath), "").Replace('\\', '/');
        }
    }
}
