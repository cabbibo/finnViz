using UnityEngine;
using System.Collections;


[ExecuteAlways]
public class AudioListenerTexture : MonoBehaviour
{

    private int width; // texture width
    private int height; // texture height
    private Color backgroundColor = Color.black;
    //public Color waveformColor = Color.green;
    public int size = 1024; // size of sound segment displayed in texture

    private Color[] blank; // blank image array
    public Texture2D texture;
    public float[] samples; // audio samples array
    public float[] lowRes;
    public int lowResSize;// = 256;


    public LoopbackAudio loopbackAudio;
    public float loopbackMultiplier;
    public float nonloopbackMultiplier;


    public Color[] pixels;

    public int structSize;
    public int count;

    public void SetStructSize(){
      structSize = 4;
    }

    public void SetCount(){
      count = size * 2;
    }

    public void OnEnable()
    {
        width = size;
        height = 1;

        // create the samples array
        samples = new float [ size * 8 ];
        lowRes = new float [ 64 ];
        lowResSize = 64;

        // create the AudioTexture and assign to the guiTexture:
        texture = new Texture2D ( width, height );
        pixels = texture.GetPixels(0,0,width,1 );

        // create a 'blank screen' image
        blank = new Color [ width * height ];

        for ( int i = 0; i < blank.Length; i++ ){
            blank [ i ] = backgroundColor;
        }

        // refresh the display each 100mS
    }



   public void LateUpdate( ){

        bool mainAudioMuted = false;
        float multiplier = 128;

        multiplier *= nonloopbackMultiplier;

            #if UNITY_EDITOR
            // If our audio is muted replace data from the lookback audio!
                mainAudioMuted = UnityEditor.EditorUtility.audioMasterMute;
                if( mainAudioMuted ){
                    samples = loopbackAudio.SpectrumData;

                    
                    for( int i = 0; i < samples.Length; i++ ){
                        samples[i] = samples[i] * samples[i] * samples[i] * samples[i];
                    }
                    multiplier = loopbackMultiplier;
                }

            #endif


        if( !mainAudioMuted ){
            AudioListener.GetSpectrumData ( samples, 0, FFTWindow.Triangle );
        }

        print( pixels.Length);
        print( samples.Length);


        pixels = texture.GetPixels(0,0,width,1 );
            print(samples[(size-1)*4+3]);
            print(pixels[(size-1)]);
        for ( int i = 0; i < size; i++ )
        {
            pixels [ i ].r = pixels [ i ].r * .8f + samples [ ( int ) ( i * 4 ) + 0 ]*multiplier;
            pixels [ i ].g = pixels [ i ].g * .8f + samples [ ( int ) ( i * 4 ) + 1 ]*multiplier;
            pixels [ i ].b = pixels [ i ].b * .8f + samples [ ( int ) ( i * 4 ) + 2 ]*multiplier;
            pixels [ i ].a = pixels [ i ].a * .8f + samples [ ( int ) ( i * 4 ) + 3 ]*multiplier;

        }   

        texture.SetPixels ( pixels );
        texture.Apply();

       // if( samples != null && _buffer != null ){ SetData( samples ); }

        
        Shader.SetGlobalTexture( "_AudioMap" , texture );
    }

}

