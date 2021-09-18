Shader "Unlit/Wall"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainColor("Color",Color)=(1,1,1,1)
        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout" }
        LOD 100

        Pass
        {
        Stencil
			{
                Ref 2
                Comp NotEqual//不通过模板测试
            }

            Tags { "LightMode"="ForwardBase" }

            Blend One OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldNormal:TEXCOORD1;
                float3 worldPos:TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _MainColor;

            fixed _Cutoff;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldPos = normalize(i.worldPos);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                // 纹素值
                fixed4 texColor = tex2D(_MainTex, i.uv);
                // 原理
                // if ((texColor.a - _Cutoff) < 0.0) { discard; }
                // 如果结果小于0，将片元舍弃
                clip(texColor.a - _Cutoff);
                // 反射率
                fixed3 albedo =  texColor.rgb * _MainColor.rgb;
                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;
                // 漫反射
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
                return fixed4(ambient + diffuse, 1.0);
            }
            ENDCG
        }
    }
}
