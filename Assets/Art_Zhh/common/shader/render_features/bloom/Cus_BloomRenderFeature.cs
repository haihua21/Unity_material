using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Cus_BloomRenderFeature : ScriptableRendererFeature
{
    public enum BloomType
    {
        KawaseBloom,
        DualBloom,
        StandardBloom_test

    }

    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent passEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        public Shader shader;
        public BloomType BloomType;
        public int BloomTimes = 3;        
        public float Threshold = 1.05f;
        public float Intensity = 0.5f;
        public float ThresholdKnee = 0.1f;
        public float Scatter = 0.5f;    // 开放传入一个浮动数
        public int DownSample = 1;   //降采样
        
    }
    private TutorialBloomRenderPass pass;
    [SerializeField]
    public Settings settings = new Settings();
    public override void Create()
    {
        pass = new TutorialBloomRenderPass(settings);
    }
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        pass.renderTarget = renderer.cameraColorTarget;
        renderer.EnqueuePass(pass);
    }
}
public class TutorialBloomRenderPass : ScriptableRenderPass
{
    private Material passMaterial;

    public RenderTargetIdentifier renderTarget;
    private RenderTextureDescriptor renderTextureDescriptor;

    // private Cus_Bloom BloomProcess;

    // private static readonly int MainTexId = Shader.PropertyToID("_MainTex");
    private static readonly int BloomBaseTex = Shader.PropertyToID("_SourceTex");
    private static readonly string tag = "Cus_Bloom";

    private RenderTargetHandle buffer01, buffer02;
    private Cus_BloomRenderFeature.BloomType BloomType;
    private static float Scatter;
    private static int BloomTimes;
    private static float Threshold;
    private static float Intensity;
    private static float ThresholdKnee;
    private static int DownSample;


    public TutorialBloomRenderPass(Cus_BloomRenderFeature.Settings settings)
    {
        this.renderPassEvent = settings.passEvent;

        if (passMaterial == null && settings.shader != null)
        {
            passMaterial = CoreUtils.CreateEngineMaterial(settings.shader);
        }
        BloomType = settings.BloomType;
        Scatter = settings.Scatter;
        BloomTimes =settings.BloomTimes;
        Threshold =settings.Threshold;
        Intensity =settings.Intensity;
        ThresholdKnee =settings.ThresholdKnee;
        DownSample =settings.DownSample;
    }
    /// <summary>
    /// 重写Configure，主要是拿一下【cameraTextureDescriptor】纹理参数
    /// </summary>
    /// <param name="cmd"></param>
    /// <param name="cameraTextureDescriptor"></param>
    public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
    {
        base.Configure(cmd, cameraTextureDescriptor);
        this.renderTextureDescriptor = cameraTextureDescriptor;
        this.renderTextureDescriptor.depthBufferBits = 0;

        buffer01.Init("buffer01");
        buffer02.Init("buffer02");
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (passMaterial == null) return;
        // if (renderingData.cameraData.isSceneViewCamera) return; //Scene视图不予处理
        if (!renderingData.cameraData.postProcessEnabled) return; //摄像机未开启后处理 

        var stack = VolumeManager.instance.stack; //获取全局后处理实例栈
        // BloomProcess = stack.GetComponent<Cus_Bloom>(); //获取我们的扩展组件
        // if (BloomProcess == null) return;

        //cmd执行
        var cmd = CommandBufferPool.Get(tag);

        if (BloomType == Cus_BloomRenderFeature.BloomType.DualBloom)
        {
            DualBloom(cmd);
        }
        else if (BloomType == Cus_BloomRenderFeature.BloomType.KawaseBloom)
        {
            KawaseBloom(cmd);
        }
        else if (BloomType == Cus_BloomRenderFeature.BloomType.StandardBloom_test)
        {
            StandardBloom(cmd);
        }
        context.ExecuteCommandBuffer(cmd);   //提交图形
        CommandBufferPool.Release(cmd);   //回收
    }


    private void KawaseBloom(CommandBuffer cmd)
    {
        var source = renderTarget;   //摄像机图源
        int BloomTex = BloomBaseTex;

        var dsp = renderTextureDescriptor; //获取纹理参数描述符
        var width = dsp.width / DownSample; //降采样宽度
        var height = dsp.height / DownSample; //降采样高度      

        cmd.GetTemporaryRT(BloomTex, renderTextureDescriptor.width, renderTextureDescriptor.height, 0, FilterMode.Bilinear, RenderTextureFormat.ARGBHalf);

         for (int i = 0; i < BloomTimes; i++)
         {
             width = Mathf.Max(width / 3, 1);  //约束图像最小值
             height =Mathf.Max(height / 3, 1);
             cmd.GetTemporaryRT(buffer01.id, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.ARGBHalf); //获取临时RT,降 sampleTex
             cmd.GetTemporaryRT(buffer02.id, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.ARGBHalf);
         }

        passMaterial.SetFloat("_Scatter", 0); //初始化Scatter
        passMaterial.SetFloat("_Threshold", Threshold);
        passMaterial.SetFloat("_Intensity",Intensity);
        passMaterial.SetFloat("_ThresholdKnee",ThresholdKnee);
       
        cmd.Blit(source, BloomTex);  //图像存入_SourceTex，以备合并时调用
        cmd.Blit(source,buffer01.Identifier(),passMaterial,0);  //使用shader的第一个pass进行渲染 ，把来源图source,存入 buffer01
        
        for (int i = 0; i < BloomTimes ; i++) //模糊循环
        {
            passMaterial.SetFloat("_Scatter", (i + 1) * Scatter); //随着迭代次数，Scatter逐渐扩大
            
            cmd.Blit(buffer01.Identifier(), buffer02.Identifier(), passMaterial, 1); //使用shader的第二个pass进行渲染

            var temRT = buffer01; //交换RT
            buffer01 = buffer02;
            buffer02 = temRT;
 
        }
        // cmd.SetGlobalTexture("_SourceTex",BloomTex);  //获取当前摄像机
        cmd.Blit(buffer01.Identifier(),source, passMaterial, 2);  //把最后结果写入摄像机

        cmd.ReleaseTemporaryRT(buffer01.id); //释放临时RT
        cmd.ReleaseTemporaryRT(buffer02.id);
        cmd.ReleaseTemporaryRT(BloomTex);
        
    }

