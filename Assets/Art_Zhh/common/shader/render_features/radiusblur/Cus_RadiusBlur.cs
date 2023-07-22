using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
[System.Serializable, VolumeComponentMenu("Custom/Cus_RadiusBlur")] //添加到Volume 目录中
public class Cus_RadiusBlur : VolumeComponent
{
    public BoolParameter isShow = new BoolParameter(false, true);  //当场景没有Volume时，停止执行 Volume 
    [Tooltip("Strength of the line.")]

   // public TextureParameter NoiseTex = new TextureParameter(null); 
   // [Tooltip("Dirtiness texture to add smudges or dust to the bloom effect.")]  

    public ClampedFloatParameter Level = new ClampedFloatParameter(10f,1f,30f,true);       

    public ClampedFloatParameter CenterX = new ClampedFloatParameter(0.5f,0f,1f,true);    

    public ClampedFloatParameter CenterY = new ClampedFloatParameter(0.5f,0f,1f,true);   

    public ClampedFloatParameter BufferRadius = new ClampedFloatParameter(1f,0f,1f,true);    

    // public ColorParameter baseColor = new ColorParameter(Color.white, true);
}
