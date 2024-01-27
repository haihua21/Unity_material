using System;
using System.Collections;

using UnityEngine;
#if UNITY_EDITOR
    using UnityEditor;
#endif

[RequireComponent(typeof(LODGroup))]
public class DistanceLod : MonoBehaviour
{
    private const float CalcInterval = 0.5f;

    public float[] distances = {20.0f, 30.0f, 40.0f};

    private Camera _camera;
    private int _lastLodIndex = -1;

    private LODGroup _lodGroup;

    private void OnEnable()
    {
        _lodGroup = GetComponent<LODGroup>();
        _camera = Camera.main;

        if ((isActiveAndEnabled && _camera != null && _lodGroup != null))
        {
            var curDistance = Vector3.Distance(transform.position, _camera.transform.position);
            var curLodIndex = GetLodIndexByDistance(curDistance);
            _lastLodIndex = curLodIndex;
            _lodGroup.ForceLOD(_lastLodIndex);
        }

        StartCoroutine(UpdateLodByDistance());
    }

    private IEnumerator UpdateLodByDistance()
    {
        while (isActiveAndEnabled && _camera != null && _lodGroup != null)
        {
            var curDistance = Vector3.Distance(transform.position, _camera.transform.position);
            var curLodIndex = GetLodIndexByDistance(curDistance);
            if (_lastLodIndex != curLodIndex)
            {
                _lastLodIndex = curLodIndex;
                _lodGroup.ForceLOD(_lastLodIndex);
            }
            
            yield return new WaitForSeconds(CalcInterval);
        }
    }

    public void SetDistance(float[] targetDistances)
    {
        distances = targetDistances;
    }

    private int GetLodIndexByDistance(float distance)
    {
        for (var i = 0; i < distances.Length; ++i)
        {
            if (distance <= distances[i])
            {
                return i;
            }
        }

        return distances.Length;
    }

#if UNITY_EDITOR
    [CustomEditor(typeof(DistanceLod))]
    public class DistanceLodEditor : Editor
    {
        private void OnSceneGUI()
        {
            DistanceLod dLOD = target as DistanceLod;
            if (dLOD != null)
            {
                Vector3 pos = dLOD.gameObject.transform.position;
                float dis = Vector3.Distance(Camera.current.transform.position, pos);
                Handles.Label(pos, dis.ToString("F2") + "m");
            }
        }
    }
#endif
}
