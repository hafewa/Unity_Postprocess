using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;


namespace PostProcess
{
	[ExecuteInEditMode, ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
	public class BlurController : MonoBehaviour
	{
		static readonly int PIXEL_ID = Shader.PropertyToID("_PixelSize");

		private Material material;

		[SerializeField]
		[Range(0, 20)]
		private float resolution = 0;

		//[SerializeField][Range(2, 50)]
		private float dispersion = 4f;

		//[SerializeField][Range(2, 100)]
		private int iteration = 8;

		public float Resolution
		{
			get { return this.resolution; }
		}

		public void SetResolution(float newResolution)
		{
			this.resolution = newResolution;
		}

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

		private void OnRenderImage(RenderTexture source, RenderTexture dest)
		{
			if (this.material == null)
			{
				this.material = new Material(Shader.Find("Hidden/PostProcess/Blur"));
				this.material.hideFlags = HideFlags.HideAndDontSave;
			}

			if (resolution <= 0)
			{
				Graphics.Blit(source, dest);
				return;
			}

			var value = Mathf.FloorToInt(resolution);
			CommandBuffer command = new CommandBuffer();
			int rt1 = Shader.PropertyToID("RT1");
			command.GetTemporaryRT(rt1, -value, -value, 0, FilterMode.Point);
			int rt2 = Shader.PropertyToID("RT2");
			command.GetTemporaryRT(rt2, -value, -value, 0, FilterMode.Trilinear);

			//var weight = CalcWeight(this.dispersion, this.iteration);
			//this.material.SetFloatArray(PIXEL_ID, weight);

			command.SetGlobalVector(PIXEL_ID, new Vector4(resolution / Screen.width * 0.5f, resolution / Screen.height * 0.5f, 0, 0));
			command.Blit((RenderTargetIdentifier)source, rt1, this.material, 0);
			command.Blit(rt1, rt2, material, 1);
			command.Blit(rt2, dest);
			Graphics.ExecuteCommandBuffer(command);
		}
	}

}

