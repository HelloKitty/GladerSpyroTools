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
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;
using System.Linq;
using JetBrains.Annotations;
using GladerSpyroTools.Editor;
using UnityEditor.SceneManagement;
using UnityEngine.SceneManagement;
using Object = UnityEngine.Object;


namespace GladerSpyroTools.Editor
{
	public class SpyroLevelVertexColorEditor : EditorWindow
	{
		/// <summary>
		/// The gameobject that contains the textured meshes.
		/// </summary>
		[SerializeField] private GameObject texturedGameObject;

		/// <summary>
		/// The gameobject (asset) that contains the vertex color channels: Red and Green.
		/// </summary>
		[SerializeField] private GameObject vertexColoredGameObject;

		/// <summary>
		/// The gameobject (asset) that contains the vertex color channels: Blue.
		/// </summary>
		[SerializeField] private GameObject uvwSwappedVertexColoredGameObject;

		/// <summary>
		/// Indicates if adjacent mesh vertex color blending should be applied.
		/// This option will cause the vertex coloring to take slightly longer
		/// and is dependedant on mesh complexity and the number of overlapping
		/// submesh bounding volumes.
		/// </summary>
		[SerializeField] private bool useVertexBlending;

		/// <summary>
		/// Indicates if the vertex color meshes should be persisted.
		/// They are persisted by assigning new mesh copies with the vertex color data
		/// to each <see cref="MeshFilter"/> and saving them in a folder next to
		/// the vertex color gameobject source.
		/// </summary>
		[SerializeField] private bool saveAsSeperateMesh;

		[MenuItem("GladerSpyroTools/Texture and VertexColor Combiner")]
		public static void ShowWindow()
		{
			EditorWindow.GetWindow(typeof(SpyroLevelVertexColorEditor));
		}

		void OnGUI()
		{
			//We make the expectation that this is at 0,0,0 and that it's a scene object. Doesn't have to be a scene object but that would be preferable
			//I suggest a prefab in the scene that isn't prefab linked to the original imported asset gameobject
			texturedGameObject = EditorGUILayout.ObjectField("Textured GameObject", texturedGameObject, typeof(GameObject), true)
				as GameObject;

			vertexColoredGameObject = EditorGUILayout.ObjectField("VertexColor GameObject", vertexColoredGameObject, typeof(GameObject), true)
				as GameObject;

			uvwSwappedVertexColoredGameObject = EditorGUILayout.ObjectField("UWV Swapped VertexColor GameObject", uvwSwappedVertexColoredGameObject, typeof(GameObject), true)
				as GameObject;

			useVertexBlending = EditorGUILayout.Toggle("Use Vertex Blending", useVertexBlending);

			saveAsSeperateMesh = EditorGUILayout.Toggle("Save Seperate Meshes", saveAsSeperateMesh);

			if(GUILayout.Button("Combine Data"))
			{
				//TODO: Does this work?
				List<GameObject> texturedGameObjectList = GetOrderedChildrenGameObjects(texturedGameObject);

				List<GameObject> vertexColoredGameObjectList = GetOrderedChildrenGameObjects(vertexColoredGameObject);

				//TODO: Does this work?
				List<GameObject> uvwSwappedVertexColoredGameObjectList = GetOrderedChildrenGameObjects(uvwSwappedVertexColoredGameObject);

				if(texturedGameObjectList.Count != vertexColoredGameObjectList.Count || texturedGameObjectList.Count != uvwSwappedVertexColoredGameObjectList.Count)
				{
					Debug.LogError("Cannot combine data from gameobjects with different mesh count.");
					return;
				}

				//Foreach gameobject set the colors on the textured mesh.
				for(int i = 0; i < texturedGameObjectList.Count; i++)
				{
					Mesh tm = texturedGameObjectList[i].GetComponent<MeshFilter>().sharedMesh;
					Mesh vm = vertexColoredGameObjectList[i].GetComponent<MeshFilter>().sharedMesh;
					Mesh uvwvm = uvwSwappedVertexColoredGameObjectList[i].GetComponent<MeshFilter>().sharedMesh;

					//We could use real vertex count but access causes alloc I think? Didn't check
					Vector2[] textureCoords = vm.uv;
					Vector2[] uwvSwappedTextureCoords = uvwvm.uv;

					//Due to API vertices returns a copy so takes allocate
					//Therefore to avoid significant overhead in using accessing for large meshes
					//we grab here and use in the lop
					Vector3[] tmVertices = tm.vertices;
					Vector3[] vmVertices = vm.vertices;
					Vector3[] uvwvmVertices = uvwvm.vertices;

					if(vmVertices.Length != textureCoords.Length || uwvSwappedTextureCoords.Length != uvwvmVertices.Length)
					{
						Debug.LogError("No 1:1 vertex to UV mapping.");
						return;
					}

					//We only need to set the generated array
					//to the main meshes vertex colors.
					tm.colors = GenerateColorsArray(vertexColoredGameObjectList, uvwSwappedVertexColoredGameObjectList, i, tm, vm, uvwvm, textureCoords, uwvSwappedTextureCoords, tmVertices, vmVertices, uvwvmVertices);

					Debug.LogFormat("Applied colors to a submesh.");


				}

				//This option allows for the users to
				//set the generated vertex color meshes as new meshes and save them
				//this lets them persist between loading
				if(saveAsSeperateMesh)
					SetAsNewMeshAssetsAndSave(texturedGameObjectList);

				Debug.Log("Finished applying vertex colors.");
			}

			if(GUILayout.Button("Clear Vertex Colors"))
			{
				//TODO: Does this work?
				List<GameObject> texturedGameObjectList = texturedGameObject
					.GetComponentsInChildren<Transform>()
					.Select(t => t.gameObject)
					.Where(go => go != texturedGameObject) //ignore parent
					.ToList();

				foreach(GameObject go in texturedGameObjectList)
					go.GetComponent<MeshFilter>().sharedMesh.colors = new Color[0];
			}
		}

