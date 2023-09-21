using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEditor.Animations;
using UnityEngine;
using Object = UnityEngine.Object;
 
/// <summary>
/// 资源导入工具
/// </summary>
public class ResourceImportEditorWindow : EditorWindow
{
    // 预制体创建路径
    private string PrefabCreatePath; 
    private Vector2 ve2;
 
    [MenuItem("美术/资源导入工具")]
    private static void OpenFbxEditorWindow()
    {
        ResourceImportEditorWindow window = EditorWindow.CreateWindow<ResourceImportEditorWindow>("FBX导入工具");
        window.position = new Rect(window.position.center.x,window.position.center.y,1000,400);
    }
 
    private void OnGUI()
    {
        DrawWindow();
    }
 
    private void DrawWindow()
    {
        EditorGUILayout.Space();
        EditorGUILayout.Space();
        EditorGUILayout.Space();
 
        EditorGUILayout.BeginVertical();
        DrawInstantiate();
        DrawVerificationFileName();
        DrawCheckReference();
        EditorGUILayout.EndHorizontal();
    }
    
    /// <summary>
    /// 绘制角色生成
    /// </summary>
    private void DrawInstantiate()
    {
        EditorGUILayout.LabelField("角色生成",EditorStyles.boldLabel);
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Prefab生成路径:",GUILayout.Width(110));
        PrefabCreatePath = EditorGUILayout.TextField(PrefabCreatePath);
        if (PrefabCreatePath != String.Empty && !Directory.Exists(PrefabCreatePath))
        {
            EditorGUILayout.LabelField("文件夹不存在",GUILayout.Width(200));
        }
 
        EditorGUILayout.EndHorizontal();
        // 选择项
        EditorGUILayout.BeginHorizontal();
        var obj = Selection.activeGameObject;
        if (IsFbxFile())
        {
            EditorGUILayout.LabelField("当前FBX:",GUILayout.Width(110));
            EditorGUILayout.ObjectField(obj,obj.GetType());
           // if (PrefabCreatePath == String.Empty)
           // {
                
           // }
          //  else
           // {
           // }
        }
        else
        {
            EditorGUILayout.LabelField("请选择选择FBX文件:",GUILayout.Width(110));
            EditorGUILayout.ObjectField(obj,typeof(GameObject));
        }
        
        EditorGUILayout.EndHorizontal();
 
        EditorGUILayout.BeginHorizontal();
        if (GUILayout.Button("创建角色or小怪",GUILayout.Height(40)))
        {
            InstantiatePlayModel();
        }
        if (GUILayout.Button("创建Map角色",GUILayout.Height(40)))
        {
            InstantiateMapModel();
        }
        EditorGUILayout.EndHorizontal();
    }
 
    /// <summary>
    /// 绘制文件名检查
    /// </summary>
    private void DrawVerificationFileName()
    {
        EditorGUILayout.Space();
        EditorGUILayout.Space();
        EditorGUILayout.Space();
        EditorGUILayout.Space();
        EditorGUILayout.BeginVertical();
        EditorGUILayout.LabelField("文件名检查",EditorStyles.boldLabel);
        string path = GetSelectDirectoryPath();
        EditorGUILayout.LabelField($"所选文件夹：{path}",EditorStyles.boldLabel);
        if (GUILayout.Button("检查文件名",GUILayout.Height(40)))
        {
            VerificationFileName(path);
        }
        EditorGUILayout.EndHorizontal();
 
    }
 
    private void DrawCheckReference()
    {
        EditorGUILayout.Space();
        EditorGUILayout.Space();
        EditorGUILayout.Space();
        EditorGUILayout.Space();
        EditorGUILayout.LabelField("引用丢失检查",EditorStyles.boldLabel);
 
        GameObject[] gos = Selection.gameObjects;
        ve2 = EditorGUILayout.BeginScrollView(ve2,GUILayout.Height(Math.Min(100,gos.Length * 18)));
        for (int i = 0; i < gos.Length; i++)
        {
            // EditorGUILayout.ObjectField(gos[i],gos.GetType());
            string path = AssetDatabase.GetAssetPath(gos[i]);
            EditorGUILayout.LabelField(path == String.Empty ? gos[i].name : path);
        }
        EditorGUILayout.EndScrollView();
        
        if (GUILayout.Button("检查引用",GUILayout.Height(40)))
        {
            CheckReference(gos);
        }
    }
 
