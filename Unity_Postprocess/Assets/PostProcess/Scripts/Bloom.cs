using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace PostProcess
{
	[ExecuteInEditMode, ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
	public sealed class Bloom : PostProcessBase
	{
		static readonly int FILTER_PROP_ID = Shader.PropertyToID("_Filter");
		static readonly int COLOR_PROP_ID = Shader.PropertyToID("_Color");
		static readonly int INTENSITY_PROP_ID = Shader.PropertyToID("_Intensity");
		static readonly int SOURCE_PROP_ID = Shader.PropertyToID("_SourceTex");
		const int BoxDownPrefilterPass = 0;
		const int BoxDownPass = 1;
		const int BoxUpPass = 2;
		const int ApplyBloomPass = 3;
		const int DebugBloomPass = 4;

		public float Intensity { get => intensity; set => intensity = value; }

		public float Threshold { get => threshold; set => threshold = value; }

		public float SoftThreshold { get => softThreshold; set => softThreshold = value; }

		public Color Color { get => color; set => color = value; }

		[SerializeField][Range(0, 10)]
		private float intensity = 1;

		[SerializeField][Range(0, 10)]
		private float threshold = 1;

		[SerializeField][Range(0, 1)]
		private float softThreshold = 0.5f;

		[SerializeField, ColorUsage(false, true)]
		private Color color = Color.black;

		[SerializeField]
		private bool debug;

		[SerializeField]
		private int iterations = 4;

		private RenderTexture[] textures = new RenderTexture[8];

		/// <summary>
		/// ImageEffect Opaque
		/// </summary>
		/// <param name="source"></param>
		/// <param name="destination"></param>
		private void OnRenderImage(RenderTexture source, RenderTexture destination)
		{
			if (material == null)
			{
				material = new Material(Shader.Find("Hidden/PostProcess/Bloom"));
				material.hideFlags = HideFlags.HideAndDontSave;
			}

			if (material == null)
			{
				Graphics.Blit(source, destination);
				return;
			}

			float knee = threshold * softThreshold;
			Vector4 filter;
			filter.x = threshold;
			filter.y = threshold - knee;
			filter.z = knee * 2f;
			filter.w = 0.25f / (knee + 0.00001f);
			material.SetVector(FILTER_PROP_ID, filter);
			material.SetColor(COLOR_PROP_ID, color);
			material.SetFloat(INTENSITY_PROP_ID, Mathf.GammaToLinearSpace(intensity));

			int width = source.width / 2;
			int height = source.height / 2;
			RenderTextureFormat format = source.format;

			RenderTexture currentDestination = textures[0] = RenderTexture.GetTemporary(width, height, 0, format);
			Graphics.Blit(source, currentDestination, material, BoxDownPrefilterPass);
			RenderTexture currentSource = currentDestination;

			int i = 1;
			for (; i < iterations; ++i)
			{
				width /= 2;
				height /= 2;
				if (height < 2)
				{
					break;
				}
				currentDestination = textures[i] = RenderTexture.GetTemporary(width, height, 0, format);
				Graphics.Blit(currentSource, currentDestination, material, BoxDownPass);
				currentSource = currentDestination;
			}

			for (i -= 2; i >= 0; --i)
			{
				currentDestination = textures[i];
				textures[i] = null;
				Graphics.Blit(currentSource, currentDestination, material, BoxUpPass);
				RenderTexture.ReleaseTemporary(currentSource);
				currentSource = currentDestination;
			}

			if (debug)
			{
				Graphics.Blit(currentSource, destination, material, DebugBloomPass);
			}
			else
			{
				material.SetTexture(SOURCE_PROP_ID, source);
				Graphics.Blit(currentSource, destination, material, ApplyBloomPass);
			}
			RenderTexture.ReleaseTemporary(currentSource);
		}
	}
}
