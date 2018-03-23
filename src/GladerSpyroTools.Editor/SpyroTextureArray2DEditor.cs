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
	public class SpyroTextureArray2DEditor : EditorWindow
	{
		[SerializeField]
		private Texture2D textureToConvert;

		[MenuItem("GladerSpyroTools/Texture2DArray Generator")]
		public static void ShowWindow()
		{
			EditorWindow.GetWindow(typeof(SpyroTextureArray2DEditor));
		}

		void OnGUI()
		{
			textureToConvert = EditorGUILayout.ObjectField("Texture to Convert", textureToConvert, typeof(Texture2D), false)
				as Texture2D;

			//TODO: Verify texture input before acting on it
			if(GUILayout.Button("Create Dx11 Texture2DArray") && textureToConvert != null)
			{
				//We'll save it at the same location
				AssetDirectoryService originalAssetDirectory = new AssetDirectoryService(textureToConvert);

				//These values should be the same
				int widthPerTile = textureToConvert.width / 16;
				int heightPerTile = textureToConvert.height / 8;

				Debug.Log("Using Format: " + textureToConvert.format.ToString());
				//We use 16 by 8 because that is the layout for Spyro 1 and 2 (maybe 3 too haven't check)
				//meaning we have an entire array of them now.

				//TODO: Will we ever be able to support mipmapping?
				//TODO: We can do an optimization by cutting the length of it off at the tile count
				Texture2DArray textureArray = new Texture2DArray(widthPerTile, heightPerTile, 16 * 8, textureToConvert.format, false);

				List<int> index = new List<int>();
				//TODO: Should we allow configurable size?
				for(int indexX = 0; indexX < 16; indexX++)
					for(int indexY = 0; indexY < 8; indexY++)
					{
						index.Add(indexY * 16 + indexX);
						//We use 7 - indexY because UV Y starts at the bottom left corner
						textureArray.SetPixels(textureToConvert.GetPixels(indexX * widthPerTile, indexY * heightPerTile, widthPerTile, heightPerTile), indexY * 16 + indexX);
					}

				foreach(int i in index.OrderBy(i => i))
					Debug.Log(i);

				textureArray.Apply(false, true);

				AssetDirectoryService newTextuAssetDirectoryService = new AssetDirectoryService(textureArray);
				newTextuAssetDirectoryService.SaveAsset(originalAssetDirectory.GetAssetDirectory(), textureToConvert.name + "_" + "texture2Darray");
			}
		}
	}
}
