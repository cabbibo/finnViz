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

float cycleTime;


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

float2 smoothU( float d1, float d2, float k)
{
    float a = d1;
    float b = d2;
    float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
    return ( lerp(b, a, h) - k*h*(1.0-h));
}


float3 hsv(float h, float s, float v)
{
  return lerp( float3( 1.0 , 1, 1 ) , clamp( ( abs( frac(
    h + float3( 3.0, 2.0, 1.0 ) / 3.0 ) * 6.0 - 3.0 ) - 1.0 ), 0.0, 1.0 ), s ) * v;
}



// Rotation matrix around the X axis.
float3x3 rotateX(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return float3x3(
        float3(1, 0, 0),
        float3(0, c, -s),
        float3(0, s, c)
    );
}

// Rotation float3xrix around the Y axis.
float3x3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return float3x3(
        float3(c, 0, s),
        float3(0, 1, 0),
        float3(-s, 0, c)
    );
}

// Rotation float3xrix around the Z axis.
float3x3 rotateZ(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return float3x3(
        float3(c, -s, 0),
        float3(s, c, 0),
        float3(0, 0, 1)
    );
}




float map(float3 p) 
{

      //  float d1 = (length(p)-.6);
    float d1 = 10000;
        for( int i = 0; i < 12; i++ ){
            float fi = float(i+1212);

            float radius = .5;//(sin( _Time.y * sin(fi) + fi) +3) *1.3;
            float3 offset = float3(
               sin( _Time.y * sin(fi+424) + fi+242) * .8,
               sin( _Time.y * sin(fi+42) + fi+2466) * .5,
               sin( _Time.y * sin(fi+24) + fi+542) * .1
            );

            offset *= cycleTime;
            radius *= cycleTime;
            radius *= cycleTime;
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
        for( int i = 0; i < 80; i++ ){
            float fi = float(i);

            float radius = (sin( _Time.y * sin(fi) + fi) +3) * .05;
            float3 offset = float3(
               sin( _Time.y * sin(fi+424) + fi+242) * 1,
               sin( _Time.y * sin(fi+42) + fi+2466) * .8,
               sin( _Time.y * sin(fi+24) + fi+542) * .1
            );

            offset *= cycleTime;
            radius *= cycleTime;
            radius *= cycleTime;
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

            offset *= cycleTime;
            radius *= cycleTime;
            radius *= cycleTime;
            //d1 = smin( d1,length(p-offset)-radius ,15);
            d1 = min( d1,length(p-offset)-radius);
        }

    // /d*=d;
    //d += triNoise3D(p,1) * .01;
    
    d1 += triNoise3D(p*.1,1) * .4;
	return d1;
}


float doL( float3 p ){

    float3 v = 10000;
      v = min(v,sdBox( p , float3(.03,.3,.2)));
    v = min(v,sdBox( p - float3(-.4,-.15,0) , float3(.4,.15,.2)));

    return v;
}

float doLogo( float3 p ){

    float v = 100000;


    float me = clamp( (cycleTime - .8) *(1/.1) + sin(_Time.y * .23) * .2  , 0 , 1.2);
      float solidVal = (sin(_Time.y * .2) + 1 )/2;

         solidVal =  solidVal * solidVal * (3.0 - 2.0 * solidVal);
//solidVal = 1;
    for( int i = 0; i < 2; i++ ){

        float fi = float(i);
        if( i == 1 ){
            p.x = -p.x;
        }
        
        float3 tp = p;
        float3 tpRandom = p;

        float s1 = 1;
        
        tp -= 1 * float3(1,0,0);
        tp *= .95;
        tpRandom *= (1 + me);

             float3 offset = float3(
               sin( _Time.y * .2 * sin(fi+424) + fi+242) * .5,
               sin( _Time.y * .2* sin(fi+42) + fi+2466) * 2,
               sin( _Time.y * .2 * sin(fi+24) + fi+542) * 0
            );

            tpRandom += -offset * .5;


        

        tpRandom = tpRandom - 2*float3(1*me + .06 * sin(_Time.y * .37 ) + .04 * sin(_Time.y * .27 )   ,0,0);

        float3x3 ro = rotateY( sin( _Time.y * .8 *(fi +2) + fi ) * .1  );
        float3x3 ro2 = rotateZ( sin( _Time.y * .2 *(fi +2) + fi *313 + 31313) * .8 );

        tpRandom = mul(ro,mul(ro2,tpRandom * (2 + sin(_Time.y * .1 + fi) )  /2));

   
        
       // solidVal = 1;
         ro2 = rotateZ( sin( _Time.y * 11111.2 *(fi +2) + fi *313 + 31313) * .01  * pow( solidVal,10));       
        tp =mul(ro2,tp * ( 1- (sin(_Time.y * 121212 + fi * 212) * .01* pow( solidVal,10))));

    
        
        float3 fPos = lerp( tpRandom , tp , solidVal);
    
        v = smin(v,doL(fPos * (1.1/me)) , 1000);

       




    }
// v*= 4;

        float n = (noise(p * 15+ float3(0,0,-_Time.y))-.5) * .3  * me * (sin(_Time.y*.39)+1.2);
      n += (noise(p * 30+ float3(0,0,-2*_Time.y))-.5) * .15  * me * (sin(_Time.y * .59)+1.2);

n *= .5;
    //n = 0;
    float notMax = 1-me;
    notMax *= 10;

     v += (1-solidVal) * ( n * (me) * saturate(sin( _Time.y * .21) + .5) + n * notMax);
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

        float outL = logo;
        float m2 = map2(fPos);

    float m2Temp = m2;
       m2 = smin( outL , m2 * .4 , 20 );
       float m3 = min( outL , m2Temp * .1 );


    float delta = abs(m3 - m2);

        m2 = opOnion(m2,.002);

        float tm = m2;

     //m2 = smin(m2 * .4, opOnion(outL,.1) , .1);
        float d =  max( tm , -outL);

        float d2 = m2 - d; 

    //color += delta * .1;
        
       // m2 = max( m2 , -(doLogo(fPos)) );


        if( m2 < 0 ){
            color +=  .04*float3(0,1,0);//float3(.05,.02,0);
        }
    }

    m = doLogo( fPos );

    if( m < 0 ){
       color += .1*float3(1.5,.4,0.);
    }

    return color;
}
float3 render( float3 ro , float3 rd ){

    cycleTime = 1*(_Time.y / 600) % 1;

    cycleTime = cycleTime * cycleTime * (3.0 - 2.0 * cycleTime);

    if( cycleTime > 1 ){ cycleTime = 1; }

/*

    if( cycleTime > 1 && cycleTime < 2 ){
        cycleTime = 1;
    }else if( cycleTime >= 2 ){
        cycleTime = pow( 3- cycleTime,.5);
    }*/

    //cycleTime = cycleTime * cycleTime * cycleTime

cycleTime = 1;

float3 color = float3(.1,0,.3);

for( int i = 0; i< 50; i ++ ){
    float fi = float(i);

    fi += (hash(ro.x +_Time.y) + hash(ro.y + _Time.y * 1.3))/2;//(hash(ro.x * 10000) + hash(ro.y*10000))/2;
    float3 fPos = ro + fi * .015 * rd;

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



    float d = abs(fPos.z- pow( saturate( sin(_Time.y *.1 ) * .6 + sin( _Time.y * .17 ) * .7),2)   );

    float Radius = 0;

    if( d > .1){
        Radius = clamp((d-.1) * .1 , 0, .05);
    }


    Radius *= .8;




            float a = 3.14159;
            float r = 0;

          /*  a = 3.14159;
            r = 1 * Radius; 
			ave +=  getColor(fPos+float3(cos(a),sin(a),0)*r);		
			ave +=  getColor(fPos+float3(cos(a),sin(a),0)*-r);		
            
            a = 3.14159/2;
            r = 1 * Radius; 
			ave +=  getColor(fPos+float3(cos(a),sin(a),0)*r);		
			ave +=  getColor(fPos+float3(cos(a),sin(a),0)*-r);		*/
/*
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
			ave +=  getColor(fPos+float3(cos(a),sin(a),0)*-r);		*/




   

   //color /= 2;//Directions * Quality;

   //ave /= 11;
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
