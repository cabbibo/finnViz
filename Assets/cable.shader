Shader "Unlit/cable"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _CubeMap("Texture", CUBE) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 localCam : TEXCOORD1;
                float3 ro : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            samplerCUBE _CubeMap;

            


// Taken from https://www.shadertoy.com/view/4ts3z2
float tri(in float x){return abs(frac(x)-.5);}
float3 tri3(in float3 p){return float3( tri(p.z+tri(p.y*1.)), tri(p.z+tri(p.x*1.)), tri(p.y+tri(p.x*1.)));}

            

// Taken from https://www.shadertoy.com/view/4ts3z2
float triNoise3D(float3 p,  float spd)
{
    float z=1.4;
	float rz = 0.;
    float3 bp = p;
	for (float i=0.; i<=3.; i++ )
	{
        float3 dg = tri3(bp*2.);
        p += (dg+_Time.y*.1*spd);

        bp *= 1.8;
		z *= 1.5;
		p *= 1.2;
        //p.xz*= m2;
        
        rz+= (tri(p.z+tri(p.x+tri(p.y))))/z;
        bp += 0.14;
	}
	return rz;
}


float _IntersectionPrecision = .01;

int _NumberSteps = 100;
float _MaxTraceDistance = 1000;


float sdSphere( float3 p, float s ){
  return length(p)-s;
}

float sdCylinderX( float3 p, float3 c )
{
  return length(p.xy-c.yz)-c.x;
}


float sdCylinderZ( float3 p, float3 c )
{
  return length(p.xz-c.xy)-c.z;
}


float2 map( float3 pos ){


    pos = pos.yxz;
    pos.x += triNoise3D(pos * .01 , 1);

   // pos.x += sin(pos.y * .4 + 1.1 + _Time.y *1);
    float a = pos.y;
 float d = 100000;
    for(int i = 0; i<20; i++ ){
        a+= float(i) *  .1;

        float r = .5;
        r *= 1/(.1 + abs(pos.y));

        a *= 3/(3+abs(.3*pos.y));
    float3 fPos = pos + cos( a ) * float3(1,0,0) * r - sin( a) * float3(0,0,1) * r;
        d = min(d,sdCylinderZ( fPos , float3(0 * float(i),0 * float(i),.02)));

        
    }

    d +=  triNoise3D( pos * .1 ,1) * 1 * (1/(.1+10*abs(pos.y)))-.3;
    return float2(d , 12);// float2(length(pos)-20,2);
}






float2 calcIntersection( float3 ro ,  float3 rd ){     
            
               
    float h =  .0001  * 2;
    float t = 0.0;
    float res = -1.0;
    float id = -1.0;

    for( int i = 0; i< 1000; i++ ){
        
        if( h < .0001 || t >10) break;

        float3 pos = ro + rd*t;
        float2 m = map( pos );
        
        h = m.x;
        t += h;
        id = m.y;
        
    }


    if( t <  10 ){ res = t; }
    if( t >  10){ id = -1.0; }

    return float2( res , id );
  

}

float3 calcNormal( in float3 pos ){

        float3 eps = float3( 0.0001, 0.0, 0.0 );
        float3 nor = float3(
            map(pos+eps.xyy).x - map(pos-eps.xyy).x,
            map(pos+eps.yxy).x - map(pos-eps.yxy).x,
            map(pos+eps.yyx).x - map(pos-eps.yyx).x );
        return normalize(nor);

      }
        

float3 render( float3 ro , float3 rd ){

    float3 col = 0;

    float2 res = calcIntersection(ro,rd);
    if( res.y > -.5 ){
        float3 fPos = ro + rd * res.x;

        float3 nor = calcNormal(fPos);
        float3 refl = reflect( rd , nor );
        col = texCUBE(_CubeMap,normalize(refl));
        col *= 1.3; 
        col *= 1-dot( -rd, nor);
        //col = calcNormal( fPos ) * .5 + .5;
    }
    //col = 1;
    return col;
}

            v2f vert (appdata v)
            {
                v2f o;
            

                o.ro  = mul( unity_ObjectToWorld,v.vertex).xyz;;
                o.localCam  = _WorldSpaceCameraPos; //mul( unity_WorldToObject, float4( _WorldSpaceCameraPos ,1 )).xyz;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag (v2f v) : SV_Target
            {
                float3 rd =normalize( v.ro - v.localCam);
                float3 col = render( v.ro , rd );

                return fixed4(col,1);
            }
            ENDCG
        }
    }
}
