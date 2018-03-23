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
Shader "Spyro/SpyroVertexColorSpyro2Water" 
{
	Properties 
	{
		[Toggle(_TRANSPARENT_FADE_ON)]
		_TransparencyToggle("Toggle Transparency", Int) = 1

		_Color ("Color (RGBA)", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_FlatAmbient ("Flat Ambient Lighting", Float) = 0.25
		_VertexColorAmbient ("Vertex Colored Ambient Lighting", Float) = 1.7
		_SmoothnessMultiplier ("Smoothness Albedo Alpha Multiplier", Float) = 1.0
		_SpecularMultiplier ("Specular From Albedo Multiplier", Float) = 0.4

		[Toggle(_MAP_TEXTURE_ANIM_ON)]
		_AnimationToggle("Toggle Animation", Int) = 0
		_AnimationInformation ("X: X Coord Y: Y Coord Z: X Scroll Speed W: Y Scroll Speed", Vector) = (0, 0, 0, 0)

		[Toggle(_MAP_EMISSION_ON)]
		_EmissionToggle ("Toggle Emission", Int) = 0
		_EmissionMask ("Emission Mask", 2D) = "white" {}
		_EmissionStrength ("Emission Strength", Float) = 1.0
	}
	SubShader 
	{
		Tags { "Queue" = "Transparent" "RenderType"="Transparent" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model that uses vertex colors as ambient light
		#pragma surface surf StandardSpyroSpecular noforwardadd nolppv vertex:vert alpha:auto

#if _TRANSPARENT_FADE_ON
		#pragma alpha:auto
#endif

		//Allows emission
		#pragma shader_feature _MAP_EMISSION_ON
		#pragma shader_feature _MAP_TEXTURE_ANIM_ON
		#pragma shader_feature _TRANSPARENT_FADE_ON

		#include "UnityPBSLighting.cginc"
		#include "HLSLSupport.cginc"
		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		half3 _VertexColor;
		uniform half _FlatAmbient;
		uniform half _VertexColorAmbient;
		uniform half _SmoothnessMultiplier;
		uniform half _SpecularMultiplier;
		fixed4 _Color;
	
		#if _MAP_TEXTURE_ANIM_ON
		uniform fixed4 _AnimationInformation;
		#endif

		#if _MAP_EMISSION_ON
		uniform sampler2D _EmissionMask;
		float _EmissionStrength;
		#endif

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

		inline float WrapMinMax(float x, float x_min, float x_max)
		{
			return (fmod((x - x_min), (x_max - x_min))) + x_min;
		}

		void surf (Input IN, inout SurfaceOutputStandardSpecular o)
		{
			#if _MAP_TEXTURE_ANIM_ON
			int tileIndexX = (int)(IN.uv_MainTex.x * 16.0f);
			int tileIndexY = (int)(IN.uv_MainTex.y * 8.0f);

			//This is equivalent non-branching
			/*int booleanIsAnimatedTileRange = clamp(((int)(tileIndexX / 7) - (int)(tileIndexX / 8) * 100), 0.0f, 1.0f) * clamp(((int)(tileIndexY / 6) - (int)(tileIndexY / 7) * 100), 0.0f, 1.0f);

			float newYCoord = lerp(IN.uv_MainTex.y, WrapMinMax(IN.uv_MainTex.y + _Time.x, tileIndexY * 0.125f, tileIndexY * 0.125f + 0.125f), booleanIsAnimatedTileRange);

			fixed4 c = tex2D(_MainTex, float2(IN.uv_MainTex.x, newYCoord));*/

			if (tileIndexX == _AnimationInformation.x && tileIndexY == _AnimationInformation.y)
				IN.uv_MainTex = float2(WrapMinMax(IN.uv_MainTex.x + _Time.x * _AnimationInformation.z, _AnimationInformation.x * 0.0625f, (_AnimationInformation.x + 1.0f) * 0.0625f), WrapMinMax(IN.uv_MainTex.y + _Time.x * _AnimationInformation.w, _AnimationInformation.y * 0.125f, (_AnimationInformation.y + 1.0f) * 0.125f));
			#endif

			fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
			
			//If the user requested emission then we should use it
			#if _MAP_EMISSION_ON
			fixed3 em = tex2D(_EmissionMask, IN.uv_MainTex);
			o.Emission = em * _EmissionStrength;
			#endif

			_VertexColor = IN.vertexColor;
			o.Albedo = c.rgb * _VertexColor * _Color.rgb;

			//Since it's easier to cut out pieces we want to add smoothness to we will use roughness
			//for this shader. The concept being 1 - smoothness is roughness. So, remove alpha to a part of the picture to add smoothness
			float smoothness = (1.0f - c.a);
			o.Smoothness = smoothness * _SmoothnessMultiplier;
			o.Specular = o.Albedo * smoothness * _SpecularMultiplier;

			#if _TRANSPARENT_FADE_ON
				o.Alpha = _Color.a;
			#else
				o.Alpha = 1.0f;
			#endif
		}
		ENDCG
	}
	FallBack "Diffuse"
}