    private void DualBloom(CommandBuffer cmd)
    {
        int width = this.renderTextureDescriptor.width, height = this.renderTextureDescriptor.height;
        var loopCount = BloomTimes;        
        var downSampleRT = new int[loopCount];
        var upSampleRT = new int[loopCount];
        int BloomTex = BloomBaseTex;

        RenderTargetIdentifier tmpRT = renderTarget;

        passMaterial.SetFloat("_BloomRange", Scatter);
        passMaterial.SetFloat("_Threshold", Threshold);
        passMaterial.SetFloat("_Intensity", Intensity);
        //initial
        for (int i = 0; i < loopCount; i++)
        {
            downSampleRT[i] = Shader.PropertyToID("DownSample" + i);//临时图像
            upSampleRT[i] = Shader.PropertyToID("UpSample" + i);//临时图像
        }

        cmd.GetTemporaryRT(BloomTex, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.Default);
        cmd.GetTemporaryRT(buffer01.id, width/2, height/2, 0, FilterMode.Bilinear, RenderTextureFormat.ARGBHalf);

        cmd.Blit(tmpRT, BloomTex);  //图像存入_SourceTex，以备合并时调用
        cmd.Blit(tmpRT, buffer01.id, passMaterial, 5); 
        
        //downSample
        for (int i = 0; i < loopCount ; i++)
        {
            cmd.GetTemporaryRT(downSampleRT[i], width/2, height/2, 0, FilterMode.Bilinear, RenderTextureFormat.ARGBHalf);
            cmd.GetTemporaryRT(upSampleRT[i], width, height, 0, FilterMode.Bilinear, RenderTextureFormat.ARGBHalf);//在down时，顺便把up也申请了
            width = Mathf.Max(width / 2, 1);
            height = Mathf.Max(height / 2, 1);

            cmd.Blit(buffer01.id, downSampleRT[i], passMaterial, 3);
            tmpRT = downSampleRT[i];
        }
        cmd.ReleaseTemporaryRT(buffer01.id);
        //UpSample
        for (int j = loopCount - 1; j >= 0; j--)
        {
            cmd.Blit(tmpRT, upSampleRT[j], passMaterial, 4);
            tmpRT = upSampleRT[j];
        }
        //release
        // cmd.Blit(tmpRT, renderTarget);
        cmd.Blit(tmpRT,renderTarget, passMaterial, 6);  //把最后结果写入摄像机
        cmd.ReleaseTemporaryRT(BloomTex);

        for (int i = 0; i < loopCount; i++)
        {
            cmd.ReleaseTemporaryRT(downSampleRT[i]);
            cmd.ReleaseTemporaryRT(upSampleRT[i]);
        }
    }
    private void StandardBloom(CommandBuffer cmd)
    {
        int width = this.renderTextureDescriptor.width, height = this.renderTextureDescriptor.height;
        var loopCount = BloomTimes;        
        var downSampleRT = new int[loopCount];
        var upSampleRT = new int[loopCount];
        int BloomTex = BloomBaseTex;

        RenderTargetIdentifier tmpRT = renderTarget;
        

        passMaterial.SetFloat("_BloomRange", Scatter);
        passMaterial.SetFloat("_Threshold", Threshold);
        passMaterial.SetFloat("_Intensity", Intensity);
        //initial


        cmd.GetTemporaryRT(BloomTex, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.Default);
        cmd.GetTemporaryRT(buffer01.id, width/2, height/2, 0, FilterMode.Bilinear, RenderTextureFormat.ARGBHalf);


        cmd.Blit(tmpRT, BloomTex);  //图像存入_SourceTex，以备合并时调用
        cmd.Blit(tmpRT, buffer01.id, passMaterial, 5); 


        cmd.ReleaseTemporaryRT(buffer01.id);
        cmd.ReleaseTemporaryRT(BloomTex);

        for (int i = 0; i < loopCount; i++)
        {
            cmd.ReleaseTemporaryRT(downSampleRT[i]);
            cmd.ReleaseTemporaryRT(upSampleRT[i]);
        }
    }
}

