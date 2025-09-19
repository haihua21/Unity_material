using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEditor;
using System.IO;
using System.Collections.Generic;
using System.Diagnostics;

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
    
    // 后处理相关设置（适配新版URP）
    private bool enablePostProcessing = true;
    private VolumeProfile postProcessProfile; // 替换 PostProcessProfile 为 VolumeProfile

    // Scene视图相机生成相关配置
    private bool autoFocusSceneSelection = true;
    private float sceneCameraDistance = 5.0f;

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
    // 存储原始后处理设置
    private bool originalPostProcessingEnabled;

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
        
        savePath = Path.GetFullPath(Path.Combine(Application.dataPath, "Screenshots"));
        if (!Directory.Exists(savePath))
        {
            Directory.CreateDirectory(savePath);
        }

        EnsureWhiteMaterialExists();
        
        // 尝试加载默认后处理配置文件（适配新版）
        if (postProcessProfile == null)
        {
            string defaultProfilePath = "Assets/URP_Screenshot_Tool/PostProcessing/DefaultVolumeProfile.asset";
            postProcessProfile = AssetDatabase.LoadAssetAtPath<VolumeProfile>(defaultProfilePath);
        }
    }

    private void OnGUI()
    {
        GUILayout.Label("截图设置", EditorStyles.boldLabel);
        
        // Scene视图相机生成区域
        EditorGUILayout.Space();
        GUILayout.Label("Scene视图相机生成", EditorStyles.boldLabel);
        
        autoFocusSceneSelection = EditorGUILayout.Toggle(
            "自动聚焦Scene选中物体", 
            autoFocusSceneSelection
        );
        
        if (autoFocusSceneSelection)
        {
            sceneCameraDistance = EditorGUILayout.Slider(
                "相机与物体距离", 
                sceneCameraDistance, 
                1.0f, 
                20.0f
            );
        }
        
        // 后处理开关
        enablePostProcessing = EditorGUILayout.Toggle(
            "启用后处理效果", 
            enablePostProcessing
        );
        
        // 后处理配置文件选择（适配新版）
        if (enablePostProcessing)
        {
            postProcessProfile = (VolumeProfile)EditorGUILayout.ObjectField(
                "后处理配置文件", 
                postProcessProfile, 
                typeof(VolumeProfile), 
                false
            );
            
            if (GUILayout.Button("创建默认后处理配置文件", GUILayout.Width(200)))
            {
                CreateDefaultPostProcessProfile();
            }
        }
        
        if (GUILayout.Button("从Scene视图生成相机", GUILayout.Height(25)))
        {
            GenerateCameraFromSceneView();
        }

        // 目标相机选择区域
        EditorGUILayout.Space();
        targetCamera = (Camera)EditorGUILayout.ObjectField(
            "目标相机（生成后自动赋值）", 
            targetCamera, 
            typeof(Camera), 
            true
        );

        // 截图尺寸设置
        EditorGUILayout.Space();
        GUILayout.Label("截图尺寸", EditorStyles.boldLabel);
        
        EditorGUILayout.BeginHorizontal();
        screenshotWidth = EditorGUILayout.IntField("宽度", screenshotWidth);
        if (GUILayout.Button("2x", GUILayout.Width(40)))
        {
            screenshotWidth *= 2;
            screenshotHeight *= 2;
        }
        EditorGUILayout.EndHorizontal();
        
        EditorGUILayout.BeginHorizontal();
        screenshotHeight = EditorGUILayout.IntField("高度", screenshotHeight);
        if (GUILayout.Button("3x", GUILayout.Width(40)))
        {
            screenshotWidth *= 3;
            screenshotHeight *= 3;
        }
        if (GUILayout.Button("4x", GUILayout.Width(40)))
        {
            screenshotWidth *= 4;
            screenshotHeight *= 4;
        }
        EditorGUILayout.EndHorizontal();
        
        // 常用尺寸预设按钮
        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("常用尺寸:", GUILayout.Width(80));
        if (GUILayout.Button("1080p", GUILayout.Width(70)))
        {
            screenshotWidth = 1920;
            screenshotHeight = 1080;
        }
        if (GUILayout.Button("2K", GUILayout.Width(70)))
        {
            screenshotWidth = 2560;
            screenshotHeight = 1440;
        }
        if (GUILayout.Button("4K", GUILayout.Width(70)))
        {
            screenshotWidth = 3840;
            screenshotHeight = 2160;
        }
        EditorGUILayout.EndHorizontal();
        
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

        // 保存路径设置
        EditorGUILayout.Space();
        GUILayout.Label("保存路径", EditorStyles.boldLabel);
        EditorGUILayout.TextField("路径", savePath);
        
        EditorGUILayout.BeginHorizontal();
        if (GUILayout.Button("浏览路径"))
        {
            string newPath = EditorUtility.OpenFolderPanel("选择保存路径", savePath, "");
            if (!string.IsNullOrEmpty(newPath))
            {
                savePath = Path.GetFullPath(newPath);
            }
        }
        
        if (GUILayout.Button("打开路径"))
        {
            OpenSavePath();
        }
        EditorGUILayout.EndHorizontal();

        // 截图按钮
        EditorGUILayout.Space();
        if (GUILayout.Button("截取屏幕", GUILayout.Height(40)))
        {
            CaptureScreenshot();
        }

        if (targetCamera == null)
        {
            EditorGUILayout.HelpBox("请指定一个目标相机（可通过\"从Scene视图生成相机\"快速创建）", MessageType.Warning);
        }
        
        // 当前分辨率显示
        EditorGUILayout.HelpBox($"当前分辨率: {screenshotWidth}x{screenshotHeight}", MessageType.Info);
    }

    // 从Scene视图生成相机（添加后处理支持）
    private void GenerateCameraFromSceneView()
    {
        SceneView currentSceneView = SceneView.lastActiveSceneView;
        if (currentSceneView == null)
        {
            EditorUtility.DisplayDialog("错误", "未找到激活的Scene视图，请先打开Scene窗口", "确定");
            return;
        }
        Camera sceneViewCamera = currentSceneView.camera;
        if (sceneViewCamera == null)
        {
            EditorUtility.DisplayDialog("错误", "无法获取Scene视图的相机数据", "确定");
            return;
        }

        GameObject cameraObj = new GameObject("Screenshot_Camera_" + System.DateTime.Now.ToString("HHmmss"));
        Camera newCamera = cameraObj.AddComponent<Camera>();

        // 配置URP相机数据
        UniversalAdditionalCameraData urpCameraData = cameraObj.AddComponent<UniversalAdditionalCameraData>();
        urpCameraData.renderType = CameraRenderType.Base;
        urpCameraData.requiresColorOption = (CameraOverrideOption)0;
        urpCameraData.requiresDepthOption = (CameraOverrideOption)0;

        // 添加后处理组件并配置（适配新版URP）
        Volume postProcessVolume = cameraObj.AddComponent<Volume>();
        postProcessVolume.priority = 100;
        postProcessVolume.isGlobal = true;

        // 如果启用后处理且有配置文件，则设置
        if (enablePostProcessing && postProcessProfile != null)
        {
            postProcessVolume.profile = postProcessProfile;
        }

        // 相机基本参数配置
        newCamera.fieldOfView = sceneViewCamera.fieldOfView;
        newCamera.nearClipPlane = sceneViewCamera.nearClipPlane;
        newCamera.farClipPlane = sceneViewCamera.farClipPlane;
        newCamera.aspect = (float)screenshotWidth / screenshotHeight;

        if (autoFocusSceneSelection && Selection.activeGameObject != null)
        {
            Transform targetTransform = Selection.activeGameObject.transform;
            Bounds targetBounds = GetObjectTotalBounds(targetTransform);
            
            Vector3 directionToTarget = (targetBounds.center - sceneViewCamera.transform.position).normalized;
            Vector3 cameraPosition = targetBounds.center - directionToTarget * (sceneCameraDistance + targetBounds.extents.magnitude);
            
            newCamera.transform.position = cameraPosition;
            newCamera.transform.LookAt(targetBounds.center);
        }
        else
        {
            newCamera.transform.position = sceneViewCamera.transform.position;
            newCamera.transform.rotation = sceneViewCamera.transform.rotation;
        }

        newCamera.cullingMask = sceneViewCamera.cullingMask;
        newCamera.clearFlags = captureTransparentBackground ? CameraClearFlags.Depth : CameraClearFlags.Skybox;
        newCamera.backgroundColor = new Color(0, 0, 0, 0);
        newCamera.allowHDR = true; // 后处理通常需要HDR支持

        targetCamera = newCamera;
        Selection.activeGameObject = cameraObj;

        EditorUtility.DisplayDialog(
            "相机生成成功", 
            $"已从Scene视图生成截图相机：\n{cameraObj.name}\n\n相机已自动选中，可在Hierarchy面板调整细节", 
            "确定"
        );

        SceneView.RepaintAll();
    }

    // 创建默认后处理配置文件（适配新版URP）
    private void CreateDefaultPostProcessProfile()
    {
        string ppDir = "Assets/URP_Screenshot_Tool/PostProcessing";
        if (!Directory.Exists(ppDir))
        {
            Directory.CreateDirectory(ppDir);
        }

        string profilePath = Path.Combine(ppDir, "DefaultVolumeProfile.asset");
        VolumeProfile profile = ScriptableObject.CreateInstance<VolumeProfile>();
        AssetDatabase.CreateAsset(profile, profilePath);

        // 添加一些默认效果（示例）
        var bloom = profile.Add<Bloom>();
        bloom.active = true;
        bloom.intensity.value = 0.5f;

        var colorAdjustments = profile.Add<ColorAdjustments>();
        colorAdjustments.active = true;
        colorAdjustments.postExposure.value = 0f;

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();

        postProcessProfile = profile;
        EditorUtility.DisplayDialog("成功", "已创建默认后处理配置文件", "确定");
    }

    // 获取物体的总包围盒
    private Bounds GetObjectTotalBounds(Transform targetTransform)
    {
        Renderer[] renderers = targetTransform.GetComponentsInChildren<Renderer>(true);
        if (renderers.Length == 0)
        {
            return new Bounds(targetTransform.position, Vector3.one);
        }

        Bounds totalBounds = renderers[0].bounds;
        foreach (Renderer renderer in renderers)
        {
            if (renderer.enabled)
            {
                totalBounds.Encapsulate(renderer.bounds);
            }
        }
        return totalBounds;
    }

    // 打开保存路径
    private void OpenSavePath()
    {
        string normalizedPath = Path.GetFullPath(savePath);
        
        if (Directory.Exists(normalizedPath))
        {
            try
            {
#if UNITY_EDITOR_WIN
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

    // 截图核心方法
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

        string normalizedSavePath = Path.GetFullPath(savePath);
        if (!Directory.Exists(normalizedSavePath))
        {
            Directory.CreateDirectory(normalizedSavePath);
        }

        EnsureWhiteMaterialExists();
        UpdateWhiteMaterialAlpha();

        SaveOriginalSettings();

        if (useWhiteMaterial)
        {
            ApplyWhiteMaterials();
        }

        ConfigureScreenshotSettings();

        // 检查分辨率是否过大，给出警告
        if (screenshotWidth * screenshotHeight > 20000000) // 超过2000万像素
        {
            bool continueCapture = EditorUtility.DisplayDialog(
                "高分辨率警告", 
                $"您设置的分辨率({screenshotWidth}x{screenshotHeight})可能导致性能问题或内存不足。\n是否继续？", 
                "继续", "取消"
            );
            
            if (!continueCapture)
            {
                RestoreOriginalSettings();
                if (useWhiteMaterial)
                {
                    RestoreOriginalMaterials();
                }
                return;
            }
        }

        RenderTexture renderTexture = new RenderTexture(screenshotWidth, screenshotHeight, 24, RenderTextureFormat.ARGB32)
        {
            antiAliasing = antiAliasingLevel > 1 ? antiAliasingLevel : 1
        };
        
        targetCamera.targetTexture = renderTexture;
        targetCamera.Render();
        
        RenderTexture.active = renderTexture;
        Texture2D screenshot = new Texture2D(screenshotWidth, screenshotHeight, TextureFormat.ARGB32, false);
        screenshot.ReadPixels(new Rect(0, 0, screenshotWidth, screenshotHeight), 0, 0);
        screenshot.Apply();
        
        RestoreOriginalSettings();
        if (useWhiteMaterial)
        {
            RestoreOriginalMaterials();
        }
        
        DestroyImmediate(renderTexture);
        targetCamera.targetTexture = originalTargetTexture;
        RenderTexture.active = null;
        
        SaveScreenshot(screenshot, normalizedSavePath);
    }

    // 白色材质相关方法
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

    // 相机设置保存与恢复
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
        
        // 保存后处理原始设置
        var postProcessVolume = targetCamera.GetComponent<Volume>();
        if (postProcessVolume != null)
        {
            originalPostProcessingEnabled = postProcessVolume.enabled;
        }
    }

    private void ConfigureScreenshotSettings()
    {
        targetCamera.allowHDR = true; // 后处理通常需要HDR
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
        
        // 确保后处理启用（如果需要）
        if (enablePostProcessing)
        {
            var postProcessVolume = targetCamera.GetComponent<Volume>();
            if (postProcessVolume != null)
            {
                postProcessVolume.enabled = true;
            }
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
        
        // 恢复后处理原始设置
        var postProcessVolume = targetCamera.GetComponent<Volume>();
        if (postProcessVolume != null)
        {
            postProcessVolume.enabled = originalPostProcessingEnabled;
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
        if (enablePostProcessing)
        {
            fileName += "_PostProcessed";
        }
        fileName += ".png";
        
        string fullPath = Path.Combine(saveDirectory, fileName);
        
        byte[] bytes = screenshot.EncodeToPNG();
        File.WriteAllBytes(fullPath, bytes);
        
        UnityEngine.Debug.Log($"截图已保存: {fullPath}");
        
        EditorUtility.DisplayDialog(
            "截图完成", 
            $"截图已保存到:\n{fullPath}\n尺寸: {screenshotWidth}x{screenshotHeight}", 
            "确定"
        );
    }
}
    