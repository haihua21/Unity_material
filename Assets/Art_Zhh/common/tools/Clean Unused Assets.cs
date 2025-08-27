using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.Linq;

public class MaterialTextureReferenceCleaner : EditorWindow
{
    private List<Material> selectedMaterials = new List<Material>();
    private Vector2 scrollPos;
    private List<(Material mat, string propName, Texture tex)> unusedReferences = new List<(Material, string, Texture)>();
    private Rect dropArea;

    // [MenuItem("Window/材质球贴图引用清理")]
    [MenuItem("Assets/宝石特攻队/美术/材质球贴图引用清理 &c", false, 51)]
    public static void ShowWindow()
    {
        GetWindow<MaterialTextureReferenceCleaner>("贴图引用残留清理");
    }

    private void OnGUI()
    {
        GUILayout.Label("材质球清理工具", EditorStyles.boldLabel);
        GUILayout.Label("支持直接拖入多个材质球到下方区域", EditorStyles.miniLabel);
        
        // 绘制拖放区域
        dropArea = GUILayoutUtility.GetRect(0, 50, GUILayout.ExpandWidth(true));
        GUI.Box(dropArea, "拖放材质球到这里");
        
        // 处理拖放逻辑
        HandleDragAndDrop();
        
        GUILayout.Space(10);
        GUILayout.Label("已选择的材质球:", EditorStyles.boldLabel);
        
        // 材质球列表显示区域
        scrollPos = EditorGUILayout.BeginScrollView(scrollPos);
        for (int i = 0; i < selectedMaterials.Count; i++)
        {
            EditorGUILayout.BeginHorizontal();
            selectedMaterials[i] = (Material)EditorGUILayout.ObjectField(
                selectedMaterials[i], typeof(Material), false);
            
            if (GUILayout.Button("移除", GUILayout.Width(50)))
            {
                selectedMaterials.RemoveAt(i);
                i--;
            }
            EditorGUILayout.EndHorizontal();
        }
        EditorGUILayout.EndScrollView();
        
        // 添加材质球按钮（保留原有方式）
        if (GUILayout.Button("添加材质球"))
        {
            selectedMaterials.Add(null);
        }
        
        // 查找未使用引用按钮
        if (GUILayout.Button("查找未使用的贴图引用", GUILayout.Height(25)))
        {
            FindUnusedTextureReferences();
        }
        
        // 显示结果和清理按钮
        if (unusedReferences.Count > 0)
        {
            GUILayout.Space(10);
            GUILayout.Label($"发现 {unusedReferences.Count} 个未使用的贴图引用:", EditorStyles.boldLabel);
            
            foreach (var item in unusedReferences)
            {
                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField($"{item.mat.name} 的 [{item.propName}] 属性", GUILayout.Width(250));
                EditorGUILayout.ObjectField(item.tex, typeof(Texture), false, GUILayout.Width(150));
                EditorGUILayout.EndHorizontal();
            }
            
            if (GUILayout.Button("清理所有未使用的引用", GUILayout.Height(30)))
            {
                CleanUnusedReferences();
            }
        }
    }

  
    private void HandleDragAndDrop()
    {
        
        Event currentEvent = Event.current;
        
       
        if (dropArea.Contains(currentEvent.mousePosition))
        {
            
            switch (currentEvent.type)
            {
                case EventType.DragUpdated:
                case EventType.DragPerform:
                   
                    DragAndDrop.visualMode = DragAndDrop.objectReferences
                        .All(obj => obj is Material) ? DragAndDropVisualMode.Copy : DragAndDropVisualMode.Rejected;
                    
                    
                    if (currentEvent.type == EventType.DragPerform)
                    {
                        DragAndDrop.AcceptDrag();
                        
                        
                        foreach (Object obj in DragAndDrop.objectReferences)
                        {
                            if (obj is Material material && !selectedMaterials.Contains(material))
                            {
                                selectedMaterials.Add(material);
                            }
                        }
                    }
                    
                    currentEvent.Use();
                    break;
            }
        }
    }

    private void FindUnusedTextureReferences()
    {
        unusedReferences.Clear();
        var validMaterials = selectedMaterials.Where(m => m != null).ToList();

        if (validMaterials.Count == 0)
        {
            EditorUtility.DisplayDialog("提示", "请先添加并选择材质球", "确定");
            return;
        }

        foreach (var mat in validMaterials)
        {
            Undo.RecordObject(mat, "Clean unused texture references");
            var texturePropertyNames = mat.GetTexturePropertyNames();

            foreach (var propName in texturePropertyNames)
            {
                Texture tex = mat.GetTexture(propName);
                if (tex != null && !IsTexturePropertyUsedByMaterial(mat, propName))
                {
                    unusedReferences.Add((mat, propName, tex));
                }
            }
        }

        if (unusedReferences.Count == 0)
        {
            EditorUtility.DisplayDialog("结果", "未发现未使用的贴图引用", "确定");
        }
    }

    private bool IsTexturePropertyUsedByMaterial(Material material, string propertyName)
    {
        return material.HasProperty(propertyName);
    }

    private void CleanUnusedReferences()
    {
        int cleanedCount = 0;
        foreach (var item in unusedReferences)
        {
            item.mat.SetTexture(item.propName, null);
            EditorUtility.SetDirty(item.mat);
            Debug.Log($"已清理：材质「{item.mat.name}」的「{item.propName}」贴图引用", item.mat);
            cleanedCount++;
        }

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
        
        unusedReferences.Clear();
        EditorUtility.DisplayDialog("完成", $"已清理 {cleanedCount} 个未使用的贴图引用\n（贴图文件已保留）", "确定");
    }
}
    