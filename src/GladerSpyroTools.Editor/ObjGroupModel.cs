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
using JetBrains.Annotations;
using UnityEngine;

namespace GladerSpyroTools.Editor
{
	public sealed class ObjGroupModel
	{
		//VT
		public Vector3[] TextureCoordinates { get; }

		/// <inheritdoc />
		public ObjGroupModel([NotNull] Vector3[] textureCoordinates)
		{
			TextureCoordinates = textureCoordinates;
		}
	}
}