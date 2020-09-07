using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;

namespace Motion.Tools
{
	public class SceneSwicher : SingletonMonoBehaviour<SceneSwicher>
	{
		static readonly List<string> scenes = new List<string>
		{
			"PlanarReflection",
			"CameraMotionBlur",
			"ChromaDepth",
			"Example",
		};

		static readonly float REFRESH_INTERVAL_SECS = 1f;


		[SerializeField]
		private Button sceneButton = default;

		[SerializeField]
		private Button fxaaButton = default;

		[SerializeField]
		private Text fxaaText = default;

		[SerializeField]
		private Text fpsText = default;

		private int index = 0;
		private float refreshSecs;
		private float delta;


		private void Start()
		{
			sceneButton?.onClick.AddListener(OnNext);
			fxaaButton?.onClick.AddListener(OnFXAAClickCallBack);
		}

		private void Update()
		{
			if (fpsText == null)
			{
				return;
			}
			refreshSecs += Time.unscaledDeltaTime;
			delta += (Time.unscaledDeltaTime - delta) * 0.1f;
			if (refreshSecs >= REFRESH_INTERVAL_SECS)
			{
				float fps = 1f / this.delta;
				fpsText.text = string.Format("{0:F2} FPS", fps);
				refreshSecs = 0f;
			}
		}

		private void OnNext()
		{
			if (index >= scenes.Count - 1)
			{
				index = 0;
			}
			else
			{
				++index;
			}
			SceneManager.LoadScene(scenes[index]);
		}

		private void OnFXAAClickCallBack()
		{
			if (!fxaaButton || !fxaaText)
			{
				return;
			}

			var loader = FindObjectOfType<SceneLoader>();
			if (loader && loader.FXAA)
			{
				loader.FXAA.enabled = !loader.FXAA.enabled;
				fxaaText.text = string.Format("FXAA_{0}", loader.FXAA.enabled ? "ON" : "OFF");
			}			
		}

		public void UpdateFXAA(bool wasEnabled)
		{
			if (fxaaText)
			{
				fxaaText.text = string.Format("FXAA_{0}", wasEnabled ? "ON" : "OFF");
			}
		}
	}


}

