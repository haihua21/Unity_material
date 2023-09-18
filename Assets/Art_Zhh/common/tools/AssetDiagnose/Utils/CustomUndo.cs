using System.Collections.Generic;

using UnityEditor;

using UnityEngine;

namespace AssetDiagnose
{
    public class CustomUndo
    {
        public delegate void Callback();

        List<Object> targetList = new List<Object>();
        List<Callback> callList = new List<Callback>();
        string m_name;

        public CustomUndo(string name)
        {
            m_name = name;
        }

        public void RecordObject(Object obj, Callback call)
        {
            targetList.Add(obj);
            callList.Add(call);
        }

        public void RegisterCreatedObjectUndo(Object obj)
        {
            Undo.RegisterCreatedObjectUndo(obj, m_name);
        }

        public void RegisterDestroyObjectImmediate(Object obj)
        {
            Undo.DestroyObjectImmediate(obj);
        }

        public void Flush()
        {
            Undo.RegisterCompleteObjectUndo(targetList.ToArray(), m_name);
            foreach (var each in callList)
            {
                each();
            }

            targetList.Clear();
            callList.Clear();
        }
    }
}
