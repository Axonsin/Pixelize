using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class PixelizeRenderFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        [Header("General Settings")]
        [Range(0, 1)]
        public float mixAmount = 0.5f;
        
        [Header("Image Settings")]
        [Range(2, 512)]
        public float pixelResolutionX = 16f;
        [Range(2, 512)]
        public float pixelResolutionY = 16f;
        public bool customresolution = false;       
        [Header("Circle Settings")]
        [Range(0.01f, 0.5f)]
        public float circleRadius = 0.4f;
        [Range(0.001f, 0.1f)]
        public float edgeSharpness = 0.01f;
        
        // Circle UV缩放
        [Range(2,512)]
        public float uvScaleX = 2.0f;
        [Range(2,512)]
        public float uvScaleY = 2.0f;
        public bool linkUVScales = false;
        public Vector2 circleOffset = new Vector2(0.5f, 0.5f);
        public Color circleColor = Color.white;
        public Color backgroundColor = Color.black;
        
        [Header("GrayScale Settings")]
        public bool enableGrayscale = false;
        public Color shadowColor = new Color(0.2f, 0.3f, 0.5f, 1f);
        public Color highlightColor = new Color(0.9f, 0.7f, 0.4f, 1f);
        [Range(0.1f, 5f)]
        public float contrast = 1f;
        
        [Header("Sync Settings")]
        public bool adaptToScreenRatio = false;
    }

    // 在Inspector中公开设置
    public Settings settings = new Settings();
    
    class SDFCircleRenderPass : ScriptableRenderPass
    {
        private Material _material;
        private RenderTargetHandle tempTexture;
        private Settings settings;

        public SDFCircleRenderPass(Settings settings)
        {
            this.settings = settings;
            tempTexture.Init("_TempSDFCircleRT");
        }

        // 只接受材质
        public void Setup(Material material)
        {
            this._material = material;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (_material == null)
                return;

            // 从renderingData获取相机颜色目标
            var cameraColorTarget = renderingData.cameraData.renderer.cameraColorTarget;

            CommandBuffer cmd = CommandBufferPool.Get("Custom/TiledSDFCirclesAdvanced");
            
            _material.SetFloat("_MixAmount", settings.mixAmount);
            _material.SetFloat("_PixelResolutionX", settings.pixelResolutionX);
            _material.SetFloat("_PixelResolutionY", settings.pixelResolutionY);
            _material.SetFloat("_LinkResolutions", settings.customresolution ? 1.0f : 0.0f);
            _material.SetFloat("_CircleRadius", settings.circleRadius);
            _material.SetFloat("_EdgeSharpness", settings.edgeSharpness);
            _material.SetFloat("_UVScaleX", settings.uvScaleX);
            _material.SetFloat("_UVScaleY", settings.uvScaleY);
            _material.SetFloat("_LinkUVScales", settings.linkUVScales ? 1.0f : 0.0f);
            _material.SetVector("_CircleOffset", settings.circleOffset);
            _material.SetColor("_CircleColor", settings.circleColor);
            _material.SetColor("_BackgroundColor", settings.backgroundColor);
            _material.SetInt("_EnableGrayscale", settings.enableGrayscale ? 1 : 0);
            _material.SetColor("_ShadowColor", settings.shadowColor);
            _material.SetColor("_HighlightColor", settings.highlightColor);
            _material.SetFloat("_Contrast", settings.contrast);
            // 字符串查找怎么你了（生气）
            

            RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;
            cmd.GetTemporaryRT(tempTexture.id, descriptor);

            // 使用cameraColorTarget替代_source
            cmd.Blit(cameraColorTarget, tempTexture.Identifier(), _material);
            cmd.Blit(tempTexture.Identifier(), cameraColorTarget);
        
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
            
            //Here is Debug
            Debug.Log($"Setting parameters: (Tip in l108)circleRadius={settings.circleRadius}");
        }


        public override void FrameCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(tempTexture.id);
        }
    }

    private SDFCircleRenderPass _renderPass;
    private Material _material;

    public override void Create()
    {
        // 加载着色器并创建材质
        Shader shader = Shader.Find("Custom/TiledSDFCirclesAdvanced");
        if (shader == null)
        {
            Debug.LogError("无法找到SDF圆形后处理着色器!");
            return;
        }
        
        _material = new Material(shader);
        
        // 创建渲染通道
        _renderPass = new SDFCircleRenderPass(settings);
        
        // 设置渲染事件时机 - 在后处理之前
        _renderPass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (_material == null)
            return;
        
        // 只传递材质，不传递相机颜色目标
        _renderPass.Setup(_material);
        renderer.EnqueuePass(_renderPass);
    }
    
    protected override void Dispose(bool disposing)
    {
        if (disposing && _material != null)
        {
            CoreUtils.Destroy(_material);
        }
    }
}