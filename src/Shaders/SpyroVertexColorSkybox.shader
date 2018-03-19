Shader "Spyro/SpyroVertexColorSkybox" 
{
	Properties
	{
		_Color("Skybox Color", Color) = (1.0, 1.0, 1.0)
		_SkyboxIntensity("Skybox Light Intensity", Float) = 1.0
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 200
		CULL OFF

		CGPROGRAM
		//We use a no lighting function to avoid any lighting at all
		#pragma surface surf NoLighting noforwardadd nolightmaps noambient nolppv vertex:vert

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 1.0

		uniform fixed3 _Color;
		uniform half _SkyboxIntensity;

		struct Input
		{
			half3 vertexColor;
			float2 uv_MainTex;
		};

		fixed4 LightingNoLighting(SurfaceOutput s, fixed3 lightDir, fixed atten)
		{
			fixed4 c;
			c.rgb = s.Albedo;
			c.a = s.Alpha;
			return c;
		}

		void vert(inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.vertexColor = v.color; // Save the Vertex Color in the Input for the surf() method
		}

		void surf (Input IN, inout SurfaceOutput o)
		{
			o.Albedo = IN.vertexColor * _Color * _SkyboxIntensity;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
