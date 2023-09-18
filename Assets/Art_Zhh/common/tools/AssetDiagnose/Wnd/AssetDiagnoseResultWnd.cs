using System;
using System.Collections.Generic;
using System.IO;
using System.Threading;

using UnityEditor;
using UnityEditor.IMGUI.Controls;

using UnityEngine;

using Object = UnityEngine.Object;

namespace AssetDiagnose
{
    public class AssetDiagnoseResultWnd : EditorWindow
    {
        protected AssetDiagnoseSettingData m_settingData;
        protected List<JobFileTextSearch> m_jobList = new List<JobFileTextSearch>();

        protected List<IAssetInfoBase> m_assetInfoList = new List<IAssetInfoBase>();
        protected List<IAssetInfoBase> m_allAssetInfoList = new List<IAssetInfoBase>();
        protected bool m_showAll;

        protected SearchField m_searchField;
        protected string m_searchContent;
        protected Vector2 m_vec2;

        protected string[] _title = null;

        protected virtual string[] m_title
        {
            get
            {
                if (_title == null)
                {
                    _title = new[] {"名称", "引用的资源", "隶属"};
                }

                return _title;
            }
        }

        protected float[] _titleColWidth;

        protected virtual float[] m_titleColWidth
        {
            get
            {
                if (_titleColWidth == null)
                {
                    _titleColWidth = new[] {370.0f, 430.0f, 100.0f};
                }

                return _titleColWidth;
            }
        }

        public static void OpenWnd<T>(AssetDiagnoseSettingData settingData) where T : AssetDiagnoseResultWnd
        {
            var wnd = GetWindow<T>();
            wnd.minSize = new Vector2(500, 500);
            wnd.Init(settingData);
            wnd.Focus();
        }

        protected virtual void OnGUI()
        {
            DrawMenu();
            DrawTitle();
            DrawAssetList();
        }

        protected virtual void DrawAssetList()
        {
            m_vec2 = GUILayout.BeginScrollView(m_vec2);
            GUILayout.BeginVertical();

            List<IAssetInfoBase> showedData = m_showAll ? m_allAssetInfoList : m_assetInfoList;


            int index = 0;
            int count = showedData.Count;
            for (int i = 0; i < count; i++)
            {
                IAssetInfoBase assetInfoBase = showedData[i];
                DrawAssetInfo(assetInfoBase, ref index);
                GUI.backgroundColor = Color.white;
            }

            GUILayout.EndVertical();
            GUILayout.EndScrollView();
        }

        void DrawAssetInfo(IAssetInfoBase assetInfoBase, ref int index)
        {
            DrawLine(() =>
                     {
                         var rect = EditorGUILayout.GetControlRect(false, 16, GUILayout.Width(10));
                         assetInfoBase.m_fold = EditorGUI.Foldout(rect, assetInfoBase.m_fold, "");

                         rect = EditorGUILayout.GetControlRect(false, 16, GUILayout.Width(320));
                         EditorGUI.ObjectField(rect, assetInfoBase.m_target, typeof(Object), false);


                         var assetList = assetInfoBase.m_assetPathList;
                         int count = assetList.Count;
                         if (count <= 0)
                         {
                             EditorGUILayout.LabelField("无引用");
                         }
                     },
                     ref index);

            if (assetInfoBase.m_fold)
            {
                var assetList = assetInfoBase.m_assetPathList;
                int count = assetList.Count;

                if (count > 0)
                {
                    for (int i = 0; i < count; i++)
                    {
                        DrawLine(() =>
                                 {
                                     EditorGUILayout.LabelField("", GUILayout.Width(m_titleColWidth[0]));
                                     EditorGUILayout.ObjectField(assetList[i], typeof(GameObject), false, GUILayout.Width(m_titleColWidth[1]));
                                 },
                                 ref index);
                    }
                }
            }
        }

        protected void DrawLine(Action callback, ref int index)
        {
            if (index % 2 == 1)
            {
                GUILayout.BeginHorizontal("box", GUILayout.ExpandWidth(true));
            }
            else
            {
                GUILayout.BeginHorizontal("Box", GUILayout.ExpandWidth(true));
            }

            index++;
            callback?.Invoke();
            GUILayout.EndHorizontal();
        }

        protected void DrawTitle()
        {
            GUILayout.BeginHorizontal("box");
            int count = m_title.Length;
            for (int i = 0; i < count; i++)
            {
                string name = i == 0 ? m_title[i] : "|" + m_title[i];
                EditorGUILayout.LabelField(name, GUILayout.Width(m_titleColWidth[i]));
            }

            GUILayout.EndHorizontal();
        }

