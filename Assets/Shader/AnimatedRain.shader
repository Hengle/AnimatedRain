// Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.

Shader "Custom/AnimatedRain" {
	/*Properties{
		_MainTex("Rain Texture", 2D) = "White" {}
		_NoiseTex("Noise Texture", 2D) = "White" {}
		_DistortionTex("Distortion Texture", 2D) = "White" {}
		_RainDepthMapTex("Rain DepthMap Texture", 2D) = "White" {}

		_RainTransform("Rain Transform", vector) = (1.0, 1.0, 0.0, 1.0)
		_RainDepthStart("Rain Depth Start", vector) = (0.0, 100.0, 200.0, 300.0)
		_RainDepthRange("Rain Depth Range", vector) = (100.0, 100.0, 100.0, 100.0)
		_RainOpacities("Rain Opacities", vector) = (1.0, 1.0, 1.0, 1.0)
		_RainIntensity("Rain Intensity", float) = 1.0
	}*/
	SubShader{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 uvP : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float4 vertexP : TEXCOORD3;
				float4 viewPos : TEXCOORD4;
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.vertexP = v.vertex;
				o.uv = v.uv;
				o.uvP = ComputeScreenPos(o.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.viewPos = mul(UNITY_MATRIX_MV, v.vertex);
				return o;
			}

			sampler2D _MainTex;
			sampler2D _RainTex;
			sampler2D _NoiseTex;
			sampler2D _DistortionTex;
			sampler2D _CameraDepthTexture;;

			float4 _RainOpacities;
			float _RainIntensity;
			float4 _RainDepthStart;
			float4 _RainDepthRange;
			float4 _RainTransform;

			float _Windy;
			float _WindDegree;

			float calcSceneDepth(float2 position) {
				return 100.0f;
			}

			float rainDepthMapTest(float viewPixelDepth, float2 uv, float rainDepthStart, float rainDepthRange, float rainOpacity) {
				// Layers Depth tests : 
				float viewRainDepth = 0;
				// Constant are based on layers distance
				float2 rainAndDepth = tex2D(_RainTex, uv).gb;
				viewRainDepth = rainAndDepth.g * rainDepthRange + rainDepthStart;
				// Mask using virtual position and the scene depth
				float occlusionDistance = saturate((viewPixelDepth - viewRainDepth) * 10000.0f);
				float mask = rainOpacity * saturate((viewRainDepth - rainDepthStart) / rainDepthRange);
				return occlusionDistance * rainAndDepth.r * mask;
			}

			fixed4 frag(v2f i) : SV_Target{
				float2 uvRandomFactor = _RainTransform.zw * _Time.y;
				//uvRandomFactor = 0.0f;
				float pi = 3.1415926;
				float radianPerDegree = pi / 180.0f;
				// windy
				float2 windRadian = _WindDegree * radianPerDegree;
				float4 cosines = float4(cos(windRadian), sin(windRadian));
				float2 centeredUV = i.uv - float2(0.5f, 0.5f);
				float4 rotatedUV = float4(dot(cosines.xz * float2(1.0f, -1.0f), centeredUV)
										 ,dot(cosines.zx, centeredUV)
										 ,dot(cosines.yw * float2(1.0f, -1.0f), centeredUV)
										 ,dot(cosines.wy, centeredUV)) + float4(0.5f, 0.5f, 0.5f, 0.5f);
				rotatedUV = rotatedUV * _Windy + i.uv.xyxy * (1 - _Windy);
				float2 centeredUVRandomFactor = uvRandomFactor - float2(0.5f, 0.5f);
				float4 rotatedUVRandomFactor = float4(dot(cosines.xz * float2(1.0f, -1.0f), centeredUVRandomFactor)
													 ,dot(cosines.zx, centeredUVRandomFactor)
													 ,dot(cosines.yw * float2(1.0f, -1.0f), centeredUVRandomFactor)
													 ,dot(cosines.wy, centeredUVRandomFactor)) + float4(0.5f, 0.5f, 0.5f, 0.5f);
				rotatedUVRandomFactor = rotatedUVRandomFactor * _Windy + uvRandomFactor.xyxy * (1 - _Windy);
				float4 scaleLayer12 = float4(1.0f, 1.0f, 2.0f, 2.0f) * _RainTransform.xyxy;
				float4 uvLayer12 = scaleLayer12 * rotatedUV + rotatedUVRandomFactor;
				float4 scaleLayer34 = float4(3.0f, 3.0f, 4.0f, 4.0f) * _RainTransform.xyxy;
				float4 uvLayer34 = scaleLayer34 * i.uv.xyxy + uvRandomFactor.xyxy;

				// occlusion of layer12 and mask of layer34
				
				// Background pixel depth - in view space
				// Mask using virtual layer depth and the depth map
				// RainDepthMapTest use the same projection matrix than
				// the one use forrender depth map
				float viewPixelDepth = 0;
				float2 screenUV = i.uvP.xy / i.uvP.w;
				float highPrecisionDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV);
				// _ProjectionParams.z far clip plane
				float linearViewDepth = _ProjectionParams.z * Linear01Depth(highPrecisionDepth);
				viewPixelDepth = linearViewDepth;
				float2 occlusion12 = 0.0f;
				occlusion12.x = rainDepthMapTest(viewPixelDepth, uvLayer12.xy, _RainDepthStart.x, _RainDepthRange.x, _RainOpacities.x);
				occlusion12.y = rainDepthMapTest(viewPixelDepth, uvLayer12.zw, _RainDepthStart.y, _RainDepthRange.y, _RainOpacities.y);
				float2 occlusion34 = 0.0f;
				occlusion34.x = rainDepthMapTest(viewPixelDepth, uvLayer34.xy, _RainDepthStart.z, _RainDepthRange.z, _RainOpacities.z);
				occlusion34.y = rainDepthMapTest(viewPixelDepth, uvLayer34.zw, _RainDepthStart.w, _RainDepthRange.w, _RainOpacities.w);

				// Noise And Distortion
				float2 noiseAndDistortion;
				noiseAndDistortion.x = tex2D(_NoiseTex, screenUV);
				noiseAndDistortion.y = tex2D(_DistortionTex, screenUV);

				fixed4 rainPropertyOutput = fixed4(occlusion12.xy * noiseAndDistortion, occlusion34 * noiseAndDistortion);

				// Albedo comes from a texture tinted by color
				float4 values = 1.0f;
				values.x = tex2D(_RainTex, uvLayer12.xy).r;
				values.y = tex2D(_RainTex, uvLayer12.zw).r;
				values.z = tex2D(_RainTex, uvLayer34.xy).r;
				values.w = tex2D(_RainTex, uvLayer34.zw).r;

				float3 outColor = dot(values, rainPropertyOutput).xxx;
				outColor = outColor * 0.09f * _RainIntensity;

				float3 mainColor = tex2D(_MainTex, screenUV).rgb;
				outColor += mainColor;

				return float4(outColor, 1.0f);
			}
			ENDCG
		}
	}
	FallBack"Diffuse"
}
