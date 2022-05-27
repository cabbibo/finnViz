using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[ExecuteAlways]
public class SCrip : MonoBehaviour
{


public Transform cam;
    public bool rotateCamera;

    public float radius;
    public float angle;
    public float speed;

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
        if( rotateCamera ){

            float a =  angle*Mathf.Sin(Time.time * speed);

            cam.position = Vector3.left * Mathf.Sin( a ) * radius - Vector3.forward * Mathf.Cos(a) * radius;

            cam.LookAt( Vector3.zero );
        }else{

            transform.rotation = Quaternion.AxisAngle( Vector3.up , .2f*Mathf.Sin(Time.time * 1) );
        }
    }
}
