using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

namespace PostProcess
{
	[ExecuteInEditMode]
	public class PlanarReflection : PostProcessBase
	{
		public enum Dimension
		{
			x128 = 128,
			x256 = 256,
			x512 = 512,
			x1024 = 1024,
			x2048 = 2048,
			x4096 = 4096,
		}

		[HideInInspector] public Shader shader;

		public Dimension reflectionMapSize = Dimension.x1024;
		public LayerMask reflectLayerMask = ~0;

		public float clipPlaneOffset = 0.01f;
		public float nearPlaneDistance = 0.1f;
		public float farPlaneDistance = 25f;
		public float mipShift = default;
		public float depthScale = 1.25f;
		public float depthExponent = 2.25f;
		public float depthRayPinchFadeSteps = 4f;

#if false
		public float shadowDistance = 200f;
		public bool renderShadows = false;
		public int maxPixelLights = -1;
#endif
		public Color clearColor = Color.gray;

		//public RenderingPath renderingPath = RenderingPath.UsePlayerSettings;

		private RenderTexture reflectionBuffer;
		private RenderTexture reflectionDepthBuffer;
		private CommandBuffer copyDepthCommandBuffer;
		private Camera reflectionCamera;
		private Camera renderCamera;
		private Material[] materials = new Material[0];

#if UNITY_EDITOR
		private void OnValidate()
		{
			OnEnable();
			UnityEditor.SceneView.RepaintAll();
		}
#endif

		private bool CheckSupport()
		{
			bool supported = true;
			if (shader == null || (shader && !shader.isSupported))
			{
				supported = false;
			}
			return supported;
		}

		private void OnEnable()
		{
			materials = GetComponent<Renderer>().sharedMaterials;

			if (!shader)
			{
				shader = Shader.Find("Hidden/PostProcess/PlanarReflection");
			}

			if (!material)
			{
				material = new Material(shader);
				material.hideFlags = HideFlags.DontSave;
			}

			material.EnableKeyword("USE_DEPTH");
			material.SetFloat("_DepthScale", depthScale);
			material.SetFloat("_DepthExponent", depthExponent);

			if (CheckSupport())
			{
				EnsureReflectionCamera(null);
				EnsureReflectionTexture();
				EnsureResolveDepthHooks();
			}
		}

		protected override void OnDisable()
		{
			base.OnDisable();
			for (int i = 0, n = materials.Length; i < n; ++i)
			{
				materials[i].DisableKeyword("PLANE_REFLECTION");
			}

			if (reflectionCamera)
			{
				DestroyImmediate(reflectionCamera.gameObject);
				reflectionCamera = null;
			}
			if (copyDepthCommandBuffer != null)
			{
				copyDepthCommandBuffer.Release();
				copyDepthCommandBuffer = null;
			}
			if (material)
			{
				DestroyImmediate(material);
				material = null;
			}
			if (reflectionBuffer)
			{
				reflectionBuffer.Release();
				DestroyImmediate(reflectionBuffer);
				reflectionBuffer = null;
			}
			if (reflectionDepthBuffer)
			{
				reflectionDepthBuffer.Release();
				DestroyImmediate(reflectionDepthBuffer);
				reflectionDepthBuffer = null;
			}
		}

		/// <summary>
		/// Mesh Was Rendering
		/// </summary>
		private void OnRenderObject()
		{
			if (!CheckSupport())
			{
				return;
			}

			//Debug.LogFormat("OnRenderObject: {0} from camera {1} (self rendercam: {2})", name, Camera.current.name, m_renderCamera);

			if (Camera.current != renderCamera)
			{
			}
			else
			{
				renderCamera = null;
			}
		}

