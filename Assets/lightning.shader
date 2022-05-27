Shader "Unlit/lightning"
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



float3 render( float3 ro , float3 rd ){


float3 col = float3(0,0,0);
    for( int i = 0; i < 30; i++ ){

        float fi = float(i);
        float3 pos = ro + rd * fi * .001; 

   // float y = pos.y + .5;

    float2 uv = (pos.xy * float2(1 , 16./9.)) * 2+ .5;
    uv = clamp(uv,0,1);

    float4 tCol = tex2D(_MainTex, uv);


    pos.y += tCol.w * .1;
    if( tCol.w < .9999 ){ tCol.w=0;}else{
        if( length(tCol) > 0 ){
            col += tCol.xyz;
            break;
        }
   // col += tCol.xyz * tCol.w;
    //break;
    }
    col += tCol.xyz * tCol.w;


        float y = pos.y + .5;

    //if( tCol.w < .999 ){ col= 0;}

    
    
    y +=  triNoise3D( pos * .3, 3. + 2. * sin(fi * 1430)) * .3;//sin( uv.x * 40. + iTime) * .1 + fract( uv.x * 30. * sin(iTime)  - iTime) * .1; 
    y +=  triNoise3D( pos * .8, 6. +7. * sin(fi * 155430.)) * .2;//sin( uv.x * 40. + iTime) * .1 + fract( uv.x * 30. * sin(iTime)  - iTime) * .1; 

   y = abs(y - .6 + sin( fi* 100.) * .3  * (.5-1*abs(pos.x)));
    
    y = .5 -y;
    
    y *= 60.;
    y -= 29.9;
    

    
    y = clamp(y*100.,0.,1.);
    
    
    if( i == 19 ){
    
        if( y > 0 ){
        col = y * .5 * float3(1. , .4 , 0.);
        }
    }else{
    
    //col += y;
    
        col+= y * .5 * float3(1. , .4 , 0.);
        //}
    }
    


    
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
