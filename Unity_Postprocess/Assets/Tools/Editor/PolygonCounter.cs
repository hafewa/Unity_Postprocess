using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;


namespace Motion.Tools
{
	[CustomEditor(typeof(MeshFilter))]
	public class PolygonCounter : Editor
	{
		public override void OnInspectorGUI()
		{
			base.OnInspectorGUI();

			MeshFilter filter = target as MeshFilter;
			string polygons = "Triangles: " + filter.sharedMesh.triangles.Length / 3;
			EditorGUILayout.LabelField(polygons);
		}
	}
}

