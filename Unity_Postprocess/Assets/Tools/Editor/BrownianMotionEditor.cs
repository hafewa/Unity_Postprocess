
using UnityEngine;
using UnityEditor;

namespace Motion.Tools
{
	[CanEditMultipleObjects]
	[CustomEditor(typeof(BrownianMotion))]
	public class BrownianMotionEditor : Editor
	{
		static readonly GUIContent textPositionNoise = new GUIContent("Position Noise");
		static readonly GUIContent textRotationNoise = new GUIContent("Rotation Noise");
		static readonly GUIContent textFrequency = new GUIContent("Frequency");
		static readonly GUIContent textAmplitude = new GUIContent("Amplitude");
		static readonly GUIContent textScale = new GUIContent("Scale");
		static readonly GUIContent textFractal = new GUIContent("Fractal");

		private SerializedProperty enablePositionNoise = default;
		private SerializedProperty enableRotationNoise = default;
		private SerializedProperty positionFrequency = default;
		private SerializedProperty rotationFrequency = default;
		private SerializedProperty positionAmplitude = default;
		private SerializedProperty rotationAmplitude = default;
		private SerializedProperty positionScale = default;
		private SerializedProperty rotationScale = default;
		private SerializedProperty positionFractalLevel = default;
		private SerializedProperty rotationFractalLevel = default;

		private void OnEnable()
		{
			enablePositionNoise = serializedObject.FindProperty("_enablePositionNoise");
			enableRotationNoise = serializedObject.FindProperty("_enableRotationNoise");
			positionFrequency = serializedObject.FindProperty("_positionFrequency");
			rotationFrequency = serializedObject.FindProperty("_rotationFrequency");
			positionAmplitude = serializedObject.FindProperty("_positionAmplitude");
			rotationAmplitude = serializedObject.FindProperty("_rotationAmplitude");
			positionScale = serializedObject.FindProperty("_positionScale");
			rotationScale = serializedObject.FindProperty("_rotationScale");
			positionFractalLevel = serializedObject.FindProperty("_positionFractalLevel");
			rotationFractalLevel = serializedObject.FindProperty("_rotationFractalLevel");
		}

		public override void OnInspectorGUI()
		{
			serializedObject.Update();

			EditorGUILayout.PropertyField(enablePositionNoise, textPositionNoise);

			if (enablePositionNoise.hasMultipleDifferentValues || enablePositionNoise.boolValue)
			{
				EditorGUI.indentLevel++;
				EditorGUILayout.PropertyField(positionFrequency, textFrequency);
				EditorGUILayout.PropertyField(positionAmplitude, textAmplitude);
				EditorGUILayout.PropertyField(positionScale, textScale);
				EditorGUILayout.PropertyField(positionFractalLevel, textFractal);
				EditorGUI.indentLevel--;
			}

			EditorGUILayout.PropertyField(enableRotationNoise, textRotationNoise);

			if (enableRotationNoise.hasMultipleDifferentValues || enableRotationNoise.boolValue)
			{
				EditorGUI.indentLevel++;
				EditorGUILayout.PropertyField(rotationFrequency, textFrequency);
				EditorGUILayout.PropertyField(rotationAmplitude, textAmplitude);
				EditorGUILayout.PropertyField(rotationScale, textScale);
				EditorGUILayout.PropertyField(rotationFractalLevel, textFractal);
				EditorGUI.indentLevel--;
			}

			serializedObject.ApplyModifiedProperties();
		}
	}
}
