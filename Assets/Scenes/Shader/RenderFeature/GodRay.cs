using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class VolumeLightingFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class VolumeLightingSettings
    {
        [Range(0,0.0001f)]
        public float lightIntensity = 0f;
        public float stepSize = 0.1f;
        public float maxDistance = 1000f;
        public int maxStep = 200;
    }
    
    [SerializeField] private VolumeLightingSettings settings = new VolumeLightingSettings();
    private VolumeLightingPass volumeLightingPass;//这个RenderPass在下面class声明，这里仅作为实例化写入到逻辑之中
    private Material material;//RenderPass是执行层，这里是上面的逻辑层

    public override void Create()
    {
        // 创建材质
        material = CoreUtils.CreateEngineMaterial("URP/PPS/VolumeLightingShader");
        
        // 创建渲染通道
        volumeLightingPass = new VolumeLightingPass(settings, material);
        volumeLightingPass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (material == null || settings.lightIntensity <= 0)
            return;
        
        renderer.EnqueuePass(volumeLightingPass);//将Create()创建的渲染通道添加到渲染器
    }

    protected override void Dispose(bool disposing)
    {
        CoreUtils.Destroy(material);//销毁材质
    }

    private class VolumeLightingPass : ScriptableRenderPass
    {
        private readonly VolumeLightingSettings settings;
        private readonly Material material;
        private RenderTargetIdentifier source;
        private RenderTargetHandle tempRT;

        public VolumeLightingPass(VolumeLightingSettings settings, Material material)
        {
            this.settings = settings;
            this.material = material;
            tempRT.Init("_VolumeLightingTemp");
            ConfigureInput(ScriptableRenderPassInput.Color);

        }

        public void Setup(RenderTargetIdentifier source)
        {
            //this.source = source;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (material == null)
                return;

            CommandBuffer cmd = CommandBufferPool.Get("VolumeLighting");
            var source = renderingData.cameraData.renderer.cameraColorTarget;

            // 设置材质参数
            material.SetFloat("_LightIntensity", settings.lightIntensity);
            material.SetFloat("_StepSize", settings.stepSize);
            material.SetFloat("_MaxDistance", settings.maxDistance);
            material.SetInt("_MaxStep", settings.maxStep);

            // 获取摄像机目标描述符
            RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;
            descriptor.depthBufferBits = 0;

            // 创建临时RT
            cmd.GetTemporaryRT(tempRT.id, descriptor, FilterMode.Bilinear);

            // 执行渲染
            cmd.Blit(source, tempRT.Identifier());
            cmd.Blit(tempRT.Identifier(), source, material);
            
            // 释放临时RT
            cmd.ReleaseTemporaryRT(tempRT.id);

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}