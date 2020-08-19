
using System.IO;
using UnityEditor;
using UnityEngine;

namespace Klak.Tools
{
	public class ImageSequenceWindow : EditorWindow
	{
		// recorder settings
		int frameRate = 30;
		int superSampling = 1;
		bool autoRecord;

		// recorder state
		bool isRecording;
		int frameCount;
		int previousFrame;


		public void InitializeRecorder()
		{
			isRecording = false;
			if (autoRecord)
			{
				StartRecord();
			}
		}

		private void StartRecord()
		{
			frameCount = -1;
			isRecording = true;
		}

		private void EndRecord()
		{
			Time.captureFramerate = 0;
			isRecording = false;
		}

		private void StepRecorder()
		{
			if (frameCount == 0)
			{
				Directory.CreateDirectory("Capture");
				Time.captureFramerate = frameRate;
			}
			else if (frameCount > 0)
			{
				var name = "Capture/frame" + frameCount.ToString("0000") + ".png";
				ScreenCapture.CaptureScreenshot(name, superSampling);
			}
			frameCount++;
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
			frameRate = EditorGUILayout.IntSlider("Frame Rate", frameRate, 1, 120);
			superSampling = EditorGUILayout.IntSlider("Supersampling", superSampling, 1, 4);
			autoRecord = EditorGUILayout.Toggle("Auto Recording", autoRecord);

			if (EditorApplication.isPlaying)
			{
				var fatButton = GUILayout.Height(30);

				if (!isRecording)
				{
					if (GUILayout.Button("REC", fatButton))
					{
						StartRecord();
					}
				}
				else
				{
					var time = (float)frameCount / frameRate;
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
			if (previousFrame != frame)
			{
				if (Application.isPlaying && isRecording)
				{
					StepRecorder();
					Repaint();
				}
				previousFrame = frame;
			}
		}

	}
}
