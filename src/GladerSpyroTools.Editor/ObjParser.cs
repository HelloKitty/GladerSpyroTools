using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEngine;

namespace GladerSpyroTools.Editor
{
	public static class ObjParser
	{
		public static ParsedObjModel LoadObj(string path)
		{
			string[] lines = File.ReadAllLines(path);
			Dictionary<string, ObjGroupModel> groups = new Dictionary<string, ObjGroupModel>();

			List<Vector3> vtLines = new List<Vector3>();
			//Create every group
			for(int i = 0; i < lines.Length; i++)
			{
				//Track the vt position
				if(isVTLine(lines[i]))
					vtLines.Add(VTLineToVector3(lines[i]));

				//We've found a new group
				if(lines[i][0] == 'g')
				{
					string groupName = new String(lines[i].Skip(2).ToArray());
					Debug.LogFormat("Found Group: {0}", groupName);

					groups.Add(groupName.Split('_').Last(), new ObjGroupModel(vtLines.ToArray()));
					vtLines.Clear();
				}
			}

			return new ParsedObjModel(groups);
		}

		public static bool isVTLine(string line)
		{
			return line.ToLower().Contains("vt");
		}

		public static Vector3 VTLineToVector3(string line)
		{
			string[] splitVTLine = line.Split(' ');

			return new Vector3(float.Parse(splitVTLine[1]), float.Parse(splitVTLine[2]), float.Parse(splitVTLine[3]));
		}

		public static string Vector3ToVTLine(Vector3 vec)
		{
			return string.Format("vt {0:0.000000} {1:0.000000} {2:0.000000}", vec.x, vec.y, vec.z);
		}
	}
}
