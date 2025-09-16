using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEditor;
using System.IO;
using System.Collections.Generic;
using Process = System.Diagnostics.Process;
using ProcessStartInfo = System.Diagnostics.ProcessStartInfo;

public class URPScreenshotTool : EditorWindow
{
    private Camera targetCamera;
    private int screenshotWidth = 1920;
    private int screenshotHeight = 1080;
    private bool captureTransparentBackground = false;
    private int antiAliasingLevel = 2;
    private string savePath = "";
    private bool useWhiteMaterial = false;
    private float materialAlpha = 1.0f;

    // 存储原始设置的变量
    private bool originalAllowHDR;
    private Color originalBackgroundColor;
    private RenderTexture originalTargetTexture;
    private CameraClearFlags originalClearFlags;
    private CameraRenderType originalRenderType;
    private bool originalRenderSkybox;
    private LayerMask originalCullingMask;
    private Dictionary<Renderer, Material[]> originalMaterials = new Dictionary<Renderer, Material[]>();
    private Material whiteMaterial;

    [MenuItem("Tools/URP 美术截图工具")]
    public static void ShowWindow()
    {
        GetWindow<URPScreenshotTool>("URP 美术截图工具");
    }

    private void OnEnable()
    {
        if (Camera.main != null)
        {
            targetCamera = Camera.main;
        }
        
        // 初始化保存路径，确保正确转换为操作系统格式
        savePath = Path.GetFullPath(Path.Combine(Application.dataPath, "Screenshots"));
        if (!Directory.Exists(savePath))
        {
            Directory.CreateDirectory(savePath);
        }

        EnsureWhiteMaterialExists();
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
        
        screenshotWidth = EditorGUILayout.IntField("宽度", screenshotWidth);
        screenshotHeight = EditorGUILayout.IntField("高度", screenshotHeight);
        
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

        // 材质设置
        EditorGUILayout.Space();
        GUILayout.Label("材质设置", EditorStyles.boldLabel);
        
        useWhiteMaterial = EditorGUILayout.Toggle(
            "使用无光白色材质", 
            useWhiteMaterial
        );

        if (useWhiteMaterial)
        {
            materialAlpha = EditorGUILayout.Slider(
                "材质透明度", 
                materialAlpha, 
                0.1f, 
                1.0f
            );
        }

        EditorGUILayout.Space();
        GUILayout.Label("保存路径", EditorStyles.boldLabel);
        EditorGUILayout.TextField("路径", savePath);
        
        // 路径按钮区域
        EditorGUILayout.BeginHorizontal();
        if (GUILayout.Button("浏览路径"))
        {
            string newPath = EditorUtility.OpenFolderPanel("选择保存路径", savePath, "");
            if (!string.IsNullOrEmpty(newPath))
            {
                // 标准化路径格式
                savePath = Path.GetFullPath(newPath);
            }
        }
        
        if (GUILayout.Button("打开路径"))
        {
            OpenSavePath();
        }
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.Space();
        
        if (GUILayout.Button("截取屏幕", GUILayout.Height(40)))
        {
            CaptureScreenshot();
        }

        if (targetCamera == null)
        {
            EditorGUILayout.HelpBox("请指定一个目标相机", MessageType.Warning);
        }
    }

    // 打开保存路径的方法 - 确保使用正确的路径
    private void OpenSavePath()
    {
        // 验证并标准化路径
        string normalizedPath = Path.GetFullPath(savePath);
        
        if (Directory.Exists(normalizedPath))
        {
            try
            {
                // 根据不同操作系统打开文件夹，使用正确的路径格式
#if UNITY_EDITOR_WIN
                // Windows需要处理路径中的空格
                Process.Start(new ProcessStartInfo("explorer.exe", $"\"{normalizedPath}\""));
#elif UNITY_EDITOR_OSX
                Process.Start("open", $"\"{normalizedPath}\"");
#else
                Process.Start("xdg-open", $"\"{normalizedPath}\"");
#endif
            }
            catch (System.Exception e)
            {
                UnityEngine.Debug.LogError($"打开路径失败: {e.Message}");
                EditorUtility.DisplayDialog("错误", $"无法打开路径:\n{normalizedPath}\n{e.Message}", "确定");
            }
        }
        else
        {
            bool createPath = EditorUtility.DisplayDialog(
                "路径不存在", 
                $"指定的保存路径不存在:\n{normalizedPath}\n是否创建该路径？", 
                "是", "否"
            );
            
            if (createPath)
            {
                try
                {
                    Directory.CreateDirectory(normalizedPath);
                    AssetDatabase.Refresh();
                    // 创建后自动打开
                    OpenSavePath();
                }
                catch (System.Exception e)
                {
                    UnityEngine.Debug.LogError($"创建路径失败: {e.Message}");
                    EditorUtility.DisplayDialog("错误", $"无法创建路径:\n{normalizedPath}\n{e.Message}", "确定");
                }
            }
        }
    }

