using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[System.Serializable]
[PostProcess(typeof(AnimatedRainFXRenderer), PostProcessEvent.BeforeStack, "Custom/AnimatedRainFX")]

public sealed class AnimatedRainFX : PostProcessEffectSettings
{
    public override bool IsEnabledAndSupported(PostProcessRenderContext context)
    {
        return base.IsEnabledAndSupported(context) && AnimatedRain.Instance;
    }


}

public sealed class AnimatedRainFXRenderer : PostProcessEffectRenderer<AnimatedRainFX>
{
    public override void Render(PostProcessRenderContext context)
    {
        AnimatedRain.Instance.Render(context.camera, context.source, context.destination, context.command);
    }
}