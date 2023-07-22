Shader "code/pp/test/RadiusBlur_hlsl"
 {
    Properties {
        _MainTex("纹理",2D)="while"{}
        _Level("强度",Range(1,30))=10
        _CenterX("中心X坐标",Range(0,1))=0.5
        _CenterY("中心Y坐标",Range(0,1))=0.5
        _BufferRadius("缓冲半径",Range(0, 1))=1
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
       
        Pass{
            HLSLPROGRAM
            #pragma vertex vert  
            #pragma fragment frag  
               
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct v2f
            {
                float4 pos:SV_POSITION;   
                float2 uv:TEXCOORD;
            };  

            CBUFFER_START(UnityPerMaterial)
            float _Level;
            float _CenterX;
            float _CenterY;
            float _BufferRadius;
            float4 _MainTex_ST;
            CBUFFER_END           

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
           
             v2f vert (appdata v) 
            {
                v2f o;          
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
				o.pos = vertexInput.positionCS;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag(v2f i):SV_Target
            {
               
                half4 finalColor;
                half2 center=half2(_CenterX,_CenterY);

                //求中心点uv坐标到片元所在uv的向量
                //屏幕成像左下角的点的uv坐标是零向量
                //右上角的点的uv坐标是一向量
                //向量的方向是减数指向被减数
                half2 uvDir =i.uv - center;
                half3 tempColor = half3(0,0,0);

                //求得两点之间的距离  
                //根据uv坐标的特点 这个距离值不会大于根号2 或小于0
                half dis= distance(i.uv, center);

                half blurRatio = 0;

                //这里遇到了个奇怪的bug
                //之前编辑的时候 这部分代码剪切后可以运行
                //粘贴后不能运行
                //但是重新打一次就可以了
                //估计是在中文模式下重输入了一些空白符

               if(_BufferRadius == 0){
                    blurRatio = 1;
                }else if(_BufferRadius == 1){
                   blurRatio = 0;
                }else
                {
                    //saturate(dis / _BufferRadius)一定是小数
                    //在center不变即dis不变的时候
                    //_BufferRadius越大
                    //saturate(dis / _BufferRadius)越小
                    //pow是为了让blurRatio呈现两极分化
                    //即靠近中心区域的片元是极小的
                    //越远离则模糊效率越大
                    blurRatio = pow(saturate(dis / _BufferRadius), 4);
                }
   
                for(half j=0; j<_Level; j++){
                    //在blurRatio等于1时 每次采样的uv坐标刚好等于uvDir + center
                    //即等于i.uv 即每次采样都是片元本身对应像素点的颜色然后叠加
                    //最后再除以采样次数 结果相当于没有开启径向模糊

                    //在blurRatio等于1时
                    //相当于没有开启径向模糊的清晰半径
                    //因为每个像素点都按照注释3进行径向模糊

                    //在blurRatio介于两者之间时
                    //其实是各个采样点更加靠近了片元的原始像素点
                    //并且blurRatio越小 每次的采样点更加靠近原始像素点
                    //越靠近原始像素点 模糊的效果越小

                    //注释3
                    //下面的讨论在blurRatio等于1的条件下进行
                    //当j = 0的时候  采样的uv坐标刚好等于uvDir + center
                    //即等于i.uv
                    //j = 1的时候 uvDir  * (1 - 0.01 * j * blurRatio)的值等于
                    //uvDir * 0.99
                    //采样的uv坐标等于在i.uv的基础上
                    //往 center 方向推移了
                    //uvDir与center距离乘以0.01再乘以1的长度
                    //j = 2的时候  uvDir  * (1 - 0.01 * j * blurRatio)的值等于
                    //uvDir * 0.98
                    //采样的uv坐标等于在i.uv的基础上
                    //往 center 方向推移了
                    //uvDir与center距离乘以0.01再乘以2的长度
                    //如此类推 这里将这些位置的颜色值叠加起来
                    //在结尾部分再进行求平均值
                    tempColor += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex,uvDir * (1 - 0.01 * j * blurRatio) + center).rgb;
                }

                //将叠加的值进行求平均值
                //变成当前片元代表的颜色
                finalColor.rgb = tempColor / _Level;


                return finalColor;
            }

            ENDHLSL
            }
        }
    FallBack "Diffuse"
}