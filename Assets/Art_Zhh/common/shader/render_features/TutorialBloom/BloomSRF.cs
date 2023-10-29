using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

// 通用渲染管线程序集
namespace UnityEngine.Rendering.Universal
{
    //添加到Volume组件菜单中
    [Serializable, VolumeComponentMenu("奶粉/辉光")]
    public class BloomVC : VolumeComponent
    {
        public FloatParameter 阈值 = new ClampedFloatParameter(0.5f, 0.0f, 1.0f);
        public FloatParameter 软阈值 = new ClampedFloatParameter(0.5f, 0.0f, 1.0f);
        public FloatParameter 强度 = new ClampedFloatParameter(1.0f, 1.0f, 10.0f);
        public ColorParameter 颜色 = new ColorParameter(Color.white);
        public FloatParameter 模糊范围 = new ClampedFloatParameter(0f, 0f, 15f);
        public IntParameter 迭代次数 = new ClampedIntParameter(4, 1, 8);
        public FloatParameter 降采样 = new ClampedFloatParameter(1f, 1f, 10f);
        public BoolParameter Debug = new BoolParameter(false);
    }
}


public class BloomSRF : ScriptableRendererFeature
{
    [System.Serializable]
    public class BloomSettings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        public Shader shader; // 设置后处理Shader
    }

    public BloomSettings settings = new BloomSettings();
    BloomRenderPass bloomScriptablePass;

    public override void Create()
    {
        this.name = "bloom测试"; // 外部显示名字
        bloomScriptablePass =
            new BloomRenderPass(RenderPassEvent.BeforeRenderingPostProcessing, settings.shader); // 初始化Pass
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        bloomScriptablePass.Setup(renderer.cameraColorTarget); // 初始化Pass里的属性
        renderer.EnqueuePass(bloomScriptablePass);
    }
}

public class BloomRenderPass : ScriptableRenderPass
{
    static readonly string k_RenderTag = "Bloom"; // 设置渲染 Tags
    static readonly int TempTargetId = Shader.PropertyToID("_存储阈值的临时贴图"); // 设置储存图像信息
    BloomVC bloomVC; // 传递到volume
    Material bloomMaterial; // 后处理使用材质
    RenderTargetIdentifier cameraColorTexture; // 设置当前渲染目标

    Level[] m_Pyramid;
    const int k_MaxPyramidSize = 16;


    struct Level
    {
        internal int down;
        internal int up;
    }

    static class ShaderIDs
    {
        internal static readonly int BlurOffset = Shader.PropertyToID("_BlurOffset");
        internal static readonly int Threshold = Shader.PropertyToID("_Threshold");
        internal static readonly int ThresholdKnee = Shader.PropertyToID("_ThresholdKnee");
        internal static readonly int Intensity = Shader.PropertyToID("_Intensity");
        internal static readonly int BloomColor = Shader.PropertyToID("_BloomColor");
    }

    public BloomRenderPass(RenderPassEvent evt, Shader bloomShader)
    {
        renderPassEvent = evt; // 设置渲染事件的位置
        var shader = bloomShader; // 输入Shader信息
        
        // 判断如果不存在Shader
        if (shader = null) // Shader如果为空提示
        {
            Debug.LogError("BloomRenderPass没有指定Shader");
            return;
        }

        //如果存在新建材质
        bloomMaterial = CoreUtils.CreateEngineMaterial(bloomShader);

        m_Pyramid = new Level[k_MaxPyramidSize];

        for (int i = 0; i < k_MaxPyramidSize; i++)
        {
            m_Pyramid[i] = new Level
            {
                down = Shader.PropertyToID("_BlurMipDown" + i),
                up = Shader.PropertyToID("_BlurMipUp" + i)
            };
        }
    }

    public void Setup(in RenderTargetIdentifier currentTarget)
    {
        this.cameraColorTexture = currentTarget;
    }

    //后处理的逻辑和渲染核心函数，基本相当于内置管线的OnRenderImage函数
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        // 判断材质是否为空
        if (bloomMaterial == null)
        {
            Debug.LogError("材质初始化失败");
            return;
        }

