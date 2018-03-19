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