using System.Collections.Generic;

using UnityEngine;

namespace AssetDiagnose
{
    public interface IAssetInfoBase
    {
        string m_targetAssetPath { get; }
        Object m_target { get; }
        List<Object> m_assetPathList { get; }

        string m_name { get; }
        bool m_fold { get; set; }

        Texture m_icon { get; }

        void AddAssetByPath(string assetPath);
    }
}
