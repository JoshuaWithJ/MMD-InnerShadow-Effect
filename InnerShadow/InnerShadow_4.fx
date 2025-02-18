/////////////////////////////////////////////////////////////////////////////////

float4 ClearColor = {0,0,0,1};
float ClearDepth  = 1.0;

float Script : STANDARDSGLOBAL <
	string ScriptOutput = "color";
	string ScriptClass = "scene";
	string ScriptOrder = "postprocess";
> = 0.8;

float2 ViewportSize : VIEWPORTPIXELSIZE;
static float2 ViewportOffset = (float2(0.5,0.5)/ViewportSize);

texture2D DepthBuffer : RENDERDEPTHSTENCILTARGET <
	string Format = "D24S8";
>;


texture2D ScnMap : RENDERCOLORTARGET <
	float2 ViewportRatio = {1.0f, 1.0f};
	bool AntiAlias = true;
	int MipLevels = 1;
	string Format = "A16B16G16R16F";
>;

sampler2D ScnSamp = sampler_state {
	texture = <ScnMap>;
	MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
    MIPFILTER = LINEAR;
    ADDRESSU  = WRAP;
    ADDRESSV  = WRAP;
};

shared texture2D FXRT : RENDERCOLORTARGET <
	bool AntiAlias = true;
	string Format = "A16B16G16R16F";
>;

/////////////////////////////////////////////////////////////////////////////////
texture2D InnerShadowAM_4 : OFFSCREENRENDERTARGET
<
    string Description = "InnerShadow Alpha Mask RT (Uncheck)_4";
	float4 ClearColor = { 0, 0, 0, 0 };
    float ClearDepth = 1.0;
	bool AntiAlias = true;
	int Miplevels = 1;
	string DefaultEffect = "self = hide;"
	    "*= Resources/Alpha - Off.fx;";
>;
sampler2D AlphaMaskSampler = sampler_state {
    texture = <InnerShadowAM_4>;
	MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
    MIPFILTER = LINEAR;
    ADDRESSU  = CLAMP;
    ADDRESSV  = CLAMP;
};
/////////////////////////////////////////////////////////////////////////////////
//Controller 
#define CONTROLLER_NAME	"DropShadow - Controller.pmx"

float3 IS4_Pos : CONTROLOBJECT < string name = "InnerShadow - Controller.pmx"; string item = "IShad_P_4"; >;
float IS4_R : CONTROLOBJECT < string name = "InnerShadow - Controller.pmx"; string item = "IS4_R"; >;
float IS4_G : CONTROLOBJECT < string name = "InnerShadow - Controller.pmx"; string item = "IS4_G"; >;
float IS4_B : CONTROLOBJECT < string name = "InnerShadow - Controller.pmx"; string item = "IS4_B"; >;
////////////////////////////////////////////////////////////////////////////////////////////////

float4	CameraPosition    : POSITION  < string Object = "Camera"; >;

///////////////////////////////////////////////////////////////////////////////////////////////
//Vertex Shader
struct VS_OUTPUT {
	float4 Pos			: POSITION;
	float2 Tex			: TEXCOORD0;
	float2 Tex1			: TEXCOORD1;
    float4 PPos			: TEXCOORD2;
};

VS_OUTPUT SceneVS( float4 Pos : POSITION, float4 Tex : TEXCOORD0, float4 Tex1 : TEXCOORD1,float4 PPos : TEXCOORD2)
{
	VS_OUTPUT Out = (VS_OUTPUT)0; 
	
	Out.Pos = Pos;
	Out.Tex = Tex + ViewportOffset;
	Out.Tex1 = Tex1 + ViewportOffset;
	Out.PPos = Out.Pos;
	
	return Out;
}

/////////////////////////////////////////////////////////////////////////////////
//Pixel Shader

float4 ScenePS(VS_OUTPUT IN) : COLOR0
{   

	//AlphaMask
	float2 RTPos1;
    RTPos1.x				= (IN.PPos.x / IN.PPos.w)*0.5+0.5;
	RTPos1.y				= (-IN.PPos.y / IN.PPos.w)*0.5+0.5;
	
    float4 AlphaMask = tex2D(AlphaMaskSampler, RTPos1 + float2(-1,0) + (float2(1-IS4_Pos.x/10,IS4_Pos.y/10) ) );
    float4 AlphaMaskOG = tex2D(AlphaMaskSampler, RTPos1);
	
    float4 scene = tex2D(ScnSamp,IN.Tex);
    float4 scene1 = tex2D(ScnSamp,IN.Tex);
	
    float4 color;
    color = float4(IS4_R,IS4_G,IS4_B,1);

	color.rgb = lerp(scene, color, 1 - AlphaMask);
	
	scene.rgb = lerp( scene, lerp(scene,color.rgb,AlphaMaskOG), scene.a);

    return scene;
}

/////////////////////////////////////////////////////////////////////////////////
technique RTT <
	string Script = 
		
		"RenderColorTarget0=ScnMap;"
		"RenderDepthStencilTarget=DepthBuffer;"
		"ClearSetColor=ClearColor;"
		"ClearSetDepth=ClearDepth;"
		"Clear=Color;"
		"Clear=Depth;"
		"ScriptExternal=Color;"
		
		"RenderColorTarget0=;"
		"RenderDepthStencilTarget=;"
		"ClearSetColor=ClearColor;"
		"ClearSetDepth=ClearDepth;"
		"Clear=Color;"
		"Clear=Depth;"
		"Pass=RT;"
		;
	
> {
	pass RT < string Script= "Draw=Buffer;"; > {
		AlphaBlendEnable = false; AlphaTestEnable = false;
		ZEnable = false; ZWriteEnable = false;
		VertexShader = compile vs_3_0 SceneVS();
        PixelShader = compile ps_3_0 ScenePS();
	}
}
/////////////////////////////////////////////////////////////////////////////////
