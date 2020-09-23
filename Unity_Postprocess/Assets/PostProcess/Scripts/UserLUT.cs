using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace PostProcess
{
	[ExecuteInEditMode, ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
	public sealed class UserLUT : PostProcessBase
	{
		static readonly int LUT = Shader.PropertyToID("_LUT");
		static readonly int CONTRIBUTION = Shader.PropertyToID("_Contribution");

		public Texture2D lutTexture = default;

		[Range(0.0f, 1.0f)]
		public float contribution = 1.0f;


		/// <summary>
		/// ImageEffect Opaque
		/// </summary>
		/// <param name="source"></param>
		/// <param name="destination"></param>
		private void OnRenderImage(RenderTexture source, RenderTexture destination)
		{
			if (material == null)
			{
				material = new Material(Shader.Find("Hidden/PostProcess/UserLUT"));
				material.hideFlags = HideFlags.HideAndDontSave;
			}

			if (material == null)
			{
				Graphics.Blit(source, destination);
				return;
			}

			material.SetTexture(LUT, lutTexture);
			material.SetFloat(CONTRIBUTION, contribution);

			Graphics.Blit(source, destination, material);
		}

	}

}

