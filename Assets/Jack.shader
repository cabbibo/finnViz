Shader "Unlit/jack"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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


//-----------------------------------------------------------------------------
// Mathx3s utils
//-----------------------------------------------------------------------------
#define HASHSCALE1 443.8975

float hash (float n)
{
	return frac(sin(n)*43758.5453);
}

float noise (in float3 x)
{
	float3 p = floor(x);
	float3 f = frac(x);

	f = f*f*(3.0-2.0*f);

	float n = p.x + p.y*57.0 + 113.0*p.z;

	float res = lerp(lerp(lerp( hash(n+  0.0), hash(n+  1.0),f.x),
						lerp( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
					lerp(lerp( hash(n+113.0), hash(n+114.0),f.x),
						lerp( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
	return res;
}




float fbm(float3 p)
{
   return noise(p*.06125)*.5 + noise(p*.125)*.25 + noise(p*.25)*.125 + noise(p*.4)*.2;
}

float length2( float2 p )
{
	return sqrt( p.x*p.x + p.y*p.y );
}

float length8( float2 p )
{
	p = p*p; p = p*p; p = p*p;
	return pow( p.x + p.y, 1.0/8.0 );
}


float Disk( float3 p, float3 t )
{
    float2 q = float2(length2(p.xy)-t.x,p.z*0.5);
    return max(length8(q)-t.y, abs(p.z) - t.z);
}

//==============================================================
// otaviogood's noise from https://www.shadertoy.com/view/ld2SzK
//--------------------------------------------------------------
// This spiral noise works by successively adding and rotating sin waves while increasing frequency.
// It should work the same on all computers since it's not based on a hash function like some other noises.
// It can be much faster than other noise functions if you're ok with some repetition.
const float nudge = 0.9;	// size of perpendicular floattor
	// pythagorean theorem on that perpendicular to maintain scale
float SpiralNoiseC(float3 p)
{
    float normalizer = 1.0 / sqrt(1.0 + nudge*nudge);

    float n = 0;	// noise amount
    float iter = 2.0;
    for (int i = 0; i < 8; i++)
    {
        // add sin and cos scaled inverse with the frequency
        n += -abs(sin(p.y*iter) + cos(p.x*iter)) / iter;	// abs for a ridged look
        // rotate by adding perpendicular and scaling down
        p.xy += float2(p.y, -p.x) * nudge;
        p.xy *= normalizer;
        p.x += _Time.y * .03;
        // rotate on other axis
        p.xz += float2(p.z, -p.x) * nudge;
        p.xz *= normalizer;
        p.z += _Time.y * .04;
        p.y += _Time.y * .05;
        // increase the frequency
        iter *= 1.733733;
    }
  //  n = 1;
    return n;
}

float NebulaNoise(float3 p)
{
    float final = abs( length(p.xyz) - 4   )  ;//Disk(p.xzy,float3(2.0,1.8,1.25));
   //final += fbm(p*90 + float3(0,_Time.y,0));

   final += abs( length(p.xyz-float3(1,0,0)) - 1   );
    //final += 3*triNoise3D(p.xyz * .1,1);
   //final += SpiralNoiseC(p.yxz*0.5123+100.0)*3.0;
   final += 1*triNoise3D(p.xyz * 1,1);
  //  final += triNoise3D(p.xyz * .1,1);
   // final *= final * final * 100000000;
    
    
    return final;
}


float GetDensity( float3 p ){

	return NebulaNoise(p);//.5-length(p)*.1+10*fbm(p);
}

float scene(float3 p)
{	
	float d;
    
    /*= .1-length(p)*.05+fbm2(p*1);
	 d += .1-length(p-float3(4,0,0))*.05+fbm2(p*1);
	 d += .1-length(p-float3(-6,0,0))*.05+fbm2(p*1);

    //d *= d * d * d * 10;

    d = clamp(d,-10,10);//saturate(d);

*/
    d = NebulaNoise(p);
    return d;
}

float hash12(float2 p)
{
	float3 p3  = frac(float3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.x + p3.y) * p3.z);
}
float smin(float a, float b, float k)
{
    return -(log(exp(k*-a)+exp(k*-b))/k);
}

float opOnion( in float sdf, in float thickness )
{
    return abs(sdf)-thickness;
}

float3 hsv(float h, float s, float v)
{
  return lerp( float3( 1.0 , 1, 1 ) , clamp( ( abs( frac(
    h + float3( 3.0, 2.0, 1.0 ) / 3.0 ) * 6.0 - 3.0 ) - 1.0 ), 0.0, 1.0 ), s ) * v;
}



float map(float3 p) 
{

        float d1 =(length(p)-.6);
    d1 =  smin( length(p-float3(.6,0,0))-.4,d1,4.6);
    d1 =  smin( length(p-float3(.6,.3 * sin(_Time.y),0))-.4,d1,4.6);
    d1 =  smin( length(p-float3(-.6 * sin(_Time.y),.3 * sin(_Time.y),0))-.4,d1,4.6);

    d1 = smin(d1, (length(p)-.3), 100);


    d1 += pow(triNoise3D(p*2,1),4) * .2-.3;
    //d1 = abs(d1);


d1 = opOnion( d1 , .01 );


float3 d2 = (length(p)-.0);
    d2 =  smin( length(p-float3(.2,0,0))-.8,d2,4.6);
    d2 =  smin( length(p-float3(.2,.4 * sin(_Time.y+10),.3))-.8,d2,4.6);
    d2 =  smin( length(p-float3(-.7 * sin(_Time.y*.3+3),.5* sin(_Time.y*.4 + 10),0))-.4,d2,4.6);

    d2 = opOnion( d2, .02 );

    d1 = min( d1 , d2 );

d1 = abs(d1);
	float d = .001/pow((.6+2000000000*pow(d1*100,40)),50);

    // /d*=d;
    //d += triNoise3D(p,1) * .01;
    
	return d;
}

float3 render( float3 ro , float3 rd ){


float3 color = 0;

for( int i = 0; i< 120; i ++ ){
    float fi = float(i);

    fi += (hash(ro.x +_Time.y) + hash(ro.y + _Time.y * 1.3))/2;//(hash(ro.x * 10000) + hash(ro.y*10000))/2;
    float3 fPos = ro + fi * .01 * rd;

    float m = map( fPos );

    float3 eps = float3(.001,0,0) * 10*abs( fPos.z );


    float Directions = 6;
    float Quality = 2;

    float Radius = abs(fPos.z)*abs(fPos.z) * .4;

    for( float d=0.0; d<3.14159; d+=3.14159/Directions)
    {
		for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality)
        {
			m +=  map(fPos+float3(cos(d),sin(d),0)*Radius*i);		
        }
    }

    m /= Directions * Quality;
    color +=  m * .000000001;//float3(1,.5,0) * m;
}

return color;
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
               // col = ToneMapFilmicALU(col);

               col = hsv(col * .2 + .8, .3,col*col);

                col = 1-col;
                return fixed4(col,1);
            }
            ENDCG
        }
    }
}
