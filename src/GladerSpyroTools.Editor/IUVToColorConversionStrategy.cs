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
