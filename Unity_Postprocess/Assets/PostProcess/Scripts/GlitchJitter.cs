using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace PostProcess
{
	[ExecuteInEditMode, ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
	public sealed class GlitchJitter : PostProcessBase
	{
		public enum Direction
		{
			Horizontal = 0,
			Vertical   = 1,
			Both       = 2,
		}

		[Header("UV NoiseStrength")]
		[Range(0f, 2f)]
		public float amount = 1f;

		[Range(0f, 50f)]
		public float frequency = 5f;

		[Header("Noise RGBSplit Speed")]
		[Range(0f, 1f)]
		public float speed = default;

		[Header("ImageEffect RGB Split Params")]
		[Range(0f, 50f)]
		public float rgbSplit = 20f;

		[Header("Horizontal Vertical Blend(Only MixDirection)")]
		[Range(0f, 1f)]
		public float blend = 0.5f;

		[Header("ScreenSize Resolution")]
		[Range(1, 6)]
		public int resolution = 1;

		[Header("If Checked Random FrequencyValue")]
		public bool randomFrequency = false;

		[Header("If Checked Frequency Multiply DeltaTimes")]
		public bool frequencyLoop = false;

		[Header("Glitch Direction")]
		public Direction direction = Direction.Horizontal;

		/// <summary>
		/// ImageEffect Opaque
		/// </summary>
		/// <param name="source"></param>
		/// <param name="destination"></param>
		private void OnRenderImage(RenderTexture source, RenderTexture destination)
		{
			if (material == null)
			{
				material = new Material(Shader.Find("Hidden/PostProcess/GlitchJitter"));
				material.hideFlags = HideFlags.HideAndDontSave;
			}

			if (material == null)
			{
				Graphics.Blit(source, destination);
				return;
			}

			SetKeyword();
			SetMaterialProperty();
			Graphics.Blit(source, destination, material, (int)direction);
		}


		private void SetKeyword()
		{
			if (frequencyLoop)
			{
				material.DisableKeyword("LOOP_OFF");
				material.EnableKeyword("LOOP_ON");
			}
			else
			{
				material.DisableKeyword("LOOP_ON");
				material.EnableKeyword("LOOP_OFF");
			}
		}

		private void SetMaterialProperty()
		{
			material.SetFloat("_Speed", speed);
			material.SetFloat("_RGBSplit", rgbSplit);
			material.SetFloat("_Amount", amount);
			material.SetFloat("_Blend", blend);
			material.SetFloat("_Frequency", randomFrequency ? Random.Range(0, frequency) : frequency);
			material.SetVector("_Resolution", 
				new Vector4(
					(float)Screen.width / resolution,
					(float)Screen.height / resolution,
					1f, 
					1f));
		}

	}


}

