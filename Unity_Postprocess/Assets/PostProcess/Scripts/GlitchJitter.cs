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
			Horizontal  = 0,
			Vertical    = 1,
			Both		= 2,
		}

		[Range(0f, 1f)]
		public float speed = default;

		[Range(0f, 50f)]
		public float frequency = 5f;

		[Range(0f, 50f)]
		public float rgbSplit = 20f;

		[Range(0f, 2f)]
		public float amount = 1f;

		[Range(0f, 1f)]
		public float blend = 0.5f;

		public Vector2 resolution = new Vector2(640f, 480f);
		public bool customResolution = false;
		public bool randomFrequency = false;
		public bool frequencyLoop = false;
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
					customResolution ? resolution.x : Screen.width, 
					customResolution ? resolution.y : Screen.height,
					1f, 
					1f));
		}

	}


}

