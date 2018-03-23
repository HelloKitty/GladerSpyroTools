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
using JetBrains.Annotations;
using UnityEditor;
using UnityEngine;

namespace GladerSpyroTools
{
	public sealed class AssetDirectoryService
	{
		/// <summary>
		/// The object to be used in the directory service.
		/// </summary>
		public UnityEngine.Object DirectoryObject { get; private set; }

		public AssetDirectoryService([NotNull] UnityEngine.Object directoryObject)
		{
			if(directoryObject == null) throw new ArgumentNullException("directoryObject");

			DirectoryObject = directoryObject;
		}

		/// <summary>
		/// The directory the asset is saved in.
		/// </summary>
		/// <returns></returns>
		public string GetAssetDirectory()
		{
			string path = AssetDatabase.GetAssetPath(DirectoryObject);

			try
			{
				return Path.GetDirectoryName(path);

			}
			catch(Exception e)
			{
				throw new InvalidOperationException("Failed to generate Path for asset at calculated Path:" + path + " GameObject Name: " + DirectoryObject.name, e);
			}
		}

		/// <summary>
		/// Creates a subfolder in the same directory as the
		/// <see cref="DirectoryObject"/>.
		/// </summary>
		/// <param name="directory"></param>
		/// <param name="subfolderName"></param>
		/// <returns>True if the folder was created.</returns>
		public bool CreateSubFolder([NotNull] string directory, [NotNull] string subfolderName)
		{
			if(string.IsNullOrEmpty(subfolderName)) throw new ArgumentException("Value cannot be null or empty.", "subfolderName");
			if(string.IsNullOrEmpty(directory)) throw new ArgumentException("Value cannot be null or empty.", "directory");

			if(!Directory.Exists(Path.Combine(Path.Combine(Application.dataPath, directory.TrimStart("Assets".ToCharArray())), subfolderName)))
			{
				AssetDatabase.CreateFolder(directory, subfolderName);
				AssetDatabase.SaveAssets();
			}

			return true;
		}

		public bool SaveAsset([NotNull] string path, [NotNull] string assetName)
		{
			if(string.IsNullOrEmpty(path)) throw new ArgumentException("Value cannot be null or empty.", "path");
			if(string.IsNullOrEmpty(assetName)) throw new ArgumentException("Value cannot be null or empty.", "assetName");

			//TODO: Does this throw?
			AssetDatabase.CreateAsset(DirectoryObject, Path.Combine(path, assetName + ".asset"));
			return true;
		}
	}
}
