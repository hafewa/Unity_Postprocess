using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace PostProcess
{
	[ExecuteInEditMode, ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
	public sealed class FXAA : PostProcessBase
	{
		[Header("if trued console quality FXAA. falsed Fast FXAA")]
		public bool priorityQuality = false;

		private void OnEnable()
		{
			if (material == null)
			{
				material = new Material(Shader.Find("Hidden/PostProcess/FXAA"));
				material.hideFlags = HideFlags.HideAndDontSave;
			}

			var cam = GetComponent<Camera>();
			if (cam.allowMSAA)
			{
				cam.allowMSAA = false;
			}
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
				Graphics.Blit(source, destination);
				return;
			}

			float w = 1.0f / Screen.width;
			float h = 1.0f / Screen.height;

			material.SetVector("_FXAAFrame", new Vector4(w, h, 0, 0));
			material.SetVector("_FXAAFrameSize", new Vector4(w * 2, h * 2, w * 0.5f, h * 0.5f));

			// Renders faster on mobile builds..
#if UNITY_EDITOR
			int pass = 0;
			if (priorityQuality)
			{
				pass = 1;
			}

			Graphics.Blit(source, destination, material, pass);
#else
			Graphics.Blit(source, destination, material, 0);
#endif

		}
	}

}

