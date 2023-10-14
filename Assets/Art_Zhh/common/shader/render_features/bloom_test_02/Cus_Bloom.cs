using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
[System.Serializable, VolumeComponentMenu("Custom/Cus_Bloom")] //添加到Volume 目录中
public class Cus_Bloom : VolumeComponent
{
    public BoolParameter isShow = new BoolParameter(false, true);  //当场景没有Volume时，停止执行 Volume 
    [Tooltip("Strength of the line.")]

    public ClampedFloatParameter Threshold = new ClampedFloatParameter(1.1f,0.1f,2f,true);       

    public MinFloatParameter Intensity = new MinFloatParameter(1, 0,true);
    [Tooltip("The color of the line.")]  

    public ClampedFloatParameter Scatter = new ClampedFloatParameter(0.7f,0.1f,5f,true);
    [Tooltip("The color of the line.")]  

    public MinFloatParameter Radius = new MinFloatParameter(1, 0,true);
    [Tooltip("The color of the line.")]  

    public ColorParameter baseColor = new ColorParameter(Color.white, true);
}
