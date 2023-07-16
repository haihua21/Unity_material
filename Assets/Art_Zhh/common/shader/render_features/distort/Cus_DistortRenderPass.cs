using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Cus_DistortPass : ScriptableRenderPass
{
    //指定输入输出贴图
    static readonly string renderTag = "Cus_Distort Effects";
    static readonly int MainTexId = Shader.PropertyToID("_MainTex");   // 和shader 对应上
    static readonly int TempTargetId = Shader.PropertyToID("_TempTargetColorTint");

    private Cus_Distort Cus_DistortVolume;
    private Material mat;
    RenderTargetIdentifier currentTarget;

    // 构造函数 
    public Cus_DistortPass(RenderPassEvent passEvent,Shader Cus_DistortShader)
    {
        renderPassEvent = passEvent;
        if(Cus_DistortShader == null)
        {
            Debug.LogError("Shader不存在");
            return;
        }
        mat = CoreUtils.CreateEngineMaterial(Cus_DistortShader);
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
        Cus_DistortVolume = stack.GetComponent<Cus_Distort>();
        if(Cus_DistortVolume == null)
        {
            return;
        }
        if (Cus_DistortVolume.isShow.value == false)
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

        mat.SetFloat("_Distort", Cus_DistortVolume.Distort.value);  
        mat.SetFloat("_DistortScale", Cus_DistortVolume.DistortScale.value);
        mat.SetFloat("_DistortSpeed", Cus_DistortVolume.DistortSpeed.value);          
        mat.SetColor("_baseColor", Cus_DistortVolume.baseColor.value);
        mat.SetTexture("_NormalMap",Cus_DistortVolume.NormalMap.value);

        cmd.SetGlobalTexture(MainTexId, source);
        cmd.GetTemporaryRT(destination, cameraData.camera.scaledPixelWidth, cameraData.camera.scaledPixelHeight, 0, FilterMode.Trilinear, RenderTextureFormat.Default);
        cmd.Blit(source, destination);
        cmd.Blit(destination, source, mat, 0);
    }
}
