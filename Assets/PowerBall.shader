Shader "Unlit/Powerball"
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
    for( int i = 0; i < 100; i++ ){

        float fi = float(i);
        float3 pos = ro + rd * fi *  .001;//lerp( .003 , .001 , (1 +sin(_Time.y * .1  + 424) ) /2 ); 

   // float y = pos.y + .5;

    float2 uv = (pos.xy * float2(1 , 2)) * 3+ float2(.5, .7);
    uv = clamp(uv,0,1);

    float4 tCol = tex2Dlod(_MainTex, float4(uv,0,0));

    float2 eps = float2( .001 , 0 );
  //  float2 nor = float2(
   float nX = tex2Dlod(_MainTex, float4(uv + eps.xy,0,0)) - tex2Dlod(_MainTex, float4(uv - eps.xy,0,0)).w;
    float nY = tex2Dlod(_MainTex, float4(uv + eps.yx,0,0)) - tex2Dlod(_MainTex, float4(uv - eps.yx,0,0)).w;
  //  )


    pos.xy -=  normalize(float2(nX,nY)) * tCol.w * .1;

    
    if( tCol.w < .9999 ){ tCol.w=0;}else{
        if( length(tCol) > 0 && i >9999){
            col += tCol.xyz;
            break;
        }

          if( length(tCol) > 0 && i == 0){
            col += tCol.xyz;
            break;
        }
   // col += tCol.xyz * tCol.w;
    //break;
    }
    //col += lerp(0, .1, pow((sin(_Time.y * .3) + 1) /2 ,2))*tCol.xyz * tCol.w;
    //col +=.01*tCol.xyz * tCol.w;


        float y = pos.y + .5;// + sin(_Time.y) * .2 +.5;

    //if( tCol.w < .999 ){ col= 0;}

    
    float noiseVal =  triNoise3D( pos * 1 + (fi) + float3(11,1,1), 1.  ) ;//sin( uv.x * 40. + iTime) * .1 + fract( uv.x * 30. * sin(iTime)  - iTime) * .1; 
    
   // noiseVal -= tCol.w * .1;

   if( noiseVal >.3 && noiseVal < .33){

      
       
       col = pow((sin(1*(fi * .4))+1)/2,10)  * (.015 - abs(noiseVal-.315)) * 100;// * noiseVal;// float3(1,.5,0) * saturate( ((noiseVal -.5)) * 10);
       break;
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
