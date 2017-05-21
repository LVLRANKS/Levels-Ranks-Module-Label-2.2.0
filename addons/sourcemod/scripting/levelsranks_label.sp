#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <lvl_ranks>

#define PLUGIN_NAME "Levels Ranks"
#define PLUGIN_AUTHOR "RoadSide Romeo"

int	g_iLabelRank[MAXPLAYERS+1],
	g_iLabelFix[MAXPLAYERS+1];

public Plugin myinfo = {name = "[LR] Module - Label", author = PLUGIN_AUTHOR, version = PLUGIN_VERSION}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch(GetEngineVersion())
	{
		case Engine_CSGO, Engine_CSS, Engine_TF2: LogMessage("[%s Label] Запущен успешно", PLUGIN_NAME);
		default: SetFailState("[%s Label] Плагин работает только на CS:GO, CS:S или TF2", PLUGIN_NAME);
	}
}

public void OnPluginStart()
{
	HookEvent("player_death", Event_Label);
	HookEvent("player_team", Event_Label);
	HookEvent("player_spawn", Event_Label);
}

public void OnMapStart()
{
	char sBuffer[256];
	PrecacheModel("models/weapons/v_knife_default_ct.mdl");
	for(int i = 1; i <= 18; i++)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "materials/lvl_sprites/rank_%d.vtf", i); AddFileToDownloadsTable(sBuffer);
		FormatEx(sBuffer, sizeof(sBuffer), "materials/lvl_sprites/rank_%d.vmt", i); AddFileToDownloadsTable(sBuffer);
		PrecacheModel(sBuffer);
	}
}

public void Event_Label(Handle hEvent, char[] sEvName, bool bDontBroadcast)
{
	switch(sEvName[7])
	{
		case 't':
		{
			int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
			if(IsValidClient(iClient)) DeleteSprite(iClient);
		}

		case 's':
		{
			int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
			if(IsValidClient(iClient) && LR_GetClientRank(iClient) > 0) SetSprite(iClient);
		}

		case 'd':
		{
			int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
			if(IsValidClient(iClient)) DeleteSprite(iClient);
		}
	}
}

void SetSprite(int iClient)
{
	DeleteSprite(iClient);

	int iRank = LR_GetClientRank(iClient);
	if(iRank > 0)
	{
		float fOrigin[3]; char sBuffer[256];
		GetClientAbsOrigin(iClient, fOrigin); FormatEx(sBuffer, sizeof(sBuffer), "materials/lvl_sprites/rank_%d.vmt", iRank);

		fOrigin[2] += 80;
		g_iLabelRank[iClient] = CreateEntityByName("env_sprite_oriented");
		DispatchKeyValue(g_iLabelRank[iClient], "classname", "rank_hud");
		DispatchKeyValue(g_iLabelRank[iClient], "model", sBuffer);
		DispatchSpawn(g_iLabelRank[iClient]);
		TeleportEntity(g_iLabelRank[iClient], fOrigin, NULL_VECTOR, NULL_VECTOR);
		SetEntPropEnt(g_iLabelRank[iClient], Prop_Send, "m_hOwnerEntity", iClient);

		fOrigin[2] -= 90;
		g_iLabelFix[iClient] = CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(g_iLabelFix[iClient], "model", "models/weapons/v_knife_default_ct.mdl");
		DispatchSpawn(g_iLabelFix[iClient]);
		SetEntityRenderMode(g_iLabelFix[iClient], RENDER_NONE);
		TeleportEntity(g_iLabelFix[iClient], fOrigin, NULL_VECTOR, NULL_VECTOR);

		SetVariantString("!activator"); AcceptEntityInput(g_iLabelFix[iClient], "SetParent", iClient, g_iLabelFix[iClient], 0);
		SetVariantString("!activator"); AcceptEntityInput(g_iLabelRank[iClient], "SetParent", g_iLabelFix[iClient], g_iLabelRank[iClient], 0);
		SDKHook(g_iLabelRank[iClient], SDKHook_SetTransmit, Hook_Hide);
	}
}

void DeleteSprite(int iClient)
{
	if(g_iLabelRank[iClient] != 0 && IsValidEdict(g_iLabelRank[iClient]))
	{
		AcceptEntityInput(g_iLabelRank[iClient], "Kill");
		//AcceptEntityInput(g_iLabelFix[iClient], "Kill");
	}
	g_iLabelRank[iClient] = 0;
}

public Action Hook_Hide(int entity, int iClient)
{
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(owner != -1)
	{
		if(owner == iClient || GetClientTeam(owner) != GetClientTeam(iClient))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void OnClientDisconnect(int iClient)
{
	if(iClient > 0)
	{
		DeleteSprite(iClient);
	}
}

public void OnPluginEnd()
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient))
		{
			OnClientDisconnect(iClient);	
		}
	}
}