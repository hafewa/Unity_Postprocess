using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace PostProcess
{
	[ExecuteInEditMode, ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
	public class Fog : PostProcessBase
	{
		public enum FogType
		{
			Distance = 1,
			Height = 2,
			//Multi = 3,
		}

		static readonly int MAIN_TEXTURE_ID = Shader.PropertyToID("_MainTex");
		static readonly int NOISE_TEXTURE_ID = Shader.PropertyToID("_NoiseTex");
		static readonly int COLOR_ID = Shader.PropertyToID("_FogColor");
		static readonly int SPEED_ID = Shader.PropertyToID("_ScrollSpeed");
		static readonly int SCALE_ID = Shader.PropertyToID("_FogNoiseScale");

		static readonly int MATRIX_ID = Shader.PropertyToID("_FrustumCornersWS");
		static readonly int CAMERA_POS_ID = Shader.PropertyToID("_CameraWorldSpase");
		static readonly int HEIGHT_PARAM_ID = Shader.PropertyToID("_HeightParams");
		static readonly int DISTANCE_PARAM_ID = Shader.PropertyToID("_DistanceParams");

		private new Camera camera;

		[SerializeField]
		private float height = 5f;

		[SerializeField][Range(0.001f, 10f)]
		private float density = 1f;

		[SerializeField]
		private Color color = Color.white;

		[SerializeField][Range(0, 10000f)]
		private float startDistance = default;

		[SerializeField][Range(0, 10000f)]
		private float endDistance = 5000f;

		[SerializeField]
		private FogType fogType = FogType.Distance;

		private bool useRadialDistance = false;

		[SerializeField]
		private float scale = 100f;

		[SerializeField]
		private Vector2 speed = default;

		[SerializeField]
		private Texture2D noiseTexture = default;


		private readonly Vector3[] frustumCorners = new Vector3[4];


		private void Start()
		{
			if (camera == null)
			{
				camera = GetComponent<Camera>();
			}
			camera.depthTextureMode |= DepthTextureMode.Depth;
		}

		private void OnRenderImage(RenderTexture source, RenderTexture destination)
		{
			if (material == null)
			{
				material = new Material(Shader.Find("Hidden/PostProcess/Fog"));
				material.hideFlags = HideFlags.HideAndDontSave;
			}

			if (material == null || camera == null)
			{
				Graphics.Blit(source, destination);
				return;
			}

			material.SetMatrix(MATRIX_ID, GetFrustumCorners());

			Transform cameraTransform = camera.transform;
			float FdotC = cameraTransform.position.y - height;
			float paramK = FdotC <= 0.0f ? 1.0f : 0.0f;
			float densityInternal = density * 0.005f;

			material.SetVector(CAMERA_POS_ID, cameraTransform.position);
			material.SetVector(HEIGHT_PARAM_ID, new Vector4(height, FdotC, paramK, densityInternal));
			material.SetVector(DISTANCE_PARAM_ID, new Vector4(startDistance, endDistance, 0, 0));
			material.SetColor(COLOR_ID, color);
			material.SetFloat(SCALE_ID, scale);

			var movementSpeed = speed / 100f;
			movementSpeed *= Time.realtimeSinceStartup;
			material.SetVector(SPEED_ID, movementSpeed);
			material.SetTexture(NOISE_TEXTURE_ID, noiseTexture);

			SetFogKeyword();
			CustomGraphicsBlit(source, destination, material, 0);
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

		/// <summary>
		/// Update keyword
		/// </summary>
		private void SetFogKeyword()
		{
			switch (fogType)
			{
				case FogType.Distance:
					material.DisableKeyword("HEIGHT_FOG");
					material.EnableKeyword("DISTANCE_FOG");
					break;
				case FogType.Height:
					material.DisableKeyword("DISTANCE_FOG");
					material.EnableKeyword("HEIGHT_FOG");
					break;
			}
		}

		/// <summary>
		/// 円錐台のコーナーインデックスを入力頂点にエンコードするGraphics.Blitの簡単なカスタムバージョン。
		/// 次の錐台角インデックス情報がz座標に渡される
		/// Top Left vertex:     z=0, u=0, v=0
		/// Top Right vertex:    z=1, u=1, v=0
		/// Bottom Right vertex: z=2, u=1, v=1
		/// Bottom Left vertex:  z=3, u=1, v=0
		/// DirectXマシンで反転したUVを考慮する必要がある
		/// Use The shader define UNITY_UV_STARTS_AT_TOP
		/// </summary>
		static void CustomGraphicsBlit(RenderTexture source, RenderTexture dest, Material fxMaterial, int passNr)
		{
			RenderTexture.active = dest;
			fxMaterial.SetTexture(MAIN_TEXTURE_ID, source);

			// 射影行列を保存
			GL.PushMatrix();
			GL.LoadOrtho();

			fxMaterial.SetPass(passNr);

			// RendererPrimitive
			GL.Begin(GL.QUADS);

			// Here, GL.MultitexCoord2(0, x, y) assigns the value (x, y) to the TEXCOORD0 slot in the shader.
			// GL.Vertex3(x,y,z) queues up a vertex at position (x, y, z) to be drawn.  Note that we are storing
			// our own custom frustum information in the z coordinate.
			GL.MultiTexCoord2(0, 0.0f, 0.0f);
			GL.Vertex3(0.0f, 0.0f, 3.0f); // BL

			GL.MultiTexCoord2(0, 1.0f, 0.0f);
			GL.Vertex3(1.0f, 0.0f, 2.0f); // BR

			GL.MultiTexCoord2(0, 1.0f, 1.0f);
			GL.Vertex3(1.0f, 1.0f, 1.0f); // TR

			GL.MultiTexCoord2(0, 0.0f, 1.0f);
			GL.Vertex3(0.0f, 1.0f, 0.0f); // TL

			// 変更をPOPする
			GL.End();
			GL.PopMatrix();
		}

	}
}
