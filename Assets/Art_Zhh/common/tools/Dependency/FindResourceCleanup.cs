using System.Collections.Generic;
using System.IO;

using Sirenix.Utilities.Editor;

using UnityEditor;

using UnityEngine;

namespace Assets.Editor.Dependency
{
    public class DependAnalysis : EditorWindow
    {
        private static readonly List<TargetReferenceInfo> TargetReferenceInfos = new List<TargetReferenceInfo>();

        // private readonly string[] _withoutExtensions = {".prefab", ".unity", ".mat", ".asset", ".controller"};

        private string _pathCus = "/PG/art_assets";
        private Vector2 _scrollPos;

        private void OnDestroy()
        {
            TargetReferenceInfos.Clear();
        }

        private void OnGUI()
        {
            if (GUILayout.Button("重建数据缓存...(大概耗时5分钟)"))
            {
                BuildReferencesMap();
            }

            GUILayout.Space(15);

            EditorGUILayout.BeginHorizontal();
            GUILayout.Label("查找路径:  Assets");
            _pathCus = EditorGUILayout.TextField(_pathCus);

            EditorGUILayout.EndHorizontal();

            _scrollPos = EditorGUILayout.BeginScrollView(_scrollPos);

            foreach (var targetReferenceInfo in TargetReferenceInfos)
            {
                if (targetReferenceInfo.markDeleted)
                {
                    continue;
                }

                var objName = Path.GetFileName(AssetDatabase.GetAssetPath(targetReferenceInfo.target));
                var info = targetReferenceInfo.references.Count == 0
                               ? $"<color=yellow>{objName}【{targetReferenceInfo.references.Count}】</color>"
                               : $"{objName}【{targetReferenceInfo.references.Count}】";
                targetReferenceInfo.expend = SirenixEditorGUI.Foldout(targetReferenceInfo.expend, info);
                if (targetReferenceInfo.expend)
                {
                    if (targetReferenceInfo.references.Count > 0)
                    {
                        foreach (var objReference in targetReferenceInfo.references)
                        {
                            EditorGUILayout.BeginHorizontal();
                            GUILayout.Space(15);
                            SirenixEditorFields.UnityObjectField(objReference, typeof(Object), true, null);
                            EditorGUILayout.EndHorizontal();
                        }
                    }
                    else
                    {
                        EditorGUILayout.BeginHorizontal();
                        GUILayout.Space(15);
                        SirenixEditorFields.UnityObjectField(targetReferenceInfo.target, typeof(Object), true, null);
                        EditorGUILayout.EndHorizontal();

                        EditorGUILayout.BeginHorizontal();
                        EditorGUILayout.LabelField("【无引用、是否删除】");
                        GUI.color = Color.red;
                        if (GUILayout.Button("删  除", GUILayout.Width(150), GUILayout.Height(20)))
                        {
                            var assetPath = AssetDatabase.GetAssetPath(targetReferenceInfo.target);

                            //  DestroyImmediate(obj,true);
                            File.Delete(assetPath);
                            File.Delete(assetPath + ".meta");
                            Debug.Log(assetPath);

                            targetReferenceInfo.markDeleted = true;
                        }

                        EditorGUILayout.EndHorizontal();
                        GUI.color = Color.white;
                    }
                }
            }

            EditorGUILayout.EndScrollView();
        }

        private static void BuildReferencesMap()
        {
            AssetsReferenceMapData.instance.assetsReferenceMap.Clear();

            var files = AssetDatabase.GetAllAssetPaths();
            var startIndex = 0;
            EditorApplication.update = delegate
            {
                var file = files[startIndex];

                var isCancel = EditorUtility.DisplayCancelableProgressBar("引用数据生成中", file, startIndex / (float)files.Length);

                var dependencies = AssetDatabase.GetDependencies(file);
                foreach (var dependence in dependencies)
                {
                    if (dependence.Equals(file))
                    {
                        continue; //排除自身
                    }

                    if (AssetsReferenceMapData.instance.assetsReferenceMap.TryGetValue(dependence, out var assetDependencies))
                    {
                        assetDependencies.Add(file);
                    }
                    else
                    {
                        assetDependencies = new HashSet<string> {file};
                        AssetsReferenceMapData.instance.assetsReferenceMap.Add(dependence, assetDependencies);
                    }
                }

                startIndex++;
                if (isCancel || startIndex >= files.Length)
                {
                    AssetsReferenceMapData.instance.Save();
                    EditorUtility.ClearProgressBar();
                    EditorApplication.update = null;
                    startIndex = 0;
                }
            };
        }

        private void Init()
        {
            EditorStyles.foldout.richText = true;
            foreach (var targetReferenceInfo in TargetReferenceInfos)
            {
                GetBeDepend(targetReferenceInfo);
            }
        }

        /// <summary>
        ///     查找所有引用目标资源的物体
        /// </summary>
        /// <param name="targetReferenceInfo">目标资源</param>
        private void GetBeDepend(TargetReferenceInfo targetReferenceInfo)
        {
            var path = AssetDatabase.GetAssetPath(targetReferenceInfo.target);
            if (string.IsNullOrEmpty(path))
            {
                return;
            }

            if (AssetsReferenceMapData.instance.assetsReferenceMap.TryGetValue(path, out var assetSet))
            {
                foreach (var assetPath in assetSet)
                {
                    targetReferenceInfo.references.Add(AssetDatabase.LoadAssetAtPath<Object>(assetPath));
                }
            }
        }

        [MenuItem("美术/查找被引用 ")]
        [MenuItem("Assets/查找被引用 &f", false, 51)]
        private static void FindReferences()
        {
            TargetReferenceInfos.Clear();
            var selections = Selection.GetFiltered<Object>(SelectionMode.Assets);
            if (selections != null)
            {
                foreach (var selection in selections)
                {
                    TargetReferenceInfos.Add(new TargetReferenceInfo(selection));
                }
            }

            var window = GetWindow<DependAnalysis>("被引用依赖分析");
            window.Init();
            window.Show();
        }

        private class TargetReferenceInfo
        {
            public readonly List<Object> references = new List<Object>();

            public readonly Object target;
            public bool expend;
            public bool markDeleted;

            public TargetReferenceInfo(Object obj)
            {
                target = obj;
            }
        }
    }
}
