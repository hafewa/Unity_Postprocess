using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace PostProcess
{
	[ExecuteInEditMode, ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
	public sealed class ChromaDepth : PostProcessBase
	{
		[SerializeField][Range(0.0f, 100.0f)]
		private float waveSpeed = 2.0f;

		[SerializeField][Range(0.0f, 100.0f)]
		private float waveTrail = 2.0f;

		[SerializeField]
		private Color waveColor = new Color(0, 0, 0, 0);

		[SerializeField]
		private Texture2D noiseTexture = default;

		[SerializeField]
		private float noiseScale = default;

		private new Camera camera;

		private void Start()
		{
			if (camera == null)
			{
				camera = GetComponent<Camera>();
			}
			camera.depthTextureMode |= DepthTextureMode.Depth;
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
				material = new Material(Shader.Find("Hidden/PostProcess/ChromaDepth"));
				material.hideFlags = HideFlags.HideAndDontSave;
			}

			if (material == null)
			{
				Graphics.Blit(source, destination);
				return;
			}

			material.SetMatrix("_FrustumCornersWS", GetFrustumCorners());
			material.SetVector("_CameraWorldSpase", camera.transform.position);
			material.SetFloat("_WaveSpeed", waveSpeed);
			material.SetFloat("_WaveTrail", waveTrail);
			material.SetFloat("_NoiseScale", noiseScale);
			material.SetColor("_WaveColor", waveColor);
			material.SetTexture("_NoiseTex", noiseTexture);
			Graphics.Blit(source, destination, material);
		}


		/// brief Stores the normalized rays representing the camera frustum in a 4x4 matrix.  Each row is a vector.
		/// The following rays are stored in each row (in eyespace, not worldspace):
		/// Top Left corner:     row=0
		/// Top Right corner:    row=1
		/// Bottom Right corner: row=2
		/// Bottom Left corner:  row=3
		private Matrix4x4 GetFrustumCorners()
		{
			Transform cameraTransform = camera.transform;
			Matrix4x4 frustumCorners = Matrix4x4.identity;
			float near = camera.nearClipPlane;
			float far = camera.farClipPlane;
			float fov = camera.fieldOfView;
			float cameraAspect = camera.aspect;

			float fovWHalf = fov * 0.5f;
			Vector3 toRight = cameraTransform.right * near * Mathf.Tan(fovWHalf * Mathf.Deg2Rad) * cameraAspect;
			Vector3 toTop = cameraTransform.up * near * Mathf.Tan(fovWHalf * Mathf.Deg2Rad);
			Vector3 topLeft = (cameraTransform.forward * near - toRight + toTop);
			float camScale = topLeft.magnitude * far / near;
			topLeft.Normalize();
			topLeft *= camScale;

			Vector3 topRight = (cameraTransform.forward * near + toRight + toTop);
			topRight.Normalize();
			topRight *= camScale;

			Vector3 bottomRight = (cameraTransform.forward * near + toRight - toTop);
			bottomRight.Normalize();
			bottomRight *= camScale;

			Vector3 bottomLeft = (cameraTransform.forward * near - toRight - toTop);
			bottomLeft.Normalize();
			bottomLeft *= camScale;

			frustumCorners.SetRow(0, topLeft);
			frustumCorners.SetRow(1, topRight);
			frustumCorners.SetRow(2, bottomRight);
			frustumCorners.SetRow(3, bottomLeft);
			return frustumCorners;

		}


	}

}

