using UnityEngine;
using System.Collections;

namespace PostProcess
{

	[ExecuteInEditMode, ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
	public sealed class CameraMotionBlur : PostProcessBase
	{
		static float MAX_RADIUS = 100.0f;

		public enum MotionBlurFilter
		{
			CameraMotion = 0,
			LocalBlur = 1,
			Reconstruction = 2,
			ReconstructionDX11 = 3,
			ReconstructionDisc = 4,
		}

		[SerializeField]
		private MotionBlurFilter filterType = MotionBlurFilter.Reconstruction;

		[Header("Scaleが高いほど、画像がぼやけやすくなる")]
		[SerializeField]
		private float velocityScale = 0.8f;

		[Header("最大ピクセル距離")]
		[SerializeField][Range(0.0f, 100f)]
		private float maxVelocity = 10.0f;

		[Header("最小ピクセル距離")]
		[SerializeField][Range(0.0f, 100f)]
		private float minVelocity = 0.1f;

		[SerializeField]
		private float movementScale = 0.0f;

		[SerializeField]
		private float rotationScale = 1.0f;

		[SerializeField]
		private float softZDistance = 0.005f;

		[Header("品質調整、値が大きいほど、ぼかし効果はよくなるが、FPSに影響する。")]
		[SerializeField]
		private int velocityDownsample = 1;

		[Header("除外したいLayer")]
		[SerializeField]
		private LayerMask excludeLayers = 0;

		[SerializeField]
		private Texture2D noiseTexture = default;

		[SerializeField]
		private float jitter = 0.05f;

		// resources
		private GameObject tmpCam = default;
		private Shader shader = default;
		private Shader dx11MotionBlurShader = default;
		private Shader replacementClear = default;
		private Material motionBlurMaterial = default;
		private Material dx11MotionBlurMaterial = default;

		private Matrix4x4 currentViewProjMat = default;
		private Matrix4x4 prevViewProjMat = default;
		private int prevFrameCount = default;
		private bool wasActive = false;
		private Vector3 prevFrameForward = Vector3.forward;
		private Vector3 prevFrameUp = Vector3.up;
		private Vector3 prevFramePos = Vector3.zero;
		private new Camera camera = default;

		private void Start()
		{
			wasActive = gameObject.activeInHierarchy;
			CalculateViewProjection();
			Remember();
			wasActive = false;
		}

		private void OnEnable()
		{
			if (camera == null)
			{
				camera = GetComponent<Camera>();
			}
			camera.depthTextureMode |= DepthTextureMode.Depth;
			replacementClear = Shader.Find("Hidden/PostProcess/MotionBlurClear");

			// Mobile用 MotionBlur
			shader = Shader.Find("Hidden/PostProcess/CameraMotionBlur");
			motionBlurMaterial = new Material(shader);

			// Console用 MotionBlur
			dx11MotionBlurShader = Shader.Find("Hidden/PostProcess/CameraMotionBlurDX11");
			dx11MotionBlurMaterial = new Material(dx11MotionBlurShader);
		}

		protected override void OnDisable()
		{
			base.OnDisable();

			if (motionBlurMaterial != null)
			{
				DestroyImmediate(motionBlurMaterial);
				motionBlurMaterial = null;
			}
			if (dx11MotionBlurMaterial != null)
			{
				DestroyImmediate(dx11MotionBlurMaterial);
				dx11MotionBlurMaterial = null;
			}
			if (tmpCam != null)
			{
				DestroyImmediate(tmpCam);
				tmpCam = null;
			}
		}

		private void CalculateViewProjection()
		{
			Matrix4x4 viewMat = camera.worldToCameraMatrix;
			Matrix4x4 projMat = GL.GetGPUProjectionMatrix(camera.projectionMatrix, true);
			currentViewProjMat = projMat * viewMat;
		}

		private bool CheckResources()
		{
			if (shader == null || 
				camera == null ||
				replacementClear == null || 
				motionBlurMaterial == null || 
				dx11MotionBlurShader == null || 
				dx11MotionBlurMaterial == null)
			{
				return false;
			}
			return true;
		}

		private void ReplacementShader(RenderTexture veloctityBuffer)
		{
			Camera cam = null;
			if (excludeLayers.value != 0)
			{
				cam = GetTmpCam();
			}

			if (cam && excludeLayers.value != 0 && replacementClear && replacementClear.isSupported)
			{
				cam.targetTexture = veloctityBuffer;
				cam.cullingMask = excludeLayers;
				cam.RenderWithShader(replacementClear, "");
			}
		}

		private void Remember()
		{
			prevViewProjMat = currentViewProjMat;
			prevFrameForward = transform.forward;
			prevFrameUp = transform.up;
			prevFramePos = transform.position;
		}

		private Camera GetTmpCam()
		{
			if (tmpCam == null)
			{
				string name = "_" + camera.name + "_MotionBlurTmpCam";
				GameObject go = GameObject.Find(name);
				if (go == null)
				{
					tmpCam = new GameObject(name, typeof(Camera));
				}
				else
				{
					tmpCam = go;
				}
			}

			tmpCam.hideFlags = HideFlags.DontSave;
			tmpCam.transform.position = camera.transform.position;
			tmpCam.transform.rotation = camera.transform.rotation;
			tmpCam.transform.localScale = camera.transform.localScale;
			tmpCam.GetComponent<Camera>().CopyFrom(camera);

			tmpCam.GetComponent<Camera>().enabled = false;
			tmpCam.GetComponent<Camera>().depthTextureMode = DepthTextureMode.None;
			tmpCam.GetComponent<Camera>().clearFlags = CameraClearFlags.Nothing;

			return tmpCam.GetComponent<Camera>();
		}

		private void StartFrame()
		{
			prevFramePos = Vector3.Slerp(prevFramePos, transform.position, 0.75f);
		}

		private int RoundUp(int x, int d)
		{
			return (x + d - 1) / d;
		}

		/// <summary>
		/// Update RenderImage
		/// </summary>
		/// <param name="source"></param>
		/// <param name="destination"></param>
		private void OnRenderImage(RenderTexture source, RenderTexture destination)
		{
			if (!CheckResources())
			{
				Graphics.Blit(source, destination);
				return;
			}

			if (filterType == MotionBlurFilter.CameraMotion)
			{
				StartFrame();
			}

			var rtFormat = SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.RGHalf) ? RenderTextureFormat.RGHalf : RenderTextureFormat.ARGBHalf;

			// get temp textures
			RenderTexture velBuffer = RenderTexture.GetTemporary(RoundUp(source.width, velocityDownsample), RoundUp(source.height, velocityDownsample), 0, rtFormat);
			int tileWidth = 1;
			int tileHeight = 1;
			maxVelocity = Mathf.Max(2.0f, maxVelocity);
			float _maxVelocity = maxVelocity;

			tileWidth = RoundUp(velBuffer.width, (int)maxVelocity);
			tileHeight = RoundUp(velBuffer.height, (int)maxVelocity);
			_maxVelocity = velBuffer.width / tileWidth;

			RenderTexture tileMax = RenderTexture.GetTemporary(tileWidth, tileHeight, 0, rtFormat);
			RenderTexture neighbourMax = RenderTexture.GetTemporary(tileWidth, tileHeight, 0, rtFormat);
			velBuffer.filterMode = FilterMode.Point;
			tileMax.filterMode = FilterMode.Point;
			neighbourMax.filterMode = FilterMode.Point;
			if (noiseTexture)
			{
				noiseTexture.filterMode = FilterMode.Point;
			}
			source.wrapMode = TextureWrapMode.Clamp;
			velBuffer.wrapMode = TextureWrapMode.Clamp;
			neighbourMax.wrapMode = TextureWrapMode.Clamp;
			tileMax.wrapMode = TextureWrapMode.Clamp;

			// calc correct viewprj matrix
			CalculateViewProjection();

			if (gameObject.activeInHierarchy && !wasActive)
			{
				Remember();
			}
			wasActive = gameObject.activeInHierarchy;

			// matrices
			Matrix4x4 invViewPrj = Matrix4x4.Inverse(currentViewProjMat);
			motionBlurMaterial.SetMatrix("_InvViewProj", invViewPrj);
			motionBlurMaterial.SetMatrix("_PrevViewProj", prevViewProjMat);
			motionBlurMaterial.SetMatrix("_ToPrevViewProjCombined", prevViewProjMat * invViewPrj);

			motionBlurMaterial.SetFloat("_MaxVelocity", _maxVelocity);
			motionBlurMaterial.SetFloat("_MaxRadiusOrKInPaper", _maxVelocity);
			motionBlurMaterial.SetFloat("_MinVelocity", minVelocity);
			motionBlurMaterial.SetFloat("_VelocityScale", velocityScale);
			motionBlurMaterial.SetFloat("_Jitter", jitter);

			// texture samplers
			motionBlurMaterial.SetTexture("_NoiseTex", noiseTexture);
			motionBlurMaterial.SetTexture("_VelTex", velBuffer);
			motionBlurMaterial.SetTexture("_NeighbourMaxTex", neighbourMax);
			motionBlurMaterial.SetTexture("_TileTexDebug", tileMax);


			if (filterType == MotionBlurFilter.CameraMotion)
			{
				Vector4 blurVector = Vector4.zero;
				float lookUpDown = Vector3.Dot(transform.up, Vector3.up);
				Vector3 distanceVector = prevFramePos - transform.position;
				float distMag = distanceVector.magnitude;
				float farHeur = 1.0f;

				// pitch (vertical)
				farHeur = (Vector3.Angle(transform.up, prevFrameUp) / camera.fieldOfView) * (source.width * 0.75f);
				blurVector.x = rotationScale * farHeur;

				// yaw #1 (horizontal, faded by pitch)
				farHeur = (Vector3.Angle(transform.forward, prevFrameForward) / camera.fieldOfView) * (source.width * 0.75f);
				blurVector.y = rotationScale * lookUpDown * farHeur;

				// yaw #2 (when looking down, faded by 1-pitch)
				farHeur = (Vector3.Angle(transform.forward, prevFrameForward) / camera.fieldOfView) * (source.width * 0.75f);
				blurVector.z = rotationScale * (1.0f - lookUpDown) * farHeur;

				if (distMag > Mathf.Epsilon && movementScale > Mathf.Epsilon)
				{
					blurVector.w = movementScale * (Vector3.Dot(transform.forward, distanceVector)) * (source.width * 0.5f);
					blurVector.x += movementScale * (Vector3.Dot(transform.up, distanceVector)) * (source.width * 0.5f);
					blurVector.y += movementScale * (Vector3.Dot(transform.right, distanceVector)) * (source.width * 0.5f);
				}
				motionBlurMaterial.SetVector("_BlurDirectionPacked", blurVector);
			}
			else
			{
				Graphics.Blit(source, velBuffer, motionBlurMaterial, 0);
				ReplacementShader(velBuffer);
			}

			if (Time.frameCount != prevFrameCount)
			{
				prevFrameCount = Time.frameCount;
				Remember();
			}

			source.filterMode = FilterMode.Bilinear;

			switch (filterType)
			{
				case MotionBlurFilter.CameraMotion:
				{
					Graphics.Blit(source, destination, motionBlurMaterial, 6);
				}
				break;

				case MotionBlurFilter.LocalBlur:
				{
					Graphics.Blit(source, destination, motionBlurMaterial, 5);
				}
				break;

				case MotionBlurFilter.Reconstruction:
				{
					motionBlurMaterial.SetFloat("_SoftZDistance", Mathf.Max(0.00025f, softZDistance));
					Graphics.Blit(velBuffer, tileMax, motionBlurMaterial, 2);
					Graphics.Blit(tileMax, neighbourMax, motionBlurMaterial, 3);
					Graphics.Blit(source, destination, motionBlurMaterial, 4);
				}
				break;

				case MotionBlurFilter.ReconstructionDX11:
				{
					dx11MotionBlurMaterial.SetFloat("_MinVelocity", minVelocity);
					dx11MotionBlurMaterial.SetFloat("_VelocityScale", velocityScale);
					dx11MotionBlurMaterial.SetFloat("_Jitter", jitter);
					dx11MotionBlurMaterial.SetTexture("_NoiseTex", noiseTexture);
					dx11MotionBlurMaterial.SetTexture("_VelTex", velBuffer);
					dx11MotionBlurMaterial.SetTexture("_NeighbourMaxTex", neighbourMax);
					dx11MotionBlurMaterial.SetFloat("_SoftZDistance", Mathf.Max(0.00025f, softZDistance));
					dx11MotionBlurMaterial.SetFloat("_MaxRadiusOrKInPaper", _maxVelocity);
					Graphics.Blit(velBuffer, tileMax, dx11MotionBlurMaterial, 0);
					Graphics.Blit(tileMax, neighbourMax, dx11MotionBlurMaterial, 1);
					Graphics.Blit(source, destination, dx11MotionBlurMaterial, 2);
				}
				break;

				case MotionBlurFilter.ReconstructionDisc:
				{
					motionBlurMaterial.SetFloat("_SoftZDistance", Mathf.Max(0.00025f, softZDistance));
					Graphics.Blit(velBuffer, tileMax, motionBlurMaterial, 2);
					Graphics.Blit(tileMax, neighbourMax, motionBlurMaterial, 3);
					Graphics.Blit(source, destination, motionBlurMaterial, 7);
				}
				break;
			}

			RenderTexture.ReleaseTemporary(velBuffer);
			RenderTexture.ReleaseTemporary(tileMax);
			RenderTexture.ReleaseTemporary(neighbourMax);
		}
	}


}

