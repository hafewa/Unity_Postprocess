using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;


namespace Motion.Tools
{
	[CustomEditor(typeof(SkinnedMeshRenderer))]
	public class SkinPolygonCounter : Editor
	{
		public override void OnInspectorGUI()
		{
			base.OnInspectorGUI();

			SkinnedMeshRenderer skin = target as SkinnedMeshRenderer;
			string polygons = "Triangles: " + skin.sharedMesh.triangles.Length / 3;
			EditorGUILayout.LabelField(polygons);
		}
	}
}

