Shader "Unlit/cable2"
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


float sdBox( float3 p, float3 b )
{
  float3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdPlane( float3 p, float3 n, float h )
{
  // n must be normalized
  return dot(p,n) + h;
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
float opS( float d1, float d2 ) { return max(-d1,d2); }


// ROTATION FUNCTIONS TAKEN FROM
//https://www.shadertoy.com/view/XsSSzG
float3x3 xrotate(float t) {
  return float3x3(1.0, 0.0, 0.0,
                0.0, cos(t), -sin(t),
                0.0, sin(t), cos(t));
}

float3x3 yrotate(float t) {
  return float3x3(cos(t), 0.0, -sin(t),
                0.0, 1.0, 0.0,
                sin(t), 0.0, cos(t));
}

float3x3 zrotate(float t) {
    return float3x3(cos(t), -sin(t), 0.0,
                sin(t), cos(t), 0.0,
                0.0, 0.0, 1.0);
}


float3x3 fullRotate( float3 r ){
 
   return xrotate( r.x ) * yrotate( r.y ) * zrotate( r.z );
    
}



float2x2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return float2x2(c, -s, s, c);
}




float rand(float n){return frac(sin(n) * 43758.5453123);}

float noise(float p){
	float fl = floor(p);
  float fc = frac(p);
	return lerp(rand(fl), rand(fl + 1.0), fc * fc * (3.0 - 2.0 * fc));
}

float smin(float a, float b, float k)
{
    return -(log(exp(k*-a)+exp(k*-b))/k);
}

float GetDist(float3 p) {

   float time = 12. + _Time.y; // 0.3 * h21(floor(10. * uv))  //<-very cool extremely laggy


    float calmness =( sin(time * .1) +1)/2;

    calmness = 1;

    // MAKE SURE THIS RATIO IS EXACT
    float2 uv2 = (p.xy * float2(1 , 2)) * .2+ .5;
    uv2 = clamp(uv2,0,1);

   // float4 s = tex2D(_MainTex, uv2.xy );


//p *= .4;
    float2 uv = p.xz;

    float2 tmpUV = uv;

    float d = 1000;
 


    // For each cable
    for( int b = 0; b < 5; b++ ){
    

    // cable id
    float cid = float(b);

    // reset our 'space'
    uv = tmpUV;

    float tNoise1 =    triNoise3D( float3(p.y * .01,cid*10,0) ,1 ); 
    //uv.x = abs(uv.x) -.1;
   // uv.x -= sin(cid + time * .1 *(sin( cid * 100 ) + 3))*(tNoise1 * 3-2) + sin(  p.y*(2+sin(float(b) *20)) * .6  +(float(b)*100) + time ) - sin(float(b) * 202)*2 - .5;// (sin(float(b)+1.3) * .5 + float(b) * 10) * (sin(float(b) + 131) + time) *4 -.5;
    uv.x -= noise(p.y  * (.04 * (cid+4)) + cid*100 + time * .1)  * 2 -1;//
    uv.x -= noise(p.y  * (.2 * (cid+4)) + cid*100 + time * .1)  * .3 -.1;//
    uv.x -= noise(p.y  * (.03 * (cid+4)) + cid*100 + time * .1)  * 8 -6;//

    //uv.y = abs(uv.y) - 1;
    float2 q = float2(1,0);
    
    float th = .4 * sin(cid*20) * p.y - .6 * time;
    float n = 8.;
    float m = 0 * length(uv)+1.8;// +1.5*(sin(_Time.y*.67+230) + 1.1) ;
    
    for (float i = 0.; i < n; i++) { 
        float fn =  float(i);

        uv -= m * q;
        th += 0.5 * p.y *   (sin(time*.1+fn+20) + 1.1) + ( (calmness * .5 + .3) * time);
        uv = mul(Rot(th) ,uv);
        uv.x = abs(uv.x * 1)-.1*calmness;//-.1 * 1*(sin(uv.y*4));
        m *=.05*cos(8. * length(uv)) + (sin(time * .1 + cid) * .25 * calmness + .25 * calmness + .04 );//.55;// +  0.2 * (sin(time * .1 + fn) + 1.1);// + 0.05 * cos(0.4 * p.y - 0.6 * _Time.y);
    
        //m += m * cos(_Time.y);
    }

     /*   float th = 0.4 * p.y - 0.6 * time;
    float n = 9.;
    float m = -0.0 * length(uv) + 1.8;
    for (float i = 0.; i < n; i++) { 
        uv -= m * q;
        th += 0.5 * p.y + 0.05 * time;
        uv = Rot(th) * uv;
        uv.x = abs(uv.x);
        m *= 0.05 * cos(8. * length(uv)) +  0.55;// + 0.05 * cos(0.4 * p.y - 0.6 * iTime);
        //m += m * cos(iTime);
    }*/
    
     d = smin(d,length(uv) - 3 * m,(sin(cid+time) * 4 + 6));

    //d = length(uv) - 1. * m;
    //d += s.w * .1;
    
    //float d = length(uv)- 0.5;

    }
    
    return .3  * d;
}
float2 opU( float2 d1, float2 d2 ){
    
  return (d1.x<d2.x) ? d1 : d2;
    
}float2 smoothU( float2 d1, float2 d2, float k)
{
    float a = d1.x;
    float b = d2.x;
    float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
    return float2( lerp(b, a, h) - k*h*(1.0-h), lerp(d2.y, d1.y, pow(h, 2.0)));
}

float2 map( float3 pos ){


    pos = pos.yxz;


   // pos.x += triNoise3D(pos * .01 , 1);

   // pos.x += sin(pos.y * .4 + 1.1 + _Time.y *1);
    float a = pos.y;
 float2 d = float2(100000,-1000);

 d.x = GetDist(pos);
    float2 uv2 = (pos.yx * float2(1 , 16./9.)) * .2+ .5;
    uv2 = clamp(uv2,0,1);

    /*float4 s = tex2D(_MainTex, uv2.xy );
float2 logo = float2((1-s.w) -.01  ,2);

logo.x = opS(  sdPlane( pos, float3(0,0,1) ,.2),logo.x );
logo.x = opS(  sdPlane( pos, float3(0,0,-1) ,.2),logo.x );
logo.x += triNoise3D(pos * .2 ,1) * .8;// *(sin(_Time.y*.87+440) + 1.1);
*/


 d = float2(d.x,1);
 //d=smoothU( float2(d.x,1) , logo , .6);//min(d , 1-s.w );



    float3 p = pos;
        //p.yz = ((p.yz+1)%2)-1; 

for( int i =0; i < 4; i++ ){


    p = abs(p);

//p = mul( xrotate(p.x) , pos );
}


      //  d = min(d,sdCylinderZ( p , float3(0,0,.1)));

   // d +=  triNoise3D( pos * .1 ,1) * 1 * (1/(.1+10*abs(pos.y)))-.3;
    return d;//float2(d , 12);// float2(length(pos)-20,2);
}






float2 calcIntersection( float3 ro ,  float3 rd ){     
            
    float ip = .001;//* (1.1+sin(_Time.y));
    float h =  ip  * 2;
    float t = 0.0;
    float res = -1.0;
    float id = -1.0;

    for( int i = 0; i< 100; i++ ){
        
        if( h < ip || t >60) break;

        float3 pos = ro + rd*t;
        float2 m = map( pos );
        
        h = m.x;
        t += h;
        id = m.y;
        
    }


    if( t <  60 ){ res = t; }
    if( t >  60){ id = -1.0; }

    return float2( res , id );
  

}

float3 calcNormal( in float3 pos ){

        float3 eps = float3( 0.01, 0.0, 0.0 );
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
        col *= 2.3; 
        col *= 1-dot( -rd, nor);


                float2 uv2 = (fPos.xy * float2(1 , 16./9.)) * .2+ .5;
    uv2 = clamp(uv2,0,1);

    float4 s = tex2D(_MainTex, uv2.xy );

    float3 col2 = s.xyz;

    col = lerp( col , col2 , res.y-1);
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
