 using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode()] //不运行也能执行脚本
public class ForceField : MonoBehaviour
{
    // Start is called before the first frame update
    public ParticleSystem ps;  //声明一个粒子系统,  公有变量
    public string triggerTag = "ForceField";   //声明一个标签
    public float clicksPerSecond = 0.1f;    //点击时间间隔
    public int AffectorAmount = 20; 
   
    private float clickTimer = 0.0f;   // 私有变量
    private ParticleSystem.Particle[] particles;  //私有变量数组
    private Vector4[] positions;  
    private float[] sizes;

    void Start()
    {
        
    }
    void DoRayCast()   //事件 DorayCast() 逻辑
    {
        RaycastHit hitInfo;
        Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);

        if (Physics.Raycast(ray,out hitInfo,1000))
        {
            if(hitInfo.transform.CompareTag(triggerTag))   // 判断是否在标签内
           {
            ps.transform.position =hitInfo.point;
            ps.Emit(1);  // 生成一个粒子
           }
           // transform.position =hitInfo.point;   //点击扩散
        }
    }

    // Update is called once per frame
    void Update()
    {
        clickTimer += Time.deltaTime;
        
        if(Input.GetMouseButton(0))  // 鼠标点击事件
        {
           if (clickTimer > clicksPerSecond)  //当 clickTimer 大于 0.2f时候
        {
            clickTimer = 0.0f;       // 重新归零
            DoRayCast();             // 跳转执行事件 DorayCast()
        }
           
        }
        var ps_main = ps.main;  //拿到粒子的 main 模块
        ps_main.maxParticles = AffectorAmount;
        particles = new ParticleSystem.Particle[AffectorAmount];   //初始化变量，生成20个容量数组
        positions= new Vector4[AffectorAmount];
        sizes = new float[AffectorAmount];
        ps.GetParticles(particles);
        for(int i=0; i< AffectorAmount;i++)   // 拿到每个粒子的 位置和大小
        {
            positions[i] = particles[i].position;
            sizes[i] = particles[i].GetCurrentSize(ps);
        }

          Shader.SetGlobalVectorArray("HitPosition",positions);  // 传送positions 整段数组,到材质 HitPosition
          Shader.SetGlobalFloatArray("HitSize",sizes);           // 传送整段数组
          Shader.SetGlobalFloat("AffectorAmount",AffectorAmount);
          //Shader.SetGlobalVector("HitPosition",positions[0]);    // 传送第一个数组
          //Shader.SetGlobalFloat("HitSize",sizes[0]);
       // Shader.SetGlobalVector("HitPosition",transform.position); //传递transform.坐标 到材质参数,需要改变shader 里变量为 Global 类型
       // Shader.SetGlobalFloat("HitSize",transform.lossyScale.x);  //传递transform.缩放 到材质参数
        
    }
}
