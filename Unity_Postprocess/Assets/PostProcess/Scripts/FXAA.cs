using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace PostProcess
{
	[ExecuteInEditMode, ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
	public sealed class FXAA : PostProcessBase
	{
		/// <summary>
		/// ImageEffect Opaque
		/// </summary>
		/// <param name="source"></param>
		/// <param name="destination"></param>
		private void OnRenderImage(RenderTexture source, RenderTexture destination)
		{
			if (material == null)
			{
				material = new Material(Shader.Find("Hidden/PostProcess/FXAA"));
				material.hideFlags = HideFlags.HideAndDontSave;
			}

			if (material == null)
			{
				Graphics.Blit(source, destination);
				return;
			}

			float rcpWidth = 1.0f / Screen.width;
			float rcpHeight = 1.0f / Screen.height;

			material.SetVector("_rcpFrame", new Vector4(rcpWidth, rcpHeight, 0, 0));
			material.SetVector("_rcpFrameOpt", new Vector4(rcpWidth * 2, rcpHeight * 2, rcpWidth * 0.5f, rcpHeight * 0.5f));

			Graphics.Blit(source, destination, material);
		}
	}

}

