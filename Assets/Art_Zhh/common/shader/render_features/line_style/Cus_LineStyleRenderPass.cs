using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Cus_LineStylePass : ScriptableRenderPass
{
    //指定输入输出贴图
    static readonly string renderTag = "Cus_LineStyle Effects";
    static readonly int MainTexId = Shader.PropertyToID("_MainTex");   // 和shader 对应上
    static readonly int TempTargetId = Shader.PropertyToID("_TempTargetColorTint");

    private Cus_LineStyle Cus_lineStyleVolume;
    private Material mat;
    RenderTargetIdentifier currentTarget;

    // 构造函数 
    public Cus_LineStylePass(RenderPassEvent passEvent,Shader Cus_lineStyleShader)
    {
        renderPassEvent = passEvent;
        if(Cus_lineStyleShader == null)
        {
            Debug.LogError("Shader不存在");
            return;
        }
        mat = CoreUtils.CreateEngineMaterial(Cus_lineStyleShader);
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
        Cus_lineStyleVolume = stack.GetComponent<Cus_LineStyle>();
        if(Cus_lineStyleVolume == null)
        {
            return;
        }
        if (Cus_lineStyleVolume.isShow.value == false)
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

        mat.SetFloat("_lineStrength", Cus_lineStyleVolume.lineStrength.value);
        mat.SetColor("_lineColor", Cus_lineStyleVolume.lineColor.value);
        mat.SetColor("_baseColor", Cus_lineStyleVolume.baseColor.value);

        cmd.SetGlobalTexture(MainTexId, source);
        cmd.GetTemporaryRT(destination, cameraData.camera.scaledPixelWidth, cameraData.camera.scaledPixelHeight, 0, FilterMode.Trilinear, RenderTextureFormat.Default);
        cmd.Blit(source, destination);
        cmd.Blit(destination, source, mat, 0);
    }
}
