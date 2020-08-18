using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;


namespace PostProcess
{
	[ExecuteInEditMode, ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
	public sealed class RadialBlur : PostProcessBase
	{
		static readonly int SAMPLES_ID = Shader.PropertyToID("_Samples");
		static readonly int AMOUNT_ID = Shader.PropertyToID("_EffectAmount");
		static readonly int CENTERX_ID = Shader.PropertyToID("_CenterX");
		static readonly int CENTERY_ID = Shader.PropertyToID("_CenterY");
		static readonly int RADIUS_ID = Shader.PropertyToID("_Radius");


		[SerializeField][Range(4f, 32f)]
		private float samples = 10f;

		[SerializeField]
		private float amount = 1f;

		[SerializeField][Range(0f, 1f)]
		private float centerX = 0.5f;

		[SerializeField][Range(0f, 1f)]
		private float centerY = 0.5f;

		[SerializeField][Range(0f, 50f)]
		private float radius = 0.1f;

		private void OnRenderImage(RenderTexture source, RenderTexture destination)
		{
			if (material == null)
			{
				material = new Material(Shader.Find("Hidden/PostProcess/RadialBlur"));
				material.hideFlags = HideFlags.HideAndDontSave;
			}

			if (material == null)
			{
				Graphics.Blit(source, destination);
				return;
			}

			material.SetFloat(SAMPLES_ID, this.samples);
			material.SetFloat(AMOUNT_ID, this.amount);
			material.SetFloat(CENTERX_ID, this.centerX);
			material.SetFloat(CENTERY_ID, this.centerY);
			material.SetFloat(RADIUS_ID, this.radius);
			Graphics.Blit(source, destination, this.material);
		}
	}

}

