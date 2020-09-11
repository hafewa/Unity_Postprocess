using UnityEngine;
using UnityEditor;
using System.Collections;

namespace PostProcess
{
	[CustomEditor(typeof(ColorGrading))]
	public class ColorGradingInspector : Editor
	{
		private SerializedProperty propColorTemp = default;
		private SerializedProperty propColorTint = default;
		private SerializedProperty propToneMapping = default;
		private SerializedProperty propExposure = default;
		private SerializedProperty propSaturation = default;
		private SerializedProperty propRCurve = default;
		private SerializedProperty propGCurve = default;
		private SerializedProperty propBCurve = default;
		private SerializedProperty propCCurve = default;
		private SerializedProperty propDitherMode = default;
		private GUIContent labelColorTemp = default;
		private GUIContent labelColorTint = default;

		private void OnEnable()
		{
			propColorTemp = serializedObject.FindProperty("colorTemp");
			propColorTint = serializedObject.FindProperty("colorTint");
			propToneMapping = serializedObject.FindProperty("toneMapping");
			propExposure = serializedObject.FindProperty("exposure");
			propSaturation = serializedObject.FindProperty("saturation");
			propRCurve = serializedObject.FindProperty("rCurve");
			propGCurve = serializedObject.FindProperty("gCurve");
			propBCurve = serializedObject.FindProperty("bCurve");
			propCCurve = serializedObject.FindProperty("cCurve");
			propDitherMode = serializedObject.FindProperty("ditherMode");
			labelColorTemp = new GUIContent("Color Temperature");
			labelColorTint = new GUIContent("Tint (green-purple)");
		}

		public override void OnInspectorGUI()
		{
			serializedObject.Update();

			EditorGUILayout.PropertyField(propToneMapping);

			if (propToneMapping.boolValue)
			{
				EditorGUILayout.Slider(propExposure, 0, 5);
				if (QualitySettings.activeColorSpace != ColorSpace.Linear)
				{
					EditorGUILayout.HelpBox("Linear space lighting should be enabled for tone mapping.", MessageType.Warning);
				}
			}

			EditorGUILayout.Space();
			EditorGUILayout.Slider(propColorTemp, -1.0f, 1.0f, labelColorTemp);
			EditorGUILayout.Slider(propColorTint, -1.0f, 1.0f, labelColorTint);

			EditorGUILayout.Space();
			EditorGUILayout.Slider(propSaturation, 0, 2);

			EditorGUILayout.LabelField("Curves (R, G, B, Combined)");
			EditorGUILayout.BeginHorizontal();
			var doubleHeight = GUILayout.Height(EditorGUIUtility.singleLineHeight * 2);
			EditorGUILayout.PropertyField(propRCurve, GUIContent.none, doubleHeight);
			EditorGUILayout.PropertyField(propGCurve, GUIContent.none, doubleHeight);
			EditorGUILayout.PropertyField(propBCurve, GUIContent.none, doubleHeight);
			EditorGUILayout.PropertyField(propCCurve, GUIContent.none, doubleHeight);
			EditorGUILayout.EndHorizontal();

			EditorGUILayout.Space();

			EditorGUILayout.PropertyField(propDitherMode);

			serializedObject.ApplyModifiedProperties();
		}
	}

}

