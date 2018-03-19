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
using UnityEngine;

namespace GladerSpyroTools.Editor
{
	/// <summary>
	/// Implementation of <see cref="IUVToColorConversionStrategy"/>
	/// Converts the the first coordinate (expected to be UVW swapped) to
	/// the blue channel leaving the other channels unfilled.
	/// </summary>
	public sealed class SwappedUVWToColorConversionStrategy : IUVToColorConversionStrategy
	{
		/// <inheritdoc />
		public Color ConvertCoordinate(Vector2 textureCoordinate)
		{
			//Standard implementation is to consider the first two
			//coordinates as the first two color channels
			return new Color(0.0f, 0.0f, textureCoordinate.x);
		}
	}
}