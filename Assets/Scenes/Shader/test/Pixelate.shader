Shader "Custom/PixelatedImageWithCircles"
{
    Properties
    {
        _MainTex ("Image Texture", 2D) = "white" {}
        _PixelSize ("Pixel Size", Range(1, 100)) = 10
        _CircleUVScale ("Circle UV Scale", Range(0.1, 10)) = 1.0
        _CircleRadius ("Max Circle Radius", Range(0.01, 0.5)) = 0.4
        _MinCircleRadius ("Min Circle Radius", Range(0.01, 0.5)) = 0.05
        _EdgeSharpness ("Edge Sharpness", Range(0.001, 0.1)) = 0.01
        _CircleColor ("Circle Color", Color) = (1,1,1,1)
        _BackgroundColor ("Background Color", Color) = (0,0,0,1)
        [Toggle] _UseImageColors ("Use Image Colors", Float) = 1
        [Toggle] _SizeBasedOnBrightness ("Size Based On Brightness", Float) = 1
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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _PixelSize;
            float _CircleUVScale;
            float _CircleRadius;
            float _MinCircleRadius;
            float _EdgeSharpness;
            float4 _CircleColor;
            float4 _BackgroundColor;
            float _UseImageColors;
            float _SizeBasedOnBrightness;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 1. 处理图像UV - 仅像素化，不缩放
                float2 dimensions = float2(1, 1) / _PixelSize;
                float2 pixelatedUV = floor(i.uv * dimensions) / dimensions;
                
                // 对原始图像进行采样
                fixed4 pixelatedColor = tex2D(_MainTex, pixelatedUV);
                
                // 计算亮度
                float brightness = dot(pixelatedColor.rgb, float3(0.299, 0.587, 0.114));
                
                // 2. 处理圆形点阵UV - 应用缩放
                float2 circleUV = i.uv * _CircleUVScale;
                float2 tiledCircleUV = frac(circleUV);
                
                // 计算点阵单元
                float2 circleCellUV = frac(tiledCircleUV * dimensions);
                
                // 每个像素单元内的本地中心点
                float2 localCenter = float2(0.5, 0.5);
                float distanceToCenter = length(circleCellUV - localCenter);
                
                // 根据亮度动态调整圆形半径
                // 我们需要知道当前圆形对应原图的哪个像素
                // 计算当前平铺后的单元对应的原始图像的哪个像素
                float2 originalPixelPos = floor(circleUV * dimensions) / dimensions;
                // 确保在图像边界内
                originalPixelPos = frac(originalPixelPos);
                // 获取对应像素的颜色
                fixed4 correspondingPixelColor = tex2D(_MainTex, originalPixelPos);
                // 计算对应像素的亮度
                float correspondingBrightness = dot(correspondingPixelColor.rgb, float3(0.299, 0.587, 0.114));
                
                float dynamicRadius;
                if (_SizeBasedOnBrightness > 0.5)
                {
                    // 亮度越高，圆越大
                    dynamicRadius = lerp(_MinCircleRadius, _CircleRadius, correspondingBrightness);
                }
                else
                {
                    // 固定半径
                    dynamicRadius = _CircleRadius;
                }
                
                // 生成SDF圆形
                float circle = smoothstep(dynamicRadius + _EdgeSharpness, dynamicRadius - _EdgeSharpness, distanceToCenter);
                
                // 决定圆的颜色
                float4 finalCircleColor;
                if (_UseImageColors > 0.5)
                {
                    finalCircleColor = correspondingPixelColor;
                }
                else
                {
                    finalCircleColor = _CircleColor;
                }
                
                // 混合背景和圆形
                return lerp(_BackgroundColor, finalCircleColor, circle);
            }
            ENDCG
        }
    }
}