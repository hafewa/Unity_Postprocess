using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace PostProcess
{
	[ExecuteInEditMode, ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
	public class GlareController : MonoBehaviour
	{
		private static readonly int THRESHOLD_ID = Shader.PropertyToID("_Threshold");
		private static readonly int ATTENUATION_ID = Shader.PropertyToID("_Attenuation");
		private static readonly int INTENSITY_ID = Shader.PropertyToID("_Intensity");
		private static readonly int ITERATION_ID = Shader.PropertyToID("_Iteration");

		private Material material;

		[SerializeField, Range(0.0f, 10.0f)]
		private float threshold = 0.5f;

		[SerializeField, Range(0.5f, 0.95f)]
		private float attenuation = 0.9f;

		[SerializeField, Range(0.0f, 10.0f)]
		private float intensity = 1.0f;

		[SerializeField, Range(2, 8)]
		private int iteration = 4;

		[SerializeField, Range(0f, 2f)]
		private float valueX, valueY;

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
			material.SetFloat(THRESHOLD_ID, this.threshold);
			material.SetFloat(ATTENUATION_ID, this.attenuation);
			material.SetFloat(INTENSITY_ID, this.intensity);
			material.SetFloat(ITERATION_ID, this.iteration);

			var tempRT1 = RenderTexture.GetTemporary(source.width / this.iteration, source.height / this.iteration);
			var tempRT2 = RenderTexture.GetTemporary(source.width / this.iteration, source.height / this.iteration);

			// SourceをDestにコピーしておく
			Graphics.Blit(source, dest);

			// 4方向にスターを作るループ
			for (int i = 0; i < this.iteration; ++i)
			{
				// まず明度が高い部分を抽出する
				Graphics.Blit(source, tempRT1, material, 0);

				var currentSrc = tempRT1;
				var currentTarget = tempRT2;
				var parameters = Vector3.zero;

				// x, yにUV座標のオフセットを代入する
				// (-1, -1), (-1, 1), (1, -1), (1, 1)
				parameters.x = i == 0 || i == 1 ? -1 * valueX : valueX;
				parameters.y = i == 0 || i == 2 ? -1 * valueY : valueY;

				// 1方向にぼかしを伸ばしていくループ
				for (int j = 0; j < this.iteration; ++j)
				{
					// zに描画回数のindexを代入してマテリアルにセット
					parameters.z = j;
					material.SetVector(paramsId, parameters);

					// 二つのRenderTextureに交互にBlitして効果を足していく
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

