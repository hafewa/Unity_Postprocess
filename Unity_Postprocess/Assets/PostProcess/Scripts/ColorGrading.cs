using UnityEngine;
using System.Collections;


namespace PostProcess
{
	[ExecuteInEditMode, RequireComponent(typeof(Camera))]
	public sealed class ColorGrading : PostProcessBase
	{
		public enum DitherModeType
		{
			Off,
			Ordered,
			Triangular
		}

		[Header("White balance.")]
		[SerializeField]
		private float colorTemp = 0.0f;

		[SerializeField]
		private float colorTint = 0.0f;

		[SerializeField]
		private bool toneMapping = false;

		[SerializeField]
		private float exposure = 1.0f;

		[SerializeField]
		private float saturation = 1.0f;

		[SerializeField]
		private AnimationCurve rCurve = AnimationCurve.Linear(0, 0, 1, 1);

		[SerializeField]
		private AnimationCurve gCurve = AnimationCurve.Linear(0, 0, 1, 1);

		[SerializeField]
		private AnimationCurve bCurve = AnimationCurve.Linear(0, 0, 1, 1);

		[SerializeField]
		private AnimationCurve cCurve = AnimationCurve.Linear(0, 0, 1, 1);

		[SerializeField]
		private DitherModeType ditherMode = DitherModeType.Off;

		public float ColorTemp
		{
			get { return colorTemp; }
			set { colorTemp = value; }
		}

		public float ColorTint
		{
			get { return colorTint; }
			set { colorTint = value; }
		}

		public bool ToneMapping
		{
			get { return toneMapping; }
			set { toneMapping = value; }
		}

		public float Exposure
		{
			get { return exposure; }
			set { exposure = value; }
		}

		public float Saturation
		{
			get { return saturation; }
			set { saturation = value; }
		}

		public AnimationCurve RedCurve
		{
			get { return rCurve; }
			set { rCurve = value; UpdateLUT(); }
		}

		public AnimationCurve GreenCurve
		{
			get { return gCurve; }
			set { gCurve = value; UpdateLUT(); }
		}

		public AnimationCurve BlueCurve
		{
			get { return bCurve; }
			set { bCurve = value; UpdateLUT(); }
		}

		public AnimationCurve RGBCurve
		{
			get { return cCurve; }
			set { cCurve = value; UpdateLUT(); }
		}

		public DitherModeType DitherMode
		{
			get { return ditherMode; }
			set { ditherMode = value; }
		}


		private Texture2D lutTexture = default;

		public bool WasLinear => (QualitySettings.activeColorSpace == ColorSpace.Linear);


		static Color EncodeRGBM(float r, float g, float b)
		{
			var a = Mathf.Max(Mathf.Max(r, g), Mathf.Max(b, 1e-6f));
			a = Mathf.Ceil(a * 255) / 255;
			return new Color(r / a, g / a, b / a, a);
		}

		// http://en.wikipedia.org/wiki/Standard_illuminant#Illuminant_series_D
		// An analytical model of chromaticity of the standard illuminant, by Judd et al.
		// Slightly modifed to adjust it with the D65 white point (x=0.31271, y=0.32902).
		static float StandardIlluminantY(float x)
		{
			return 2.87f * x - 3.0f * x * x - 0.27509507f;
		}

		// http://en.wikipedia.org/wiki/LMS_color_space#CAT02
		// CIE xy chromaticity to CAT02 LMS.
		static Vector3 CIExyToLMS(float x, float y)
		{
			var Y = 1.0f;
			var X = Y * x / y;
			var Z = Y * (1.0f - x - y) / y;
			var L = 0.7328f * X + 0.4296f * Y - 0.1624f * Z;
			var M = -0.7036f * X + 1.6975f * Y + 0.0061f * Z;
			var S = 0.0030f * X + 0.0136f * Y + 0.9834f * Z;
			return new Vector3(L, M, S);
		}


		private void CreateLUT()
		{
			if (lutTexture == null)
			{
				lutTexture = new Texture2D(512, 1, TextureFormat.ARGB32, false, true);
				lutTexture.hideFlags = HideFlags.DontSave;
				lutTexture.wrapMode = TextureWrapMode.Clamp;
				UpdateLUT();
			}
		}

		private void UpdateLUT()
		{
			if (lutTexture == null)
			{
				CreateLUT();
			}
			for (var x = 0; x < lutTexture.width; x++)
			{
				var u = 1.0f / (lutTexture.width - 1) * x;
				var r = cCurve.Evaluate(rCurve.Evaluate(u));
				var g = cCurve.Evaluate(gCurve.Evaluate(u));
				var b = cCurve.Evaluate(bCurve.Evaluate(u));
				lutTexture.SetPixel(x, 0, EncodeRGBM(r, g, b));
			}
			lutTexture.Apply();
		}

		private Vector3 CalculateColorBalance()
		{
			// Calculate the color balance coefficients.
			// Get the CIE xy chromaticity of the reference white point.
			// Note: 0.31271 = x value on the D65 white point
			var x = 0.31271f - colorTemp * (colorTemp < 0.0f ? 0.1f : 0.05f);
			var y = StandardIlluminantY(x) + colorTint * 0.05f;

			// Calculate the coefficients in the LMS space.
			var w1 = new Vector3(0.949237f, 1.03542f, 1.08728f); // D65 white point
			var w2 = CIExyToLMS(x, y);
			return new Vector3(w1.x / w2.x, w1.y / w2.y, w1.z / w2.z);
		}

		private void OnEnable()
		{
			if (material == null)
			{
				material = new Material(Shader.Find("Hidden/PostProcess/ColorGrading"));
				material.hideFlags = HideFlags.DontSave;
			}
			CreateLUT();
		}

		protected override void OnDisable()
		{
			base.OnDisable();

			if (lutTexture)
			{
				DestroyImmediate(lutTexture);
				lutTexture = null;
			}
		}

		private void OnValidate()
		{
			UpdateLUT();
		}

		private void OnRenderImage(RenderTexture source, RenderTexture destination)
		{
			if (material == null)
			{
				Graphics.Blit(source, destination);
				return;
			}

			if (colorTemp != 0.0f || colorTint != 0.0f)
			{
				material.EnableKeyword("BALANCING_ON");
				material.SetVector("_Balance", CalculateColorBalance());
			}
			else
			{
				material.DisableKeyword("BALANCING_ON");
			}


			if (toneMapping && WasLinear)
			{
				material.EnableKeyword("TONEMAPPING_ON");
				material.SetFloat("_Exposure", exposure);
			}
			else
			{
				material.DisableKeyword("TONEMAPPING_ON");
			}

			material.SetTexture("_Curves", lutTexture);
			material.SetFloat("_Saturation", saturation);

			if (ditherMode == DitherModeType.Ordered)
			{
				material.EnableKeyword("DITHER_ORDERED");
				material.DisableKeyword("DITHER_TRIANGULAR");
			}
			else if (ditherMode == DitherModeType.Triangular)
			{
				material.DisableKeyword("DITHER_ORDERED");
				material.EnableKeyword("DITHER_TRIANGULAR");
			}
			else
			{
				material.DisableKeyword("DITHER_ORDERED");
				material.DisableKeyword("DITHER_TRIANGULAR");
			}

			Graphics.Blit(source, destination, material);
		}
	}

}

