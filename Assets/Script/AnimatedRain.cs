using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class AnimatedRain : MonoBehaviour
{

    public static AnimatedRain Instance { get; private set; }
    [Header("Setup")]
    public Shader rainShader;
    public Mesh rainMesh;

    [Header("Shader Panel")]
    public Texture2D rainTexture = null;
    public Texture2D noiseTexture = null;
    public Texture2D distortionTexture = null;

    public Vector4 rainTransform = new Vector4(1.0f, 1.0f, 0.0f, 1.0f);
    public Vector4 rainDepthStart = new Vector4(0.0f, 100.0f, 200.0f, 300.0f);
    public Vector4 rainDepthRange = new Vector4(100.0f, 100.0f, 100.0f, 100.0f);
    public Vector4 rainOpacities = new Vector4(1.0f, 1.0f, 1.0f, 1.0f);
    //[Range(0f, 2f)]
    public float rainIntensity = 1.0f;
    public bool isWindy = false;
    public float windDegree = 30.0f;


    //[Range(0.25f, 4f)]
    //public float lightExponent = 1.0f;
    //[Range(0.25f, 4f)]
    //public float lightIntensity1 = 1.0f;
    //[Range(0.25f, 4f)]
    //public float lightIntensity2 = 1.0f;


    Material m_RainMaterial;

	void OnEnable()
    {
        m_RainMaterial = new Material(rainShader ?? Shader.Find("Hidden/PPRain"));
        m_RainMaterial.hideFlags = HideFlags.DontSave;

        Debug.Assert(Instance == null);
        Instance = this;
    }
	
	
	void OnDisable()
    {
        DestroyImmediate(m_RainMaterial);
        m_RainMaterial = null;

        Debug.Assert(Instance == this);
        Instance = null;
    }
	
	public void Render(Camera cam, RenderTargetIdentifier src, RenderTargetIdentifier dst, CommandBuffer deferredCmds)
    {
        deferredCmds.SetGlobalTexture("_MainTex", src);

        deferredCmds.SetGlobalTexture("_RainTex", rainTexture);
        deferredCmds.SetGlobalTexture("_NoiseTex", noiseTexture);
        deferredCmds.SetGlobalTexture("_DistortionTex", distortionTexture);

        deferredCmds.SetGlobalVector("_RainTransform", rainTransform);
        deferredCmds.SetGlobalVector("_RainDepthStart", rainDepthStart);
        deferredCmds.SetGlobalVector("_RainDepthRange", rainDepthRange);
        deferredCmds.SetGlobalVector("_RainOpacities", rainOpacities);
        deferredCmds.SetGlobalFloat("_RainIntensity", rainIntensity);

        float windy = isWindy ? 1.0f : 0.0f;
        deferredCmds.SetGlobalFloat("_Windy", windy);
        deferredCmds.SetGlobalFloat("_WindDegree", windDegree);


        //deferredCmds.SetGlobalFloat("_LightExponent", lightExponent);
        //deferredCmds.SetGlobalFloat("_LightIntensity1", lightIntensity1);
        //deferredCmds.SetGlobalFloat("_LightIntensity2", lightIntensity2);

        var xform = Matrix4x4.TRS(cam.transform.position, transform.rotation, new Vector3(1f, 1f, 1f) );

        deferredCmds.SetRenderTarget(dst);
        deferredCmds.DrawMesh(rainMesh, xform, m_RainMaterial);
    }
    



    void OnDrawGizmos()
    {
        Gizmos.matrix = transform.localToWorldMatrix;
        Gizmos.color = Color.blue;

        Gizmos.DrawLine(Vector3.up * 0.5f, Vector3.zero);

    

        //Gizmos.DrawMesh(rainMesh, transform.position);
    }
}
