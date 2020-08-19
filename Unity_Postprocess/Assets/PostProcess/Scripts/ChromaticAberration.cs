using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;


namespace PostProcess
{
	[ExecuteInEditMode, ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
	public sealed class ChromaticAberration : PostProcessBase
	{
		static readonly int PROP_R = Shader.PropertyToID("_ROffset");
		static readonly int PROP_G = Shader.PropertyToID("_GOffset");
		static readonly int PROP_B = Shader.PropertyToID("_BOffset");

		public Vector2 R = default;
		public Vector2 G = default;
		public Vector2 B = default;

		/// <summary>
		/// ImageEffect Opaque
		/// </summary>
		/// <param name="source"></param>
		/// <param name="destination"></param>
		private void OnRenderImage(RenderTexture source, RenderTexture destination)
		{
			if (material == null)
			{
				material = new Material(Shader.Find("Hidden/PostProcess/ChromaticAberration"));
				material.hideFlags = HideFlags.HideAndDontSave;
			}

			if (material == null)
			{
				Graphics.Blit(source, destination);
				return;
			}

			material.SetVector(PROP_R, R);
			material.SetVector(PROP_G, G);
			material.SetVector(PROP_B, B);
			Graphics.Blit(source, destination, material);
		}

	}

}

