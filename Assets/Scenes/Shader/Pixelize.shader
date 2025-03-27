Shader "Custom/TiledSDFCirclesAdvanced"
{
    Properties
    {
        [Header(GeneralSettings)]
        _MixAmount ("MixAmount(Image&Circle)", Range(0, 1)) = 0.5//混合量
        
        [Header(ImageSettings)]
        _MainTex ("Texture", 2D) = "white" {}
        [Toggle] _LinkResolutions ("Open Custom X/Y Resolutions", Float) = 0 // 链接XY分辨率的开关
        _PixelResolutionX ("Pixel Resolution (X)", Range(2,512)) = 16
        _PixelResolutionY ("Pixel Resolution Y", Range(2,512)) = 16
        
        
        [Header((I recommend Pixel Resolution is same with UV Scale))]
        
        [Header(CircleSettings)]
        _CircleRadius ("Circle Radius", Range(0.01, 0.5)) = 0.4
        _EdgeSharpness ("Edge Sharpness", Range(0.001, 0.1)) = 0.01
        _UVScaleX ("UV Scale X", Range(1, 512)) = 2.0
        _UVScaleY ("UV Scale Y", Range(1, 512)) = 2.0
        [Toggle] _LinkUVScales ("Link UV X/Y", Float) = 1
        _CircleOffset ("Circle Offset", Vector) = (0.5, 0.5, 0, 0)
        _CircleColor ("Circle Color", Color) = (1,1,1,1)
        _BackgroundColor ("Background Color", Color) = (0,0,0,1)
        
        [Header(GrayScaleSettings)]
        [Toggle] _EnableGrayscale ("Enable Grayscale", Float) = 0//灰度开关控制
        _ShadowColor ("Shadow Color", Color) = (0.2, 0.3, 0.5, 1.0)//阴影色
        _HighlightColor ("Highlight Color", Color) = (0.9, 0.7, 0.4, 1.0)//高光色
        _Contrast ("Contrast", Range(0.1, 5)) = 1.0//对比度
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Cull"="Off" "ZWrite"="Off" "ZTest"="Always" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "GrayScale.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv2 : TEXCOORD1;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float _PixelResolution;
            float _CircleRadius;
            float _EdgeSharpness;
            float _UVScaleX;
            float _UVScaleY;
            float2 _CircleOffset;
            float4 _CircleColor;
            float4 _BackgroundColor;
            float _MixAmount;
            float _EnableGrayscale;
            float4 _ShadowColor;
            float4 _HighlightColor;
            float _Contrast;
            float _LinkResolutions;
            float _PixelResolutionX;
            float _PixelResolutionY;
            float _LinkUVScales;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.uv2 = v.uv2;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //像素化部分
               // 原始 UV 坐标
                float2 uv = i.uv;
                // 计算像素化UV - 使用独立的X和Y分辨率
                float2 pixelResolution = float2(_PixelResolutionX, _PixelResolutionY);
                // 如果链接分辨率开关打开，则使用X分辨率
                if (_LinkResolutions < 0.5) {
                    pixelResolution.y = pixelResolution.x;
                }
                float2 pixelatedUV = floor(uv * pixelResolution) / pixelResolution;
                // 使用修改后的 UV 坐标从纹理中采样
                fixed4 col0 = tex2D(_MainTex, pixelatedUV);
                if(_EnableGrayscale > 0.5)
                {
                    float grayscale = GrayscaleStandard(col0.rgb);
                    float4 tintedGrayscale = GrayscaleDuotone(
                    grayscale,
                    _ShadowColor,  // 阴影色(冷色调)
                    _HighlightColor,  // 高光色(暖色调)
                    0.5                          // 中点
                    );
                    tintedGrayscale.rgb = pow(tintedGrayscale.rgb,_Contrast);
                    col0 = tintedGrayscale;
                }

                 //Circles部分
                 // 计算Circle的UV缩放
                float2 uvScale = float2(_UVScaleX, _UVScaleY);
                if (_LinkUVScales < 0.5)
                {
                    uvScale.y = uvScale.x;
                }
                
                // 应用UV缩放和偏移
                float2 scaledUV = i.uv * uvScale;
                float2 tiledUV = frac(scaledUV);
                // 以指定偏移为中心
                float2 centeredUV = tiledUV - _CircleOffset;
                // 计算到圆心的距离
                float distance = length(centeredUV);
                // 平滑边缘的SDF圆
                float circle = smoothstep(_CircleRadius + _EdgeSharpness, _CircleRadius - _EdgeSharpness, distance);
                // 混合颜色
                fixed4 col1 = lerp(_BackgroundColor, _CircleColor, circle);
                fixed4 finalColor = lerp(col0, col1, _MixAmount);
                return finalColor;
            }
            ENDHLSL
        }
    }
}