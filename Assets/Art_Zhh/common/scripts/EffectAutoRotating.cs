using UnityEngine;

public class EffectAutoRotating : MonoBehaviour
{
    public Vector3 XYZspeed;

    void Update()
    {
        // transform.Rotate(Vector3.right, Time.deltaTime * XYZspeed.x, Space.Self);
        // transform.Rotate(Vector3.up, Time.deltaTime * XYZspeed.y, Space.Self);
        // transform.Rotate(Vector3.forward, Time.deltaTime * XYZspeed.z, Space.Self);
        transform.Rotate(XYZspeed * Time.deltaTime, Space.Self);
    }
}
