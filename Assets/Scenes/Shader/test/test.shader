Shader "Custom/test"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _PixelResolution ("Pixel Resolution", Float) = 16
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
             
            sampler2D _MainTex;
            float _PixelResolution;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 原始 UV 坐标
                float2 uv = i.uv;
                // 量化 UV，实现像素化：将UV乘以分辨率，取整数后再恢复到 0~1 范围
                float2 pixelatedUV = floor(uv * _PixelResolution) / _PixelResolution;
                // 使用修改后的 UV 坐标从纹理中采样
                fixed4 col = tex2D(_MainTex, pixelatedUV);
                return col;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}