    private void CaptureScreenshot()
    {
        if (targetCamera == null)
        {
            UnityEngine.Debug.LogError("请指定一个有效的相机");
            return;
        }

        if (GraphicsSettings.currentRenderPipeline == null || 
            !(GraphicsSettings.currentRenderPipeline is UniversalRenderPipelineAsset))
        {
            UnityEngine.Debug.LogError("当前渲染管线不是URP，请切换到URP管线");
            return;
        }

        // 确保保存路径存在
        string normalizedSavePath = Path.GetFullPath(savePath);
        if (!Directory.Exists(normalizedSavePath))
        {
            Directory.CreateDirectory(normalizedSavePath);
        }

        // 确保材质准备就绪
        EnsureWhiteMaterialExists();
        UpdateWhiteMaterialAlpha();

        // 保存原始设置
        SaveOriginalSettings();

        // 应用临时材质（如果启用）
        if (useWhiteMaterial)
        {
            ApplyWhiteMaterials();
        }

        // 配置截图设置
        ConfigureScreenshotSettings();

        // 创建带Alpha通道的渲染纹理
        RenderTexture renderTexture = new RenderTexture(screenshotWidth, screenshotHeight, 24, RenderTextureFormat.ARGB32)
        {
            antiAliasing = antiAliasingLevel > 1 ? antiAliasingLevel : 1
        };
        
        // 渲染相机视图
        targetCamera.targetTexture = renderTexture;
        targetCamera.Render();
        
        // 读取像素数据
        RenderTexture.active = renderTexture;
        Texture2D screenshot = new Texture2D(screenshotWidth, screenshotHeight, TextureFormat.ARGB32, false);
        screenshot.ReadPixels(new Rect(0, 0, screenshotWidth, screenshotHeight), 0, 0);
        screenshot.Apply();
        
        // 恢复原始设置和材质
        RestoreOriginalSettings();
        if (useWhiteMaterial)
        {
            RestoreOriginalMaterials();
        }
        
        // 释放资源
        DestroyImmediate(renderTexture);
        targetCamera.targetTexture = originalTargetTexture;
        RenderTexture.active = null;
        
        // 保存截图
        SaveScreenshot(screenshot, normalizedSavePath);
    }

    private void EnsureWhiteMaterialExists()
    {
        if (whiteMaterial == null)
        {
            string materialPath = "Assets/URP_Screenshot_Tool/Materials/WhiteUnlitMaterial.mat";
            whiteMaterial = AssetDatabase.LoadAssetAtPath<Material>(materialPath);

            if (whiteMaterial == null)
            {
                string materialDir = "Assets/URP_Screenshot_Tool/Materials";
                if (!Directory.Exists(materialDir))
                {
                    Directory.CreateDirectory(materialDir);
                }

                Shader unlitShader = Shader.Find("Universal Render Pipeline/Unlit");
                if (unlitShader == null)
                {
                    unlitShader = Shader.Find("Unlit/Transparent");
                }

                whiteMaterial = new Material(unlitShader);
                whiteMaterial.name = "WhiteUnlitMaterial";
                whiteMaterial.color = new Color(1, 1, 1, 1);
                whiteMaterial.renderQueue = 3000;

                AssetDatabase.CreateAsset(whiteMaterial, materialPath);
                AssetDatabase.Refresh();
            }
        }
    }

