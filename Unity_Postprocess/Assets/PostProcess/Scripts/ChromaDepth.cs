using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace PostProcess
{
	[ExecuteInEditMode, ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
	public sealed class ChromaDepth : PostProcessBase
	{
		[SerializeField][Range(0.0f, 100.0f)]
		private float waveSpeed = 2.0f;

		[SerializeField][Range(0.0f, 100.0f)]
		private float waveTrail = 2.0f;

		[SerializeField]
		private Color waveColor = new Color(0, 0, 0, 0);

		private new Camera camera;

		private void Start()
		{
			if (camera == null)
			{
				camera = GetComponent<Camera>();
			}
			camera.depthTextureMode |= DepthTextureMode.Depth;
		}

		/// <summary>
		/// ImageEffect Opaque
		/// </summary>
		/// <param name="source"></param>
		/// <param name="destination"></param>
		private void OnRenderImage(RenderTexture source, RenderTexture destination)
		{
			if (material == null)
			{
				material = new Material(Shader.Find("Hidden/PostProcess/ChromaDepth"));
				material.hideFlags = HideFlags.HideAndDontSave;
			}

			if (material == null)
			{
				Graphics.Blit(source, destination);
				return;
			}

			material.SetFloat("_WaveSpeed", waveSpeed);
			material.SetFloat("_WaveTrail", waveTrail);
			material.SetColor("_WaveColor", waveColor);
			Graphics.Blit(source, destination, material);
		}
	}

}

