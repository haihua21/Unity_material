using System;
using System.Collections.Generic;
using System.IO;

using UnityEditor;

using UnityEngine;

namespace AssetDiagnose
{
    public class HopeEditorUtility
    {
#region 文件相关

        /// <summary>
        /// 读取文件的内容
        /// </summary>
        /// <returns></returns>
        public static string ReadAllFileContent(string filePath)
        {
            string content = "";
            if (!File.Exists(filePath)) return content;

            FileStream fileStream = File.OpenRead(filePath);
            StreamReader reader = new StreamReader(fileStream);
            content = reader.ReadToEnd();
            fileStream.Close();
            reader.Close();
            return content;
        }

        /// <summary>
        /// 将内容写入文件
        /// </summary>
        /// <param name="filePath"></param>
        /// <param name="content"></param>
        /// <param name="autoRepeat">true则会替换之前内容，false则在文本后追加content内容</param>
        public static void WriteContentToFile(string filePath, string content, bool autoRepeat = false)
        {
            FileStream fileStream = null;

            if (autoRepeat) fileStream = File.Open(filePath, FileMode.Create);
            else fileStream = File.Open(filePath, FileMode.Append);

            StreamWriter writer = new StreamWriter(fileStream);

            writer.WriteLine(content);

            writer.Close();
            fileStream.Close();
        }

        /// <summary>
        /// 递归获取指定路径下的所有文件
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="path"></param>
        /// <param name="parttern"></param>
        /// <param name="list"></param>
        public static List<string> GetFiles(string path, string parttern)
        {
            List<string> list = new List<string>();
            string[] files = Directory.GetFileSystemEntries(path, parttern, SearchOption.AllDirectories);

            for (int i = 0; i < files.Length; i++)
            {
                string file = files[i];
                list.Add(file);
            }

            return list;
        }

        /// <summary>
        /// 检查创建路径
        /// </summary>
        public static void CheckCreateDir(string dir)
        {
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
        }

        /// <summary>
        /// 读取Texture
        /// </summary>
        /// <param name="file_path"></param>
        /// <returns></returns>
        public static Texture2D ReadTexture2D(string file_path)
        {
            //创建文件读取流
            FileStream fileStream = new FileStream(file_path, FileMode.Open, FileAccess.Read);
            fileStream.Seek(0, SeekOrigin.Begin);

            //创建文件长度缓冲区
            byte[] bytes = new byte[fileStream.Length];

            //读取文件
            fileStream.Read(bytes, 0, (int)fileStream.Length);

            //释放文件读取流
            fileStream.Close();
            fileStream.Dispose();
            fileStream = null;

            //创建Texture
            int width = 300;
            int height = 372;
            Texture2D texture = new Texture2D(width, height);
            texture.LoadImage(bytes);
            return texture;
        }

        public static bool Exists(string file_path)
        {
            return File.Exists(file_path);
        }

        public static bool IsDirectory(string path)
        {
            return (Path.GetExtension(path) == "") ? true : false;
        }

#endregion

#region Editor功能相关

        public static void DrawTitleContent(string[] titles, ref int index, params System.Action[] callbacks)
        {
            GUILayout.BeginHorizontal();
            int count = titles.Length;
            for (int i = 0; i < count; i++)
            {
                GUI.color = i == index ? Color.green : Color.white;
                if (GUILayout.Button(titles[i]))
                {
                    index = i;
                }

                GUI.color = Color.white;
            }

            GUILayout.EndHorizontal();

            callbacks[index]?.Invoke();
        }

        static Color defaultcolor = GUI.color;

        public static GUIStyle RichTextStyle
        {
            get
            {
                if (_style == null)
                {
                    _style = new GUIStyle("IN Label");
                    _style.richText = true;
                    _style.padding = new RectOffset(0, 0, 0, 0);
                }

                return _style;
            }
        }

        static GUIStyle _style;

        /// <summary>
        /// 获取场景实例对象的资源路径
        /// </summary>
        /// <param name="instanceObject"></param>
        /// <returns></returns>
        public static string GetAssetPath(GameObject instanceObject)
        {
            UnityEngine.Object parentObject = PrefabUtility.GetCorrespondingObjectFromSource(instanceObject);
            string path = AssetDatabase.GetAssetPath(parentObject);
            if (path.IndexOf("Resources") > -1)
            {
                path = path.Substring(path.IndexOf("Resources") + 10);
            }

            path = path.Replace(".prefab", "");
            return path;
        }

        public static void SetColorBegin(Color c)
        {
            defaultcolor = GUI.color;
            GUI.color = c;
        }

        public static void SetColorEnd()
        {
            GUI.color = defaultcolor;
        }

        public static string DrawPath(string label, string targetPath)
        {
            var rect = EditorGUILayout.GetControlRect(true,
                                                      16 * targetPath.Split('\n').Length + 3,
                                                      GUILayout.Width(500));

            targetPath = EditorGUI.TextField(rect, label, targetPath);
            if ((Event.current.type == EventType.DragUpdated || Event.current.type == EventType.DragExited)
                && rect.Contains(Event.current.mousePosition))
            {
                DragAndDrop.visualMode = DragAndDropVisualMode.Generic;
                if (Event.current.type == EventType.DragUpdated)
                {
                    return targetPath;
                }
                else if (!targetPath.Contains(DragAndDrop.paths[0])
                         && DragAndDrop.paths != null
                         && DragAndDrop.paths.Length > 0)
                {
                    if (targetPath.Length > 0) targetPath += "\n";
                    targetPath += DragAndDrop.paths[0];
                }
            }

            return targetPath;
        }

        public static void DisplayProgressBar(string[] files,
                                              System.Action<int> actionCallback,
                                              System.Action finishCallback = null,
                                              string title = "匹配资源中")
        {
            int startIndex = 0;
            DateTime cachedTime = DateTime.Now;
            EditorApplication.update = delegate()
            {
                if (files.Length <= 0)
                {
                    EditorApplication.update = null;
                    finishCallback?.Invoke();
                    return;
                }

                string file = files[startIndex];
                bool isCancel
                    = UnityEditor.EditorUtility.DisplayCancelableProgressBar(title,
                                                                             file,
                                                                             (float)startIndex / (float)files.Length);

                actionCallback(startIndex);

                startIndex++;
                if (isCancel || startIndex >= files.Length)
                {
                    UnityEditor.EditorUtility.ClearProgressBar();
                    EditorApplication.update = null;
                    startIndex = 0;

                    TimeSpan ts = DateTime.Now - cachedTime;
                    Debug.Log(" 本次  花了: " + (ts.TotalMilliseconds * 1.0f / 1000) + " 秒，unity才缓过来");

                    finishCallback?.Invoke();
                }
            };
        }

        public static string GetObjectGUID(UnityEngine.Object obj)
        {
            string tmpPath = AssetDatabase.GetAssetPath(obj);
            string tmpGUID = AssetDatabase.AssetPathToGUID(tmpPath);
            return tmpGUID;
        }

        public static string GetObjectPath(UnityEngine.Object obj)
        {
            string tmpPath = AssetDatabase.GetAssetPath(obj);
            return tmpPath;
        }

#endregion
    }
}
