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
using System.Linq;
using System.Text;
using UnityEngine;

namespace GladerSpyroTools.Editor
{
	/// <summary>
	/// Strategy for converting texture coodinates
	/// to <see cref="Color"/>
	/// </summary>
	public interface IUVToColorConversionStrategy
	{
		/// <summary>
		/// Converts the provided <see cref="Vector2"/> texture coordinate
		/// to a <see cref="Color"/>.
		/// </summary>
		/// <param name="textureCoordinate">The texture coordinate to convert.</param>
		/// <returns>The color representation of the texture coordinate.</returns>
		Color ConvertCoordinate(Vector2 textureCoordinate);
	}
}
