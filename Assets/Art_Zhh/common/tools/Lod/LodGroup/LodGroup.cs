using SRF;
using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

using Sirenix.Utilities.Editor;

// using Unity.Entities;

using UnityEditor;

using UnityEngine;

namespace LodGroup
{
    public class LodGroup : EditorWindow
    {
        private static int checkNum;
        private static List<GameObject> problemGOs;
        private static List<string> probelmDescriptions;
        const string k_splitFlag = "_LOD_CHECK_SPLIT_FLAG_";
        Vector2 _scrollPos;

        private void OnEnable()
        {
            problemGOs = new List<GameObject>();
            probelmDescriptions = new List<string>();
            
            var guids = Selection.assetGUIDs;
            CollectProblemPrefabs(guids);
        }

        private void OnGUI()
        {
            GUILayout.BeginHorizontal();
            GUILayout.Label($"共检测{checkNum}项，找到{problemGOs.Count}个问题项");
            if (GUILayout.Button("重新检测问题项"))
            {
                string[] guids = new string[problemGOs.Count];
                for (int i = 0; i < guids.Length; i++)
                {
                    long unused;
                    AssetDatabase.TryGetGUIDAndLocalFileIdentifier(problemGOs[i], out guids[i], out unused);
                }
                
                CollectProblemPrefabs(guids);
            }
            GUILayout.EndHorizontal();
            
            _scrollPos = EditorGUILayout.BeginScrollView(_scrollPos);
            
            string[] stringSeparator = new string[] {k_splitFlag};
            for (int i = 0; i < problemGOs.Count; i++)
            {
                GUILayout.BeginVertical(GUI.skin.box);
                SirenixEditorFields.UnityObjectField(problemGOs[i], typeof(GameObject), true, null);
                string[] descriptions = probelmDescriptions[i].Split(stringSeparator, StringSplitOptions.None);
                GUI.contentColor = Color.yellow;
                for (int j = 0; j < descriptions.Length; j++)
                {
                    if (!string.IsNullOrEmpty(descriptions[j]))
                    {
                        EditorGUILayout.SelectableLabel(descriptions[j]);
                    }
                }
                GUI.contentColor = Color.white;
                GUILayout.EndVertical();
                GUILayout.Space(15);
            }

            EditorGUILayout.EndScrollView();
        }

        [MenuItem("CONTEXT/LODGroup/大", false, 1001)]
        private static void GenerateLodBig(MenuCommand menuCommand)
        {
            LODGroup lodGroup = (LODGroup)menuCommand.context;
            GenerateLodByIndex(lodGroup, 0);
        }

        [MenuItem("CONTEXT/LODGroup/中", false, 1001)]
        private static void GenerateLodMiddle(MenuCommand menuCommand)
        {
            LODGroup lodGroup = (LODGroup)menuCommand.context;
            GenerateLodByIndex(lodGroup, 1);
        }

        [MenuItem("CONTEXT/LODGroup/小", false, 1001)]
        private static void GenerateLodSmall(MenuCommand menuCommand)
        {
            LODGroup lodGroup = (LODGroup)menuCommand.context;
            GenerateLodByIndex(lodGroup, 2);
        }

        [MenuItem("Assets/LODGroup/大", false, 1001)]
        static void GenerateLodFromFolderBig()
        {
            GenerateLodFromFolder(0);
        }

        [MenuItem("Assets/LODGroup/中", false, 1001)]
        static void GenerateLodFromFolderMiddle()
        {
            GenerateLodFromFolder(1);
        }

        [MenuItem("Assets/LODGroup/小", false, 1001)]
        static void GenerateLodFromFolderSmall()
        {
            GenerateLodFromFolder(2);
        }

        [MenuItem("Assets/LODGroup/LOD检查", false, 1002)]
        private static void LODCheck()
        {
            var window = GetWindow<LodGroup>("LOD检查");
            window.Show();
        }