		/// <summary>
		/// Mesh Was Cam Rendering
		/// </summary>
		private void OnWillRenderObject()
		{
			if (!CheckSupport())
			{
				return;
			}

			if (Camera.current == Camera.main)
			{
				renderCamera = Camera.current;
#if UNITY_EDITOR
			}
			else if (UnityEditor.SceneView.currentDrawingSceneView && UnityEditor.SceneView.currentDrawingSceneView.camera == Camera.current)
			{
				renderCamera = Camera.current;
#endif
			}
			else
			{
				return;
			}

			reflectionCamera = EnsureReflectionCamera(renderCamera);
			EnsureReflectionTexture();
			EnsureResolveDepthHooks();

			var reflectionMap0 = reflectionBuffer;
			// find the reflection plane: position and normal in world space
			Vector3 pos = transform.position;
			Vector3 normal = transform.up;

			// Reflect camera around reflection plane
			float d = -Vector3.Dot(normal, pos) - clipPlaneOffset;
			Vector4 reflectionPlane = new Vector4(normal.x, normal.y, normal.z, d);

			Matrix4x4 reflectionMatrix = Matrix4x4.zero;
			CalculateReflectionMatrix(ref reflectionMatrix, reflectionPlane);
			Vector3 newpos = reflectionMatrix.MultiplyPoint(renderCamera.transform.position);
			reflectionCamera.worldToCameraMatrix = renderCamera.worldToCameraMatrix * reflectionMatrix;

			reflectionCamera.cullingMask = reflectLayerMask;
			reflectionCamera.targetTexture = reflectionMap0;
			reflectionCamera.transform.position = newpos;
			reflectionCamera.aspect = renderCamera.aspect;

			// find the reflection plane: position and normal in world space
			Vector3 planePos = transform.position;
			Vector3 planeNormal = transform.up;
			float planeDist = -Vector3.Dot(planeNormal, planePos) - clipPlaneOffset;
			reflectionPlane = new Vector4(planeNormal.x, planeNormal.y, planeNormal.z, planeDist);

			// reflect the camera about the reflection plane
			var srcCamPos = renderCamera.transform.position;
			//var srcCamPos4 = new Vector4(srcCamPos.x, srcCamPos.y, srcCamPos.z, 1f);
			var srcCamRgt = renderCamera.transform.right;
			var srcCamUp = renderCamera.transform.up;
			var srcCamFwd = renderCamera.transform.forward;
			//var reflectedPos = srcCamPos - 2f * Vector4.Dot(reflectionPlane, srcCamPos4) * planeNormal;
			var reflectedDir = -ReflectVector(planeNormal, srcCamFwd);
			reflectionCamera.transform.rotation = Quaternion.LookRotation(reflectedDir, srcCamUp);

			if (reflectionCamera && ssnap)
			{
				sup = reflectionCamera.transform.up;
				spos = reflectionCamera.transform.position;
				srot = reflectionCamera.transform.rotation;
				sfov = reflectionCamera.fieldOfView;
				sfar = reflectionCamera.farClipPlane;
				snear = reflectionCamera.nearClipPlane;
				saspect = reflectionCamera.aspect;
				ssnap = false;
			}

			// Setup user defined clip plane instead of oblique frustum
			Shader.SetGlobalVector("_PlaneReflectionClipPlane", reflectionPlane);
			Shader.EnableKeyword("PLANE_REFLECTION_USER_CLIPPLANE");

#if false
			var oldShadowDist = QualitySettings.shadowDistance;
			if (!renderShadows)
			{
				QualitySettings.shadowDistance = 0f;
			}
			else if (shadowDistance > 0f)
			{
				QualitySettings.shadowDistance = shadowDistance;
			}

			var oldPixelLights = QualitySettings.pixelLightCount;
			if (maxPixelLights != -1)
			{
				QualitySettings.pixelLightCount = maxPixelLights;
			}
#endif
			for (int i = 0, n = materials.Length; i < n; ++i)
			{
				materials[i].DisableKeyword("PLANE_REFLECTION");
			}

			GL.invertCulling = true;
			reflectionCamera.Render();
			GL.invertCulling = false;

			for (int i = 0, n = materials.Length; i < n; ++i)
			{
				materials[i].EnableKeyword("PLANE_REFLECTION");
			}

#if false
			if (!renderShadows || shadowDistance > 0f)
			{
				QualitySettings.shadowDistance = oldShadowDist;
			}
			if (maxPixelLights != -1)
			{
				QualitySettings.pixelLightCount = oldPixelLights;
			}
#endif
			Shader.DisableKeyword("PLANE_REFLECTION_USER_CLIPPLANE");

			SetupConvolveParams(srcCamPos, srcCamRgt, srcCamUp, srcCamFwd, reflectionMatrix, planeNormal);
			Convolve(reflectionCamera.targetTexture, reflectionDepthBuffer);
			reflectionCamera.targetTexture = null;

			float mipCount = Mathf.Max(0f, Mathf.Round(Mathf.Log((float)reflectionBuffer.width, 2f)) - mipShift);
			for (int i = 0, n = materials.Length; i < n; ++i)
			{
				var m = materials[i];
				m.SetFloat("_PlaneReflectionLodSteps", mipCount);
				m.SetTexture("_PlaneReflection", reflectionBuffer);
			}
		}

