using UnityEditor;

using UnityEngine;

namespace AssetDiagnose
{
    public class AssetDiagnoseWnd : EditorWindow
    {
        private Vector2 m_vec2;

        private AssetDiagnoseSetting m_assetDiagnoseSetting => AssetDiagnoseSetting.m_ins;

        [MenuItem("美术/资源诊断", false, 3001)]
        public static void OpenWnd()
        {
            var wnd = GetWindow<AssetDiagnoseWnd>();
            wnd.InitData();
        }

        void InitData()
        {
            AssetDiagnoseSetting.ClearIns();
            m_assetDiagnoseSetting.Init();
        }

        void OnGUI()
        {
            DrawSettingData();

            Repaint();
        }

        void DrawSettingData()
        {
            m_vec2 = GUILayout.BeginScrollView(m_vec2);
            GUILayout.BeginVertical();

            int count = m_assetDiagnoseSetting.m_settingDataList.Count;
            for (int i = 0; i < count; i++)
            {
                GUILayout.BeginVertical("box");

                AssetDiagnoseSettingData data = m_assetDiagnoseSetting.m_settingDataList[i];

                data.m_remark = EditorGUILayout.TextField("备注", data.m_remark);
                data.m_refPath = HopeEditorUtility.DrawPath("引用目录", data.m_refPath);
                data.m_resPath = HopeEditorUtility.DrawPath("资源目录", data.m_resPath);

                GUILayout.BeginHorizontal();
                GUI.color = Color.red;
                if (GUILayout.Button("删除"))
                {
                    m_assetDiagnoseSetting.DelSetting(i);
                    break;
                }

                GUI.color = Color.white;

                if (GUILayout.Button("引用查找"))
                {
                    if (!AssetReferenceWnd.m_isOpened)
                    {
                        AssetDiagnoseResultWnd.OpenWnd<AssetReferenceWnd>(data);
                    }
                    else
                    {
                        AssetDiagnoseResultWnd.OpenWnd<AssetReferenceWnd2>(data);
                    }

                    break;
                }

                if (GUILayout.Button("被引用查找"))
                {
                    if (!AssetDependenciesWnd.m_isOpened)
                    {
                        AssetDiagnoseResultWnd.OpenWnd<AssetDependenciesWnd>(data);
                    }
                    else
                    {
                        AssetDiagnoseResultWnd.OpenWnd<AssetDependenciesWnd2>(data);
                    }

                    break;
                }

                if (GUILayout.Button("检查重复"))
                {
                    AssetDiagnoseResultWnd.OpenWnd<AssetDuplicateWnd>(data);
                    m_assetDiagnoseSetting.DelSetting(i);
                    break;
                }

                GUILayout.EndHorizontal();

                GUILayout.EndVertical();
                EditorGUILayout.Space(15);
            }

            GUILayout.EndVertical();
            GUILayout.EndScrollView();

            GUI.color = Color.green;
            if (GUILayout.Button("添加配置"))
            {
                m_assetDiagnoseSetting.CreateNewSetting();
            }

            if (GUILayout.Button("刷新"))
            {
                AssetDiagnoseSetting.ClearIns();
            }

            if (GUILayout.Button("保存"))
            {
                var cached = m_assetDiagnoseSetting;
                AssetDatabase.DeleteAsset(Constant.m_settingDataPath);
                AssetDatabase.CreateAsset(cached, Constant.m_settingDataPath);
                AssetDiagnoseSetting.ClearIns();
            }

            GUI.color = Color.white;
        }
    }
}
