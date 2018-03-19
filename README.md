# GladerSpyroTools

Library for tools for use in Unity3D that allows Unity3D developers to work with Spyro-like data in Unity3D.

## Downloads

There are many ways to grab and use these tools.

- You could download the source and build this solution.
- You could download the source and drop it into the Editor folder in Unity3D
- You can download a unity package from the release tab [here](todo)
- You can download a compiled assembly and drop it into the editor from the download tab [here](todo)

## Features
- [x] Vertex Coloring
- [x] Vertex Color Shaders
- [ ] Animation Shaders
- [ ] Portal Shader
- [ ] Secondary Object Placement

### Vertex Coloring

**WARNING:** Make sure you disable mesh compression, vertex welding and mesh optimization for all .M assets. It's possible to lose some vertex data this way. If you encounter coloring problems open an issue on this repository.

GladerSpyroTools contains a Unity3D editor extension for adding vertex colors to meshes from Spyro.

1. Import map OBJs.
2. Open **UVW Flipper** window under GladerSpyroTools.
2. Take UVW texture coordinate OBJ (known as .M or .S for Skybox) OBJ and create *uvswapped* version.
3. Add textured map into scene (known as .T)
4. Open **Texture and VertexColor Combiner**
5. Assign Textured scene object
6. Assign vertex color OBJ (known as .M or .S for Skybox)
7. Assigned uvswapped vertex color OBJ (known as .M_uvswapped or .S_uvswapped)
8. Hit **Combine Data*!

#### Options

**Vertex Color Blending:** This feature allows for vertex colors to softly blended with data from nearby meshes for each vertex. This will increase the amount of time it takes to generate the vertex colored meshes. However, it's highly recommended you use this feature to generate proper vertex colors.


**Save Meshes:** This feature allows will create new Mesh assets and assign them to the scene's MeshFilters. It will create copies from the original mesh asset and save them in a folder next to the vertex colored gameobject. This **MUST** be used to persist vertex coloring.

### Shaders

As of right now two shaders are provided. One for maps and one for skyboxes. 

**Map:** The map one provides vertex coloring, lightmap support or vertex light (unity3d) support in Forward rendering path or pixel/vertex lights in Deferred. It technically supports reflection probes everything the standard specular lighting model supports. However I recommend just using lightmaps to bake the ambient in and gain some nice touches from baked shadows. Vertex colors are multiplicative with the sampled texture color and are added as ambient light in the lighting function. There are material properties for flat ambient term and the strength of the vertex coloring as lighting.

**Skybox:** The skybox is very simple. Just uses vertex color as Albedo color with no lighting support. Provides properties for coloring and for intensity of the brightness.

# License

AGPL Glader/HelloKitty@Github
