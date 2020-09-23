using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace PostProcess
{
	[ExecuteInEditMode, ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
	public sealed class Glare : PostProcessBase
	{
		private static readonly int THRESHOLD_ID = Shader.PropertyToID("_Threshold");
		private static readonly int ATTENUATION_ID = Shader.PropertyToID("_Attenuation");
		private static readonly int INTENSITY_ID = Shader.PropertyToID("_Intensity");
		private static readonly int ITERATION_ID = Shader.PropertyToID("_Iteration");

		[Range(0.0f, 10.0f)]
		public float threshold = 0.5f;

		[Range(0.5f, 0.95f)]
		public float attenuation = 0.9f;

		[Range(0.0f, 10.0f)]
		public float intensity = 1.0f;

		[Range(1, 6)]
		public int resolution = 4;

		[Range(1, 10)]
		public int iteration = 4;

		[Range(0f, 2f)]
		public float valueX, valueY;

		/// <summary>
		/// ImageEffect Opaque
		/// </summary>
		/// <param name="source"></param>
		/// <param name="destination"></param>
		private void OnRenderImage(RenderTexture source, RenderTexture dest)
		{
			if (material == null)
			{
				material = new Material(Shader.Find("Hidden/PostProcess/Glare"));
				material.hideFlags = HideFlags.HideAndDontSave;
			}

			if (material == null)
			{
				Graphics.Blit(source, dest);
				return;
			}

			var paramsId = Shader.PropertyToID("_Params");
			material.SetFloat(THRESHOLD_ID, threshold);
			material.SetFloat(ATTENUATION_ID, attenuation);
			material.SetFloat(INTENSITY_ID, intensity);
			material.SetFloat(ITERATION_ID, iteration);

			int width = source.width / resolution;
			int height = source.height / resolution;
			var tempRT1 = RenderTexture.GetTemporary(width, height, 0, RenderTextureFormat.ARGBHalf);
			var tempRT2 = RenderTexture.GetTemporary(width, height, 0, RenderTextureFormat.ARGBHalf);

			Graphics.Blit(source, dest);

			for (int i = 0; i < iteration; ++i)
			{
				Graphics.Blit(source, tempRT1, material, 0);

				var currentSrc = tempRT1;
				var currentTarget = tempRT2;
				var parameters = Vector3.zero;

				// (-1, -1), (-1, 1), (1, -1), (1, 1)
				parameters.x = i == 0 || i == 1 ? -1 * valueX : valueX;
				parameters.y = i == 0 || i == 2 ? -1 * valueY : valueY;

				for (int j = 0; j < this.iteration; ++j)
				{
					parameters.z = j;
					material.SetVector(paramsId, parameters);
					Graphics.Blit(currentSrc, currentTarget, material, 1);
					var tmp = currentSrc;
					currentSrc = currentTarget;
					currentTarget = tmp;
				}
				Graphics.Blit(currentSrc, dest, material, 2);
			}
			RenderTexture.ReleaseTemporary(tempRT1);
			RenderTexture.ReleaseTemporary(tempRT2);
		}
	}

}

