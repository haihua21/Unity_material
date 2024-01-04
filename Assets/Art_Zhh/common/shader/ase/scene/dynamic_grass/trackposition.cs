using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class trackposition : MonoBehaviour
{
     private GameObject tracker;
    private Material grassMat;

    // Start is called before the first frame update
    void Start()
    {
        grassMat = GetComponent<MeshRenderer>().material;
        tracker =GameObject.Find("tracker");
    }

    // Update is called once per frame
    void Update()
    {
        Vector3 trackerPos = tracker.GetComponent<Transform>().position;  //挂载物体需要命名成 tracker 
        grassMat.SetVector("_trackerPosition",trackerPos);
    }
}
