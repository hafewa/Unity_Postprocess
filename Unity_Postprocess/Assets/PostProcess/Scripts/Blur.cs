using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;


namespace PostProcess
{
	[ExecuteInEditMode, ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
	public sealed class Blur : PostProcessBase
	{
		static readonly int PIXEL_ID = Shader.PropertyToID("_PixelSize");

		[SerializeField][Range(0, 20)]
		private float resolution = 0;

		//[SerializeField][Range(0, 20)]
		//private float dispersion = 4f;

		private int iteration = 8;

		public float Resolution { get => resolution; set => resolution = value; }

		//public float Dispersion { get => dispersion; set => dispersion = value; }


		private float[] CalcWeight(float dispersion, int count)
		{
			float[] weight = new float[count];
			float total = 0;
			for (int i = 0; i < weight.Length; ++i)
			{
				weight[i] = Mathf.Exp(-0.5f * (i * i) / dispersion);
				total += weight[i] * ((0 == i) ? 1 : 2);
			}
			for (int i = 0; i < weight.Length; ++i)
			{
				weight[i] /= total;
			}
			return weight;
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
				material = new Material(Shader.Find("Hidden/PostProcess/Blur"));
				material.hideFlags = HideFlags.HideAndDontSave;
			}

			if (resolution <= 0 || material == null)
			{
				Graphics.Blit(source, destination);
				return;
			}

			var value = Mathf.FloorToInt(resolution);
			CommandBuffer command = new CommandBuffer();
			int rt1 = Shader.PropertyToID("RT1");
			command.GetTemporaryRT(rt1, -value, -value, 0, FilterMode.Point);
			int rt2 = Shader.PropertyToID("RT2");
			command.GetTemporaryRT(rt2, -value, -value, 0, FilterMode.Trilinear);

			//var weight = CalcWeight(this.dispersion, this.iteration);
			//material.SetFloatArray(PIXEL_ID, weight);

			command.SetGlobalVector(PIXEL_ID, new Vector4(resolution / Screen.width * 0.5f, resolution / Screen.height * 0.5f, 0, 0));
			command.Blit((RenderTargetIdentifier)source, rt1, this.material, 0);
			command.Blit(rt1, rt2, material, 1);
			command.Blit(rt2, destination);
			Graphics.ExecuteCommandBuffer(command);
		}
	}

}

