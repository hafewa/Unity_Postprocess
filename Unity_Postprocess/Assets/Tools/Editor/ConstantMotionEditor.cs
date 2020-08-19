
using UnityEngine;
using UnityEditor;

namespace Klak.Tools
{
	[CanEditMultipleObjects]
	[CustomEditor(typeof(ConstantMotion))]
	public class ConstantMotionEditor : Editor
	{
		static readonly GUIContent textLocalCoordinate = new GUIContent("Local Coordinate");
		static readonly GUIContent textRotation = new GUIContent("Rotation");
		static readonly GUIContent textSpeed = new GUIContent("Speed");
		static readonly GUIContent textTranslation = new GUIContent("Translation");
		static readonly GUIContent textVector = new GUIContent("Vector");

		private SerializedProperty translationMode = default;
		private SerializedProperty translationVector = default;
		private SerializedProperty translationSpeed = default;
		private SerializedProperty rotationMode = default;
		private SerializedProperty rotationAxis = default;
		private SerializedProperty rotationSpeed = default;
		private SerializedProperty useLocalCoordinate = default;

		private void OnEnable()
		{
			translationMode = serializedObject.FindProperty("_translationMode");
			translationVector = serializedObject.FindProperty("_translationVector");
			translationSpeed = serializedObject.FindProperty("_translationSpeed");
			rotationMode = serializedObject.FindProperty("_rotationMode");
			rotationAxis = serializedObject.FindProperty("_rotationAxis");
			rotationSpeed = serializedObject.FindProperty("_rotationSpeed");
			useLocalCoordinate = serializedObject.FindProperty("_useLocalCoordinate");
		}

		public override void OnInspectorGUI()
		{
			serializedObject.Update();
			EditorGUILayout.PropertyField(translationMode, textTranslation);
			EditorGUI.indentLevel++;

			if (translationMode.hasMultipleDifferentValues || translationMode.enumValueIndex == (int)ConstantMotion.TranslationMode.Vector)
			{
				EditorGUILayout.PropertyField(translationVector, textVector);
			}

			if (translationMode.hasMultipleDifferentValues || translationMode.enumValueIndex != 0)
			{
				EditorGUILayout.PropertyField(translationSpeed, textSpeed);
			}

			EditorGUI.indentLevel--;
			EditorGUILayout.PropertyField(rotationMode, textRotation);
			EditorGUI.indentLevel++;

			if (rotationMode.hasMultipleDifferentValues || rotationMode.enumValueIndex == (int)ConstantMotion.RotationMode.Vector)
			{
				EditorGUILayout.PropertyField(rotationAxis, textVector);
			}

			if (rotationMode.hasMultipleDifferentValues || rotationMode.enumValueIndex != 0)
			{
				EditorGUILayout.PropertyField(rotationSpeed, textSpeed);
			}

			EditorGUI.indentLevel--;
			EditorGUILayout.PropertyField(useLocalCoordinate, textLocalCoordinate);
			serializedObject.ApplyModifiedProperties();
		}
	}
}
