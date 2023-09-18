using System;
using System.Collections.Generic;
using System.IO;
using System.Threading;

namespace AssetDiagnose
{
    public class JobFileTextSearch
    {
        public string m_path;
        private List<string> m_patternList = new List<string>();
        public List<string> m_comparePartternList = new List<string>();

        public ManualResetEvent m_doneEvent;
        public string m_exception;

        public JobFileTextSearch(string path, List<string> patternList)
        {
            m_path = path;
            m_patternList = patternList;
            m_doneEvent = new ManualResetEvent(false);
        }

        public void ThreadPoolCallback(System.Object threadContext)
        {
            try
            {
                string content = File.ReadAllText(m_path);
                int count = m_patternList.Count;
                for (int i = 0; i < count; i++)
                {
                    if (content.Contains(m_patternList[i]))
                    {
                        m_comparePartternList.Add(m_patternList[i]);
                    }
                }
            }
            catch (Exception e)
            {
                m_exception = m_path + "\n" + e.Message;
                throw;
            }

            m_doneEvent.Set();
        }
    }
}
