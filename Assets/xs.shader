Shader "Unlit/xs"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainTex2 ("Texture", 2D) = "white" {}
        _MainTex3 ("Texture", 2D) = "white" {}
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
            sampler2D _MainTex2;
            sampler2D _MainTex3;
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

       //From IQ shaders
      float hash( float n )
      {
          return frac(sin(n)*43758.5453);
      }

      float noise( float3 x )
      {
          // The noise function returns a value in the range -1.0f -> 1.0f
          x.z += .2 * _Time.y;

          float3 p = floor(x);
          float3 f = frac(x);

          f       = f*f*(3.0-2.0*f);
          float n = p.x + p.y*57.0 + 113.0*p.z;

          return lerp(lerp(lerp( hash(n+0.0), hash(n+1.0),f.x),
                         lerp( hash(n+57.0), hash(n+58.0),f.x),f.y),
                     lerp(lerp( hash(n+113.0), hash(n+114.0),f.x),
                         lerp( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
      }


float3 hsv(float h, float s, float v)
{
  return lerp( float3( 1.0 , 1, 1 ) , clamp( ( abs( frac(
    h + float3( 3.0, 2.0, 1.0 ) / 3.0 ) * 6.0 - 3.0 ) - 1.0 ), 0.0, 1.0 ), s ) * v;
}



float3 doColor(float3 pos){


   // pos.x += floor( sin(pos.y * 100 +_Time.y) ) * .01 * floor( sin(pos.y * 404 + _Time.y + sin(pos.y * 333+_Time.y))) * (floor( noise( _Time.y * .3) * 3 )/3);
   // pos.x += noise(pos.y *1000 +_Time.y);//floor( noise(float3(pos.y * 1000 , _Time.y * .6,_Time.y * .341)) * 3  ) * .002 * floor( noise(_Time.y * .411 + pos.y) * 2 )/2;

  
    float2 uv = (pos.xy * float2(1 , 2)) * 3.3+ float2(.5, .5);
    


    //uv += .1*floor( 5 * (triNoise3D( pos * 5  + floor( _Time.y * .1),1)-.3) *  (sin(_Time.y * 1.134) +1)) /5;
    uv = clamp(uv,0,1);



    sampler2D t = _MainTex;



    float4 tCol = tex2Dlod(_MainTex, float4(uv,0,0));

    float3 v = tCol.x * .01;//  * noise( _Time.y * 3.41);


    float n = (triNoise3D( pos * 1.3 , 1 )-.1);
    //v *= (triNoise3D( pos * 1.3 , 1 )-.1) * 4;
    v *= hsv( n * 1 + .7 + _Time.y * .3, .5,n)* 4;

    
    //v *= float3(1,0,0);
    v += pow(triNoise3D( pos , 1),4) * .1;
    return v;
}

float3 render( float3 ro , float3 rd ){

    float eyeDelta = (sin(_Time.y * .8) +1) * .4;

    eyeDelta = floor( eyeDelta * 3 )/3;
    float3 nor = float3(0,0,-1);
    float3 r1 = refract(rd,nor,.9);// + float3(eyeDelta,0,0);
    float3 r2 = refract(rd,nor,.5);// + float3(eyeDelta,0,0);
    float3 r3 = refract(rd,nor,.3);// + float3(eyeDelta,0,0);


float stepSize = .001;

//stepSize *= floor(noise( _Time.y * 3 ) *3);// floor((sin(_Time.y + sin(_Time.y * 3 )) + sin(_Time.y * .3 + sin(_Time.y * .3)) * 2 +5)) ;

float3 col = float3(0,0,0);
    for( int i = 0; i < 100; i++ ){

        float fi = float(i);

        float3 pos1 = ro + r1 * fi * stepSize;//lerp( .003 , .001 , (1 +sin(_Time.y * .1  + 424) ) /2 ); 
        float3 pos2 = ro + r2 * fi * stepSize;//lerp( .003 , .001 , (1 +sin(_Time.y * .1  + 424) ) /2 ); 
        float3 pos3 = ro + r3 * fi * stepSize;//lerp( .003 , .001 , (1 +sin(_Time.y * .1  + 424) ) /2 ); 
      
        float3 c1 = doColor(pos1);
        float3 c2 = doColor(pos2);
        float3 c3 = doColor(pos3);

        col += c1 * float3(1,0,0);
        col += c2 * float3(0,1,0);
        col += c3 * float3(0,0,1);

    
    }

    return col;

}

            v2f vert (appdata v)
            {
                v2f o;
            

                               o.ro  = v.vertex.xyz;
                o.localCam  = mul( unity_WorldToObject, float4( _WorldSpaceCameraPos ,1 )).xyz;
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
