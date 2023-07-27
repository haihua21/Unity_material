using UnityEngine;
using UnityEngine.Experimental.Rendering.Universal;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class RenderToTexture : ScriptableRendererFeature
{
    [System.Serializable]
    public class RenderSetting
    {
        public LayerMask layerMask = -1;
        public Material material;
        public int passIndex;
    }

    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent @event = RenderPassEvent.AfterRenderingPrePasses;
        public RenderQueueType renderQueueType = RenderQueueType.Opaque;
        public RenderSetting targetRenderSetting;
        public RenderSetting coverRenderSetting;
        public string cmdName;
        public string textureName;
        public Color clearColor = Color.clear;
    }

    public Settings settings = new Settings();

    private RenderToTexturePass pass;
    private RenderTargetHandle destination;

    public override void Create()
    {
        this.pass = new RenderToTexturePass(this.settings);
        this.pass.renderPassEvent = this.settings.@event;
        this.destination.Init(this.settings.textureName);
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        this.pass.Setup(this.destination);
        renderer.EnqueuePass(this.pass);
    }
}
