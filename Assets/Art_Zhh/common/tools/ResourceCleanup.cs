using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;
using Object = UnityEngine.Object;

namespace S 
{
    public class DependAnalysis : EditorWindow
    {
        private static Object[] targetObjects;
        private bool[] foldoutArr;
        private Object[][] beDependArr;
        private static int targetCount;
        private Vector2 scrollPos;
        string[] withoutExtensions = new string[]{".prefab",".unity",".mat",".asset",".controller"};
        
      
        [MenuItem("美术/查找被引用 ")]    
        [MenuItem("Assets/查找被引用 &f", false, 51)]
        static void FindReferences()
        {               
            targetObjects=Selection.GetFiltered<Object>(SelectionMode.Assets);
            targetCount=targetObjects == null ? 0 : targetObjects.Length;
            if (targetCount == 0) return;
            DependAnalysis window = GetWindow<DependAnalysis>("依赖分析");
            window.Init();
            window.Show();
        }

        void Init()
        {
            beDependArr=new Object[targetCount][];
            foldoutArr=new bool[targetCount];
            EditorStyles.foldout.richText = true;
            for (int i = 0; i < targetCount; i++)beDependArr[i] = GetBeDepend(targetObjects[i]);
        }

        private void OnGUI()
        {
            if (beDependArr.Length != targetCount) return;
            scrollPos=EditorGUILayout.BeginScrollView(scrollPos);
            Object[] objArr;
            int count;
            string objName;
            for (int i = 0; i < targetCount; i++)
            {
                objArr = beDependArr[i];
                count = objArr == null ? 0 : objArr.Length;
                objName = Path.GetFileName(AssetDatabase.GetAssetPath(targetObjects[i]));
                string info = count == 0
                    ? $"<color=yellow>{objName}【{count}】</color>"
                    : $"{objName}【{count}】";
                foldoutArr[i] = EditorGUILayout.Foldout(foldoutArr[i], info);
                if (foldoutArr[i])
                {
                    if (count>0)
                    {
                        foreach (var obj in objArr)
                        {
                            EditorGUILayout.BeginHorizontal();
                            GUILayout.Space(15);
                            EditorGUILayout.ObjectField(obj,typeof(Object));
                            EditorGUILayout.EndHorizontal();
                        }
                    }
                    else
                    {
                        EditorGUILayout.BeginHorizontal();
                        GUILayout.Space(15);
                        EditorGUILayout.LabelField("【Null】");
                        EditorGUILayout.EndHorizontal();
                    }
                }
            }
            EditorGUILayout.EndScrollView();
        }

        /// <summary>
        /// 查找所有引用目标资源的物体
        /// </summary>
        /// <param name="target">目标资源</param>
        /// <returns></returns>
        private Object[] GetBeDepend(Object target)
        {
            if (target == null) return null;
            string path = AssetDatabase.GetAssetPath(target);
            if (string.IsNullOrEmpty(path)) return null;
            string guid = AssetDatabase.AssetPathToGUID(path);
            string[] files = Directory.GetFiles(Application.dataPath, "*",
                SearchOption.AllDirectories).Where(s => withoutExtensions.Contains(Path.GetExtension(s).ToLower())).ToArray();
            List<Object> objects= new List<Object>();
            foreach (var file in files)
            {
                string assetPath = file.Replace(Application.dataPath,"");
                assetPath = "Assets"+assetPath;
                string readText = File.ReadAllText(file);
                
                if (!readText.StartsWith("%YAML"))
                {
                    var depends = AssetDatabase.GetDependencies(assetPath, false);
                    if (depends!=null)
                    {
                        foreach (var dep in depends)
                        {
                            if (dep==path)
                            {
                                objects.Add(AssetDatabase.LoadAssetAtPath<Object>(assetPath));
                                break;
                            }
                        }
                    }
                }else if (Regex.IsMatch(readText,guid))objects.Add(AssetDatabase.LoadAssetAtPath<Object>(assetPath));
            }
            return objects.ToArray();
        }

        private void OnDestroy()
        {
            targetObjects = null;
            beDependArr = null;
            foldoutArr = null;
        }
    }
}

