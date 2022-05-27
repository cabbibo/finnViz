Shader "Unlit/cloud"
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
float3x3 m = float3x3( 0.00,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64 );
float hash( float n )
{
    return frac(sin(n)*43758.5453);
}

float noise( in float3 x )
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

float fbm( float3 p )
{
    float f;
    f  = 0.5000*noise( p ); p = mul(m,p*2.02);
    f += 0.2500*noise( p ); p = mul(m,p*2.03);
    f += 0.1250*noise( p );
    return f;
}


float fbm2( float3 p ){

    p *= .01;
    p += 102.4141;
    float f = triNoise3D(p,1);//p = mul(m,p*2.02);
    f += triNoise3D(p * 2 , 1 ) * .5;
    f += triNoise3D( p * 4 , 1 ) * .25;
    return f / 2;
}



float GetDensity( float3 p ){

	return .5-length(p)*.1+10*fbm(p);
}

float scene(float3 p)
{	
	float d= .1-length(p)*.05+fbm2(p*1);
	 d += .1-length(p-float3(4,0,0))*.05+fbm2(p*1);
	 d += .1-length(p-float3(-6,0,0))*.05+fbm2(p*1);

    //d *= d * d * d * 10;

    d = clamp(d,-10,10);//saturate(d);

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
float3 render( float3 ro , float3 rd ){


float3 color = float4(0,0,0,0);
	
	const int nbSample = 120;
	const int nbSampleLight = 12;
	
	float zMax         = 40.;
	float step         = zMax/float(nbSample);
	float zMaxl         = 20.;
	float stepl         = zMaxl/float(nbSampleLight);
    float3 p             = ro;
    float T            = 1.;
    float absorption   = 200.;
	float3 sun_direction = normalize( float3(1.,.0,.0) );
    


    	for(int i=0; i<nbSample; i++)
	{

        
         float light = lightning(p);
      
		float density = scene(p);
		if(density>0.)
		{
			float tmp = density / float(nbSample);
			T *= 1. -tmp * absorption;
			//if( T <= 0.01)
			//	break;
				
				
			 //Light scattering
			float Tl = 1.0;
			for(int j=0; j<nbSampleLight; j++)
			{
				float densityLight = scene( p + normalize(sun_direction)*float(j)*stepl);
				if(densityLight>0.)
                	Tl *= 1. - densityLight * absorption/float(nbSample);
                if (Tl <= 0.01)
                    break;
			}

            float internalLight = length( p-float3(2,0,0) );


			
			//Add ambiant + light scattering color
			color += 1*50.*tmp*T +  float4(1.,.7,.4,1.)*80.*tmp*T*Tl;

            //color += 10000*float4(1,.2,0,1) * tmp *T/ (internalLight * internalLight * 10);

            color +=10000* float4(1,.2,0,1) * tmp *T*.1/(.1+saturate(light)*saturate(light)*saturate(light)*40 );//lightning
 
            
            
            /*if( light < .1 ){
                color += 1;
                //break;
            }*/

           
		}else{      
            
            if( light < .1 ){

                color +=3*float4(1,.2,0,1);// * tmp *T*.1/(.1+saturate(light)*saturate(light)*3 );//lightning
 
                break;
            }


        }



		p += rd*step;
	}    

    return color.xyz;
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
                return fixed4(col,1);
            }
            ENDCG
        }
    }
}
