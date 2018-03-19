/*
GladerSpyroTools is a library Unity3D library tool developed by Glader/HelloKitty@Github to do Spyro things in Unity3D.
Copyright (C) 2017 Glader/HelloKitty@Github

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
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
