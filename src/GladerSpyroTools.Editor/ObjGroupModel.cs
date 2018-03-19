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