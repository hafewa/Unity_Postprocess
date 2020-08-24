using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace PostProcess
{
	[ExecuteInEditMode, ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
	public sealed class ChromaDepth : PostProcessBase
	{
		static readonly int SCANNER_WS_ID = Shader.PropertyToID("_ScannerWS");
		static readonly int CAMERA_WS_ID = Shader.PropertyToID("_CameraWS");
		static readonly int NOISE_TEX_ID = Shader.PropertyToID("_DetailTex");
		static readonly int SCANNER_DST_ID = Shader.PropertyToID("_ScanDistance");
		static readonly int SCANNER_WTH_ID = Shader.PropertyToID("_ScanWidth");
		static readonly int SCANNER_SHARP_ID = Shader.PropertyToID("_LeadSharp");
		static readonly int LEAD_COLOR_ID = Shader.PropertyToID("_LeadColor");
		static readonly int MID_COLOR_ID = Shader.PropertyToID("_MidColor");
		static readonly int TRAIL_COLOR_ID = Shader.PropertyToID("_TrailColor");
		static readonly int HBAR_COLOR_ID = Shader.PropertyToID("_HBarColor");

		public Transform scanOrigin = default;

		public float scanWidth = 10.0f;
		public float sharpness = 10.0f;

		public Color edgeColor = Color.white;
		public Color midColor = new Color(0.18f, 0.33f, 0.0f, 0.0f);
		public Color trailColor = new Color(0f, 1f, 0.94f, 0.0f);
		public Color horizontalBarColor = new Color(0f, 1f, 0.04f, 0.0f);

		public Texture2D noiseTex = default;
		public bool scanTexture = default;

		[Header("Sample")]
		[SerializeField]
		private bool scanning = false;

		[SerializeField]
		private float speed = 50.0f;

		private float scanDistance = default;
		private new Camera camera;

		private void OnEnable()
		{
			camera = GetComponent<Camera>();
			camera.depthTextureMode |= DepthTextureMode.Depth;
		}

		protected override void OnDisable()
		{
			base.OnDisable();
			camera.depthTextureMode = DepthTextureMode.None;
		}

		private void Update()
		{
			if (scanning)
			{
				scanDistance += Time.deltaTime * speed;
			}

			if (Application.isEditor)
			{
				if (Input.GetMouseButtonDown(0))
				{
					SetScreenPoint();
				}
			}
			else
			{
				if (Input.touchCount > 0)
                {
					Touch touch = Input.GetTouch(0);

					if (touch.phase == TouchPhase.Began)
					{
						SetScreenPoint();
					}
				}
			}

		}


		private void SetScreenPoint()
		{
			Ray ray = camera.ScreenPointToRay(Input.mousePosition);
			RaycastHit hit;

			if (Physics.Raycast(ray, out hit))
			{
				scanning = true;
				scanDistance = 0;
				scanOrigin.position = hit.point;
			}
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

			if (material == null || scanOrigin == null)
			{
				Graphics.Blit(source, destination);
				return;
			}

			SetKeyword();
			material.SetVector(SCANNER_WS_ID, scanOrigin.position);
			material.SetVector(CAMERA_WS_ID, camera.transform.position);
			material.SetTexture(NOISE_TEX_ID, noiseTex);
			material.SetFloat(SCANNER_DST_ID, scanDistance);
			material.SetFloat(SCANNER_WTH_ID, scanWidth);
			material.SetFloat(SCANNER_SHARP_ID, sharpness);

			material.SetColor(LEAD_COLOR_ID, edgeColor);
			material.SetColor(MID_COLOR_ID, midColor);
			material.SetColor(TRAIL_COLOR_ID, trailColor);
			material.SetColor(HBAR_COLOR_ID, horizontalBarColor);

			RaycastCornerBlit(source, destination, material);
		}

		/// <summary>
		/// Update keyword
		/// </summary>
		private void SetKeyword()
		{
			material.DisableKeyword(scanTexture ? "NOISE_OFF" : "NOISE_ON");
			material.EnableKeyword(scanTexture ? "NOISE_ON" : "NOISE_OFF");
		}

		/// <summary>
		/// Custom Blit
		/// </summary>
		/// <param name="source"></param>
		/// <param name="dest"></param>
		/// <param name="mat"></param>
		private void RaycastCornerBlit(RenderTexture source, RenderTexture destination, Material mat)
		{
			// Compute Frustum Corners
			float camFar = camera.farClipPlane;
			float camFov = camera.fieldOfView;
			float camAspect = camera.aspect;

			float fovWHalf = camFov * 0.5f;

			Vector3 toRight = camera.transform.right * Mathf.Tan(fovWHalf * Mathf.Deg2Rad) * camAspect;
			Vector3 toTop = camera.transform.up * Mathf.Tan(fovWHalf * Mathf.Deg2Rad);
			Vector3 topLeft = (camera.transform.forward - toRight + toTop);
			float camScale = topLeft.magnitude * camFar;

			topLeft.Normalize();
			topLeft *= camScale;

			Vector3 topRight = (camera.transform.forward + toRight + toTop);
			topRight.Normalize();
			topRight *= camScale;

			Vector3 bottomRight = (camera.transform.forward + toRight - toTop);
			bottomRight.Normalize();
			bottomRight *= camScale;

			Vector3 bottomLeft = (camera.transform.forward - toRight - toTop);
			bottomLeft.Normalize();
			bottomLeft *= camScale;

			// Custom Blit, encoding Frustum Corners as additional Texture Coordinates
			RenderTexture.active = destination;
			mat.SetTexture("_MainTex", source);
			GL.PushMatrix();
			GL.LoadOrtho();
			mat.SetPass(0);
			GL.Begin(GL.QUADS);

			GL.MultiTexCoord2(0, 0.0f, 0.0f);
			GL.MultiTexCoord(1, bottomLeft);
			GL.Vertex3(0.0f, 0.0f, 0.0f);

			GL.MultiTexCoord2(0, 1.0f, 0.0f);
			GL.MultiTexCoord(1, bottomRight);
			GL.Vertex3(1.0f, 0.0f, 0.0f);

			GL.MultiTexCoord2(0, 1.0f, 1.0f);
			GL.MultiTexCoord(1, topRight);
			GL.Vertex3(1.0f, 1.0f, 0.0f);

			GL.MultiTexCoord2(0, 0.0f, 1.0f);
			GL.MultiTexCoord(1, topLeft);
			GL.Vertex3(0.0f, 1.0f, 0.0f);

			GL.End();
			GL.PopMatrix();
		}
	}

}

