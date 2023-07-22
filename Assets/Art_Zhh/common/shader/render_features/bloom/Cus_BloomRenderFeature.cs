//指定到RenderFeature

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class Cus_BloomRenderFeature : ScriptableRendererFeature  //RenderFeature中显示名称
{
    [System.Serializable]
    public class Settings                                                       //初始设置
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;  //设置渲染顺序
        public Shader shader;                                                      //设置后处理Shader
    }
    public Settings settings = new Settings();

    Cus_BloomPass pass;                                                       //设置渲染Pass
    public override void Create()                                  
    {
        this.name = "Cus_BloomPass";                                         
        pass = new Cus_BloomPass(RenderPassEvent.BeforeRenderingPostProcessing, settings.shader);
        pass.renderPassEvent = settings.renderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)  //Pass执行逻辑
    {
        pass.Setup(renderer.cameraColorTarget);
        renderer.EnqueuePass(pass);                                         //初始化Pass属性
    }
}
