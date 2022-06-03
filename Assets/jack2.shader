Shader "Unlit/jack2"
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


float sdBox( float3 p, float3 b ){

  float3 d = abs(p) - b;

  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));

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

      //  float d1 = (length(p)-.6);
    float d1 = 10000;
        for( int i = 0; i < 7; i++ ){
            float fi = float(i+1212);

            float radius = .4;//(sin( _Time.y * sin(fi) + fi) +3) *1.3;
            float3 offset = float3(
               sin( _Time.y * sin(fi+424) + fi+242) * .3,
               sin( _Time.y * sin(fi+42) + fi+2466) * .2,
               sin( _Time.y * sin(fi+24) + fi+542) * .1
            );
            d1 = smin( d1,length(p-offset)-radius ,15);
            //d1 = min( d1,length(p-offset)-radius);
        }

    // /d*=d;
    //d += triNoise3D(p,1) * .01;
    
    d1 += triNoise3D(p*4,1) * .04;
	return d1;
}



float map2(float3 p) 
{

        float d1 = 10000;
        for( int i = 0; i < 40; i++ ){
            float fi = float(i);

            float radius = (sin( _Time.y * sin(fi) + fi) +3) * .05;
            float3 offset = float3(
               sin( _Time.y * sin(fi+424) + fi+242) * .6,
               sin( _Time.y * sin(fi+42) + fi+2466) * .4,
               sin( _Time.y * sin(fi+24) + fi+542) * .1
            );
            d1 = smin( d1,length(p-offset)-radius ,30);
            //d1 = min( d1,length(p-offset)-radius);
        }


    // /d*=d;
    d1 += triNoise3D(p,1) * .1;
    
	return d1;
}



float map3(float3 p) 
{

      //  float d1 = (length(p)-.6);
    float d1 = 10000;
        for( int i = 0; i < 20; i++ ){
            float fi = float(i+1212);

            float radius = .4;//(sin( _Time.y * sin(fi) + fi) +3) *1.3;
            float3 offset = float3(
               sin( _Time.y * .2 * sin(fi+424) + fi+242) * 1,
               sin( _Time.y * .2* sin(fi+42) + fi+2466) * 1,
               sin( _Time.y * .2 * sin(fi+24) + fi+542) * 1
            );
            //d1 = smin( d1,length(p-offset)-radius ,15);
            d1 = min( d1,length(p-offset)-radius);
        }

    // /d*=d;
    //d += triNoise3D(p,1) * .01;
    
    d1 += triNoise3D(p*.1,1) * .4;
	return d1;
}


float doLogo( float3 p ){

    float v = 100000;

    p *= 3;
    p.x = abs(p.x);
    //p.x = abs(p.x+.4);
    float3 tp = p - float3(.85,0,0);

    //tp.x = abs(tp.x);
    v = min(v,sdBox( tp , float3(.03,.3,.3)));
    v = min(v,sdBox( tp - float3(-.4,-.15,0) , float3(.4,.15,.3)));

    return v;
}

float doLogoLong( float3 p ){

    float v = 100000;

    p *= 3;
    p.x = abs(p.x);
    //p.x = abs(p.x+.4);
    float3 tp = p - float3(.85,0,0);

    //tp.x = abs(tp.x);
    v = min(v,sdBox( tp , float3(.03,.3,2.3)));
    v = min(v,sdBox( tp - float3(-.4,-.15,0) , float3(.4,.15,1.3)));

    return v;
}


float3 getColor( float3 fPos ){
    
    float m = map( fPos );


    float inside = m;


float3 color = 0;
    

    float logo = doLogo(fPos);

    m = opOnion(m,.01);
   // m = max(m, -(doLogoLong(fPos)-.2));
    if( m < 0 ){
      color +=.1 * float3(.1,.5,0);//float3(.1,0,0);////.1/((-m)*20);//.03;
    }
    m = map3(fPos);
     m = opOnion(m,.01);
    if( m < 0 ){
      color +=.1 * float3(.1,0,.2);//float3(.1,0,0);////.1/((-m)*20);//.03;
    }
    if( inside < 0 ){

        float outL = logo - triNoise3D(fPos*1,1)*.2;
        float m2 = map2(fPos);
        m2 = opOnion(m2,.01);

        float tm = m2;

        m2 = smin(m2, opOnion(outL,.1) * 10 , 1);
        float d =  max( tm , -outL);

        float d2 = m2 - d; 


        
        m2 = max( m2 , -(doLogo(fPos)) );


        if( m2 < 0 ){
            color += .1 *float3(-d2 * 0,d2 * 1+ .4,0);//float3(.05,.02,0);
        }

    }

    m = doLogo( fPos );

    if( m < 0 ){
       color += .1*float3(1.3,1.,0.);
    }

    return color;
}
float3 render( float3 ro , float3 rd ){


float3 color = float3(.1,0,.3);

for( int i = 0; i< 100; i ++ ){
    float fi = float(i);

    fi += (hash(ro.x +_Time.y) + hash(ro.y + _Time.y * 1.3))/2;//(hash(ro.x * 10000) + hash(ro.y*10000))/2;
    float3 fPos = ro + fi * .01 * rd;

//fPos += 100;
  //  fPos = (fPos % 2)-1;


  // color += getColor( fPos );



    //color += -worleyFbm( fPos*100,1 )*.000001;

float3 ave = getColor( fPos );

float2 uv = fPos.xy * float2(.5,1) + .5;

float4 c = tex2D(_MainTex,uv);


float tv = 0;
if( c.x < .8 ){

    if( abs(fPos.z) < .2 ){
        tv += .1;//
    }
    //tv += saturate( .1- .2*abs(fPos.z));
}


//ave += 30*tv*float3(1,.8,.3);

    float3 eps = float3(.001,0,0) * 10*abs( fPos.z );


    float Directions = 4;
    float Quality = 1;



    float d = 0;//abs(fPos.z- sin(_Time.y *.1 ) * .3 );

    float Radius = 0;

    if( d > .1){
        Radius = clamp((d-.1) * .1 , 0, .3);
    }


    Radius *= .8;

/*

            float a = 3.14159;
            float r = 0;

            a = 3.14159;
            r = 1 * Radius; 
			ave +=  getColor(fPos+float3(cos(a),sin(a),0)*r);		
			ave +=  getColor(fPos+float3(cos(a),sin(a),0)*-r);		
            
            a = 3.14159/5;
            r = 1 * Radius; 
			ave +=  getColor(fPos+float3(cos(a),sin(a),0)*r);		
			ave +=  getColor(fPos+float3(cos(a),sin(a),0)*-r);		

            a = 3.14159*2/5;
            r = 1 * Radius; 
			ave +=  getColor(fPos+float3(cos(a),sin(a),0)*r);		
			ave +=  getColor(fPos+float3(cos(a),sin(a),0)*-r);		

            
            a = 3.14159*3/5;
            r = 1 * Radius; 
			ave +=  getColor(fPos+float3(cos(a),sin(a),0)*r);		
			ave +=  getColor(fPos+float3(cos(a),sin(a),0)*-r);	

            
            a = 3.14159*4/5;
            r = 1 * Radius; 
			ave +=  getColor(fPos+float3(cos(a),sin(a),0)*r);		
			ave +=  getColor(fPos+float3(cos(a),sin(a),0)*-r);		




   

   //color /= 2;//Directions * Quality;

   ave /= 11;*/
   color += ave; 
}

//color /= 2;

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

             //  col = hsv(col * .3  + .7, .8,3*(col*col));

             //   col = 1-col;
                return fixed4(col,1);
            }
            ENDCG
        }
    }
}