        protected void DrawMenu()
        {
            GUILayout.BeginHorizontal();

            m_searchContent = m_searchField.OnToolbarGUI(m_searchContent);

            GUI.color = Color.green;
            if (GUILayout.Button(m_showAll ? "显示全部" : "显示匹配项"))
            {
                m_showAll = !m_showAll;
            }

            if (GUILayout.Button("导出CSV"))
            {
                ExportCSV();
            }

            GUI.color = Color.white;

            GUILayout.EndHorizontal();
        }

        protected void DrawFieldName()
        {
        }

        protected virtual string[] GetFieldName()
        {
            return new string[] {"名字", "引用的资源"};
        }

        protected virtual void Init(AssetDiagnoseSettingData settingData)
        {
            m_settingData = settingData;
            m_searchField = new SearchField();
            m_jobList.Clear();
            m_assetInfoList.Clear();
            m_allAssetInfoList.Clear();
        }

        protected void ExportCSV()
        {
        }

        /// <summary>
        /// 搜集数据
        /// </summary>
        /// <param name="refPath">引用目录</param>
        /// <param name="resPath">资源目录</param>
        protected void CollectReferenceData(string refPath, string resPath)
        {
            m_assetInfoList.Clear();
            m_allAssetInfoList.Clear();
            m_jobList.Clear();

            var resGUIDList = new List<string>();
            m_jobList = DoFilesSearch(refPath, resPath, ref resGUIDList);

            int count = m_jobList.Count;
            for (int i = 0; i < count; i++)
            {
                var job = m_jobList[i];

                AssetInfoBase assetInfoBase = new AssetInfoBase(job.m_path, job.m_comparePartternList);
                m_allAssetInfoList.Add(assetInfoBase);
                if (job.m_comparePartternList.Count > 0)
                {
                    m_assetInfoList.Add(assetInfoBase);
                }
            }
            
            m_assetInfoList.Sort();
            m_allAssetInfoList.Sort();

            EditorUtility.ClearProgressBar();
        }

        protected void CollectDependenciesData(string refPath, string resPath)
        {
            Dictionary<string, AssetInfoBase> assetInfoDict = new Dictionary<string, AssetInfoBase>();
            Dictionary<string, AssetInfoBase> allAssetInfoDict = new Dictionary<string, AssetInfoBase>();
            m_assetInfoList.Clear();
            m_allAssetInfoList.Clear();
            m_jobList.Clear();

            List<string> resGUIDList = new List<string>();

            // 讲引用路径与资源路径调换
            m_jobList = DoFilesSearch(resPath, refPath, ref resGUIDList);

            int count = resGUIDList.Count;
            Debug.LogError($"resGUIDList  count:[{count}]");
            for (int i = 0; i < count; i++)
            {
                var guid = resGUIDList[i];
                if (!allAssetInfoDict.ContainsKey(guid))
                {
                    var assetInfoBase = new AssetInfoBase(AssetDatabase.GUIDToAssetPath(guid), new List<string>());
                    m_allAssetInfoList.Add(assetInfoBase);
                    allAssetInfoDict.Add(guid, assetInfoBase);
                }
            }


            count = m_jobList.Count;
            for (int i = 0; i < count; i++)
            {
                var job = m_jobList[i];


                if (job.m_comparePartternList.Count > 0)
                {
                    // 将引用的资源与被引用资源转换
                    int compareCount = job.m_comparePartternList.Count;
                    for (int compareIndex = 0; compareIndex < compareCount; compareIndex++)
                    {
                        string compareGUID = job.m_comparePartternList[compareIndex];
                        if (!assetInfoDict.ContainsKey(compareGUID))
                        {
                            assetInfoDict.Add(compareGUID, new AssetInfoBase(AssetDatabase.GUIDToAssetPath(compareGUID), new List<string>()));
                        }

                        assetInfoDict[compareGUID].AddAssetByPath(job.m_path);

                        if (allAssetInfoDict.ContainsKey(compareGUID))
                        {
                            allAssetInfoDict[compareGUID].AddAssetByPath(job.m_path);
                        }
                    }
                }
            }

            foreach (var dict in assetInfoDict)
            {
                m_assetInfoList.Add(dict.Value);
            }

            EditorUtility.ClearProgressBar();
        }

