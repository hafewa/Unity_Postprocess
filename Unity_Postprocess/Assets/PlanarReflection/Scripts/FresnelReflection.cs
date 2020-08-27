using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace PostProcess
{
	public sealed class FresnelReflection : MonoBehaviour
	{
		static readonly int REFLECTION_TEX_ID = Shader.PropertyToID("_ReflectionTex");

		private RenderTexture renderBuffer = default;
		private GameObject reflectionCameraObject = default;
		private Camera reflectionCamera = default;
		private Camera targetCamera = default;
		private float minNearClip = default;

		[SerializeField]
		private int resolution = 512;

		[SerializeField]
		private bool enableRefrect = false;


		private void Start()
		{
			if (!enableRefrect)
			{
				return;
			}

			FindCamera();

			SetMaterialKeyWord(true);

			renderBuffer = new RenderTexture(resolution, resolution, 16, RenderTextureFormat.ARGB32);
			renderBuffer.Create();

			reflectionCameraObject = new GameObject();
			reflectionCameraObject.name = "ReflectionCamera";
			reflectionCamera = reflectionCameraObject.AddComponent<Camera>();
			reflectionCamera.cullingMask &= ~(1 << LayerMask.NameToLayer("Mirror"));
			minNearClip = reflectionCamera.nearClipPlane;
			reflectionCameraObject.transform.SetParent(transform);
			reflectionCamera.targetTexture = renderBuffer;
			Shader.SetGlobalTexture(REFLECTION_TEX_ID, renderBuffer);
		}

		private void FindCamera()
		{
			foreach (Camera cam in FindObjectsOfType<Camera>())
			{
				// 1 : MainCameraか?
				// 2 : MainCamera以外に有効なCameraがあるか?
				if (Camera.main == cam && cam.enabled)
				{
					targetCamera = cam;
					break;
				}
				else if (cam.enabled)
				{
					targetCamera = cam;
					break;
				}
			}
		}

		private void OnDisable()
		{
			if (renderBuffer)
			{
				renderBuffer.Release();
				DestroyImmediate(renderBuffer);
				renderBuffer = null;
			}

			if (reflectionCameraObject)
			{
				DestroyImmediate(reflectionCameraObject);
				reflectionCameraObject = null;
			}

			SetMaterialKeyWord(false);
		}

		private void SetReflectionCamera(ref bool bSuccess)
		{
			if (targetCamera == null || reflectionCamera == null)
			{
				return;
			}
			Vector3 normal = transform.up;
			Vector3 pos = transform.position;
			Matrix4x4 mainCamMatrix = targetCamera.worldToCameraMatrix;
			float d = -Vector3.Dot(normal, pos);
			Matrix4x4 refMatrix = CalcReflectionMatrix(new Vector4(normal.x, normal.y, normal.z, d));
			this.reflectionCamera.worldToCameraMatrix = targetCamera.worldToCameraMatrix * refMatrix;
			Vector3 cpos = reflectionCamera.worldToCameraMatrix.MultiplyPoint(pos);
			Vector3 cnormal = reflectionCamera.worldToCameraMatrix.MultiplyVector(normal).normalized;
			if (float.IsNaN(cnormal.x) || float.IsNaN(cnormal.y) || float.IsNaN(cnormal.z))
			{
				return;
			}
			Vector4 clipPlane = new Vector4(cnormal.x, cnormal.y, cnormal.z, -Vector3.Dot(cpos, cnormal));
			reflectionCamera.projectionMatrix = targetCamera.CalculateObliqueMatrix(clipPlane);
			if (float.IsNaN(reflectionCamera.nearClipPlane) || reflectionCamera.nearClipPlane < minNearClip)
			{
				reflectionCamera.nearClipPlane = minNearClip;
			}
			bSuccess = true;
		}

		private void SetMaterialKeyWord(bool enable)
		{
			if (enable)
			{
				Shader.EnableKeyword("_REFLECT_ENABLE");
			}
			else
			{
				Shader.DisableKeyword("_REFLECT_ENABLE");
			}

		}

		private Matrix4x4 CalcReflectionMatrix(Vector4 n)
		{
			Matrix4x4 reflectionMatrix = new Matrix4x4();
			reflectionMatrix.m00 = 1f - 2f * n.x * n.x;
			reflectionMatrix.m01 = -2f * n.x * n.y;
			reflectionMatrix.m02 = -2f * n.x * n.z;
			reflectionMatrix.m03 = -2f * n.x * n.w;

			reflectionMatrix.m10 = -2f * n.x * n.y;
			reflectionMatrix.m11 = 1f - 2f * n.y * n.y;
			reflectionMatrix.m12 = -2f * n.y * n.z;
			reflectionMatrix.m13 = -2f * n.y * n.w;

			reflectionMatrix.m20 = -2f * n.x * n.z;
			reflectionMatrix.m21 = -2f * n.y * n.z;
			reflectionMatrix.m22 = 1f - 2f * n.z * n.z;
			reflectionMatrix.m23 = -2f * n.z * n.w;

			reflectionMatrix.m30 = 0f;
			reflectionMatrix.m31 = 0f;
			reflectionMatrix.m32 = 0f;
			reflectionMatrix.m33 = 1f;
			return reflectionMatrix;
		}

		private void OnWillRenderObject()
		{
			Camera cam = Camera.current;
			if (cam == null || reflectionCamera == null || cam == reflectionCamera)
			{
				return;
			}

			bool bSuccess = false;
			SetReflectionCamera(ref bSuccess);

			if (bSuccess)
			{
				reflectionCamera.enabled = true;
				GL.invertCulling = true;
				reflectionCamera.Render();
				GL.invertCulling = false;
				Shader.SetGlobalTexture(REFLECTION_TEX_ID, renderBuffer);
				reflectionCamera.enabled = false;
			}

		}

	}


}
