using UnityEngine;

namespace GladerSpyroTools.Editor
{
	/// <summary>
	/// Implementation of <see cref="IUVToColorConversionStrategy"/>
	/// Converts the first two texture coordinate positions as the first
	/// two channels in the <see cref="Color"/>.
	/// </summary>
	public sealed class StandardUVToColorConversionStrategy : IUVToColorConversionStrategy
	{
		/// <inheritdoc />
		public Color ConvertCoordinate(Vector2 textureCoordinate)
		{
			//Standard implementation is to consider the first two
			//coordinates as the first two color channels
			return new Color(textureCoordinate.x, textureCoordinate.y, 0.0f);
		}
	}
}