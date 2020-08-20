using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace PostProcess
{
	[ExecuteInEditMode, ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
	public sealed class Glitch : PostProcessBase
	{
		[Range(0, 50f)]
		public float speed = default;

		[Range(0, 50f)]
		public float blockSize = 8f;

		[Range(0f, 25f)]
		public float maxRGBSplitX = 1f;

		[Range(0f, 25f)]
		public float maxRGBSplitY = 1f;

		/// <summary>
		/// ImageEffect Opaque
		/// </summary>
		/// <param name="source"></param>
		/// <param name="destination"></param>
		private void OnRenderImage(RenderTexture source, RenderTexture destination)
		{
			if (material == null)
			{
				material = new Material(Shader.Find("Hidden/PostProcess/Glitch"));
				material.hideFlags = HideFlags.HideAndDontSave;
			}

			if (material == null)
			{
				Graphics.Blit(source, destination);
				return;
			}

			material.SetFloat("_Speed", speed);
			material.SetFloat("_BlockSize", blockSize);
			material.SetFloat("_MaxRGBSplitX", maxRGBSplitX);
			material.SetFloat("_MaxRGBSplitY", maxRGBSplitY);
			Graphics.Blit(source, destination, material);
		}
	}


}

