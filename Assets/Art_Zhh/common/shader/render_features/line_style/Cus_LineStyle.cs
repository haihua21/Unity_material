using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
[System.Serializable, VolumeComponentMenu("Custom/Cus_LineStyle")] //添加到Volume 目录中
public class Cus_LineStyle : VolumeComponent
{
    public BoolParameter isShow = new BoolParameter(false, true);  //当场景没有Volume时，停止执行 Volume 
    [Tooltip("Strength of the line.")]
    public MinFloatParameter lineStrength = new MinFloatParameter(1, 0,true);
    [Tooltip("The color of the line.")]
    public ColorParameter lineColor = new ColorParameter(Color.black, true);
    [Tooltip("The color of the background.")]
    public ColorParameter baseColor = new ColorParameter(Color.white, true);
}
