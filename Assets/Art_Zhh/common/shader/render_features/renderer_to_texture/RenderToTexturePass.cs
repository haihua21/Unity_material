using System.Collections.Generic;

using UnityEngine;
using UnityEngine.Experimental.Rendering.Universal;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

class RenderToTexturePass : ScriptableRenderPass
{
    private RenderTargetHandle destination;
    private FilteringSettings filteringSettings;
    private Material material;
    private int passIndex;
    private FilteringSettings coverFilteringSettings;
    private Material coverMaterial;
    private int coverPassIndex;
    private string cmdName;
    private string textureName;
    private new Color clearColor;

    private List<ShaderTagId> _ShaderTagIdList = new List<ShaderTagId>();

    public RenderToTexturePass(RenderToTexture.Settings param)
    {
        var renderQueueRange = param.renderQueueType == RenderQueueType.Transparent
                                   ? RenderQueueRange.transparent
                                   : RenderQueueRange.opaque;

        this.filteringSettings = new FilteringSettings(renderQueueRange, param.targetRenderSetting.layerMask);
        this.material = param.targetRenderSetting.material;
        this.passIndex = param.targetRenderSetting.passIndex;
        this.coverFilteringSettings = new FilteringSettings(renderQueueRange, param.coverRenderSetting.layerMask);
        this.coverMaterial = param.coverRenderSetting.material;
        this.coverPassIndex = param.coverRenderSetting.passIndex;
        this.cmdName = param.cmdName;
        this.textureName = param.textureName;
        this.clearColor = param.clearColor;

        _ShaderTagIdList.Add(new ShaderTagId("SRPDefaultUnlit"));
        _ShaderTagIdList.Add(new ShaderTagId("UniversalForward"));
        _ShaderTagIdList.Add(new ShaderTagId("UniversalForwardOnly"));
        _ShaderTagIdList.Add(new ShaderTagId("LightweightForward"));
    }

    public void Setup(RenderTargetHandle destination)
    {
        this.destination = destination;
    }

    // This method is called before executing the render pass.
    // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
    // When empty this render pass will render to the active camera render target.
    // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
    // The render pipeline will ensure target setup and clearing happens in an performance manner.
    public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
    {
        RenderTextureDescriptor descriptor = cameraTextureDescriptor;
        descriptor.msaaSamples = 1;

        //
        cmd.GetTemporaryRT(this.destination.id, descriptor, FilterMode.Point);
        this.ConfigureTarget(this.destination.Identifier());
        this.ConfigureClear(ClearFlag.All, this.clearColor);
    }

    // Here you can implement the rendering logic.
    // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
    // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
    // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        CommandBuffer cmd = CommandBufferPool.Get(this.cmdName);

        var sortFlags = renderingData.cameraData.defaultOpaqueSortFlags;
        var drawSettings = this.CreateDrawingSettings(this._ShaderTagIdList, ref renderingData, sortFlags);

        ref CameraData cameraData = ref renderingData.cameraData;
        Camera camera = cameraData.camera;

        // if (cameraData.xrRendering)
        // {
        //     context.StartMultiEye(camera);
        // }

        // 绘制遮挡（有时需要目标被遮挡）
        if (this.coverFilteringSettings.layerMask != 0)
        {
            drawSettings.overrideMaterial = this.coverMaterial;
            drawSettings.overrideMaterialPassIndex = this.coverPassIndex;
            context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref this.coverFilteringSettings);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
        }

        // 绘制目标
        drawSettings.overrideMaterial = this.material;
        drawSettings.overrideMaterialPassIndex = this.passIndex;
        context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref this.filteringSettings);

        cmd.SetGlobalTexture(this.textureName, this.destination.id);
        context.ExecuteCommandBuffer(cmd);

        CommandBufferPool.Release(cmd);
    }

    /// Cleanup any allocated resources that were created during the execution of this render pass.
    public override void FrameCleanup(CommandBuffer cmd)
    {
        if (this.destination != RenderTargetHandle.CameraTarget)
        {
            cmd.ReleaseTemporaryRT(this.destination.id);
            this.destination = RenderTargetHandle.CameraTarget;
        }
    }
}
