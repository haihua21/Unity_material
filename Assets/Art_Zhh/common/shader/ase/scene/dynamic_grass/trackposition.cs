using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class trackposition : MonoBehaviour
{
    private GameObject[] tracker;
    private Material grassMat;
    private Vector4[] positions;  

    // Start is called before the first frame update
    void Start()
    {
        grassMat = GetComponent<MeshRenderer>().material;
        // tracker = GameObject.Find("tracker");  //查找命名为 tracker 的物体
        tracker = GameObject.FindGameObjectsWithTag("Player");   //查找标签为Player 的物体   
       
         
    }

    // Update is called once per frame
    void Update()
    {
        int PlayerCount = tracker.Length;   //计算player 数量
        // Debug.Log(PlayerCount);        // 打印数量
        positions = new Vector4[PlayerCount];
        for(int i=0; i<PlayerCount; i++)
        {

        // Vector4 trackerPos = tracker[i].GetComponent<Transform>().position;   
        positions[i] = tracker[i].GetComponent<Transform>().position;             
        Debug.Log($"i:{i} x:{positions[i].x},y:{positions[i].y},z:{positions[i].z}");
        }
        
        // grassMat.SetVector("_trackerPosition",trackerPos);   
        Shader.SetGlobalVectorArray("trackerPosition",positions);

    }
}