    private bool IsFbxFile()
    {
        if (Selection.activeGameObject == null) return false;
        string filepath = AssetDatabase.GetAssetPath(Selection.activeGameObject);
        return filepath.EndsWith(".Fbx") || filepath.EndsWith(".FBX") || filepath.EndsWith(".fbx");
    }
 
    private void InstantiatePlayModel()
    {
        if (!IsFbxFile())
        {
            EditorUtility.DisplayDialog("创建Map角色失败", $"不是FBX模型,请重新检查资源和命名", "OK");
            return;
        }
        //创建同名空节点
        GameObject prefab = new GameObject(Selection.activeGameObject.name);
        var Model = Object.Instantiate(Selection.activeGameObject);
        Model.name = "Model";
        Model.transform.SetParent(prefab.transform);
        //添加碰撞组件,并配置临时数值
        prefab.AddComponent<CapsuleCollider>();
        var center = prefab.GetComponent<CapsuleCollider>().center;
        center = new Vector3(0, 0.8f, 0);
        prefab.GetComponent<CapsuleCollider>().center = center;
        var height = prefab.GetComponent<CapsuleCollider>().height;
        height = 2.6f;
        prefab.GetComponent<CapsuleCollider>().height = height;
        prefab.GetComponent<CapsuleCollider>().radius = 0.65f;
 
        //为Model添加animator组件 并指定所加载的控制器
        Model.AddComponent<Animator>();
        string controllerpath = "Assets/Resources/Actor/DefaultAnim/DefaultController/Human_Base.controller";
        AnimatorController human_base = AssetDatabase.LoadAssetAtPath<AnimatorController>(controllerpath);
        Model.GetComponent<Animator>().runtimeAnimatorController = human_base;
        //model下添加节点
        var BottomPoint = new GameObject("BottomPoint");
        var HitPoint = new GameObject("HitPoint");
        BottomPoint.transform.SetParent(Model.transform);
        HitPoint.transform.SetParent(Model.transform);
        //为hitppoint设置数值
        var hit = HitPoint.transform.position;
        hit = new Vector3(0, 1f, 0);
        HitPoint.transform.position = hit;
        //添加RotationPoint
        var RotationPoint = new GameObject("RotationPoint");
        RotationPoint.transform.SetParent(prefab.transform);
 
        if (PrefabCreatePath != String.Empty && Directory.Exists(PrefabCreatePath))
        {
            string fullName = $"{PrefabCreatePath}/{prefab.name}.prefab";
            PrefabUtility.SaveAsPrefabAsset(prefab,fullName);
            // Debug.Log($"角色创建成功 path:{fullName}");
            EditorUtility.DisplayDialog("角色创建成功", $"path:{fullName}", "OK");
            DestroyImmediate(prefab);
        }
        else
        {
            Debug.Log($"角色实例创建成功 name:{prefab.name}");
        }
        
    }
    
    private void InstantiateMapModel()
    {
        if (!IsFbxFile())
        {
            EditorUtility.DisplayDialog("创建Map角色失败", $"不是FBX模型,请重新检查资源和命名", "OK");
            return;
        }
 
        if (Selection.activeGameObject.name.EndsWith("_Map"))
        {
            //把fbx模型实例化 (拖到hierarchy里)
            GameObject prefab = Instantiate(Selection.activeGameObject);
            prefab.name = Selection.activeGameObject.name;
            if (PrefabCreatePath != String.Empty && Directory.Exists(PrefabCreatePath))
            {
                string fullName = $"{PrefabCreatePath}/{prefab.name}.prefab";
                PrefabUtility.SaveAsPrefabAsset(prefab,fullName);
                // Debug.Log($"角色创建成功 path:{fullName}");
                EditorUtility.DisplayDialog("创建Map角色成功", $"path:{fullName}", "OK");
                DestroyImmediate(prefab);
            }
            else
            {
                Debug.Log($"Map角色实例创建成功 name:{prefab.name}");
            }
        }
        else
        {
            EditorUtility.DisplayDialog("创建Map角色失败", $"不是地图角色(_Map后缀),请重新检查资源和命名", "OK");
        }
    }
 
