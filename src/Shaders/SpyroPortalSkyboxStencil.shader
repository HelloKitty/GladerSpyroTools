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
Shader "Spyro/SpyroPortalSkyboxStencil"
{
	Properties
	{
		_Color("Skybox Color", Color) = (1.0, 1.0, 1.0)
		_SkyboxIntensity("Skybox Light Intensity", Float) = 1.0

		_StencilReferenceID("Stencil ID Reference", Int) = 1

		_StencilWriteMask("Stencil Write Mask", Float) = 255
		_StencilReadMask("Stencil Read Mask", Float) = 255
	}

	SubShader
	{
		Tags
		{
			"Queue" = "Transparent+1" "RenderType"= "Transparent"
		}
		Pass
		{
			LOD 200
			CULL OFF
			ZTest Always
			ZWrite On

			Stencil
			{
				Ref[_StencilReferenceID]
				Comp Equal	//This is Comp 3 from the original stencil shader
				Pass Replace //This is Pass 2 from the original stencil shader
				ReadMask[_StencilReadMask]
				WriteMask[_StencilWriteMask]
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#pragma multi_compile _ PIXELSNAP_ON​
			
			#include "UnityCG.cginc"

			uniform fixed3 _Color;
			uniform half _SkyboxIntensity;

			struct appdata
			{
				float4 vertex : POSITION;
				float3 vertexColor : COLOR;
			};

			struct v2f
			{
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float3 vertexColor : TEXCOORD02;
			};
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(float4(v.vertex.xyz, 1.0));

				UNITY_TRANSFER_FOG(o,o.vertex);
				o.vertexColor = v.vertexColor;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed3 col = i.vertexColor * _Color * _SkyboxIntensity;

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);

				//Calculating the alpha like this means it will become completely invisible
				return fixed4(col, 1.0f);
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}