		private void SetAsNewMeshAssetsAndSave(List<GameObject> texturedGameObjectList)
		{
			foreach(MeshFilter texturedMeshFilter in texturedGameObjectList
				.Select(go => go.GetComponent<MeshFilter>()))
			{
				//Create a copy of the mesh and set it as the new mesh
				Mesh newMesh = Object.Instantiate(texturedMeshFilter.sharedMesh);
				string path = Path.GetDirectoryName(AssetDatabase.GetAssetPath(vertexColoredGameObject));

				if(!Directory.Exists(Application.dataPath + path.TrimStart("Assets".ToCharArray()) + "/VertexColoredMeshes"))
				{
					AssetDatabase.CreateFolder(path, "VertexColoredMeshes");
					AssetDatabase.SaveAssets();
				}

				AssetDatabase.CreateAsset(newMesh, Path.GetDirectoryName(AssetDatabase.GetAssetPath(vertexColoredGameObject)) + @"/VertexColoredMeshes/" + newMesh.name + ".asset");
				texturedMeshFilter.sharedMesh = newMesh;

				AssetDatabase.SaveAssets();
			}
		}

		private Color[] GenerateColorsArray(IList<GameObject> vertexColoredGameObjectList, IList<GameObject> uvwSwappedVertexColoredGameObjectList, int i, Mesh tm, Mesh vm, Mesh uvwvm, Vector2[] textureCoords, Vector2[] uwvSwappedTextureCoords, Vector3[] tmVertices, Vector3[] vmVertices, Vector3[] uvwvmVertices)
		{
			//Now we need to base this on triangles and not vertices because it won't work otherwise.
			//They don't have the same vert count
			Color[] colors = new Color[tm.vertexCount];

			//For each vertex we need to aggregate color information
			//This may or may not mean blending between nearby meshes
			//Either way multiplie vertices with color information will be available
			for(int vertIndex = 0; vertIndex < tm.vertexCount; vertIndex++)
			{
				colors[vertIndex] = Color.black;

				//Since the 3rd blue channel is stored on a seperate OBJ/Mesh/Object we have to parse it too and aggregate color information
				//seperately from the red green channel
				Color redGreenToAdd = ParseCoordinatesToColor(vertexColoredGameObjectList, vertexColoredGameObjectList[i], vm, textureCoords, tmVertices, vmVertices, vertIndex, new StandardUVToColorConversionStrategy());
				Color blueToAdd = ParseCoordinatesToColor(uvwSwappedVertexColoredGameObjectList, uvwSwappedVertexColoredGameObjectList[i], uvwvm, uwvSwappedTextureCoords, tmVertices, uvwvmVertices, vertIndex, new SwappedUVWToColorConversionStrategy());

				//We can just additively create the result color from the seperated channels
				colors[vertIndex] = redGreenToAdd + blueToAdd;

				if(colors[vertIndex] == Color.black)
				{
					Debug.LogWarningFormat("Found black color at vertex index: {0}", vertIndex);
					colors[vertIndex] = Color.red;
				}
			}

			return colors;
		}

