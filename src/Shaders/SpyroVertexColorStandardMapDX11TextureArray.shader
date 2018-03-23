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
Shader "Spyro/SpyroVertexColorStandardMapDX11TextureArray" 
{
	Properties 
	{
		_MainTex ("Albedo Texture2DArray", 2DArray) = "" {}
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
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model that uses vertex colors as ambient light
		#pragma surface surf StandardSpyroSpecular noforwardadd nolppv vertex:vert

		//Allows emission
		#pragma shader_feature _MAP_EMISSION_ON
		#pragma shader_feature _MAP_TEXTURE_ANIM_ON

		//This target is required for Texture2DArray's
		#pragma target 3.5

		//This macro creates the sampler
		UNITY_DECLARE_TEX2DARRAY(_MainTex);

		half3 _VertexColor;
		uniform half _FlatAmbient;
		uniform half _VertexColorAmbient;
		uniform half _SmoothnessMultiplier;
		uniform half _SpecularMultiplier;
	
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

		//TODO: How should we include this better? Including down here seems kinda bad
		//We have to include here because it depends on some variables defined above
		//This include contains the lighting functions AND the vertex portion that sets the vertex color
		#include "SpyroVertexLitCg.cginc"

		inline float WrapMinMax(float x, float x_min, float x_max)
		{
			return (fmod((x - x_min), (x_max - x_min))) + x_min;
		}

		void surf (Input IN, inout SurfaceOutputStandardSpecular o)
		{
			//TODO: Should we change the UVs of the mesh
			//For this DX11 texture array shader we always need to know the index
			//Unless we change the UVs of the mesh
			int tileIndexX = (int)(IN.uv_MainTex.x * 16);
			int tileIndexY = (int)(IN.uv_MainTex.y * 8);

			if (IN.uv_MainTex.y < 0.0f || IN.uv_MainTex.x < 0.0f || tileIndexX < 0 || tileIndexY < 0)
			{
				clip(-1);
				return;
			}

			//TODO: Support emission on Texture2DArray
			#if _MAP_TEXTURE_ANIM_ON
			//This is equivalent non-branching
			/*int booleanIsAnimatedTileRange = clamp(((int)(tileIndexX / 7) - (int)(tileIndexX / 8) * 100), 0.0f, 1.0f) * clamp(((int)(tileIndexY / 6) - (int)(tileIndexY / 7) * 100), 0.0f, 1.0f);

			float newYCoord = lerp(IN.uv_MainTex.y, WrapMinMax(IN.uv_MainTex.y + _Time.x, tileIndexY * 0.125f, tileIndexY * 0.125f + 0.125f), booleanIsAnimatedTileRange);

			fixed4 c = tex2D(_MainTex, float2(IN.uv_MainTex.x, newYCoord));*/

			if (tileIndexX == _AnimationInformation.x && tileIndexY == _AnimationInformation.y)
				IN.uv_MainTex = float2(WrapMinMax(IN.uv_MainTex.x + _Time.x * _AnimationInformation.z, _AnimationInformation.x * 0.0625f, (_AnimationInformation.x + 1.0f) * 0.0625f), WrapMinMax(IN.uv_MainTex.y + _Time.x * _AnimationInformation.w, _AnimationInformation.y * 0.125f, (_AnimationInformation.y + 1.0f) * 0.125f));
			#endif

			float3 arrayUvs = float3((IN.uv_MainTex.x - tileIndexX * 0.0625f) / 0.0625f, (IN.uv_MainTex.y - tileIndexY * 0.125f) / 0.125f, tileIndexY * 16 + tileIndexX);

			fixed4 c = UNITY_SAMPLE_TEX2DARRAY(_MainTex, arrayUvs);
			
			//TODO: Support emission on Texture2DArray
			//If the user requested emission then we should use it
			#if _MAP_EMISSION_ON
			fixed3 em = tex2D(_EmissionMask, arrayUvs);
			o.Emission = em * _EmissionStrength;
			#endif

			_VertexColor = IN.vertexColor;
			o.Albedo = c.rgb * _VertexColor;

			//Since it's easier to cut out pieces we want to add smoothness to we will use roughness
			//for this shader. The concept being 1 - smoothness is roughness. So, remove alpha to a part of the picture to add smoothness
			float smoothness = (1.0f - c.a);
			o.Smoothness = smoothness * _SmoothnessMultiplier;
			o.Specular = o.Albedo * smoothness * _SpecularMultiplier;
			o.Alpha = 1.0f;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
