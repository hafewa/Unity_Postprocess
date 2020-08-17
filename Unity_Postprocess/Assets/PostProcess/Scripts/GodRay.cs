using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace PostProcess
{
	[ExecuteInEditMode, ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
	public class GodRay : PostProcessBase
	{
		private static readonly int THRESHOLD_ID = Shader.PropertyToID("_ColorThreshold");
		private static readonly int LIGHTPOS_ID = Shader.PropertyToID("_ViewPortLightPos");
		private static readonly int RADIUS_IS = Shader.PropertyToID("_LightRadius");
		private static readonly int POWFACTOR_ID = Shader.PropertyToID("_PowFactor");
		private static readonly int BLURTEX_ID = Shader.PropertyToID("_BlurTex");
		private static readonly int LIGHTCOLOR_ID = Shader.PropertyToID("_LightColor");
		private static readonly int LIGHTFACTOR_ID = Shader.PropertyToID("_LightFactor");
		private static readonly int OFFSET_ID = Shader.PropertyToID("_offsets");
		private static readonly int DEPTH_THRESHOLD_ID = Shader.PropertyToID("_DepthThreshold");

		[Range(0.0f, 0.1f)]
		public float depthThreshold = 0.01f;

		public Color colorThreshold = Color.gray;
		public Color lightColor = Color.white;

		[Range(0.0f, 20.0f)]
		public float lightFactor = 0.5f;

		[Range(0.0f, 10.0f)]
		public float samplerScale = 1;

		[Range(1, 3)]
		public int blurIteration = 2;

		[Range(0, 3)]
		public int downSample = 1;

		public Transform lightTransform;

		[Range(0.0f, 5.0f)]
		public float lightRadius = 2.0f;

		[Range(1.0f, 4.0f)]
		public float lightPowFactor = 3.0f;

		private Camera targetCamera = null;

		private void Awake()
		{
			targetCamera = GetComponent<Camera>();
		}

		private void OnRenderImage(RenderTexture source, RenderTexture destination)
		{
			if (material == null)
			{
				material = new Material(Shader.Find("Hidden/PostProcess/GodRay"));
				material.hideFlags = HideFlags.HideAndDontSave;
			}

			if (this.targetCamera == null || material == null)
			{
				Graphics.Blit(source, destination);
				return;
			}

			int rtWidth = source.width >> downSample;
			int rtHeight = source.height >> downSample;
			RenderTexture temp1 = RenderTexture.GetTemporary(rtWidth, rtHeight, 0, source.format);

			Vector3 viewPortLightPos = lightTransform == null ? new Vector3(.5f, .5f, 0) : targetCamera.WorldToViewportPoint(lightTransform.position);
			material.SetVector(THRESHOLD_ID, colorThreshold);
			material.SetVector(LIGHTPOS_ID, new Vector4(viewPortLightPos.x, viewPortLightPos.y, viewPortLightPos.z, 0));
			material.SetFloat(RADIUS_IS, lightRadius);
			material.SetFloat(POWFACTOR_ID, lightPowFactor);
			material.SetFloat(DEPTH_THRESHOLD_ID, depthThreshold);
			Graphics.Blit(source, temp1, material, 0);

			material.SetVector(LIGHTPOS_ID, new Vector4(viewPortLightPos.x, viewPortLightPos.y, viewPortLightPos.z, 0));
			material.SetFloat(RADIUS_IS, lightRadius);
			float samplerOffset = samplerScale / source.width;

			for (int i = 0; i < blurIteration; ++i)
			{
				RenderTexture temp2 = RenderTexture.GetTemporary(rtWidth, rtHeight, 0, source.format);
				float offset = samplerOffset * (i * 2 + 1);
				material.SetVector(OFFSET_ID, new Vector4(offset, offset, 0, 0));
				Graphics.Blit(temp1, temp2, material, 1);

				offset = samplerOffset * (i * 2 + 2);
				material.SetVector(OFFSET_ID, new Vector4(offset, offset, 0, 0));
				Graphics.Blit(temp2, temp1, material, 1);
				RenderTexture.ReleaseTemporary(temp2);
			}

			material.SetTexture(BLURTEX_ID, temp1);
			material.SetVector(LIGHTCOLOR_ID, lightColor);
			material.SetFloat(LIGHTFACTOR_ID, lightFactor);
			Graphics.Blit(source, destination, material, 2);
			RenderTexture.ReleaseTemporary(temp1);
		}
	}

}

