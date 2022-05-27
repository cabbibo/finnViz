Shader "Unlit/explosion"
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
    float final = Disk(p.xzy,float3(2.0,1.8,1.25));
   final += fbm(p*90 + float3(0,_Time.y,0));
    //final += 3*triNoise3D(p.xyz * .1,1);
   final += SpiralNoiseC(p.yxz*0.5123+100.0)*3.0;
   //final += .3*triNoise3D(p.xyz * 1,1);
  //  final += triNoise3D(p.xyz * .1,1);

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

float sdCappedCylinder( float3 p, float h, float r ){

    float2 d1= 0;

    d1 = abs(float2(length(p.xz),p.y)) - float2(h,r);

    return min(max(d1.x,d1.y),0.0) + length(float2(max(d1.x,0),max(d1.y,0)));//,float2(0,0)));

}
float sdCylinder( float3 p, float3 c )
{
  return length(p.xz-c.xy)-c.z;
}


float sdCapsule( float3 p, float3 a, float3 b, float r )
{
  float3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}
float lightning( float3 p ){

    return sdCapsule( p + triNoise3D( float3(p.x * .03, 0, 0),10) * float3(0,4,0), float3(-1000,0,0) , float3(1000,0,0) , .1);

}


// Applies the filmic curve from John Hable's presentation
// More details at : http://filmicgames.com/archives/75
float3 ToneMapFilmicALU(float3 _color)
{
	_color = max(0, _color - 0.004);
	_color = (_color * (6.2*_color + .5)) / (_color * (6.2 * _color + (1.7)) + (0.06));
	return _color;
}


// assign color to the media
float3 computeColor( float density, float radius )
{
	// color based on density alone, gives impression of occlusion within
	// the media
	float3 result = lerp( float3(1.0,0.9,0.8), float3(0.4,0.15,0.1), density );
	
	// color added to the media
	float3 colCenter = 7.*float3(0.8,1.0,1.0);
	float3 colEdge = 1.5*float3(0.48,0.53,0.5);
	result *= lerp( colCenter, colEdge, min( (radius+.05)/.9, 1.15 ) );
	
	return result;
}
float map(float3 p) 
{

	float NebNoise = abs(NebulaNoise(p/0.5)*0.5);
    
	return NebNoise+0.07;
}

float3 render( float3 ro , float3 rd ){


float3 color = float4(0,0,0,0);
		// ld, td: local, total density 
	// w: weighting factor
	float ld=0., td=0., w=0.;

	// t: length of the ray
	// d: distance function
	float d=1., t=0.;
    const float h = 0.1;
    
	float4 sum = 0;
   
    float min_dist=0.0, max_dist=10;
// raymarch loop
	for (int i=0; i<64; i++) 
	{
	 
		float3 pos = ro + t*rd;
  
		// Loop break conditions.
	    if(td>0.9 || d<0.1*t || t>10. || sum.a > 0.99 || t>max_dist) break;
        
        // evaluate distance function
        float d = map(pos);
		       
		// change this string to control density 
		d = max(d,0.0);
        
        // point light calculations
        float3 ldst = 0-pos;
        float lDist = max(length(ldst), 0.001);

        // the color of light 
        float3 lightColor=float3(1.0,0.5,0.25);
        
        sum.rgb+=(float3(0.67,0.75,1.00)/(lDist*lDist*10.)/80.); // star itself
        sum.rgb+=(lightColor/exp(lDist*lDist*lDist*.08)/30.); // bloom
        
		if (d<h) 
		{
			// compute local density 
			ld = h - d;
            
            // compute weighting factor 
			w = (1. - td) * ld;
     
			// accumulate density
			td += w + 1./200.;
		
			float4 col = float4( computeColor(td,lDist), td );
            
            // emission
            sum += sum.a * float4(sum.rgb, 0.0) * 0.2;	
            
			// uniform scale density
			col.a *= 0.2;
			// colour by alpha
			col.rgb *= col.a;
			// alpha blend in contribution
			sum = sum + col*(1.0 - sum.a); 

            color.xyz += col.xyz; 
       
		}
      
		td += 1./70.;

      
        // trying to optimize step size near the camera and near the light source
        t += max(d * 0.1 * max(min(length(ldst),length(ro)),1.0), 0.01);
        
	}

        // simple scattering
	sum *= 1. / exp( ld * 0.2 ) * 0.6;
        
   	sum = clamp( sum, 0.0, 1.0 );
   
    sum.xyz = sum.xyz*sum.xyz*(3.0-2.0*sum.xyz);
    
    

    return 1*sum.xyz;
    //return color.xyz;
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
                col = ToneMapFilmicALU(col);
                return fixed4(col,1);
            }
            ENDCG
        }
    }
}
