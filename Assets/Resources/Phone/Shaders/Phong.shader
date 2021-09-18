Shader "lit/Phong"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" {}
        _NormalMap("Normal Map",2D) = "bump"{}
        _AOMap("AO Map",2D)="white" {}
        _SpecMask("Spec Mask",2D)="white"{}

        _NormalIntensity("Normal Intensity",Range(0.0,5.0)) = 1.0            
        _Shininess("Shininess",Range(0.01,100)) = 1.0
        _SpecIntensity("_SpecIntensity",Range(0.01,5)) = 1.0
        _AmbientColor("Ambient Color",Color) = (0,0,0,0)
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "AutoLight.cginc"
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 normal_dir :TEXCOORD1;
                float3 pos_world:TEXCOORD2;
                float3 tangent_dir:TEXCOORD3;
                float3 binormal_dir:TEXCOORD4;
            };

            sampler2D _MainTex;
            sampler2D _NormalMap;
            sampler2D _AOMap;
            sampler2D _SpecMask;


            float4 _MainTex_ST;
            
            float _Shininess;
            float4 _AmbientColor;
            float _SpecIntensity;
            
            float4 _LightColor0;
            
            float _NormalIntensity;
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.normal_dir = normalize(mul(float4(v.normal,0.0),unity_WorldToObject).xyz);
                o.tangent_dir = normalize(mul(unity_ObjectToWorld,float4(v.tangent.xyz,0.0)).xyz);
                o.binormal_dir = normalize(cross(o.normal_dir,o.tangent_dir)) * v.tangent.w;
                o.pos_world = mul(unity_ObjectToWorld,v.vertex).xyz;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                half4 base_color = tex2D(_MainTex,i.uv);
                half4 normalmap = tex2D(_NormalMap,i.uv);
                half4 ao_color = tex2D(_AOMap,i.uv);
                half4 spec_mask = tex2D(_SpecMask,i.uv);

                //Normalmap      
                half3 normal_data = UnpackNormal(normalmap);
                normal_data.xy = normal_data.xy *_NormalIntensity;
                half3 normal_dir = normalize(i.normal_dir);
                half3 tangent_dir = normalize(i.tangent_dir);
                half3 binormal_dir = normalize(i.binormal_dir);
                float3x3 TBN = float3x3(tangent_dir,binormal_dir,normal_dir);
                normal_dir = normalize(mul(normal_data.xyz,TBN));
                //normal_dir = normalize(tangent_dir * normal_data.x * _NormalIntensity + binormal_dir * normal_data.y * _NormalIntensity + normal_dir * normal_data.z);


                //diffuseColor    
                float3 light_dir = normalize(_WorldSpaceLightPos0.xyz);
                float3 NdotL = dot(normal_dir,light_dir);
                float3 diffuse_color = max(0.0,NdotL)*_LightColor0.xyz*base_color.xyz;

                //spec_color
                float3 reflect_dir = reflect(-light_dir,normal_dir);
                float3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);
                float RdotV= dot(reflect_dir,view_dir);
                float3 spec_color = pow(max(0.0,RdotV),_Shininess)*_LightColor0.xyz*_SpecIntensity*spec_mask; 

                float3 final_color = (diffuse_color+spec_color+_AmbientColor.xyz)*ao_color;

                return float4(final_color,1.0);
            }
            ENDCG
        }
         Pass
        {
            Tags{"LightMode"="ForwardAdd"}
            Blend One One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd
            #include "AutoLight.cginc"
            #include "UnityCG.cginc"

            struct appdata
            {
                //模型顶点
                float4 vertex : POSITION;
                //模型uv
                float2 uv : TEXCOORD0;
                //模型法线
                float3 normal : NORMAL;
                //模型切线
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                //uv信息
                float2 uv : TEXCOORD0;
                //位置信息
                float4 pos : SV_POSITION;
                //法线方向信息
                float3 normal_dir :TEXCOORD1;
                //世界空间位置信息
                float3 pos_world:TEXCOORD2;
                //切线方向信息
                float3 tangent_dir:TEXCOORD3;
                //次法线方向信息
                float3 binormal_dir:TEXCOORD4;
            };

            //
            float4 _LightColor0;

            //主贴图
            sampler2D _MainTex;
            //法线贴图
            sampler2D _NormalMap;
            //AO贴图
            sampler2D _AOMap;
            //
            sampler2D _SpecMask;

            //主贴图Tilling,Offset
            float4 _MainTex_ST;         
            //镜面反射强度
            float _Shininess;
            //环境色
            float4 _AmbientColor;
            //
            float _SpecIntensity;      
            //法线贴图强度     
            float _NormalIntensity;

            v2f vert (appdata v)
            {
                v2f o;
                //
                o.pos = UnityObjectToClipPos(v.vertex);
                //
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //
                o.normal_dir = normalize(mul(float4(v.normal,0.0),unity_WorldToObject).xyz);
                o.tangent_dir = normalize(mul(unity_ObjectToWorld,float4(v.tangent.xyz,0.0)).xyz);
                o.binormal_dir = normalize(cross(o.normal_dir,o.tangent_dir)) * v.tangent.w;
                o.pos_world = mul(unity_ObjectToWorld,v.vertex).xyz;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                half4 base_color = tex2D(_MainTex,i.uv);
                half4 ao_color = tex2D(_AOMap,i.uv);
                half4 spec_mask = tex2D(_SpecMask,i.uv);
                half4 normalmap = tex2D(_NormalMap,i.uv);
                half3 normal_data = UnpackNormal(normalmap);
                normal_data.xy = normal_data.xy *_NormalIntensity;
                //Normalmap
                half3 normal_dir = normalize(i.normal_dir);
                half3 tangent_dir = normalize(i.tangent_dir);
                half3 binormal_dir = normalize(i.binormal_dir);
                float3x3 TBN = float3x3(tangent_dir,binormal_dir,normal_dir);
                normal_dir = normalize(mul(normal_data.xyz,TBN));
                //normal_dir = normalize(tangent_dir * normal_data.x * _NormalIntensity + binormal_dir * normal_data.y * _NormalIntensity + normal_dir * normal_data.z);


                //float3 normal_dir = normalize(i.normal_dir);
                
                float3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);

                #if defined(DIRECTIONAL)
                half3 light_dir = normalize(_WorldSpaceLightPos0.xyz);
                half attenuation = 1.0;
                #elif defined(POINT)
                half3 light_dir = normalize(_WorldSpaceLightPos0.xyz - i.pos_world);
                half distance = length(_WorldSpaceLightPos0.xyz - i.pos_world);
                half range = 1.0 / unity_WorldToLight[0][0];
                half attenuation = saturate((range - distance)/range);
                #endif
                //float3 light_dir = normalize(_WorldSpaceLightPos0.xyz);
                float3 NdotL = dot(normal_dir,light_dir);
                float diffuse_color = max(0.0,NdotL)*_LightColor0.xyz*base_color.xyz*attenuation;

                float3 reflect_dir = reflect(-light_dir,normal_dir);
                float RdotV= dot(reflect_dir,view_dir);
                float3 spec_color = pow(max(0.0,RdotV),_Shininess)*_LightColor0.xyz*_SpecIntensity*spec_mask*attenuation; 
                //fixed4 col = tex2D(_MainTex, i.uv);
                float3 final_color = (diffuse_color+spec_color)*ao_color;

                return float4(final_color,1.0);
            }
            ENDCG
        }
        // Pass
        // {
        //     Tags{"LightMode"="ForwardAdd"}
        //     Blend One One
        //     CGPROGRAM
        //     #pragma vertex vert
        //     #pragma fragment frag
        //     #pragma multi_compile_fwdadd
        //     #include "AutoLight.cginc"
        //     #include "UnityCG.cginc"

        //     struct appdata
        //     {
        //         float4 vertex : POSITION;
        //         float2 texcoord : TEXCOORD0;
        //         float3 normal : NORMAL;
        //     };

        //     struct v2f
        //     {
        //         float2 uv : TEXCOORD0;
        //         float4 pos : SV_POSITION;
        //         float3 normal_dir :TEXCOORD1;
        //         float3 pos_world:TEXCOORD2;
        //     };

        //     sampler2D _MainTex;
        //     float4 _MainTex_ST;
        //     float4 _LightColor0;
        //     float _Shininess;
        //     float4 _AmbientColor;
        //     float _SpecIntensity;
        //     sampler2D _AOMap;
        //     sampler2D _SpecMask;
        //     v2f vert (appdata v)
        //     {
        //         v2f o;
        //         o.pos = UnityObjectToClipPos(v.vertex);
        //         o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
        //         o.normal_dir = normalize(mul(float4(v.normal,0.0),unity_WorldToObject).xyz);
        //         o.pos_world = mul(unity_ObjectToWorld,v.vertex).xyz;

        //         return o;
        //     }

        //     fixed4 frag (v2f i) : SV_Target
        //     {

        //         half4 base_color = tex2D(_MainTex,i.uv);
        //         half4 ao_color = tex2D(_AOMap,i.uv);
        //         half4 spec_mask = tex2D(_SpecMask,i.uv);

        //         float3 normal_dir = normalize(i.normal_dir);
        //         float3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);

        //         #if defined (DIRECTIONAL)
        //         float3 light_dir = normalize(_WorldSpaceLightPos0.xyz);      
        //         half attenuation = 1.0;         
        //         #elif defined (POINT)
        //         float3 light_dir = normalize(_WorldSpaceLightPos0.xyz - i.pos_world);
        //         half distance = length(_WorldSpaceLightPos0.xyz - i.pos_world);
        //         half range = 1.0/unity_WorldToLight[0][0];
        //         float attenuation = saturate((range - distance)/range);
        //         #endif

        //         float3 NdotL = dot(normal_dir,light_dir);
        //         float diffuse_color = max(0.0,NdotL)*_LightColor0.xyz*base_color.xyz*attenuation;

        //         float3 reflect_dir = reflect(-light_dir,normal_dir);
        //         float RdotV= dot(reflect_dir,view_dir);
        //         float3 spec_color = pow(max(0.0,RdotV),_Shininess)*_LightColor0.xyz*_SpecIntensity*spec_mask.rgb*attenuation; 
        //         //fixed4 col = tex2D(_MainTex, i.uv);
        //         float3 final_color = (diffuse_color+spec_color+_AmbientColor.xyz)*ao_color.rgb;

        //         return float4(final_color,1.0);
        //     }
        //     ENDCG
        // }

    }
}
