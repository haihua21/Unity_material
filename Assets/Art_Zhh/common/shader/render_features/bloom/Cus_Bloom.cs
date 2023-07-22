using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
[System.Serializable, VolumeComponentMenu("Custom/Cus_Bloom")] //添加到Volume 目录中
public class Cus_Bloom : VolumeComponent
{
    public BoolParameter isBloom = new BoolParameter(false, true);  //当场景没有Volume时，停止执行 Volume 
    [Tooltip("Strength of the line.")]

   // public TextureParameter NoiseTex = new TextureParameter(null); 
   // [Tooltip("Dirtiness texture to add smudges or dust to the bloom effect.")]  

    public ClampedFloatParameter Threshold = new ClampedFloatParameter(1f,0f,3f,true);      

  

}
