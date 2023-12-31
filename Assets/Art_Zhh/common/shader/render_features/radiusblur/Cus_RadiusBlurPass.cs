using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Cus_RadiusBlurPass : ScriptableRenderPass
{
    //指定输入输出贴图
    static readonly string renderTag = "Cus_RadiusBlur Effects";             //设置渲染 Tags
    static readonly int MainTexId = Shader.PropertyToID("_MainTex");   // 设置主贴图 和shader 对应上
    static readonly int TempTargetId = Shader.PropertyToID("_TempTargetColorTint");

    private Cus_RadiusBlur Cus_RadiusBlurVolume;
    private Material mat;
    RenderTargetIdentifier currentTarget;

    // 构造函数 
    public Cus_RadiusBlurPass(RenderPassEvent passEvent,Shader Cus_RadiusBlurShader)     //输入渲染位置
    {
        renderPassEvent = passEvent;
        if(Cus_RadiusBlurShader == null)
        {
            Debug.LogError("Shader不存在");
            return;
        }
        mat = CoreUtils.CreateEngineMaterial(Cus_RadiusBlurShader);
    }

    //初始化
    public void Setup(in RenderTargetIdentifier currentTarget)
    {
        this.currentTarget = currentTarget;
    }

    // 执行，当条件全部都满足的时候，就获取CommandBuffer ，并调用渲染方法，最后释放CommandBuffer
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if(mat == null)
        {
            return;
        }
        if(!renderingData.cameraData.postProcessEnabled)
        {
            return;
        }
        VolumeStack stack = VolumeManager.instance.stack;
        Cus_RadiusBlurVolume = stack.GetComponent<Cus_RadiusBlur>();
        if(Cus_RadiusBlurVolume == null)
        {
            return;
        }
        if (Cus_RadiusBlurVolume.isShow.value == false)
        {
            return;
        }
        CommandBuffer cmd = CommandBufferPool.Get(renderTag);
        Render(cmd, ref renderingData);
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }
    
    //渲染，把shader 里面参数设置给需要的材质球
    private void Render(CommandBuffer cmd,ref RenderingData renderingData)
    {

        ref CameraData cameraData = ref renderingData.cameraData;
        Camera camera = cameraData.camera;
        RenderTargetIdentifier source = currentTarget;
        int destination = TempTargetId;
        
        mat.SetFloat("_Level", Cus_RadiusBlurVolume.Level.value);
        mat.SetFloat("_CenterX", Cus_RadiusBlurVolume.CenterX.value); 
        mat.SetFloat("_CenterY", Cus_RadiusBlurVolume.CenterY.value);  
        mat.SetFloat("_BufferRadius", Cus_RadiusBlurVolume.BufferRadius.value);           
        
        

        cmd.SetGlobalTexture(MainTexId, source);
        cmd.GetTemporaryRT(destination, cameraData.camera.scaledPixelWidth, cameraData.camera.scaledPixelHeight, 0, FilterMode.Trilinear, RenderTextureFormat.Default);
        cmd.Blit(source, destination);
        cmd.Blit(destination, source, mat, 0);
    }
}
