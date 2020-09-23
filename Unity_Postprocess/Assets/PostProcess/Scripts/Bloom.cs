using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace PostProcess
{
	[ExecuteInEditMode, ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
	public sealed class Bloom : PostProcessBase
	{
		private enum Pass
		{
			Prefilter = 0,
			Down = 1,
			Up = 2,
			Final = 3,
		}

		static readonly int FILTER_PROP_ID = Shader.PropertyToID("_Filter");
		static readonly int COLOR_PROP_ID = Shader.PropertyToID("_Color");
		static readonly int INTENSITY_PROP_ID = Shader.PropertyToID("_Intensity");
		static readonly int SOURCE_PROP_ID = Shader.PropertyToID("_SourceTex");

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

		[SerializeField][Range(1, 4)]
		private int resolution = 1;

		[SerializeField, ColorUsage(false, true)]
		private Color color = Color.black;

		[SerializeField][Range(1,8)]
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
			Vector4 filter = Vector4.zero;
			filter.x = threshold;
			filter.y = threshold - knee;
			filter.z = knee * 2f;
			filter.w = 0.25f / (knee + 0.00001f);
			material.SetVector(FILTER_PROP_ID, filter);
			material.SetColor(COLOR_PROP_ID, color);
			material.SetFloat(INTENSITY_PROP_ID, Mathf.GammaToLinearSpace(intensity));

			int width = source.width / resolution;
			int height = source.height / resolution;
			// BGRA32
			RenderTextureFormat format = RenderTextureFormat.ARGBHalf;//source.format;

			RenderTexture currentDestination = textures[0] = RenderTexture.GetTemporary(width, height, 0, format);
			Graphics.Blit(source, currentDestination, material, (int)Pass.Prefilter);
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
				Graphics.Blit(currentSource, currentDestination, material, (int)Pass.Down);
				currentSource = currentDestination;
			}

			for (i -= 2; i >= 0; --i)
			{
				currentDestination = textures[i];
				textures[i] = null;
				Graphics.Blit(currentSource, currentDestination, material, (int)Pass.Up);
				RenderTexture.ReleaseTemporary(currentSource);
				currentSource = currentDestination;
			}

			material.SetTexture(SOURCE_PROP_ID, source);
			Graphics.Blit(currentSource, destination, material, (int)Pass.Final);
			RenderTexture.ReleaseTemporary(currentSource);
		}
	}
}
