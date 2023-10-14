using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Cus_BloomPass : ScriptableRenderPass
{
    //指定输入输出贴图
    static readonly string renderTag = "Cus_Bloom Effects";
    static readonly int MainTexId = Shader.PropertyToID("_MainTex");   // 和shader 对应上
    static readonly int TempTargetId = Shader.PropertyToID("_TempTargetColorTint");

    private Cus_Bloom Cus_BloomVolume;
    private Material mat;
    RenderTargetIdentifier currentTarget;

    // 构造函数 
    public Cus_BloomPass(RenderPassEvent passEvent,Shader Cus_BloomShader)
    {
        renderPassEvent = passEvent;
        if(Cus_BloomShader == null)
        {
            Debug.LogError("Shader不存在");
            return;
        }
        mat = CoreUtils.CreateEngineMaterial(Cus_BloomShader);
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
        Cus_BloomVolume = stack.GetComponent<Cus_Bloom>();
        if(Cus_BloomVolume == null)
        {
            return;
        }
        if (Cus_BloomVolume.isShow.value == false)
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

        ref CameraData cameraData = ref renderingData.cameraData;   //获取摄像机属性
        Camera camera = cameraData.camera;                          //传入摄像机  
        RenderTargetIdentifier source = currentTarget;           //获取渲染图片
        int destination = TempTargetId;                         //渲染结果图片
        
        mat.SetFloat("_Threshold", Cus_BloomVolume.Threshold.value);  //
        mat.SetFloat("_Scatter", Cus_BloomVolume.Scatter.value); 
        mat.SetFloat("_Intensity", Cus_BloomVolume.Intensity.value);  
        mat.SetFloat("_Radius", Cus_BloomVolume.Radius.value);          
        mat.SetColor("_baseColor", Cus_BloomVolume.baseColor.value);
       

        cmd.SetGlobalTexture(MainTexId, source);  // 获取当前摄像机渲染的图片
        cmd.GetTemporaryRT(destination, cameraData.camera.scaledPixelWidth, cameraData.camera.scaledPixelHeight, 0, FilterMode.Trilinear, RenderTextureFormat.Default);
        cmd.Blit(source, destination);    //设置后处理
        cmd.Blit(destination, source, mat, 0);  //传入夜色校正
    }
}
