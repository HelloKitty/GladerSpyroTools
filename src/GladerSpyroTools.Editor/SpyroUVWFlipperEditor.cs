using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using GladerSpyroTools.Editor;
using UnityEditor;
using UnityEngine;

namespace GladerSpyroTools.Editor
{
	public class SpyroUVWFlipperEditor : EditorWindow
	{
		[SerializeField] private GameObject objAssetToInvert;

		[MenuItem("GladerSpyroTools/UVW Flipper")]
		public static void ShowWindow()
		{
			EditorWindow.GetWindow(typeof(SpyroUVWFlipperEditor));
		}

		void OnGUI()
		{
			objAssetToInvert = EditorGUILayout.ObjectField("OBJ to Invert", objAssetToInvert, typeof(GameObject), true)
				as GameObject;

			if(GUILayout.Button("Generate Flipped"))
			{
				string assetPath = AssetDatabase.GetAssetPath(objAssetToInvert);

				Debug.LogFormat("Loading: {0}", assetPath);

				string[] lines = File.ReadAllLines(assetPath);

				//TODO: Do we actually benefit from this at all?
				//We use this fake Y coord to pervent unity from optimizing away coords
				float uniqueUVVCoord = 0.0f;
				for(int i = 0; i < lines.Length; i++)
					if(ObjParser.isVTLine(lines[i]))
					{
						Vector3 vtVector = ObjParser.VTLineToVector3(lines[i]);
						lines[i] = ObjParser.Vector3ToVTLine(new Vector3(vtVector.z, uniqueUVVCoord, vtVector.x));
						uniqueUVVCoord += 0.0001f;
					}

				string newPath = string.Format("{0}{1}.obj", assetPath.TrimEnd(".obj".ToCharArray()), "_uvwswapped");

				File.WriteAllLines(newPath, lines);
			}
		}
	}
}