        static async Task<(GameObject, string)> CheckLOD(string prefabGUID)
        {
            var prefabPath = AssetDatabase.GUIDToAssetPath(prefabGUID);
            GameObject go = AssetDatabase.LoadAssetAtPath<GameObject>(prefabPath);
            
            string problems = "";
            if (go)
            {
                var lodGroups = go.GetComponentsInChildren<LODGroup>();
                if (lodGroups == null || lodGroups.Length == 0)
                {
                    //Debug.Log($"{prefabPath}没有设置LOD");
                    problems += $"{prefabPath} 没有设置LOD" + k_splitFlag;
                }
                else
                {
                    foreach (var lodGroup in lodGroups)
                    {
                        var lodTransforms = new List<Transform>();
                        CollectLODChildren(lodTransforms, lodGroup.transform);
                        var lods = lodGroup.GetLODs();
                        for (int i = 0; i < lods.Length; i++)
                        {
                            for (int j = 0; j < lods[i].renderers.Length; j++)
                            {
                                if (lods[i].renderers[j] == null)
                                {
                                    //Debug.LogError($"LOD{i}存在损坏资源，需重新设置！");
                                    problems += $"LOD{i}存在损坏资源，需重新设置！" + k_splitFlag;
                                    continue;
                                }
                                
                                lodTransforms.Remove(lods[i].renderers[j].transform);
                                
                                var sIndex = lods[i].renderers[j].name.ToLower().LastIndexOf("_lod", StringComparison.Ordinal);
                                if (sIndex == -1)
                                {
                                    //Debug.LogError($"LOD{i}中{lods[i].renderers[j].name}命名错误");
                                    problems += $"LOD{i} 中 {lods[i].renderers[j].name} 命名错误" + k_splitFlag;
                                    continue;
                                }

                                if (sIndex + 4 >= lods[i].renderers[j].name.Length)
                                {
                                    problems += $"LOD{i} 中 {lods[i].renderers[j].name} 命名错误" + k_splitFlag;
                                }
                                else
                                {
                                    //ToInt32 will convert char into ASCII
                                    string level = lods[i].renderers[j].name[sIndex + 4].ToString();
                                    int l = -1;
                                    try
                                    {
                                        l = Convert.ToInt32(level);
                                    }
                                    catch (Exception e)
                                    {
                                        //Debug.LogError(lods[i].renderers[j].name);
                                        problems += $"LOD{i} 中 {lods[i].renderers[j].name} 命名错误" + k_splitFlag;
                                    }
                                    if (l != i)
                                    {
                                        //Debug.LogError($"LOD{i}中{lods[i].renderers[j].name}命名错误");
                                        problems += $"LOD{i} 中 {lods[i].renderers[j].name} 命名错误" + k_splitFlag;
                                    }
                                }
                            }
                        }

                        foreach (var lodTransform in lodTransforms)
                        {
                            //Debug.LogError($"{lodTransform.name}未设置进LODGroup" + k_splitFlag);
                            problems += $"{lodTransform.name}未设置进LODGroup" + k_splitFlag;
                        }
                    }
                }
            }
            
            return (go, problems);
        }

        [MenuItem("CONTEXT/LODGroup/Particle LOD自动分配", false, 1001)]
        public static void AutoAssignParticleLOD(MenuCommand menuCommand)
        {
            LODGroup lodGroup = (LODGroup)menuCommand.context;
            LOD[] oriLods = lodGroup.GetLODs(); 
            GameObject obj = lodGroup.gameObject;
            
            int lodCount = 0;
            Transform[] children = obj.transform.GetComponentsInChildren<Transform>();
            LOD[] tempLods = new LOD[10];
            int[] tempCounter = new int[10];
            for (int i = 0; i < 10; i++)
            {
                tempLods[i].renderers = new Renderer[1024];
                tempCounter[i] = 0;
            }

            bool isParticleSystem = false;
            foreach (var child in children)
            {
                string name = child.name;
                if (name.Length > 5)
                {
                    string suffix = name.Substring(name.Length - 5);
                    if (suffix.ToLower().StartsWith("_lod"))
                    {
                        if (int.TryParse(suffix.Substring(suffix.Length - 1), out int level))
                        {
                            ParticleSystemRenderer r = child.GetComponent<ParticleSystemRenderer>();
                            if (r)
                            {
                                isParticleSystem = isParticleSystem || child.GetComponent<ParticleSystem>();
                                lodCount = Mathf.Max(lodCount, level + 1);
                                int index = tempCounter[level];
                                tempLods[level].renderers[index] = r;
                                tempCounter[level]++;
                            }
                        }
                    }
                }
            }

            if (lodCount > 1 && isParticleSystem)
            {
                LOD[] lods = new LOD[lodCount];
                for (int i = 0; i < lodCount; i++)
                {
                    lods[i] = tempLods[i];
                    if (lodCount == lodGroup.lodCount && i < lodGroup.lodCount)
                    {
                        lods[i].fadeTransitionWidth = oriLods[i].fadeTransitionWidth;
                        lods[i].screenRelativeTransitionHeight = oriLods[i].screenRelativeTransitionHeight;
                    }
                    else
                    {
                        lods[i].screenRelativeTransitionHeight = 1f - (i + 1f) / (lodCount + 1f);
                    }
                }
                lodGroup.SetLODs(lods);
            }
        }

