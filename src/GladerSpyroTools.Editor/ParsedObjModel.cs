using System.Collections.Generic;
using System.Text;
using JetBrains.Annotations;
using UnityEditor.MemoryProfiler;

namespace GladerSpyroTools.Editor
{
	public sealed class ParsedObjModel
	{
		public Dictionary<string, ObjGroupModel> Groups { get; }

		/// <inheritdoc />
		public ParsedObjModel([NotNull] Dictionary<string, ObjGroupModel> groups)
		{
			Groups = groups;
		}
	}
}
