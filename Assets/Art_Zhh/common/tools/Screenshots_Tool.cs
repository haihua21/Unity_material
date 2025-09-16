using UnityEngine;
using UnityEngine.Rendering; // 添加这个命名空间以使用GraphicsSettings
using UnityEngine.Rendering.Universal;
using UnityEditor;
using System.IO;

public class URPScreenshotTool : EditorWindow
{
    private Camera targetCamera;
    private int screenshotWidth = 1920;  // 默认宽度
    private int screenshotHeight = 1080; // 默认高度
    private bool captureTransparentBackground = false;
    private int antiAliasingLevel = 2; // 2x MSAA
    private string savePath = "";

    // 存储原始设置的变量
    private bool originalAllowHDR;
    private Color originalBackgroundColor;
    private RenderTexture originalTargetTexture;
    private CameraClearFlags originalClearFlags;

    [MenuItem("Tools/URP 美术截图工具")]
    public static void ShowWindow()
    {
        GetWindow<URPScreenshotTool>("URP 美术截图工具");
    }

    private void OnEnable()
    {
        // 默认使用主相机
        if (Camera.main != null)
        {
            targetCamera = Camera.main;
        }
        
        // 默认保存路径
        savePath = Application.dataPath + "/Screenshots";
        if (!Directory.Exists(savePath))
        {
            Directory.CreateDirectory(savePath);
        }
    }

    private void OnGUI()
    {
        GUILayout.Label("截图设置", EditorStyles.boldLabel);
        
        targetCamera = (Camera)EditorGUILayout.ObjectField(
            "目标相机", 
            targetCamera, 
            typeof(Camera), 
            true
        );

        EditorGUILayout.Space();
        GUILayout.Label("截图尺寸", EditorStyles.boldLabel);
        
        // 自定义宽度和高度输入
        screenshotWidth = EditorGUILayout.IntField("宽度", screenshotWidth);
        screenshotHeight = EditorGUILayout.IntField("高度", screenshotHeight);
        
        // 限制最小尺寸
        screenshotWidth = Mathf.Max(128, screenshotWidth);
        screenshotHeight = Mathf.Max(128, screenshotHeight);

        antiAliasingLevel = EditorGUILayout.IntPopup(
            "抗锯齿级别", 
            antiAliasingLevel, 
            new string[] { "关闭", "2x MSAA", "4x MSAA", "8x MSAA" }, 
            new int[] { 1, 2, 4, 8 }
        );

        captureTransparentBackground = EditorGUILayout.Toggle(
            "透明背景", 
            captureTransparentBackground
        );

        EditorGUILayout.Space();
        GUILayout.Label("保存路径", EditorStyles.boldLabel);
        EditorGUILayout.TextField("路径", savePath);
        
        if (GUILayout.Button("浏览路径"))
        {
            string newPath = EditorUtility.OpenFolderPanel("选择保存路径", savePath, "");
            if (!string.IsNullOrEmpty(newPath))
            {
                savePath = newPath;
            }
        }

        EditorGUILayout.Space();
        
        if (GUILayout.Button("截取屏幕", GUILayout.Height(40)))
        {
            CaptureScreenshot();
        }

        // 显示提示信息
        if (targetCamera == null)
        {
            EditorGUILayout.HelpBox("请指定一个目标相机", MessageType.Warning);
        }
    }

    private void CaptureScreenshot()
    {
        if (targetCamera == null)
        {
            Debug.LogError("请指定一个有效的相机");
            return;
        }

        // 检查是否使用URP管线
        if (GraphicsSettings.currentRenderPipeline == null || 
            !(GraphicsSettings.currentRenderPipeline is UniversalRenderPipelineAsset))
        {
            Debug.LogError("当前渲染管线不是URP，请切换到URP管线");
            return;
        }

        // 保存原始设置
        SaveOriginalSettings();

        // 配置截图设置
        ConfigureScreenshotSettings();

        // 使用用户指定的尺寸创建渲染纹理
        RenderTexture renderTexture = new RenderTexture(screenshotWidth, screenshotHeight, 24)
        {
            antiAliasing = antiAliasingLevel > 1 ? antiAliasingLevel : 1,
            format = RenderTextureFormat.ARGB32
        };
        
        // 设置相机目标纹理并渲染
        targetCamera.targetTexture = renderTexture;
        targetCamera.Render();
        
        // 读取像素数据
        RenderTexture.active = renderTexture;
        Texture2D screenshot = new Texture2D(screenshotWidth, screenshotHeight, TextureFormat.ARGB32, false);
        screenshot.ReadPixels(new Rect(0, 0, screenshotWidth, screenshotHeight), 0, 0);
        screenshot.Apply();
        
        // 恢复原始设置
        RestoreOriginalSettings();
        
        // 释放资源
        DestroyImmediate(renderTexture);
        targetCamera.targetTexture = originalTargetTexture;
        RenderTexture.active = null;
        
        // 保存截图
        SaveScreenshot(screenshot);
    }

    private void SaveOriginalSettings()
    {
        // 保存相机基本设置
        originalAllowHDR = targetCamera.allowHDR;
        originalBackgroundColor = targetCamera.backgroundColor;
        originalTargetTexture = targetCamera.targetTexture;
        originalClearFlags = targetCamera.clearFlags;
    }

    private void ConfigureScreenshotSettings()
    {
        // 禁用HDR以确保兼容性
        targetCamera.allowHDR = false;
        
        // 配置透明背景
        if (captureTransparentBackground)
        {
            targetCamera.backgroundColor = new Color(0, 0, 0, 0);
            targetCamera.clearFlags = CameraClearFlags.SolidColor;
        }
    }

    private void RestoreOriginalSettings()
    {
        // 恢复相机设置
        targetCamera.allowHDR = originalAllowHDR;
        targetCamera.backgroundColor = originalBackgroundColor;
        targetCamera.clearFlags = originalClearFlags;
    }

    private void SaveScreenshot(Texture2D screenshot)
    {
        // 确保目录存在
        if (!Directory.Exists(savePath))
        {
            Directory.CreateDirectory(savePath);
        }
        
        // 生成文件名，包含尺寸信息
        string fileName = $"Screenshot_{System.DateTime.Now:yyyyMMdd_HHmmss}_{screenshotWidth}x{screenshotHeight}";
        if (captureTransparentBackground)
        {
            fileName += "_Transparent";
        }
        fileName += ".png";
        
        string fullPath = Path.Combine(savePath, fileName);
        
        // 保存为PNG
        byte[] bytes = screenshot.EncodeToPNG();
        File.WriteAllBytes(fullPath, bytes);
        
        Debug.Log($"截图已保存: {fullPath}");
        
        // 刷新Project窗口
        AssetDatabase.Refresh();
        
        // 显示完成提示
        EditorUtility.DisplayDialog(
            "截图完成", 
            $"截图已保存到:\n{fullPath}\n尺寸: {screenshotWidth}x{screenshotHeight}", 
            "确定"
        );
    }
}
    