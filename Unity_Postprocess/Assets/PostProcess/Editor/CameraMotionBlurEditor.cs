using UnityEditor;
using UnityEngine;
using System.Collections;

namespace PostProcess
{
	[CustomEditor(typeof(CameraMotionBlur))]
	public class CameraMotionBlurEditor : Editor
	{
		private SerializedProperty filterType = default;
		private SerializedProperty movementScale = default;
		private SerializedProperty jitter = default;
		private SerializedProperty rotationScale = default;
		private SerializedProperty maxVelocity = default;
		private SerializedProperty minVelocity = default;
		private SerializedProperty velocityScale = default;
		private SerializedProperty velocityDownsample = default;
		private SerializedProperty noiseTexture = default;
		private SerializedProperty showVelocity = default;
		private SerializedProperty showVelocityScale = default;
		private SerializedProperty excludeLayers = default;
		private SerializedProperty softZDistance = default;

		private SerializedObject searchObj = default;
		private CameraMotionBlur postProcess = default;

		private void OnEnable()
		{
			searchObj = new SerializedObject(target);
			filterType = searchObj.FindProperty("filterType");
			movementScale = searchObj.FindProperty("movementScale");
			rotationScale = searchObj.FindProperty("rotationScale");
			maxVelocity = searchObj.FindProperty("maxVelocity");
			minVelocity = searchObj.FindProperty("minVelocity");
			softZDistance = searchObj.FindProperty("softZDistance");

			jitter = searchObj.FindProperty("jitter");
			excludeLayers = searchObj.FindProperty("excludeLayers");
			velocityScale = searchObj.FindProperty("velocityScale");
			velocityDownsample = searchObj.FindProperty("velocityDownsample");
			noiseTexture = searchObj.FindProperty("noiseTexture");

			postProcess = (CameraMotionBlur)target;
		}


		public override void OnInspectorGUI()
		{
			searchObj.Update();

			EditorGUILayout.LabelField("Simulates camera based motion blur", EditorStyles.miniLabel);
			EditorGUILayout.PropertyField(filterType, new GUIContent("Technique"));

			switch(filterType.enumValueIndex)
			{
				// CameraMotion
				case 0:
				EditorGUILayout.HelpBox("カメラモーションに対してのみ機能。ぼかしは画面全体で均一", MessageType.Info);
				break;
				// LocalBlur
				case 1:
				EditorGUILayout.HelpBox("現在のピクセルに沿って方向をぼかす。", MessageType.Info);
				break;
				// Reconstruction
				case 2:
				EditorGUILayout.HelpBox("よりリアルなぼかし結果を生成", MessageType.Info);
				break;
				// ReconstructionDX11
				case 3:
				EditorGUILayout.HelpBox("DX11 mode Mobile not supported (need SM 5)", MessageType.Warning);
				break;
				// ReconstructionDisc
				case 4:
				EditorGUILayout.HelpBox("Reconstructionよりソフトな外観を生成する為に、\n異なるSamplingPatternを使用", MessageType.Info);
				break;
			}

			EditorGUILayout.PropertyField(velocityScale, new GUIContent("Velocity Scale"));
			EditorGUILayout.PropertyField(maxVelocity, new GUIContent("Max Velocity"));
			EditorGUILayout.PropertyField(minVelocity, new GUIContent("Min Velocity"));
			EditorGUILayout.PropertyField(softZDistance, new GUIContent("Z Distance"));

			EditorGUILayout.Separator();
			EditorGUILayout.LabelField("Technique Specific");
			if (filterType.enumValueIndex == 0)
			{
				// portal style motion blur
				EditorGUILayout.PropertyField(rotationScale, new GUIContent("Rotation Scale"));
				EditorGUILayout.PropertyField(movementScale, new GUIContent("Movement Scale"));
			}
			else
			{
				EditorGUILayout.PropertyField(excludeLayers, new GUIContent("Exclude Layers"));
				EditorGUILayout.PropertyField(velocityDownsample, new GUIContent("Velocity Downsample"));
				velocityDownsample.intValue = velocityDownsample.intValue < 1 ? 1 : velocityDownsample.intValue;

				if (filterType.enumValueIndex >= 2)
				{
					EditorGUILayout.PropertyField(noiseTexture, new GUIContent("Sample Jitter"));
					EditorGUILayout.PropertyField(jitter, new GUIContent("Jitter Strength"));
				}
			}

			searchObj.ApplyModifiedProperties();
		}
	}

}