		private Color ParseCoordinatesToColor(IList<GameObject> vertexColoredGameObjectList, GameObject currentVertexColoredGameObject,
			Mesh vertexColorMesh, Vector2[] textureCoords, Vector3[] tmVertices, Vector3[] vertexColoredVertices, int vertIndex, IUVToColorConversionStrategy coordToColorConversionStrategy)
		{
			List<Color> colorsToAdd = new List<Color>(10);

			AggregateVertexColorsForIndex(textureCoords, tmVertices, vertexColoredVertices, vertIndex, colorsToAdd, coordToColorConversionStrategy);

			if(useVertexBlending)
			{
				//Now we need to check nearby meshes to see if we share points and should blend/average vertex colors with them
				//This can be done efficiently using bounding box volume distance comparisions
				IEnumerable<Mesh> nearbyUnswappedMeshes = vertexColoredGameObjectList
					.Where(go => go != currentVertexColoredGameObject)
					.Select(go => go.GetComponent<MeshFilter>().sharedMesh)
					.Where(m => m.bounds.Intersects(vertexColorMesh.bounds));

				//Then once we've gathered all nearby meshes we can perform the same process against each mesh to blend colors
				//TODO: This is insanely costly N^3. Could be VERY slow for large meshes nearby large meshes
				foreach(Mesh m in nearbyUnswappedMeshes)
				{
					Vector3[] nearbyVertices = m.vertices;
					Vector2[] nearbyUVColorCoords = m.uv;

					//For performance we should only be interested in vertices that are contained in nearby bounding boxes
					if(!m.bounds.Contains(tmVertices[vertIndex]))
						continue;

					AggregateVertexColorsForIndex(nearbyUVColorCoords, tmVertices, nearbyVertices, vertIndex, colorsToAdd, coordToColorConversionStrategy);
				}
			}

			return AggregateColorData(colorsToAdd);
		}

		/// <summary>
		/// Aggregates all the provided <see cref="Color"/> data from the
		/// collection and averages the result.
		/// </summary>
		/// <param name="colorsToAdd">The colors to aggregate.</param>
		/// <returns>The resulting <see cref="Color"/>.</returns>
		private static Color AggregateColorData(ICollection<Color> colorsToAdd)
		{
			return colorsToAdd.Aggregate(Color.black, (color, color1) => color + color1) / colorsToAdd.Count;
		}

		/// <summary>
		/// Aggregates all the color data for a given mesh vertex index.
		/// Checks overlapping verticies for vertex color data and collects it in the provided
		/// collection.
		/// </summary>
		/// <param name="textureCoords">Texture coordinates to treat as colors.</param>
		/// <param name="vertexColorVertices">The vertices that contain the color information.</param>
		/// <param name="vertices">The main vertices.</param>
		/// <param name="vertIndexToCheck">The index of the vertices being checked.</param>
		/// <param name="colorsToAdd">The collection of colors to add to.</param>
		/// <param name="coordToColorConversionStrategy">The strategy to use for converting the texture coordinates to colors.</param>
		/// <returns>The number of colors added to the collection.</returns>
		private static int AggregateVertexColorsForIndex(Vector2[] textureCoords, Vector3[] vertexColorVertices, Vector3[] vertices, int vertIndexToCheck, ICollection<Color> colorsToAdd, IUVToColorConversionStrategy coordToColorConversionStrategy)
		{
			if(textureCoords == null) throw new ArgumentNullException("textureCoords");
			if(vertexColorVertices == null) throw new ArgumentNullException("vertexColorVertices");
			if(vertices == null) throw new ArgumentNullException("vertices");
			if(colorsToAdd == null) throw new ArgumentNullException("colorsToAdd");
			if(coordToColorConversionStrategy == null) throw new ArgumentNullException("coordToColorConversionStrategy");
			if(vertIndexToCheck < 0) throw new ArgumentOutOfRangeException("vertIndexToCheck", "The vertex index to check cannot be less than 0.");

			int count = colorsToAdd.Count;

			//So for each vertex we want to find one that matches in the vertex color mesh
			//so that we we assign the color to the texture mesh
			for(int colorVertIndex = 0; colorVertIndex < textureCoords.Length && colorVertIndex < vertices.Length; colorVertIndex++)
			{
				//If it's within distance (don't assume same position) then we should consider it a match and aggregate the color at this point
				if(!(Vector3.Distance(vertexColorVertices[vertIndexToCheck], vertices[colorVertIndex]) <= Vector3.kEpsilon * 10)) continue;

				colorsToAdd.Add(coordToColorConversionStrategy.ConvertCoordinate(textureCoords[colorVertIndex]));
			}

			return colorsToAdd.Count - count;
		}

		/// <summary>
		/// Gets an ordered array of children from the provided root <see cref="GameObject"/>.
		/// </summary>
		/// <param name="rootGameObject">The root <see cref="GameObject"/></param>
		/// <returns>Ordered list of all the child <see cref="GameObject"/>s</returns>
		private List<GameObject> GetOrderedChildrenGameObjects(GameObject rootGameObject)
		{

			//TODO: Does this work?
			List<GameObject> gameObjectList = rootGameObject
				.GetComponentsInChildren<Transform>()
				.Select(t => t.gameObject)
				.Where(go => go != rootGameObject) //ignore parent
				.ToList();

			//TODO: Provide ordering strategy
			//If it's greater than 1 we should do ordering under the assumed format
			if(gameObjectList.Count > 1)
				gameObjectList = gameObjectList
					.OrderBy(go => int.Parse(go.name.Split('_').Last()))
					.ToList();

			return gameObjectList;
		}
	}
}
