using UnityEngine;
using UnityEditor;

namespace Klak.Tools
{
	public static class GUIHelper
	{
		public static void ShowInputValueNote()
		{
			EditorGUILayout.HelpBox("Receives float values from the inputValue property.", MessageType.None);
		}
	}
}
