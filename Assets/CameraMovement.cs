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
    void LateUpdate()
    {
        float a =   (Time.time * speed);
        float a2 =  (Time.time * speed *.93f+ 121);
        float a3 =  (Time.time * speed * .85f+ 424221);

        Vector3 fPos = Vector3.zero;

        fPos  = Vector3.left  *(    ( Mathf.Sin(a  ) + Mathf.Sin(a  * .35f +414) )   * shake.x + offset.x);
        fPos += Vector3.up * (      ( Mathf.Sin(a2 ) + Mathf.Sin(a2 * .39f+102) ) * shake.y + offset.y);
        fPos += Vector3.forward *(  ( Mathf.Sin(a3 ) + Mathf.Sin(a3 * .43f+445) )  * shake.z + offset.z);

        if( rotateCamera ){
            cam.position = fPos;
            cam.LookAt( Vector3.zero );

            //cam.position = Vector3.left * Mathf.Sin( Time.time * speed ) * offset.z  - Vector3.forward * Mathf.Cos( Time.time * speed ) * offset.z;
  
        }else{
            
         //   transform.rotation = Quaternion.AxisAngle( Vector3.up , .1f*(Mathf.Sin(Time.time * 1.1f)+ Mathf.Sin(Time.time * .57f + 121 )) ) ;
          //  transform.Rotate(  Vector3.left * 5.2f*(Mathf.Sin(Time.time * 1 + 44.4f) + Mathf.Sin(Time.time * .5f + 155 ) ));

        }
        
    }


}