        protected List<JobFileTextSearch> DoFilesSearch(string refPath, string resPath, ref List<string> resGUIDList)
        {
            var resFileList = GetFileList(Utils.PathStrToArray(resPath), true);
            resGUIDList = GetGuidFromFileList(resFileList);
            var refFileList = GetFileList(Utils.PathStrToArray(refPath), false);

            var tmp = MultiThreadDoFilesSearch(refFileList, resGUIDList);

            return tmp;
        }

        protected List<JobFileTextSearch> MultiThreadDoFilesSearch(List<string> refFileList, List<string> resFileList)
        {
            List<JobFileTextSearch> jobList = new List<JobFileTextSearch>();
            List<ManualResetEvent> eventList = new List<ManualResetEvent>();

            int numFile = resFileList.Count;
            int numFileFinised = 0;

            Utils.DisplayThreadProgressBar(numFile, numFileFinised);

            int timeout = 10000; // 10 秒超时

            int count = refFileList.Count;
            for (int i = 0; i < count; i++)
            {
                JobFileTextSearch job = new JobFileTextSearch(refFileList[i], resFileList);
                jobList.Add(job);
                eventList.Add(job.m_doneEvent);
                ThreadPool.QueueUserWorkItem(job.ThreadPoolCallback);

                if (eventList.Count >= Environment.ProcessorCount)
                {
                    WaitForDoFile(eventList, timeout);
                    Utils.DisplayThreadProgressBar(numFile, numFileFinised);
                    numFileFinised++;
                }
            }

            while (eventList.Count > 0)
            {
                if (!WaitForDoFile(eventList, timeout))
                {
                    Debug.LogError($"超时，强制打断");
                    break;
                }

                Utils.DisplayThreadProgressBar(numFile, numFileFinised);
                numFileFinised++;
            }

            foreach (var job in jobList)
            {
                if (!string.IsNullOrEmpty(job.m_exception))
                {
                    Debug.LogError(job.m_exception);
                }
            }

            return jobList;
        }

        /// <summary>
        /// 得到资源文件列表
        /// </summary>
        /// <returns></returns>
        protected List<string> GetFileList(string[] filePathArr, bool isRes)
        {
            List<string> fileList = new List<string>();
            EditorUtility.DisplayProgressBar(Constant.m_progressTitle, String.Empty, 0f);

            foreach (var filePath in filePathArr)
            {
                if (!Directory.Exists(filePath))
                {
                    // 是个文件
                    if (IsFileRightExi(filePath, isRes))
                    {
                        fileList.Add(filePath);
                    }

                    continue;
                }

                var allFiles = Directory.GetFiles(filePath, "*", SearchOption.AllDirectories);

                for (var i = 0; i < allFiles.Length; i++)
                {
                    var file = allFiles[i];

                    if (!IsFileRightExi(file, isRes))
                    {
                        continue;
                    }


                    fileList.Add(Utils.PathToStandardized(file));
                }
            }

            EditorUtility.ClearProgressBar();

            return fileList;
        }

        protected bool IsFileRightExi(string file, bool isRes)
        {
            // 是资源， 且meta后缀   continue
            if (isRes && Utils.IsMetaExt(file))
            {
                return false;
            }

            // 不是资源， 且非资源后缀  continue
            if (!isRes && !Utils.IsPlainTextExt(file))
            {
                return false;
            }

            return true;
        }

        /// <summary>
        /// 获取文件列表的GUID
        /// </summary>
        /// <param name="fileList"></param>
        /// <returns></returns>
        protected List<string> GetGuidFromFileList(List<string> fileList)
        {
            List<string> guidList = new List<string>();
            foreach (var file in fileList)
            {
                guidList.Add(AssetDatabase.AssetPathToGUID(file));
            }

            return guidList;
        }

        protected bool[][] GetSearchResultList(int fileCount, int searchCount)
        {
            var ret = new bool[fileCount][];
            for (int i = 0; i < fileCount; i++)
            {
                ret[i] = new bool[searchCount];
            }

            return ret;
        }

        private bool WaitForDoFile(List<ManualResetEvent> events, int timeout)
        {
            int finished = WaitHandle.WaitAny(events.ToArray(), timeout);
            if (finished == WaitHandle.WaitTimeout)
            {
                Debug.Log($"!!!   超时了");
                return false;

                // 超时
            }

            events.RemoveAt(finished);
            return true;
        }
    }
}
