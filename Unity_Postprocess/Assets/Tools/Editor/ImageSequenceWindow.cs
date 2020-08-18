
using UnityEngine;
using UnityEditor;
using System.IO;

namespace Klak.Tools
{
	public class ImageSequenceWindow : EditorWindow
	{
		// recorder settings
		int _frameRate = 30;
		int _superSampling = 1;
		bool _autoRecord;

		// recorder state
		bool _isRecording;
		int _frameCount;
		int _previousFrame;


		public void InitializeRecorder()
		{
			_isRecording = false;
			if (_autoRecord)
			{
				StartRecord();
			}
		}

		private void StartRecord()
		{
			_frameCount = -1;
			_isRecording = true;
		}

		private void EndRecord()
		{
			Time.captureFramerate = 0;
			_isRecording = false;
		}

		private void StepRecorder()
		{
			if (_frameCount == 0)
			{
				Directory.CreateDirectory("Capture");
				Time.captureFramerate = _frameRate;
			}
			else if (_frameCount > 0)
			{
				var name = "Capture/frame" + _frameCount.ToString("0000") + ".png";
				ScreenCapture.CaptureScreenshot(name, _superSampling);
			}
			_frameCount++;
		}


		[MenuItem("Window/Image Sequence")]
		static void Init()
		{
			var instance = CreateInstance<ImageSequenceWindow>();
			instance.minSize = instance.maxSize = new Vector2(20, 6) * EditorGUIUtility.singleLineHeight;
			instance.titleContent = new GUIContent("Image Sequence");
			instance.ShowUtility();
		}

		private void OnEnable()
		{
			EditorApplication.playmodeStateChanged += OnPlaymodeChanged;
		}

		private void OnDisable()
		{
			EditorApplication.playmodeStateChanged -= OnPlaymodeChanged;
		}

		private void OnPlaymodeChanged()
		{
			// detecting a start of the play mode
			if (!Application.isPlaying && EditorApplication.isPlayingOrWillChangePlaymode)
			{
				InitializeRecorder();
			}
			Repaint();
		}

		private void OnGUI()
		{
			_frameRate = EditorGUILayout.IntSlider("Frame Rate", _frameRate, 1, 120);
			_superSampling = EditorGUILayout.IntSlider("Supersampling", _superSampling, 1, 4);
			_autoRecord = EditorGUILayout.Toggle("Auto Recording", _autoRecord);

			if (EditorApplication.isPlaying)
			{
				var fatButton = GUILayout.Height(30);

				if (!_isRecording)
				{
					if (GUILayout.Button("REC", fatButton))
					{
						StartRecord();
					}
				}
				else
				{
					var time = (float)_frameCount / _frameRate;
					var label = "STOP  (" + time.ToString("0.0") + "s)";
					if (GUILayout.Button(label, fatButton))
					{
						EndRecord();
					}
				}
			}
		}

		private void Update()
		{
			var frame = Time.frameCount;
			if (_previousFrame != frame)
			{
				if (Application.isPlaying && _isRecording)
				{
					StepRecorder();
					Repaint();
				}
				_previousFrame = frame;
			}
		}

	}
}
