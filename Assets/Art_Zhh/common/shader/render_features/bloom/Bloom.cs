using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
public class Bloom : MonoBehaviour
{
    #region constData
    const int firstPass = 0;
    const int downPass = 1;
    const int upPass = 2;
    const int mixPass = 3;
    #endregion


    public Shader bloom;
    private Material material;
    [Range(0,8)]
    public int Interations;
    [Range(1,10)]// 已经限定从1开始， 只有开启HDR的才会开启bloom
    public float Threshold =1;
    [Range(0,1)]
    public float SoftThreshold = 0.5f;
    [Range(0,10)]
    public float Intensity = 1;
    RenderTexture[] textures = new RenderTexture[8];
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (!material)
        {
            material = new Material(bloom);
            material.hideFlags = HideFlags.HideAndDontSave;
        }
        material.SetFloat("_Threshold", Threshold);
        material.SetFloat("_Intensity", Intensity);
        float knee = Threshold - SoftThreshold;
        Vector4 filter;
        filter.x = Threshold;
        filter.y = Threshold - knee;
        filter.z = 2 * knee;
        filter.w = 4 * knee + 0.00001f;
        // 将参数，以V4的形式传递进shader,将计算量留在CPU,减少GPU的计算
        material.SetVector("_Filter", filter);


        int width = source.width;
        int height = source.height;
        width /= 2;
        height /= 2;
        RenderTextureFormat format = source.format;
        RenderTexture currentDestination = textures[0] = RenderTexture.GetTemporary(width, height, 0, format);
        Graphics.Blit(source, currentDestination,material,firstPass);
        RenderTexture currentSource = currentDestination;
        int i = 1;
        // 向下采样
        for (; i < Interations; i++)
        {
            width /= 2;
            height /= 2;
            if (height<2)
            {
                break;
            }
            currentDestination = textures[i] = RenderTexture.GetTemporary(width, height, 0, format);
            Graphics.Blit(currentSource, currentDestination,material,downPass);
            currentSource = currentDestination;
        }
        //向上采样
        for (i-=2; i>=0; i--)
        {
            currentDestination = textures[i];
            textures[i] = null;            
            Graphics.Blit(currentSource, currentDestination,material,upPass);
            RenderTexture.ReleaseTemporary(currentSource);
            currentSource = currentDestination;
        }
        material.SetTexture("_SourceTex", source);
        //混合
        Graphics.Blit(currentDestination, destination,material,mixPass);
        RenderTexture.ReleaseTemporary(currentDestination);
    }
}

