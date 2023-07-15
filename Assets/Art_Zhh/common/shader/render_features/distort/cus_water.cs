using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
[System.Serializable, VolumeComponentMenu("Custom/Cus_Water")] //添加到Volume 目录中
public class Cus_Water : VolumeComponent
{
    public BoolParameter isShow = new BoolParameter(false, true);  //当场景没有Volume时，停止执行 Volume 
    [Tooltip("Strength of the line.")]

    public TextureParameter NormalMap = new TextureParameter(null); 
    [Tooltip("Dirtiness texture to add smudges or dust to the bloom effect.")]    

    public MinFloatParameter Distort = new MinFloatParameter(1, 0,true);
    [Tooltip("The color of the line.")]  

    public MinFloatParameter DistortScale = new MinFloatParameter(1, 0,true);
    [Tooltip("The color of the line.")]  

    public MinFloatParameter DistortSpeed = new MinFloatParameter(1, 0,true);
    [Tooltip("The color of the line.")]  

    public ColorParameter baseColor = new ColorParameter(Color.white, true);
}
