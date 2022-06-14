
Shader "Unlit/jack3"
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




sampler2D _AudioMap;
float4 sampleAudio( float v ){

   // return tex2Dlod( _AudioMap , float4( v,0, 0,0 ));
    return tex2Dlod( _AudioMap , float4( v,0,0,0));
}




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



float3 getColor( float3 pos , float fi){

    float3 v = triNoise3D(pos.xyz * .4+ float3(0,1,0),3);//sampleAudio(abs(pos.x * 3.1) ).xyz;

    v = saturate( (v.x - .4) *100);
    
    v *=4*pow( sampleAudio(fi * 10),2); 
    return v;
}    



float3 render( float3 ro , float3 rd ){


float3 color = float3(.1,0,.3);

float steps = 100;
for( int i = 0; i< steps; i ++ ){

    float fi = float(i);

     float3 fPos = ro + fi * .001 * rd;

    float3 ave = getColor( fPos , fi);

    color += ave; 

}

color /= steps;

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

                return fixed4(col,1);
            }
            ENDCG
        }
    }
}
