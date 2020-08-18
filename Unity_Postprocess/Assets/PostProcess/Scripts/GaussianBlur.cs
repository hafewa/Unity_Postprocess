using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;


namespace PostProcess
{
	[ExecuteInEditMode, ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
	public sealed class GaussianBlur : PostProcessBase
	{
		private static readonly int intencity1ID = Shader.PropertyToID("_Intencity1");
		private static readonly int intencity2ID = Shader.PropertyToID("_Intencity2");
		private static readonly int thresholdID = Shader.PropertyToID("_Threshold");
		private static readonly int radiusID = Shader.PropertyToID("_Radius");
		private static readonly int thresholdRT_ID = Shader.PropertyToID("_ThresholdRT");
		private static readonly int small1RT_ID = Shader.PropertyToID("_Small1RT");
		private static readonly int small2RT_ID = Shader.PropertyToID("_Small2RT");
		private static readonly int middleRT_ID = Shader.PropertyToID("_MiddleRT1");
		private static readonly int bloomSource1ID = Shader.PropertyToID("_BloomSource1");
		private static readonly int bloomSource2ID = Shader.PropertyToID("_BloomSource2");
		private static readonly int bloomSource1RT_ID = Shader.PropertyToID("_BloomSourceRT1");
		private static readonly int bloomSource2RT_ID = Shader.PropertyToID("_BloomSourceRT2");
		private static readonly int COLOR_PROP_ID = Shader.PropertyToID("_Color");

		[SerializeField][Range(0, 40)]
		private float intencity1 = 1;

		[SerializeField][Range(0, 10)]
		private float threshold1 = 1;

		[SerializeField][Range(2, 20)]
		private float radius1 = 8;

		[SerializeField][Range(0, 40)]
		private float intencity2 = 1;

		[SerializeField][Range(0, 10)]
		private float threshold2 = 1;

		[SerializeField][Range(2, 80)]
		private float radius2 = 8;


		private void RenderBlur(CommandBuffer commandBuffer, RenderTargetIdentifier src, int outputBufferID, float threshold, float radius, bool isCrossBloom)
		{
			commandBuffer.SetGlobalFloat(thresholdID, threshold);
			commandBuffer.SetGlobalFloat(radiusID, radius);
			int width = (int)(Screen.width / radius);
			int height = (int)(Screen.height / radius);
			commandBuffer.GetTemporaryRT(thresholdRT_ID, width, height, 0, FilterMode.Bilinear);
			commandBuffer.Blit(src, thresholdRT_ID, material, 0);

			// filter
			commandBuffer.GetTemporaryRT(small1RT_ID, width, height, 0, FilterMode.Bilinear);
			if (isCrossBloom)
			{
				commandBuffer.Blit(thresholdRT_ID, small1RT_ID, material, 1);
			}
			else
			{
				commandBuffer.GetTemporaryRT(small2RT_ID, width, height, 0, FilterMode.Bilinear);
				commandBuffer.Blit(thresholdRT_ID, small2RT_ID, material, 2);
				commandBuffer.Blit(small2RT_ID, small1RT_ID, material, 3);
			}
			commandBuffer.SetGlobalFloat(radiusID, radius / 2);
			commandBuffer.GetTemporaryRT(middleRT_ID, width * 2, height * 2, 0, FilterMode.Bilinear);
			commandBuffer.GetTemporaryRT(outputBufferID, width * 2, height * 2, 0, FilterMode.Bilinear);
			commandBuffer.Blit(small1RT_ID, middleRT_ID, material, 2);
			commandBuffer.Blit(middleRT_ID, outputBufferID, material, 3);
		}

		private void OnRenderImage(RenderTexture source, RenderTexture destination)
		{
			if (material == null)
			{
				material = new Material(Shader.Find("Hidden/PostProcess/Gaussian"));
				material.hideFlags = HideFlags.HideAndDontSave;
			}

			if (material == null)
			{
				Graphics.Blit(source, destination);
				return;
			}

			var commandBuffer = new CommandBuffer();
			//material.SetColor(COLOR_PROP_ID, color);

			// Additive to original scene
			commandBuffer.SetGlobalFloat(intencity1ID, intencity1);
			commandBuffer.SetGlobalFloat(intencity2ID, intencity2);
			RenderBlur(commandBuffer, source, bloomSource1RT_ID, threshold1, radius1, true);
			RenderBlur(commandBuffer, source, bloomSource2RT_ID, threshold2, radius2, false);
			commandBuffer.SetGlobalTexture(bloomSource1ID, bloomSource1RT_ID);
			commandBuffer.SetGlobalTexture(bloomSource2ID, bloomSource2RT_ID);
			commandBuffer.Blit((RenderTargetIdentifier)source, destination, material, 4);
			Graphics.ExecuteCommandBuffer(commandBuffer);
		}
	}

}

