using System;
using System.IO;

using UnityEditor;

using UnityEngine;

namespace AssetDiagnose
{
    public class Utils
    {
        public static string FileSizeToString(float fileSize)
        {
            string result = "";
            if (fileSize >= (1 << 20))
            {
                result = string.Format("{0:F} MB", fileSize / 1024f / 1024f);
            }
            else if (fileSize >= (1 << 10))
            {
                result = string.Format("{0:F} KB", fileSize / 1024f);
            }
            else
            {
                result = string.Format("{0:F} B", fileSize);
            }

            return result;
        }

        public static string FullPathToRelative(string path)
        {
            path = PathToStandardized(path);

            path = path.Replace(Application.dataPath, "Assets");

            return path;
        }

        public static string PathToStandardized(string path)
        {
            return path.Replace('\\', '/');
        }

        public static string[] PathStrToArray(string paths)
        {
            paths = paths.Trim('\"');
            return paths.Split(new[] {"\" || \""}, StringSplitOptions.RemoveEmptyEntries);
        }

        public static string PathArrayToStr(string[] paths)
        {
            var pathStr = '\"' + string.Join("\" || \"", paths) + '\"';
            return pathStr;
        }

        public static bool IsPlainTextExt(string ext)
        {
            ext = ext.ToLower();
            return ext.EndsWith(".prefab")
                   || ext.EndsWith(".unity")
                   || ext.EndsWith(".mat")
                   || ext.EndsWith(".asset")
                   || ext.EndsWith(".cs")
                   || ext.EndsWith(".controller")
                   || ext.EndsWith(".anim");
        }

        public static bool IsMetaExt(string ext)
        {
            ext = ext.ToLower();
            return ext.EndsWith(".meta");
        }

        public static void DisplayThreadProgressBar(int totalFiles, int filesFinished)
        {
            string msg = String.Format(@"{0} ({1}/{2})",
                                       Constant.m_progressTitle,
                                       (filesFinished + 1).ToString(),
                                       totalFiles.ToString());
            EditorUtility.DisplayProgressBar(Constant.m_progressTitle, msg, (filesFinished + 1) * 1f / totalFiles);
        }
    }
}
