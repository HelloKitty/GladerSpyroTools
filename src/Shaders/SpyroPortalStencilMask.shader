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
Shader "Spyro/SpyroPortalStencilMask"
{
	Properties
	{
		_StencilReferenceID("Stencil ID Reference Reference", Float) = 1

		[Enum(UnityEngine.Rendering.CompareFunction)]
		_StencilComp("Stencil Comparison", Float) = 8

		[Enum(UnityEngine.Rendering.StencilOp)]
		_StencilOp("Stencil Operation", Float) = 2
		_StencilWriteMask("Stencil Write Mask", Float) = 255
		_StencilReadMask("Stencil Read Mask", Float) = 255

		[MaterialToggle]
		_ZWrite("ZWrite", Float) = 0
	}

	SubShader
	{
		Tags
		{
			"RenderType" = "Transparent" "Queue" = "Transparent" "IgnoreProjector" = "True"
		}
		Pass
		{
			ZWrite [_ZWrite]
			Cull Off

			Stencil
			{
				Ref[_StencilReferenceID]
				Comp[_StencilComp]	// always
				Pass[_StencilOp]	// replace
				ReadMask[_StencilReadMask]
				WriteMask[_StencilWriteMask]
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag


			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				return o;
			}

			half4 frag(v2f i) : COLOR
			{
				return 0.0f;
			}
			ENDCG
		}
	}
}