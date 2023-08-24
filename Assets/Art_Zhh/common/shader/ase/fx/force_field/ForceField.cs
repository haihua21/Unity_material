 using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode()] //不运行也能执行脚本
public class ForceField : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        Shader.SetGlobalVector("HitPosition",transform.position); //传递transform.坐标 到材质参数,需要改变shader 里变量为 Global 类型
        Shader.SetGlobalFloat("HitSize",transform.lossyScale.x);  //传递transform.缩放 到材质参数
    }
}
