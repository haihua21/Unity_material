using System.Collections;
using UnityEngine;
using UnityEditor;
using System.IO;

/// <summary>
/// 把工程中设置了AssetBundle Name的资源打包成.unity3d 到StreamingAssets目录下
/// </summary>
public class ExportAssetBundle : EditorWindow
{
    // public static string sourcePath = Application.dataPath + "/Resources";
    private string OutputPath = "Assets/StreamingAssets";

    [MenuItem("美术/导出所有AssetBundle")]
    static void AddWindow()
    {
        //创建窗口
        ExportAssetBundle window = (ExportAssetBundle)EditorWindow.GetWindowWithRect(typeof(ExportAssetBundle),new Rect(Screen.width/2,Screen.height/2,400,80), true, "导出AssetBundle");
        window.Show();

    }


    void OnGUI()
    {
        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("导出路径:");
        OutputPath = EditorGUILayout.TextField(OutputPath);
        if (GUILayout.Button("浏览"))
        {
            //EditorApplication.delayCall += OpenFolder;
            OutputPath = EditorUtility.OpenFolderPanel("选择要导出的路径", "", "");
        }
        EditorGUILayout.EndHorizontal();
        if (GUILayout.Button("打包",GUILayout.MinHeight(50)))
        {
            BuildAssetBundle();
            this.Close();
        }
    }


    public void BuildAssetBundle()
    {
        string outputPath = Path.Combine(OutputPath, Platform.GetPlatformFolder(EditorUserBuildSettings.activeBuildTarget));
        if (!Directory.Exists(outputPath))
        {
            Directory.CreateDirectory(outputPath);
        }

        //根据BuildSetting里面所激活的平台进行打包
        BuildPipeline.BuildAssetBundles(outputPath, 0, EditorUserBuildSettings.activeBuildTarget);

        AssetDatabase.Refresh();

        Debug.Log("打包完成");

    }
}

public class Platform
{
    public static string GetPlatformFolder(BuildTarget target)
    {
        switch (target)
        {
            case BuildTarget.Android:
                return "Android";
            case BuildTarget.iOS:
                return "IOS";
            case BuildTarget.WebGL:
                return "WebGL";
            case BuildTarget.StandaloneWindows:
            case BuildTarget.StandaloneWindows64:
                return "Windows";
            case BuildTarget.StandaloneOSXIntel:
            case BuildTarget.StandaloneOSXIntel64:
           // case BuildTarget.StandaloneOSXUniversal:
                return "OSX";
            default:
                return null;
        }
    }
}