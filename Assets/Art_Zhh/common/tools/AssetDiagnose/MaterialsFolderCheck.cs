using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;
using System.Linq;

// using Sirenix.Utilities;

using UnityEditor.UIElements;

public class MaterialsFolderCheck : EditorWindow
{
    private string folderPath;
    private string folderName;
    private string extentionName;
    private Vector2 scrollPosition;
    private bool checkMaterialsButtonClicked = false;
    private Dictionary<string, List<string>> dictionary = new Dictionary<string, List<string>>();
    private Dictionary<string, bool> foldoutStatus = new Dictionary<string, bool>();
    
    
    // 创建EditorWindow
    [MenuItem("美术/角色材料引用检查")]
    public static void ShowWindow()
    {
        GetWindow<MaterialsFolderCheck>("Materials Folder Check");
    }
    
    // 添加GUI
    private void OnGUI()
    {   
        Event e = Event.current;
        GUILayout.Label("Enter the folder path:", EditorStyles.boldLabel);
        folderPath = EditorGUILayout.TextField("Path", folderPath);
        folderName = EditorGUILayout.TextField("Folder Name", folderName);
        // extentionName = EditorGUILayout.TextField("Extention Name", extentionName);
        // Create a GUI layout area to drag and drop a file
        Rect drop_area = GUILayoutUtility.GetRect(0.0f, 50.0f, GUILayout.ExpandWidth(true));
        GUI.Box(drop_area, "Drag & Drop Area");
    
        if (e.type == EventType.DragUpdated && drop_area.Contains(e.mousePosition))
        {
            DragAndDrop.visualMode = DragAndDropVisualMode.Copy;
            Event.current.Use();
        }
        else if (e.type == EventType.DragPerform && drop_area.Contains(e.mousePosition))
        {
            DragAndDrop.AcceptDrag();
            foreach (var draggedObject in DragAndDrop.paths)
            {
                folderPath = draggedObject; // Assign the path of the dragged file
            }
        }
        
        if (GUILayout.Button("Check Materials"))
            checkMaterialsButtonClicked = true;
            // Error handling for null or empty fields
            if (string.IsNullOrEmpty(folderPath))
            {
                Debug.LogError("Folder path is null or empty.");
                return;
            }
            if (string.IsNullOrEmpty(folderName))
            {
                Debug.LogError("Folder name is null or empty.");
                return;
            }
           
            
        scrollPosition = GUILayout.BeginScrollView(scrollPosition);
        foreach (var item in dictionary)
        {
            if (item.Value.Count == 0)
                continue;

            GUILayout.BeginHorizontal();
            if (!foldoutStatus.ContainsKey(item.Key))
                foldoutStatus[item.Key] = false;
            foldoutStatus[item.Key] = EditorGUILayout.Foldout(foldoutStatus[item.Key], "File path: " + item.Key, true);
            if (GUILayout.Button("Go to file", GUILayout.Width(80)))
            {
                EditorGUIUtility.PingObject(AssetDatabase.LoadAssetAtPath<Object>(item.Key));
            }
            GUILayout.EndHorizontal();
            
            // GUILayout.Label("File path: " + item.Key, EditorStyles.boldLabel);
            if (foldoutStatus[item.Key])
            {
                foreach (string path in item.Value)
                {
                    string materialPath = path.Split(new string[] { "Material path: " }, System.StringSplitOptions.None)[1];
                    if (GUILayout.Button(materialPath))
                    {
                        EditorGUIUtility.PingObject(AssetDatabase.LoadAssetAtPath<Object>(materialPath));
                    }
                }
            }

            
        }
        GUILayout.EndScrollView();
    }
    
    private void Update()
    {
        if (checkMaterialsButtonClicked)
        {   
            checkMaterialsButtonClicked = false;
            dictionary.Clear();
            CheckMaterialsInFolder();
            
        }
    }
    
    private void CheckMaterialsInFolder()
    {   
        // Get all subdirectories
        string[] directoriesArray = Directory.GetDirectories(folderPath, "*", SearchOption.AllDirectories);

        // Convert the array to a list
        List<string> directoriesList = new List<string>(directoriesArray);

        // Add the main directory
        directoriesList.Add(folderPath);

        // Filter directories by name
        string specificFolderName = folderName;
        List<string> specificDirectories = directoriesList.Where(d => Path.GetFileName(d) == specificFolderName).ToList();
        

        // Get all files in the specific directories
        List<string> files = new List<string>();
        foreach (string directory in specificDirectories)
        {
            files.AddRange(Directory.GetFiles(directory, "*", SearchOption.AllDirectories));
        }
        
        List<string> wordList = extentionName.Split(' ').Select(word => "." + word).ToList();
        Debug.Log(wordList);
        foreach (string file in files)
        {
            GameObject obj = AssetDatabase.LoadAssetAtPath<GameObject>(file);
            if (file.Contains("pf_ch_spacefarers_ur01_p_001_view.prefab"))
            {
                Debug.Log("hahahahahahahahahha");
            }
            // 得到这个文件的dependencies
            string[] dependencies = AssetDatabase.GetDependencies(file, true);
            
            //跳过不是预制的文件
            if (Path.GetExtension(file) != ".prefab")
                continue;
            Debug.Log("Processing file: " + file);
            
            List<string> warnings = new List<string>();
            foreach (string dependency in dependencies)
            {
                if (!dependency.Contains("shader")) {
                
                    // 过滤含有common的dependencies
                    if (dependency.Contains("common") || dependency.Contains("effect")) continue;
                } else if (!dependency.Contains("lobby_plastic_blend") && !dependency.Contains("ingame_plastic_blend"))
                {
                    continue;
                }

                if (dependency.Contains("urp_metallic")) continue;
                
                // 只检查特定的文件格式
                string extension = Path.GetExtension(dependency);
                if (extension == ".mat" || extension == ".shader")
                {
                    string materialFolder = Path.GetDirectoryName(dependency);
                    string secondLastName = Path.GetFileName(materialFolder); 
                    
                    // 检查文件所属的文件夹名称
                    if (!dependency.Contains(folderName))
                    {   
                        string warningMessage = $"The material {dependency} used by the file {file} is not in the same folder. Material path: {dependency}";
                        warnings.Add(warningMessage);
                        Debug.Log(warningMessage);
                    }
                }
            }
            dictionary.Add(file, warnings);
        }
    }
}
