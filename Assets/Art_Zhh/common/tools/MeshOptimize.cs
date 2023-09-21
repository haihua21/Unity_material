using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System;
using System.Reflection;
using System.IO;
using Object = UnityEngine.Object;
using UnityEditor.VersionControl;
 
public class MeshOptimize : Editor
{
    [MenuItem("美术/MeshOptimize(网格优化)/ClearMeshColor(清除模型顶点色)")]
    static void ClearMeshColor()
    {
        MeshOptimizeMethod(true, false);
    }
 
    [MenuItem("美术/MeshOptimize(网格优化)/ClearMeshUV23(清除模型UV23)")]
    static void ClearMeshUV23()
    {
        MeshOptimizeMethod(false, true);
    }
 
    [MenuItem("美术/MeshOptimize(网格优化)/ClearMeshColorUV23(清除模型顶点色和UV23)")]
    static void ClearMeshColorUV23()
    {
        MeshOptimizeMethod(true, true);
    }
 
    static void MeshOptimizeMethod(bool clearColor, bool clearUV23)
    {
        var objs = Selection.gameObjects;
        for (int i = 0; i < objs.Length; i++)
        {
            var obj = Selection.activeGameObject;
 
            foreach (var item in obj.GetComponentsInChildren<SkinnedMeshRenderer>(true))
            {
                //清除顶点色
                if (clearColor)
                {
                    item.sharedMesh.colors = null;
                }
                //清除uv2/uv3
                if (clearUV23)
                {
                    item.sharedMesh.uv2 = null;
                    item.sharedMesh.uv3 = null;
                }
            }
 
 
            foreach (var item in obj.GetComponentsInChildren<MeshFilter>(true))
            {
                //清除顶点色
                if (clearColor)
                {
                    item.sharedMesh.colors = null;
                }
                //清除uv2/uv3
                if (clearUV23)
                {
                    item.sharedMesh.uv2 = null;
                    item.sharedMesh.uv3 = null;
                }
            }
 
            ExportModel(obj);
            //如果导出新模型路径不在源模型路径，需要调用下面注释的代码刷新源模型的显示
            //AssetDatabase.ImportAsset(AssetDatabase.GetAssetPath(obj));//重新导入下，因为数据存在内存中，不重新导入，inspector视图会显示没有顶点色 和 uv23，编译后才会显示
        }
        AssetDatabase.Refresh();
    }
 
    static void ExportModel(Object obj, string sourcePath = "", string targetPath = "")
    {
        //空则通过asset获取路径
        if (string.IsNullOrEmpty(sourcePath))
        {
            sourcePath = AssetDatabase.GetAssetPath(obj);
        }
        //空表示直接覆盖原文件
        if (string.IsNullOrEmpty(targetPath))
        {
            targetPath = sourcePath;
        }
 
        //缓存meta文件，因为fbxexport会删掉初始的meta文件
        string tempFileName = Path.GetTempFileName();
        File.Copy($"{sourcePath}.meta", tempFileName, true);
 
        //反射获取导出类
        Type t = Assembly.Load("Unity.Formats.Fbx.Editor").GetType("UnityEditor.Formats.Fbx.Exporter.ModelExporter");
        //实例化导出对象
        var export = Activator.CreateInstance(t);
        //设置获取函数的条件
        BindingFlags flags = BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Instance;
        //获取导出的函数
        MethodInfo methidInfo = t.GetMethod("ExportObject", flags);
 
        //导出设置修改，默认的不保留原model 的设置
        //反射获取设置类
        Type settingType = Assembly.Load("Unity.Formats.Fbx.Editor").GetType("UnityEditor.Formats.Fbx.Exporter.ExportModelSettingsSerialize");
        //实例化设置对象
        var setting = Activator.CreateInstance(settingType);
        // !!! !!!以下逻辑修改preserveImportSettings值，使导出时使用源文件的ImportSetting，但是没有效果，debug到info的值是对的，不清楚是不是跟派生类有关系，父类的此属性是直接返回的false，派生类重写了此属性的返回
        //获取要修改的参数
        //FieldInfo info = settingType.GetField("preserveImportSettings", BindingFlags.NonPublic | BindingFlags.Default | BindingFlags.Instance);
        //修改参数      
        //info.SetValue(setting, true);
        //获取要执行的函数,设置导出格式为 Binary ，提供 ASCII和Binary两张格式，前者文件体积过大
        MethodInfo SetExportFormatMethod = settingType.GetMethod("SetExportFormat", BindingFlags.Public | BindingFlags.Default | BindingFlags.Instance);
        SetExportFormatMethod.Invoke(setting, new object[] { 1 });//枚举无法调用，直接用int值代替
 
        //函数传参赋值
        object[] args = new object[]
        {
            targetPath,
            obj,
            setting
        };
        //执行函数
        methidInfo.Invoke(export, args);
 
 
        //路径不同，拷贝meta文件，即导入设置过去。路径相同则从上面缓存的文件中拷贝回来
        if (sourcePath != targetPath )
        {
            File.Copy($"{sourcePath}.meta", $"{targetPath}.meta", true);
        }
        else
        {
            File.Copy(tempFileName, $"{targetPath}.meta", true);
        }
        AssetDatabase.Refresh();
    }
}