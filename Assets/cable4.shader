Shader "Unlit/cable4"
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

float opU( float d1, float d2 )
{
    return min(d1,d2);
}

float2 opU( float2 d1, float2 d2 )
{
	return (d1.x<d2.x) ? d1 : d2;
}


float2x2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return float2x2(c, -s, s, c);
}


void pR(inout float2 p, float a) {
	p = cos(a)*p + sin(a)*float2(p.y, -p.x);
}
#define PI 3.14159
// Repeat around the origin by a fixed angle.
// For easier use, num of repetitions is use to specify the angle.
float pModPolar(inout float2 p, float repetitions) {
float angle = 2.*PI/repetitions;
float a = atan2(p.y, p.x) + angle/2.;
float r = length(p);
float c = floor(a/angle);
a = (a%angle) - angle/2.;
p = float2(cos(a), sin(a))*r;
// For an odd number of repetitions, fix cell index of the cell in -x direction
// (cell index would be e.g. -5 and 5 in the two halves of the cell):
if (abs(c) >= (repetitions/2.)) c = abs(c);
return c;
}

float sdCylinder( float3 p, float2 h )
{
  float2 d = abs(float2(length(p.xy),p.z)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float2 cable(float3 pos) {
	const int iterations = 2;
    
    pos *= 3;

  //  pos.x += 2*sin(pos.y * .1);
    float y = pos.y;
    //pos.z -= 0.5;
    pos.z = abs(pos.z);
    pos.y = (pos.y% 1.) - .5;
    float2 dist = float2(10., 0.);
    
    float startIterations = 4.;
    float startX = 1.;
    float startRadius = startX/2.;
    float adder = 5.;
    pR(pos.xz,2* -y/4. + _Time.y);

    for (int i = 1; i < iterations+1; i++) 
    {
        float index = pModPolar(pos.xz, startIterations+adder*float(i));

    	float2 size = float2(startRadius, 100.);
        pos.x -= startX;
        dist = opU(dist, float2(sdCylinder(pos.xzy, size), float(i)));
        
        startX /= 2.;
        startRadius /=3.;
    }
    
    return dist/3;
}


float GetDist(float3 p) {

   float2 uv2 = (p.xy * float2(1 , 16./9.)) * .2+ .5;
    uv2 = clamp(uv2,0,1);

    float4 s = tex2D(_MainTex, uv2.xy );


    float2 uv = p.xz;

    uv.x += 2;
    uv.y += 1;
    
   // uv.x = abs(uv.x) -.1;

   // uv.y = abs(uv.y) + 1;
    float time = 12. + _Time.y; // 0.3 * h21(floor(10. * uv))  //<-very cool extremely laggy
    float2 q = float2(1,0);
    
    float th = .01 * p.y - 0.6 * time;
    float n = 9.;
    float m = -0.0 * length(uv) + 1.8;
    for (float i = 0.; i < n; i++) { 
        uv -= m * q;
        th += .5 * p.y + 0.25 * time  + triNoise3D( float3(uv * .1,1) , 1 );
        uv = mul(Rot(th) ,uv);
        uv.x = abs(uv.x)-   .01;
        m *= 0.3 * cos(8. * length(uv)) +  .1;// + 0.05 * cos(0.4 * p.y - 0.6 * _Time.y);
        m *= triNoise3D( float3(uv.y,0,0) ,1) + 1;
        //m += m * cos(_Time.y);
    }
    
    float d = length(uv) - .1 * m;

    // d -= triNoise3D( float3(uv.x,uv.y,0) ,1) * .2 ;

    //d += s.w * .1;
    
    //float d = length(uv)- 0.5;
    
    return .3  * d;
}

float2 smoothU( float2 d1, float2 d2, float k)
{
    float a = d1.x;
    float b = d2.x;
    float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
    return float2( lerp(b, a, h) - k*h*(1.0-h), lerp(d2.y, d1.y, pow(h, 2.0)));
}

float2 map( float3 pos ){


    pos = pos.yxz;


    float3 ogPos = pos;

    //pos.z += 1;
    pos.x = (pos.x+1000 + 1*sin( pos.y * .3)) % 1 - .5;

    //pos.y += floor( (pos.x+1.5) /3 ) * 3;



   // pos.x += sin(pos.y * .4 + 1.1 + _Time.y *1);
    float a = pos.y;
 float2 d = float2(100000,-1000);

 d = cable(pos);//GetDist(pos);
 //d.y = 1;
    float2 uv2 = (ogPos.yx * float2(1 , 16./9.)) * .2+ .5;
    uv2 = clamp(uv2,0,1);

    float4 s = tex2D(_MainTex, uv2.xy );
float2 logo = float2((1-s.w) -.5 + clamp(abs(pos.z)-.1,0,10)  ,2);
 d = smoothU( float2(d.x,1) , logo , .7 + (1-abs(pos.y * .2)));//min(d , 1-s.w );



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
            
               
    float h =  .0001  * 2;
    float t = 0.0;
    float res = -1.0;
    float id = -1.0;

    for( int i = 0; i< 40; i++ ){
        
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
        col *= 2.3; 
        col *= 1-dot( -rd, nor);


                float2 uv2 = (fPos.xy * float2(1 , 16./9.)) * .2+ .5;
    uv2 = clamp(uv2,0,1);

    float4 s = tex2D(_MainTex, uv2.xy );

    float3 col2 = 2*s.xyz;

    col = lerp( col , col2 , pow(res.y-1,2));
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
