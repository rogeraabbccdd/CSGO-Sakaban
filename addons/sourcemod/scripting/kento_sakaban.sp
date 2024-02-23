#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

public Plugin myinfo =
{
	name = "[CS:GO] Sakaban",
	author = "Kento",
	version = "1.0",
	description = "",
	url = "http://steamcommunity.com/id/kentomatoryoshika/"
};

public void OnPluginStart()
{
	AddNormalSoundHook(Event_SoundPlayed);

	HookEvent("round_start", Event_RoundStart);
}

public void OnMapStart()
{
	AddFileToDownloadsTable("materials/models/dransvitry/fimsh/fimsh.vmt");
	AddFileToDownloadsTable("materials/models/dransvitry/fimsh/fishtexture.vtf");

	AddFileToDownloadsTable("models/dransvitry/fimsh/fimsh.mdl");
	AddFileToDownloadsTable("models/dransvitry/fimsh/fimsh.vvd");
	AddFileToDownloadsTable("models/dransvitry/fimsh/fimsh.dx90.vtx");

	PrecacheModel("models/dransvitry/fimsh/fimsh.mdl", true);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "chicken"))
	{
		// Not working, stucks in floor.
		// SetEntityModel(c4, "models/dransvitry/fimsh/fimsh.mdl");
		SDKHook(entity, SDKHook_SpawnPost, OnChickenSpawn);
	}
}

public void OnChickenSpawn(int entity)
{
	if(IsValidEntity(entity)) {
		CreateTimer(0.1, Timer_OnChickenCreated, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_OnChickenCreated(Handle timer, any entity)
{
	int chicken = EntRefToEntIndex(entity);
	if (chicken > 0 && IsValidEntity(chicken))
	{
		// Get chichen pos and angle
		float pos[3], angle[3];
		GetEntPropVector(chicken, Prop_Send, "m_vecOrigin", pos);
		GetEntPropVector(chicken, Prop_Send, "m_angRotation", angle);

		// No damage to chicken
		SetEntProp(chicken, Prop_Data, "m_takedamage", 0);
		SetEntProp(chicken, Prop_Send, "m_fEffects", 0);

		// Set chicken render mode
		SetEntityRenderMode(chicken, RENDER_NONE);

		// Create fish and attach to chicken
		int fish = CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(fish, "model", "models/dransvitry/fimsh/fimsh.mdl");
		DispatchKeyValue(fish, "spawnflags", "256");
		DispatchKeyValue(fish, "solid", "0");
		SetEntPropEnt(fish, Prop_Send, "m_hOwnerEntity", chicken);
		SetEntPropFloat(fish, Prop_Send, "m_flModelScale", 5.0);
		SetEntProp(fish, Prop_Data, "m_CollisionGroup", 0);
		DispatchSpawn(fish);
		AcceptEntityInput(fish, "TurnOn", fish, fish, 0);
		pos[2] += 50.0;
		TeleportEntity(fish, pos, angle, NULL_VECTOR);
		SetVariantString("!activator");
		AcceptEntityInput(fish, "SetParent", chicken, fish, 0);
		AcceptEntityInput(fish, "SetParentAttachmentMaintainOffset", fish, fish, 0);
	}
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// Chicken does not reset on round start, but props does.
	// So we have to loop through all chickens and attach models.
	// https://developer.valvesoftware.com/wiki/S_PreserveEnts#Counter-Strike:_Global_Offensive
	int entity = -1;
	while((entity = FindEntityByClassname(entity, "chicken")) != -1)
	{
		CreateTimer(0.1, Timer_OnChickenCreated, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Event_SoundPlayed(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	// Stop chicken sound
	if(StrContains(sample, "chicken") != -1)
	{
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

