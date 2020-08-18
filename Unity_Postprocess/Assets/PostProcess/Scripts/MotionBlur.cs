using UnityEngine;

namespace PostProcess
{
	[ExecuteInEditMode, ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
	public sealed class MotionBlur : PostProcessBase
	{
		[Header("ぼかしの閾値")]
		[SerializeField]
		private float blurAmount = 0.6f;

		[Header("余分なぼかしを行うか")]
		[SerializeField]
		private bool extraBlur = false;

		[SerializeField][Range(2, 8)]
		private int resolution = 4;

		// Resouces
		private RenderTexture accumTexture;

		protected override void OnDisable()
		{
			base.OnDisable();

			if (accumTexture != null)
			{
				accumTexture.Release();
				DestroyImmediate(accumTexture);
				accumTexture = null;
			}
		}

		private void OnRenderImage(RenderTexture source, RenderTexture destination)
		{
			if (material == null)
			{
				material = new Material(Shader.Find("Hidden/PostProcess/MotionBlur"));
				material.hideFlags = HideFlags.HideAndDontSave;
			}

			if (material == null)
			{
				Graphics.Blit(source, destination);
				return;
			}

			if (accumTexture != null && (accumTexture.width != source.width || accumTexture.height != source.height))
			{
				accumTexture.Release();
				DestroyImmediate(accumTexture);
				accumTexture = null;
			}

			if (accumTexture == null)
			{
				accumTexture = new RenderTexture(source.width, source.height, 0);
				accumTexture.hideFlags = HideFlags.HideAndDontSave;
				accumTexture.Create();
				Graphics.Blit(source, accumTexture);
			}

			if (extraBlur)
			{
				RenderTexture blurbuffer = RenderTexture.GetTemporary(source.width / resolution, source.height / resolution, 0);
				// restore処理を行う
				accumTexture.MarkRestoreExpected();
				Graphics.Blit(accumTexture, blurbuffer);
				Graphics.Blit(blurbuffer, accumTexture);
				RenderTexture.ReleaseTemporary(blurbuffer);
			}

			blurAmount = Mathf.Clamp(blurAmount, 0.0f, 0.92f);

			material.SetTexture("_MainTex", accumTexture);
			material.SetFloat("_AccumOrig", 1.0f - blurAmount);

			accumTexture.MarkRestoreExpected();

			Graphics.Blit(source, accumTexture, material);
			Graphics.Blit(accumTexture, destination);
		}
	}

}