    private string GetSelectDirectoryPath()
    {
        string path = "";
        // 获取所有选中 文件、文件夹的 GUID
        string[] guids = Selection.assetGUIDs;
        foreach (var guid in guids)
        {
            // 将 GUID 转换为 路径
            string assetPath = AssetDatabase.GUIDToAssetPath(guid);
            if (Directory.Exists(assetPath))
            {
                path = assetPath;
                break;
            }
        }
        return path;
    }
 
    private void VerificationFileName(string fileRootPath)
    {
        if (!Directory.Exists(fileRootPath))
        {
            EditorUtility.DisplayDialog("提示", $"文件夹不存在", "OK");
            return;;
        }
        
        DirectoryInfo directoryInfo = new DirectoryInfo(fileRootPath);
        List<FileInfo> allFiles = new List<FileInfo>();
        GetAllFile(directoryInfo, allFiles);
 
        string errorStr = "";
        for (int i = 0; i < allFiles.Count; i++)
        {
            FileInfo info = allFiles[i]; 
            if (!info.Name.Contains(directoryInfo.Name) 
                || info.Name.Contains("@@") 
                || info.Name.Contains("__") 
                || info.Name.Contains(" ") 
                || info.Name.Contains("-"))
            {
                string fullPath = info.FullName.Replace(@"\",@"/").Replace(Application.dataPath,"Assets") + "\n";
                errorStr += fullPath; 
                Debug.LogWarning($"FileName error: {fullPath}");
            }
        }
 
        if (errorStr != "")
        {
            EditorUtility.DisplayDialog("提示", $"文件名称错误：\n {errorStr}", "OK");
        }
        else
        {
            Debug.Log("命名OK咯");
        }
    }
 
    public void GetAllFile(DirectoryInfo directoryInfo,List<FileInfo> allFiles)
    {
        FileInfo[] fileInfos = directoryInfo.GetFiles();
        for (int i = 0; i < fileInfos.Length; i++)
        {
            if(!fileInfos[i].Name.EndsWith(".meta"))
                allFiles.Add(fileInfos[i]);
        }
 
        DirectoryInfo[] directoryInfos = directoryInfo.GetDirectories();
        for (int i = 0; i < directoryInfos.Length; i++)
        {
            GetAllFile(directoryInfos[i],allFiles);
        }
    }
 
    /// <summary>
    /// 检查引用
    /// </summary>
    public void CheckReference(GameObject[] gameObjects)
    {
        if (gameObjects == null || gameObjects.Length <= 0)
        {
            EditorUtility.DisplayDialog("提示", "没有检查对象", "OK");
            return;
        }
        
        string missingError = "";
        for (int n = 0; n < gameObjects.Length; n++)
        {
            GameObject gameObject = gameObjects[n];
            if(gameObject == null) continue;
            
            Component[] components = gameObject.GetComponentsInChildren<Component>();
            for (int i = 0; i < components.Length; i++)
            {
                SerializedObject so = new SerializedObject(components[i]);   
                SerializedProperty property = so.GetIterator();
 
                while (property.NextVisible(true))
                {
                    if (property.propertyType == SerializedPropertyType.ObjectReference)
                    {
                        if (property.objectReferenceValue == null && property.objectReferenceInstanceIDValue != 0)
                        {
                            Transform trans = components[i].transform;
                            string path = trans.name;
                            while (trans.parent != null)
                            {
                                trans = trans.parent;
                                path = trans.name + "/" + path;
                            }
                            string err =  $"{path}: {components[i].GetType()} missing: {property.name} \n";
                            Debug.LogWarning(err);
                            missingError += err;
                        }
                    }
                }
            }
        }
 
        if (missingError != "")
        {
            EditorUtility.DisplayDialog("引用丢失提示", missingError, "OK");
        }
        else
        {
            EditorUtility.DisplayDialog("提示", "文件正常", "OK");
        }
    }
}