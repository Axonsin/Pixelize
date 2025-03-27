// ============================================
// ColorGradients.hlsl
// 包含各种灰度转换和颜色渐变映射函数
// ============================================

#ifndef COLOR_GRADIENTS_INCLUDED
#define COLOR_GRADIENTS_INCLUDED

// 基础灰度转换函数 - 标准亮度权重
float GrayscaleStandard(float3 color)
{
    return dot(color, float3(0.299, 0.587, 0.114));
}

// 基础灰度转换函数 - 平均值法
float GrayscaleAverage(float3 color)
{
    return (color.r + color.g + color.b) / 3.0;
}

// 基础灰度转换函数 - 最大值法
float GrayscaleMax(float3 color)
{
    return max(max(color.r, color.g), color.b);
}

// 基础灰度转换函数 - 感知亮度法
float GrayscaleLuminance(float3 color)
{
    // 考虑人眼对不同颜色感知的差异
    return sqrt(0.299 * color.r * color.r + 
                0.587 * color.g * color.g + 
                0.114 * color.b * color.b);
}

// 使用颜色渐变纹理将灰度映射为色调化灰度
float4 GrayscaleWithGradientTexture(float grayscaleValue, sampler2D gradientTex)
{
    return tex2D(gradientTex, float2(grayscaleValue, 0.5));
}

// 使用简单的双色渐变映射灰度
float4 GrayscaleWithSimpleGradient(float grayscaleValue, float4 darkColor, float4 lightColor)
{
    return lerp(darkColor, lightColor, grayscaleValue);
}

// 使用三色渐变映射灰度(暗部、中间调、高光)
float4 GrayscaleWithTripleGradient(float grayscaleValue, float4 shadowColor, float4 midtoneColor, float4 highlightColor)
{
    if (grayscaleValue < 0.5)
    {
        // 从暗部到中间调
        return lerp(shadowColor, midtoneColor, grayscaleValue * 2.0);
    }
    else
    {
        // 从中间调到高光
        return lerp(midtoneColor, highlightColor, (grayscaleValue - 0.5) * 2.0);
    }
}

// 使用多点渐变映射灰度
float4 GrayscaleWithMultiGradient(float grayscaleValue, float4 colors[4], float thresholds[3])
{
    // 确保阈值升序排列: thresholds[0] < thresholds[1] < thresholds[2]
    
    if (grayscaleValue < thresholds[0])
    {
        return lerp(colors[0], colors[1], grayscaleValue / thresholds[0]);
    }
    else if (grayscaleValue < thresholds[1])
    {
        return lerp(colors[1], colors[2], (grayscaleValue - thresholds[0]) / (thresholds[1] - thresholds[0]));
    }
    else if (grayscaleValue < thresholds[2])
    {
        return lerp(colors[2], colors[3], (grayscaleValue - thresholds[1]) / (thresholds[2] - thresholds[1]));
    }
    else
    {
        return colors[3];
    }
}

// 使用细分区间进行色调映射
float4 GrayscaleWithTintedRanges(float grayscaleValue, float4 shadowTint, float4 midtoneTint, float4 highlightTint, float shadowMax, float highlightMin)
{
    // shadowMax: 阴影区域最大值 (默认0.33)
    // highlightMin: 高光区域最小值 (默认0.66)
    
    float4 tintedGrayscale;
    
    if (grayscaleValue < shadowMax)
    {
        // 阴影区域
        float factor = grayscaleValue / shadowMax;
        tintedGrayscale = shadowTint * factor;
    }
    else if (grayscaleValue < highlightMin)
    {
        // 中间调区域
        float factor = (grayscaleValue - shadowMax) / (highlightMin - shadowMax);
        tintedGrayscale = midtoneTint * factor;
    }
    else
    {
        // 高光区域
        float factor = (grayscaleValue - highlightMin) / (1.0 - highlightMin);
        tintedGrayscale = highlightTint * factor;
    }
    
    return tintedGrayscale;
}

// 添加噪声到灰度图像
float4 GrayscaleWithNoise(float grayscaleValue, float3 position, float noiseScale, float noiseAmount)
{
    // 简单的哈希噪声函数
    float noise = frac(sin(dot(position, float3(12.9898, 78.233, 45.5432))) * 43758.5453);
    
    // 将噪声范围调整到 [-noiseAmount/2, noiseAmount/2]
    noise = (noise - 0.5) * noiseAmount;
    
    // 添加到灰度值
    float noisyGrayscale = grayscaleValue + noise;
    
    // 确保结果在[0,1]范围内
    noisyGrayscale = saturate(noisyGrayscale);
    
    return float4(noisyGrayscale, noisyGrayscale, noisyGrayscale, 1.0);
}

// 复古风格色调映射函数
float4 GrayscaleVintage(float grayscaleValue)
{
    // 复古褐色调
    float3 sepiaTint = float3(1.0, 0.9, 0.7);
    
    // 将灰度值应用于褐色调
    float3 sepia = float3(
        grayscaleValue * sepiaTint.r,
        grayscaleValue * sepiaTint.g,
        grayscaleValue * sepiaTint.b
    );
    
    return float4(sepia, 1.0);
}

// 冷暖双色调映射
float4 GrayscaleDuotone(float grayscaleValue, float4 shadowColor, float4 highlightColor, float midPoint)
{
    if (grayscaleValue < midPoint)
    {
        return lerp(float4(0,0,0,1), shadowColor, grayscaleValue / midPoint);
    }
    else
    {
        return lerp(shadowColor, highlightColor, (grayscaleValue - midPoint) / (1.0 - midPoint));
    }
}

// 将正片叠底与灰度渐变结合
float4 MultiplyWithGradient(float4 baseColor, float4 blendColor, float gradientStrength)
{
    // 计算正片叠底结果
    float4 multiplied = baseColor * blendColor;
    
    // 计算灰度值
    float grayscale = GrayscaleStandard(multiplied.rgb);
    
    // 在正片叠底和灰度值之间插值
    return lerp(multiplied, float4(grayscale, grayscale, grayscale, multiplied.a), gradientStrength);
}

#endif // COLOR_GRADIENTS_INCLUDED