		/// <summary>
		/// Create RenderTexture
		/// </summary>
		private void EnsureReflectionTexture()
		{
			var expectedSize = (int)reflectionMapSize;
			if (reflectionBuffer == null ||
				reflectionBuffer.width != expectedSize ||
				((reflectionBuffer.depth == 0) == (reflectionCamera.actualRenderingPath == RenderingPath.Forward)))
			{
				DestroyImmediate(reflectionBuffer);
				DestroyImmediate(reflectionDepthBuffer);
				reflectionBuffer = new RenderTexture(expectedSize, expectedSize, 16, RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Linear);
				reflectionBuffer.name = "PlaneReflection Full Color";
				reflectionBuffer.useMipMap = true;
				reflectionBuffer.autoGenerateMips = false;
				reflectionBuffer.filterMode = FilterMode.Trilinear;
				reflectionBuffer.hideFlags = HideFlags.DontSave | HideFlags.NotEditable;
				reflectionDepthBuffer = new RenderTexture(expectedSize, expectedSize, 0, RenderTextureFormat.RHalf, RenderTextureReadWrite.Linear);
				reflectionDepthBuffer.name = "PlaneReflection Full Depth";
				reflectionDepthBuffer.useMipMap = false;
				reflectionDepthBuffer.hideFlags = HideFlags.DontSave | HideFlags.NotEditable;
			}
		}

		/// <summary>
		/// Copy ReflectionDepth
		/// </summary>
		private void EnsureResolveDepthHooks()
		{
			if (copyDepthCommandBuffer == null)
			{
				copyDepthCommandBuffer = new CommandBuffer();
				copyDepthCommandBuffer.name = "CopyResolveReflectionDepth";
				copyDepthCommandBuffer.Blit(
					new RenderTargetIdentifier(BuiltinRenderTextureType.None),
					new RenderTargetIdentifier(reflectionDepthBuffer),
					material,
					2
				);
			}

			if (reflectionCamera.commandBufferCount == 0)
			{
				reflectionCamera.AddCommandBuffer(CameraEvent.AfterEverything, copyDepthCommandBuffer);
			}
		}

		/// <summary>
		/// Create Reflection Camera
		/// </summary>
		/// <param name="renderCamera"></param>
		/// <returns></returns>
		private Camera EnsureReflectionCamera(Camera renderCamera)
		{
			if (!reflectionCamera)
			{
				var goCam = new GameObject(string.Format("#> _Planar Reflection Camera < ({0})", name));
				goCam.hideFlags = HideFlags.DontSave | HideFlags.NotEditable | HideFlags.HideInHierarchy;

				reflectionCamera = goCam.AddComponent<Camera>();
				reflectionCamera.enabled = false;
			}

			if (renderCamera)
			{
				reflectionCamera.CopyFrom(renderCamera);

				// Undo some thing we don't want copied.
				// definitely don't want to inherit an explicit projection matrix
				reflectionCamera.ResetProjectionMatrix();
				reflectionCamera.renderingPath = renderCamera.actualRenderingPath == RenderingPath.UsePlayerSettings ? renderCamera.actualRenderingPath : RenderingPath.UsePlayerSettings;
				reflectionCamera.allowHDR = renderCamera.allowHDR;
				reflectionCamera.rect = new Rect(0f, 0f, 1f, 1f);
			}
			else
			{
				reflectionCamera.renderingPath = RenderingPath.UsePlayerSettings;
			}
			reflectionCamera.backgroundColor = clearColor;
			reflectionCamera.clearFlags = CameraClearFlags.SolidColor;
			reflectionCamera.depthTextureMode |= DepthTextureMode.Depth;
			reflectionCamera.useOcclusionCulling = false;
			reflectionCamera.nearClipPlane = nearPlaneDistance;
			reflectionCamera.farClipPlane = farPlaneDistance + nearPlaneDistance;
			return reflectionCamera;
		}

