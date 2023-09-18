using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;

using UnityEditor;

using UnityEngine;

using Object = UnityEngine.Object;

namespace AssetDiagnose
{
    public class FileMd5Info
    {
        public string filePath;
        public string fileLength;
        public string fileTime;
        public long fileSize;
        public string md5;
    }

    public class AssetDuplicateWnd : AssetDiagnoseResultWnd
    {
        private List<Md5Info> m_md5Infos = new List<Md5Info>();

        protected override string[] m_title
        {
            get
            {
                if (_title == null)
                {
                    _title = new[] {"名称", "文件大小", "创建时间"};
                }

                return _title;
            }
        }

        protected override float[] m_titleColWidth
        {
            get
            {
                if (_titleColWidth == null)
                {
                    _titleColWidth = new[] {230.0f, 130.0f, 130.0f};
                }

                return _titleColWidth;
            }
        }

        protected override void Init(AssetDiagnoseSettingData settingData)
        {
            base.Init(settingData);
            m_md5Infos.Clear();

            var resFileList = GetFileList(Utils.PathStrToArray(settingData.m_resPath), true);
            var fileList = GetFileMd5Infos(resFileList);
            if (fileList == null || fileList.Count == 0)
            {
                return;
            }

            var groups = fileList.GroupBy(info => info.md5).Where(g => g.Count() > 1);

            foreach (var group in groups)
            {
                Md5Info extraAssetInfo = new Md5Info($"重复的文件数:[{group.Count()}]");
                m_md5Infos.Add(extraAssetInfo);

                foreach (var md5Info in group)
                {
                    Md5Info assetInfo = new Md5Info(md5Info);
                    m_md5Infos.Add(assetInfo);
                }
            }

            EditorUtility.ClearProgressBar();
        }

        protected override void DrawAssetList()
        {
            m_vec2 = GUILayout.BeginScrollView(m_vec2);
            GUILayout.BeginVertical();

            int count = m_md5Infos.Count();
            int lineIndex = 0;
            for (int i = 0; i < count; i++)
            {
                Md5Info md5Info = m_md5Infos[i];

                DrawMd5Info(md5Info, ref lineIndex);
            }

            GUILayout.EndVertical();
            GUILayout.EndScrollView();
        }

        private void DrawMd5Info(Md5Info md5Info, ref int lineIndex)
        {
            DrawLine(() =>
                     {
                         if (md5Info.m_isFile)
                         {
                             EditorGUILayout.ObjectField(md5Info.m_target,
                                                         typeof(Object),
                                                         false,
                                                         GUILayout.Width(m_titleColWidth[0]));
                             EditorGUILayout.LabelField(md5Info.m_sizeString, GUILayout.Width(m_titleColWidth[1]));
                             EditorGUILayout.LabelField(md5Info.m_createTime, GUILayout.Width(m_titleColWidth[2]));
                         }
                         else
                         {
                             EditorGUILayout.LabelField(md5Info.m_name, GUILayout.Width(m_titleColWidth[0]));
                         }
                     },
                     ref lineIndex);
        }

        private List<FileMd5Info> GetFileMd5Infos(List<string> fileArray)
        {
            var fileList = new List<FileMd5Info>();

            for (int i = 0; i < fileArray.Count;)
            {
                string file = fileArray[i];
                if (string.IsNullOrEmpty(file))
                {
                    i++;
                    continue;
                }

                EditorUtility.DisplayProgressBar(Constant.m_progressTitle, file, i * 1f / fileArray.Count);
                try
                {
                    using (var md5 = MD5.Create())
                    {
                        FileInfo fileInfo = new FileInfo(file);
                        using (var stream = File.OpenRead(fileInfo.FullName))
                        {
                            FileMd5Info info = new FileMd5Info();
                            info.filePath = fileInfo.FullName;
                            info.fileSize = fileInfo.Length;
                            info.fileTime = fileInfo.CreationTime.ToString("yyyy-MM-dd HH:mm:ss");
                            info.md5 = BitConverter.ToString(md5.ComputeHash(stream)).ToLower();
                            fileList.Add(info);
                        }
                    }

                    i++;
                }
                catch (Exception e)
                {
                    if (!EditorUtility.DisplayDialog(Constant.m_errorTitle,
                                                     file + "\n" + e.Message,
                                                     Constant.m_continueStr,
                                                     Constant.m_cancelStr))
                    {
                        EditorUtility.ClearProgressBar();
                        return null;
                    }
                }
            }

            return fileList;
        }
    }
}