        // 判断是否开启后处理
        if (!renderingData.cameraData.postProcessEnabled)
        {
            return;
        }

        // 渲染设置
        var stack = VolumeManager.instance.stack; // 传入volume
        bloomVC = stack.GetComponent<BloomVC>(); // 拿到我们的volume
        if (bloomVC == null)
        {
            Debug.LogError(" Volume组件获取失败 ");
            return;
        }


        var cmd = CommandBufferPool.Get(k_RenderTag); // 设置渲染标签
        Render(cmd, ref renderingData); // 设置渲染函数
        context.ExecuteCommandBuffer(cmd); // 执行函数
        CommandBufferPool.Release(cmd); // 释放
    }

    void Render(CommandBuffer cmd, ref RenderingData renderingData)
    {
        ref var cameraData = ref renderingData.cameraData; // 获取摄像机属性
        var camera = cameraData.camera; // 传入摄像机
        var source = cameraColorTexture; // 获取渲染图片
        int buffer0 = TempTargetId; // 渲染结果图片


        int tw = (int)(camera.scaledPixelWidth / bloomVC.降采样.value);
        int th = (int)(camera.scaledPixelHeight / bloomVC.降采样.value);

        Vector4 BlurOffset = new Vector4(bloomVC.模糊范围.value / (float)Screen.width,
            bloomVC.模糊范围.value / (float)Screen.height, 0, 0);
        bloomMaterial.SetVector(ShaderIDs.BlurOffset, BlurOffset);
        bloomMaterial.SetFloat(ShaderIDs.Threshold, bloomVC.阈值.value);
        bloomMaterial.SetFloat(ShaderIDs.ThresholdKnee, bloomVC.软阈值.value);
        bloomMaterial.SetFloat(ShaderIDs.Intensity, bloomVC.强度.value);
        bloomMaterial.SetColor(ShaderIDs.BloomColor, bloomVC.颜色.value);

        //取阈值
        cmd.GetTemporaryRT(buffer0, 
            camera.scaledPixelWidth, camera.scaledPixelHeight, 0,
            FilterMode.Trilinear, RenderTextureFormat.Default);
        cmd.Blit(source, buffer0); 
        cmd.Blit(buffer0, source, bloomMaterial, 0); 

        // 降采样
        RenderTargetIdentifier lastDown = source; //备份

        for (int i = 0; i < bloomVC.迭代次数.value; i++)
        {
            int mipDown = m_Pyramid[i].down;
            int mipUp = m_Pyramid[i].up;
            cmd.GetTemporaryRT(mipDown, tw, th, 0, FilterMode.Bilinear);
            cmd.GetTemporaryRT(mipUp, tw, th, 0, FilterMode.Bilinear);

            cmd.Blit(lastDown, mipDown, bloomMaterial, 1);

            lastDown = mipDown;
            tw = Mathf.Max(tw / 2, 1);
            th = Mathf.Max(th / 2, 1);
        }

        // 升采样
        int lastUp = m_Pyramid[bloomVC.迭代次数.value - 1].down;

        for (int i = bloomVC.迭代次数.value - 2; i >= 0; i--)
        {
            int mipUp = m_Pyramid[i].up;
            cmd.Blit(lastUp, mipUp, 
                bloomMaterial, 2);
            lastUp = mipUp;
        }

        //合并
        if (bloomVC.Debug.value)
        {
            cmd.Blit(lastUp, source, bloomMaterial, 4);
        }
        else
        {
            cmd.SetGlobalTexture("_SourceTex", buffer0);
            cmd.Blit(lastUp, source, bloomMaterial, 3);
        }

        // Cleanup
        for (int i = 0; i < bloomVC.迭代次数.value; i++)
        {
            if (m_Pyramid[i].down != lastUp)
                cmd.ReleaseTemporaryRT(m_Pyramid[i].down);
            if (m_Pyramid[i].up != lastUp)
                cmd.ReleaseTemporaryRT(m_Pyramid[i].up);
        }
    }
}