		/// <summary>
		/// 
		/// </summary>
		/// <param name="camPos"></param>
		/// <param name="camRgt"></param>
		/// <param name="camUp"></param>
		/// <param name="camFwd"></param>
		/// <param name="reflectionMatrix"></param>
		/// <param name="planeNormal"></param>
		private void SetupConvolveParams(Vector3 camPos, Vector3 camRgt, Vector3 camUp, Vector3 camFwd, Matrix4x4 reflectionMatrix, Vector3 planeNormal)
		{
			camPos = reflectionMatrix.MultiplyPoint(camPos);
			camRgt = -ReflectVector(camRgt, planeNormal);
			camUp = -ReflectVector(camUp, planeNormal);
			camFwd = -ReflectVector(camFwd, planeNormal);

			var camNear = reflectionCamera.nearClipPlane;
			var camFar = reflectionCamera.farClipPlane;
			var camFov = reflectionCamera.fieldOfView;
			var camAspect = reflectionCamera.aspect;

			var frustumCorners = Matrix4x4.identity;

			var fovWHalf = camFov * 0.5f;
			var tanFov = Mathf.Tan(fovWHalf * Mathf.Deg2Rad);

			var toRight = camRgt * camNear * tanFov * camAspect;
			var toTop = camUp * camNear * tanFov;

			var topLeft = (camFwd * camNear - toRight + toTop);
			var camScale = topLeft.magnitude * camFar / camNear;

			topLeft.Normalize();
			topLeft *= camScale;

			Vector3 topRight = camFwd * camNear + toRight + toTop;
			topRight.Normalize();
			topRight *= camScale;

			Vector3 bottomRight = camFwd * camNear + toRight - toTop;
			bottomRight.Normalize();
			bottomRight *= camScale;

			Vector3 bottomLeft = camFwd * camNear - toRight - toTop;
			bottomLeft.Normalize();
			bottomLeft *= camScale;

			frustumCorners.SetRow(0, topLeft);
			frustumCorners.SetRow(1, topRight);
			frustumCorners.SetRow(2, bottomRight);
			frustumCorners.SetRow(3, bottomLeft);

			Vector4 camPos4 = new Vector4(camPos.x, camPos.y, camPos.z, 1f);
			material.SetMatrix("_FrustumCornersWS", frustumCorners);
			material.SetVector("_CameraWS", camPos4);
			var zparams = Vector4.zero;
			zparams.y = farPlaneDistance / nearPlaneDistance;
			zparams.x = 1f - zparams.y;
			zparams.z = zparams.x / farPlaneDistance;
			zparams.z = zparams.y / farPlaneDistance;

			if (SystemInfo.usesReversedZBuffer)
			{
				zparams.y += zparams.x;
				zparams.x = -zparams.x;
				zparams.w += zparams.z;
				zparams.z = -zparams.z;
			}
			material.SetVector("_PlaneReflectionZParams", zparams);
		}

		/// <summary>
		/// 
		/// </summary>
		/// <param name="reflectionMap0"></param>
		/// <param name="reflectionDepth"></param>
		private void Convolve(RenderTexture reflectionMap0, RenderTexture reflectionDepth)
		{
			// The simplest and most naive texture convolve the world ever saw. It sorta
			// gets the job done, though.

			var oldRT = RenderTexture.active;

			material.SetTexture("_CameraDepthTextureCopy", reflectionDepth);

			for (int i = 0, n = reflectionBuffer.width; (n >> i) > 1; ++i)
			{
				ConvolveStep(i, reflectionBuffer, i, i + 1);
			}
			RenderTexture.active = oldRT;
		}

