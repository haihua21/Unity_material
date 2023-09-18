using System.Collections.Generic;

using UnityEditor;

using UnityEngine;

namespace AssetDiagnose
{
    public class Md5Info
    {
        public Object m_target;
        public string m_sizeString;
        public string m_createTime;

        public string m_name { get; }
        public bool m_isFile;

        public Md5Info(FileMd5Info fileMd5Info)
        {
            string assetPath = Utils.FullPathToRelative(fileMd5Info.filePath);
            m_target = AssetDatabase.LoadAssetAtPath<Object>(assetPath);

            m_createTime = fileMd5Info.fileTime;
            m_sizeString = Utils.FileSizeToString(fileMd5Info.fileSize);

            m_isFile = true;
        }

        public Md5Info(string displayName)
        {
            m_name = displayName;
            m_isFile = false;
        }
    }
}