    private void UpdateWhiteMaterialAlpha()
    {
        if (whiteMaterial != null)
        {
            Color currentColor = whiteMaterial.color;
            whiteMaterial.color = new Color(currentColor.r, currentColor.g, currentColor.b, materialAlpha);
        }
    }

    private void ApplyWhiteMaterials()
    {
        originalMaterials.Clear();
        
        Renderer[] renderers = FindObjectsOfType<Renderer>(true);
        
        foreach (Renderer renderer in renderers)
        {
            if (!renderer.enabled) continue;
            
            if (renderer.GetComponent<CanvasRenderer>() != null || 
                renderer.GetComponent<ParticleSystem>() != null)
            {
                continue;
            }
            
            originalMaterials[renderer] = renderer.sharedMaterials;
            
            Material[] newMaterials = new Material[renderer.sharedMaterials.Length];
            for (int i = 0; i < newMaterials.Length; i++)
            {
                newMaterials[i] = whiteMaterial;
            }
            renderer.sharedMaterials = newMaterials;
        }
    }

    private void RestoreOriginalMaterials()
    {
        foreach (var kvp in originalMaterials)
        {
            if (kvp.Key != null)
            {
                kvp.Key.sharedMaterials = kvp.Value;
            }
        }
        originalMaterials.Clear();
    }

    private void SaveOriginalSettings()
    {
        originalAllowHDR = targetCamera.allowHDR;
        originalBackgroundColor = targetCamera.backgroundColor;
        originalTargetTexture = targetCamera.targetTexture;
        originalClearFlags = targetCamera.clearFlags;
        originalRenderSkybox = targetCamera.clearFlags == CameraClearFlags.Skybox;
        originalCullingMask = targetCamera.cullingMask;
        
        var urpCameraData = targetCamera.GetComponent<UniversalAdditionalCameraData>();
        if (urpCameraData != null)
        {
            originalRenderType = urpCameraData.renderType;
        }
    }

    private void ConfigureScreenshotSettings()
    {
        targetCamera.allowHDR = false;
        targetCamera.cullingMask = -1;
        
        if (captureTransparentBackground)
        {
            targetCamera.backgroundColor = new Color(0, 0, 0, 0);
            targetCamera.clearFlags = CameraClearFlags.Depth;
            
            var urpCameraData = targetCamera.GetComponent<UniversalAdditionalCameraData>();
            if (urpCameraData != null)
            {
                urpCameraData.renderType = CameraRenderType.Base;
            }
        }
        else
        {
            targetCamera.clearFlags = originalRenderSkybox ? CameraClearFlags.Skybox : CameraClearFlags.SolidColor;
        }
    }

    private void RestoreOriginalSettings()
    {
        targetCamera.allowHDR = originalAllowHDR;
        targetCamera.backgroundColor = originalBackgroundColor;
        targetCamera.clearFlags = originalClearFlags;
        targetCamera.cullingMask = originalCullingMask;
        
        var urpCameraData = targetCamera.GetComponent<UniversalAdditionalCameraData>();
        if (urpCameraData != null)
        {
            urpCameraData.renderType = originalRenderType;
        }
    }

    private void SaveScreenshot(Texture2D screenshot, string saveDirectory)
    {
        string fileName = $"Screenshot_{System.DateTime.Now:yyyyMMdd_HHmmss}_{screenshotWidth}x{screenshotHeight}";
        if (captureTransparentBackground)
        {
            fileName += "_Transparent";
        }
        if (useWhiteMaterial)
        {
            fileName += "_WhiteMat";
        }
        fileName += ".png";
        
        string fullPath = Path.Combine(saveDirectory, fileName);
        
        byte[] bytes = screenshot.EncodeToPNG();
        File.WriteAllBytes(fullPath, bytes);
        
        UnityEngine.Debug.Log($"截图已保存: {fullPath}");
        AssetDatabase.Refresh();
        
        EditorUtility.DisplayDialog(
            "截图完成", 
            $"截图已保存到:\n{fullPath}\n尺寸: {screenshotWidth}x{screenshotHeight}", 
            "确定"
        );
    }

    private void OnDisable()
    {
        if (originalMaterials.Count > 0)
        {
            RestoreOriginalMaterials();
        }
    }
}
    