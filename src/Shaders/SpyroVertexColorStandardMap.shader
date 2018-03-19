Shader "Spyro/SpyroVertexColorStandardMap" 
{
	Properties 
	{
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_FlatAmbient ("Flat Ambient Lighting", Float) = 0.25
		_VertexColorAmbient ("Vertex Colored Ambient Lighting", Float) = 1.7
	}
	SubShader 
	{
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model that uses vertex colors as ambient light
		#pragma surface surf StandardSpyroSpecular noforwardadd nolppv vertex:vert

		#include "UnityPBSLighting.cginc"
		#include "HLSLSupport.cginc"
		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		half3 _VertexColor;
		uniform half _FlatAmbient;
		uniform half _VertexColorAmbient;

		struct Input 
		{
			half3 vertexColor;
			float2 uv_MainTex;
		};

		void vert(inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);

			o.vertexColor = v.color; // Save the Vertex Color in the Input for the surf() method
		}

		//From the 5.6 standard shader source
		inline half3 UnityGISpyro_IndirectSpecular(UnityGIInput data, half occlusion, Unity_GlossyEnvironmentData glossIn)
		{
			half3 specular;

			#ifdef UNITY_SPECCUBE_BOX_PROJECTION
				// we will tweak reflUVW in glossIn directly (as we pass it to Unity_GlossyEnvironment twice for probe0 and probe1), so keep original to pass into BoxProjectedCubemapDirection
				half3 originalReflUVW = glossIn.reflUVW;
				glossIn.reflUVW = BoxProjectedCubemapDirection (originalReflUVW, data.worldPos, data.probePosition[0], data.boxMin[0], data.boxMax[0]);
			#endif

			#ifdef _GLOSSYREFLECTIONS_OFF
				specular = unity_IndirectSpecColor.rgb;
			#else
				half3 env0 = Unity_GlossyEnvironment (UNITY_PASS_TEXCUBE(unity_SpecCube0), data.probeHDR[0], glossIn);
				#ifdef UNITY_SPECCUBE_BLENDING
					const float kBlendFactor = 0.99999;
					float blendLerp = data.boxMin[0].w;
					UNITY_BRANCH
					if (blendLerp < kBlendFactor)
					{
						#ifdef UNITY_SPECCUBE_BOX_PROJECTION
							glossIn.reflUVW = BoxProjectedCubemapDirection (originalReflUVW, data.worldPos, data.probePosition[1], data.boxMin[1], data.boxMax[1]);
						#endif

						half3 env1 = Unity_GlossyEnvironment (UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0), data.probeHDR[1], glossIn);
						specular = lerp(env1, env0, blendLerp);
					}
					else
					{
						specular = env0;
					}
				#else
					specular = env0;
				#endif
			#endif

			return specular * occlusion;
		}

		//From the 5.6 standard shader source
		//This method adds vertex colors as ambient light as well as some flat ambient
		inline UnityGI UnityGISpyro_Base(UnityGIInput data, half occlusion, half3 normalWorld)
		{
			UnityGI o_gi;
			ResetUnityGI(o_gi);

			// Base pass with Lightmap support is responsible for handling ShadowMask / blending here for performance reason
			#if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
				half bakedAtten = UnitySampleBakedOcclusion(data.lightmapUV.xy, data.worldPos);
				float zDist = dot(_WorldSpaceCameraPos - data.worldPos, UNITY_MATRIX_V[2].xyz);
				float fadeDist = UnityComputeShadowFadeDistance(data.worldPos, zDist);
				data.atten = UnityMixRealtimeAndBakedShadows(data.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
			#endif

			o_gi.light = data.light;
			o_gi.light.color *= data.atten;

			#if UNITY_SHOULD_SAMPLE_SH
				o_gi.indirect.diffuse = ShadeSHPerPixel (normalWorld, data.ambient, data.worldPos);
			#endif

			#if defined(LIGHTMAP_ON)
				// Baked lightmaps
				half4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, data.lightmapUV.xy);
				half3 bakedColor = DecodeLightmap(bakedColorTex);

				#ifdef DIRLIGHTMAP_COMBINED
					fixed4 bakedDirTex = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap, data.lightmapUV.xy);
					o_gi.indirect.diffuse = DecodeDirectionalLightmap (bakedColor, bakedDirTex, normalWorld);

					#if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
						ResetUnityLight(o_gi.light);
						o_gi.indirect.diffuse = SubtractMainLightWithRealtimeAttenuationFromLightmap (o_gi.indirect.diffuse, data.atten, bakedColorTex, normalWorld);
					#endif

				#else // not directional lightmap
					o_gi.indirect.diffuse = bakedColor;

					#if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
						ResetUnityLight(o_gi.light);
						o_gi.indirect.diffuse = SubtractMainLightWithRealtimeAttenuationFromLightmap(o_gi.indirect.diffuse, data.atten, bakedColorTex, normalWorld);
					#endif

				#endif
			#endif

			#ifdef DYNAMICLIGHTMAP_ON
				// Dynamic lightmaps
				fixed4 realtimeColorTex = UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, data.lightmapUV.zw);
				half3 realtimeColor = DecodeRealtimeLightmap (realtimeColorTex);

				#ifdef DIRLIGHTMAP_COMBINED
					half4 realtimeDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_DynamicDirectionality, unity_DynamicLightmap, data.lightmapUV.zw);
					o_gi.indirect.diffuse += DecodeDirectionalLightmap (realtimeColor, realtimeDirTex, normalWorld);
				#else
					o_gi.indirect.diffuse += realtimeColor;
				#endif
			#endif

			//Add the ambient term here with vertex coloring.
			o_gi.indirect.diffuse += _VertexColorAmbient * _VertexColor + _FlatAmbient;

			o_gi.indirect.diffuse *= occlusion;
			return o_gi;
		}

		//From the 5.6 standard shader source
		inline half4 LightingStandardSpyroSpecular(SurfaceOutputStandardSpecular s, half3 viewDir, UnityGI gi)
		{
			s.Normal = normalize(s.Normal);

			// energy conservation
			half oneMinusReflectivity;
			s.Albedo = EnergyConservationBetweenDiffuseAndSpecular(s.Albedo, s.Specular, /*out*/ oneMinusReflectivity);

			// shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
			// this is necessary to handle transparency in physically correct way - only diffuse component gets affected by alpha
			half outputAlpha;
			s.Albedo = PreMultiplyAlpha(s.Albedo, s.Alpha, oneMinusReflectivity, /*out*/ outputAlpha);

			half4 c = UNITY_BRDF_PBS(s.Albedo, s.Specular, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir, gi.light, gi.indirect);
			c.a = outputAlpha;
			return c;
		}

		//From the 5.6 standard shader source
		inline UnityGI UnityGlobalIlluminationSpyro(UnityGIInput data, half occlusion, half3 normalWorld, Unity_GlossyEnvironmentData glossIn)
		{
			UnityGI o_gi = UnityGISpyro_Base(data, occlusion, normalWorld);
			o_gi.indirect.specular = UnityGISpyro_IndirectSpecular(data, occlusion, glossIn);
			return o_gi;
		}

		//From the 5.6 standard shader source
		inline void LightingStandardSpyroSpecular_GI(
			SurfaceOutputStandardSpecular s,
			UnityGIInput data,
			inout UnityGI gi)
		{
			Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(s.Smoothness, data.worldViewDir, s.Normal, s.Specular);
			gi = UnityGlobalIlluminationSpyro(data, s.Occlusion, s.Normal, g);
		}

		void surf (Input IN, inout SurfaceOutputStandardSpecular o)
		{
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb * IN.vertexColor;
			_VertexColor = IN.vertexColor;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
