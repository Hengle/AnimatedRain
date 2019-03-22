using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraSettings : MonoBehaviour {

    private Camera cam;
    public Shader rainLowPass;

    // Use this for initialization
    void Start () {
        cam = GetComponent<Camera>();
        cam.RenderWithShader(rainLowPass, "Opaque");
        cam.enabled = true;
    }

    // Update is called once per frame
    void Update () {
		
	}
}
