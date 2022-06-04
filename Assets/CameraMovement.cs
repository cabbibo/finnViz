using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[ExecuteAlways]
public class CameraMovement : MonoBehaviour
{


    public Transform cam;
    public bool rotateCamera;

    public float radius;
    public float angle;
    public float speed;

    public Vector3 shake;
    public Vector3 offset;

    public bool pause;
    // Start is called before the first frame update
    void OnEnable()
    {
    #if UNITY_EDITOR 
        EditorApplication.update += Always;
        
    #endif
    }
    
    public void OnDisable(){


    //print("god disabblee");
    #if UNITY_EDITOR 
        EditorApplication.update -= Always;

    #endif
}


void Always(){    
  #if UNITY_EDITOR 

    if(!pause) EditorApplication.QueuePlayerLoopUpdate();
  #endif
}


    // Update is called once per frame
    void Update()
    {
        float a =  (Time.time * speed);
        float a2 =  (Time.time * speed + 121);
        float a3 =  (Time.time * speed + 424221);

        Vector3 fPos = Vector3.zero;

        fPos  = Vector3.left  *( (Mathf.PerlinNoise(a , 0)-.5f) * shake.x + offset.x);
        fPos += Vector3.up * ( (Mathf.PerlinNoise(a2 , 0)-.5f) * shake.y + offset.y);
        fPos += Vector3.forward *( (Mathf.PerlinNoise(a3 , 0)-.5f) * shake.z + offset.z);

        if( rotateCamera ){
            cam.position = fPos;
            cam.LookAt( Vector3.zero );
        }else{
            
           // transform.rotation = Quaternion.AxisAngle( Vector3.up , .1f*Mathf.Sin(Time.time * 1) );
           // transform.Rotate(  Vector3.left * 3.2f*Mathf.Sin(Time.time * 1 + .4f) );

        }
        
    }


}