		/// <summary>
		/// ConvolveUpdate
		/// </summary>
		/// <param name="step"></param>
		/// <param name="srcMap"></param>
		/// <param name="srcMip"></param>
		/// <param name="dstMip"></param>
		private void ConvolveStep(int step, RenderTexture srcMap, int srcMip, int dstMip)
		{
			var srcSize = reflectionBuffer.width >> srcMip;
			var tmp = RenderTexture.GetTemporary(srcSize, srcSize, 0, RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Linear);
			tmp.name = "PlaneReflection Half";

			var power = 2048 >> dstMip;
			material.SetFloat("_CosPower", (float)power / 1000f);
			material.SetFloat("_SampleMip", (float)srcMip);
			material.SetFloat("_RayPinchInfluence", Mathf.Clamp01((float)step / depthRayPinchFadeSteps));
			Graphics.SetRenderTarget(tmp, 0);
			CustomGraphicsBlit(srcMap, material, 0);

			material.SetFloat("_SampleMip", 0f);
			Graphics.SetRenderTarget(reflectionBuffer, dstMip);
			CustomGraphicsBlit(tmp, material, 1);

			RenderTexture.ReleaseTemporary(tmp);
		}

		/// <summary>
		/// CustomRenderImage
		/// </summary>
		/// <param name="src"></param>
		/// <param name="mat"></param>
		/// <param name="pass"></param>
		private static void CustomGraphicsBlit(RenderTexture src, Material mat, int pass)
		{
			mat.SetTexture("_MainTex", src);

			GL.PushMatrix();
			GL.LoadOrtho();

			mat.SetPass(pass);

			GL.Begin(GL.QUADS);

			GL.MultiTexCoord2(0, 0.0f, 0.0f);
			GL.Vertex3(0.0f, 0.0f, 3.0f); // BL

			GL.MultiTexCoord2(0, 1.0f, 0.0f);
			GL.Vertex3(1.0f, 0.0f, 2.0f); // BR

			GL.MultiTexCoord2(0, 1.0f, 1.0f);
			GL.Vertex3(1.0f, 1.0f, 1.0f); // TR

			GL.MultiTexCoord2(0, 0.0f, 1.0f);
			GL.Vertex3(0.0f, 1.0f, 0.0f); // TL

			GL.End();
			GL.PopMatrix();
		}

		private static Vector3 ReflectVector(Vector3 vec, Vector3 normal)
		{
			return 2f * Vector3.Dot(normal, vec) * normal - vec;
		}

		private static void CalculateReflectionMatrix(ref Matrix4x4 reflectionMat, Vector4 plane)
		{
			reflectionMat.m00 = (1F - 2F * plane[0] * plane[0]);
			reflectionMat.m01 = (-2F * plane[0] * plane[1]);
			reflectionMat.m02 = (-2F * plane[0] * plane[2]);
			reflectionMat.m03 = (-2F * plane[3] * plane[0]);

			reflectionMat.m10 = (-2F * plane[1] * plane[0]);
			reflectionMat.m11 = (1F - 2F * plane[1] * plane[1]);
			reflectionMat.m12 = (-2F * plane[1] * plane[2]);
			reflectionMat.m13 = (-2F * plane[3] * plane[1]);

			reflectionMat.m20 = (-2F * plane[2] * plane[0]);
			reflectionMat.m21 = (-2F * plane[2] * plane[1]);
			reflectionMat.m22 = (1F - 2F * plane[2] * plane[2]);
			reflectionMat.m23 = (-2F * plane[3] * plane[2]);

			reflectionMat.m30 = 0F;
			reflectionMat.m31 = 0F;
			reflectionMat.m32 = 0F;
			reflectionMat.m33 = 1F;
		}

#region Debug
		public bool ssnap;
		Vector3 spos, sup; Quaternion srot;
		float sfov, snear, sfar, saspect;
		private void OnDrawGizmos()
		{
			Gizmos.color = Color.red;
			var s = transform.rotation * new Vector3(0.15f, 0.05f, 0.1f);
			s.Set(Mathf.Abs(s.x), Mathf.Abs(s.y), s.z = Mathf.Abs(s.z));
			Gizmos.DrawCube(transform.position, s);
			Gizmos.DrawSphere(transform.position + transform.up * 0.025f, 0.05f);

			if (sfov != 0f && snear != 0f && sfar != 0f)
			{
				Gizmos.DrawLine(spos, spos + sup * 0.5f);
				Gizmos.matrix = Matrix4x4.TRS(spos, srot, Vector3.one);
				Gizmos.DrawFrustum(Vector3.zero, sfov, sfar, snear, saspect);
			}
		}

#endregion
	}

}
