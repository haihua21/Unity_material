namespace UnityEngine.Rendering.LWRP
{
    /// <summary>
    /// Copy the given color buffer to the given destination color buffer.
    ///
    /// You can use this pass to copy a color buffer to the destination,
    /// so you can use it later in rendering. For example, you can copy
    /// the opaque texture to use it for distortion effects.
    /// </summary>
    internal class BlitPass : UnityEngine.Rendering.Universal.ScriptableRenderPass
    {
        public enum RenderTarget
        {
            Color,
            RenderTexture,
        }

        public Material blitMaterial = null;
        public int blitShaderPassIndex = 0;
        public FilterMode filterMode { get; set; }

        private RenderTargetIdentifier source { get; set; }
        private UnityEngine.Rendering.Universal.RenderTargetHandle destination { get; set; }

        // private LayerMask layerMask;
        // private FilteringSettings _filteringSettings;

        UnityEngine.Rendering.Universal.RenderTargetHandle m_TemporaryColorTexture;
        string m_ProfilerTag;

        /// <summary>
        /// Create the CopyColorPass
        /// </summary>
        public BlitPass(UnityEngine.Rendering.Universal.RenderPassEvent renderPassEvent,
                        Material blitMaterial,
                        int blitShaderPassIndex,
                        string tag

            // , LayerMask layerMask
            )
        {
            this.renderPassEvent = renderPassEvent;
            this.blitMaterial = blitMaterial;
            this.blitShaderPassIndex = blitShaderPassIndex;

            // this.layerMask = layerMask;
            m_ProfilerTag = tag;
            m_TemporaryColorTexture.Init("_TemporaryColorTexture");

            // _filteringSettings = new FilteringSettings(RenderQueueRange.all, layerMask);
        }

        /// <summary>
        /// Configure the pass with the source and destination to execute on.
        /// </summary>
        /// <param name="source">Source Render Target</param>
        /// <param name="destination">Destination Render Target</param>
        public void Setup(RenderTargetIdentifier source, UnityEngine.Rendering.Universal.RenderTargetHandle destination)
        {
            this.source = source;
            this.destination = destination;
        }

        /// <inheritdoc/>
        public override void Execute(ScriptableRenderContext context,
                                     ref UnityEngine.Rendering.Universal.RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);
            cmd.Clear();

            RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;
            opaqueDesc.depthBufferBits = 0;

            // cmd.ClearRenderTarget(true, true, Color.black, 1.0f);
            // context.ExecuteCommandBuffer(cmd);
            // cmd.Clear();

            // ScriptableCullingParameters parameters;
            // if (!renderingData.cameraData.camera.TryGetCullingParameters(out parameters))
            //     return;
            // parameters.cullingMask = (uint)layerMask.value;
            // var cullResults = context.Cull(ref parameters);

            // var drawSetting = CreateDrawingSettings(new ShaderTagId("UniversalForward"), ref renderingData,
            //     renderingData.cameraData.defaultOpaqueSortFlags);
            //
            // var stateBlock = new RenderStateBlock(RenderStateMask.Nothing);
            // context.DrawRenderers(cullResults, ref drawSetting, ref _filteringSettings, ref stateBlock);

            // Can't read and write to same color target, create a temp render target to blit. 
            if (destination == UnityEngine.Rendering.Universal.RenderTargetHandle.CameraTarget)
            {
                cmd.GetTemporaryRT(m_TemporaryColorTexture.id, opaqueDesc, filterMode);
                Blit(cmd, source, m_TemporaryColorTexture.Identifier(), blitMaterial, blitShaderPassIndex);
                Blit(cmd, m_TemporaryColorTexture.Identifier(), source);
            }
            else
            {
                Blit(cmd, source, destination.Identifier(), blitMaterial, blitShaderPassIndex);
            }

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        /// <inheritdoc/>
        public override void FrameCleanup(CommandBuffer cmd)
        {
            if (destination == UnityEngine.Rendering.Universal.RenderTargetHandle.CameraTarget)
                cmd.ReleaseTemporaryRT(m_TemporaryColorTexture.id);
        }
    }
}
