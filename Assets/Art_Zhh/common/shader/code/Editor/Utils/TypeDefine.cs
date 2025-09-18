namespace CustomShaderEditor
{
    public class TypeDefine
    {
    }

    public enum RenderingType : int
    {
        Opaque,
        Transparent
    }

    public enum RenderFace
    {
        Front = 2,
        Back = 1,
        Both = 0
    }

    public enum CustomBlendMode
    {
        Opaque,
        AlphaBlending,
        WZ_Additive,
        Additive,
        SoftAdditive,
        Multiplicative,
        Two_x_Multiplicative,
        Custom,
    }

    public enum LanguageType
    {
        中文,
        English,
    }

    public enum SpecularAlgorithm
    {
        PBR,
        SSS,
    }

    public enum SpecularAlgorithmSc
    {
        BlinnPhong1 = 0,
        // BlinnPhong2,
        PBR = 2,
        // SSS,
    }

    public enum ExtrudeMode
    {
        NormalVS,
        NormalOS
    }

    public enum HighlightArea
    {
        None,
        One,
        Two,
        Three
    }
    public enum ColorMask
    {
        None = 0,
        RGBA = 15,
    }
}