        async void CollectProblemPrefabs(string[] guids)
        {
            problemGOs.Clear();
            probelmDescriptions.Clear();
            List<string> guidList = new List<string>();
            var tasks = new List<Task<(GameObject, string)>>();
            foreach (var guid in guids)
            {
                var path = AssetDatabase.GUIDToAssetPath(guid);
                if (!string.IsNullOrEmpty(path) && path.EndsWith(".prefab"))
                {
                    guidList.Add(guid);
                }
                else
                {
                    var prefabGUIDs = AssetDatabase.FindAssets("t:Prefab", new[] {path});
                    guidList.AddRange(prefabGUIDs.ToList());
                }
            }
            for (var i = 0; i < guidList.Count; i++)
            {
                tasks.Add(CheckLOD(guidList[i]));
            }
            checkNum = tasks.Count;

            var result = await Task.WhenAll(tasks);
            
            for (int i = 0; i < result.Length; i++)
            {
                if (!string.IsNullOrEmpty(result[i].Item2))
                {
                    problemGOs.Add(result[i].Item1);
                    probelmDescriptions.Add(result[i].Item2);
                }
            }
        }
        
        private static void CollectLODChildren(List<Transform> collected, Transform target)
        {
            var indexOfLOD = target.name.ToLower().IndexOf("_lod", StringComparison.Ordinal);
            if (indexOfLOD + 4 < target.name.Length)
            {
                if (indexOfLOD != -1 && int.TryParse(target.name[indexOfLOD + 4].ToString(), out var level) && (level >= 0 && level <= 2))
                {
                    collected.Add(target);
                }
            }

            foreach (Transform child in target)
            {
                CollectLODChildren(collected, child);
            }
        }

        private static void GenerateLodFromFolder(int index)
        {
            var guids = Selection.assetGUIDs;
            var paths = new List<string>();
            for (var i = 0; i < guids.Length; i++)
            {
                var path = AssetDatabase.GUIDToAssetPath(guids[i]);
                if (!string.IsNullOrEmpty(path))
                {
                    paths.Add(path);
                }
            }

            for (var i = 0; i < paths.Count; i++)
            {
                var path = paths[i];
                if (!string.IsNullOrEmpty(path))
                {
                    if (!Path.HasExtension(path)) //文件夹
                    {
                        var prefabGUIDs = AssetDatabase.FindAssets("t:Prefab", new[] {path});
                        for (var j = 0; j < prefabGUIDs.Length; j++)
                        {
                            var assetPath = AssetDatabase.GUIDToAssetPath(prefabGUIDs[j]);
                            var lod = Validate(assetPath);
                            if (lod)
                            {
                                GenerateLodByIndex(lod, index);
                            }
                        }
                    }
                    else if (path.ToLower().EndsWith(".prefab"))
                    {
                        var lod = Validate(path);
                        if (lod)
                        {
                            GenerateLodByIndex(lod, index);
                        }
                    }
                }
            }

            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
        }

        private static void GenerateLodByIndex(LODGroup lodGroup, int index)
        {
            LOD[] lods = lodGroup.GetLODs();
            LOD[] newLods = new LOD[lods.Length];
            var lodData = LodGroupData.m_ins.m_lodData[index];
            if (lodData == null) return;
            for (var i = 0; i < lods.Length; i++)
            {
                var lod = lods[i];
                newLods[i].fadeTransitionWidth = lod.fadeTransitionWidth;
                newLods[i].renderers = lod.renderers;
                newLods[i].screenRelativeTransitionHeight = lodData.GetLodValue(i) / 100;
            }

            lodGroup.SetLODs(newLods);

            var distanceLOD = lodGroup.GetComponent<DistanceLod>();
            if (distanceLOD)
            {
                float[] targetDistances = new float[lods.Length];
                for (var i = 0; i < lods.Length; i++)
                {
                    var lod = lods[i];
                    targetDistances[i] = lodData.GetDistanceLodValue(i);
                }
                distanceLOD.SetDistance(targetDistances);
            }
        }

        private static LODGroup Validate(string path)
        {
            var obj = AssetDatabase.LoadAssetAtPath<GameObject>(path);

            //var view = obj.transform.Find("view");
            if (obj)
            {
                var lod = obj.GetComponentInChildren<LODGroup>();
                if (lod)
                {
                    var isVariantPrefab = PrefabUtility.GetCorrespondingObjectFromSource(lod.gameObject);
                    if (!isVariantPrefab)
                    {
                        return lod;
                    }
                }
            }

            return null;
        }
    }
}
