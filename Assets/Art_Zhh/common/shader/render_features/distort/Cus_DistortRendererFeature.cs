//指定到RenderFeature

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class Cus_DistortRendererFeature : ScriptableRendererFeature  //RenderFeature中显示名称
{
    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        public Shader shader;
    }
    public Settings settings = new Settings();
    Cus_DistortPass pass;
    public override void Create()
    {
        this.name = "Cus_DistortPass"; 
        pass = new Cus_DistortPass(RenderPassEvent.BeforeRenderingPostProcessing, settings.shader);
        pass.renderPassEvent = settings.renderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        pass.Setup(renderer.cameraColorTarget);
        renderer.EnqueuePass(pass);
    }
}
