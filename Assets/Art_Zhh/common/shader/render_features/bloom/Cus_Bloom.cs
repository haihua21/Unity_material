using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

[System.Serializable, VolumeComponentMenu("Custom/Cus_Bloom")] //添加到Volume 目录中
public class Cus_Bloom : VolumeComponent //, IPostProcessComponent
{
    public IntParameter BloomTimes = new ClampedIntParameter(1, 0, 5);
    public FloatParameter BloomRange = new ClampedFloatParameter(1.0f, 0.0f, 5.0f);
    public IntParameter donwSample = new ClampedIntParameter(2, 1, 16);

    //public FloatParameter intensity = new ClampedFloatParameter(1, 0, 10);
    public FloatParameter Threshold = new ClampedFloatParameter(0.5f, 0, 3);
    public FloatParameter centerY = new ClampedFloatParameter(0.5f, 0, 1);
}
