//==============================================================//
// Author: Created by Valve, ported by Sam "Solokiller" VanHeer.
//
// Purpose: Implements CheckTraceHullAttack, from the 
// 			Half-Life SDK code.
//
//==============================================================//

CBaseEntity@ CheckTraceHullAttack( CBaseMonster@ pThis, float flDist, int iDamage, int iDmgType )
{
	TraceResult tr;

	if (pThis.IsPlayer())
		Math.MakeVectors( pThis.pev.angles );
	else
		Math.MakeAimVectors( pThis.pev.angles );

	Vector vecStart = pThis.pev.origin;
	vecStart.z += pThis.pev.size.z * 0.5;
	Vector vecEnd = vecStart + (g_Engine.v_forward * flDist );

	g_Utility.TraceHull( vecStart, vecEnd, dont_ignore_monsters, head_hull, pThis.edict(), tr );
	
	if ( tr.pHit !is null )
	{
		CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

		if ( iDamage > 0 )
		{
			pEntity.TakeDamage( pThis.pev, pThis.pev, iDamage, iDmgType );
		}

		return pEntity;
	}

	return null;
}

CBaseEntity@ CheckTraceAttack( CBaseMonster@ pThis, float flDist, int iDamage, int iDmgType )
{
	TraceResult tr;

	if (pThis.IsPlayer())
		Math.MakeVectors( pThis.pev.angles );
	else
		Math.MakeAimVectors( pThis.pev.angles );

	Vector vecStart = pThis.pev.origin;
	vecStart.z += pThis.pev.size.z * 0.5;
	Vector vecEnd = vecStart + (g_Engine.v_forward * flDist );

	g_Utility.TraceHull( vecStart, vecEnd, dont_ignore_monsters, head_hull, pThis.edict(), tr );
	
	if ( tr.pHit !is null )
	{
		CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

		if ( iDamage > 0 )
		{
			pEntity.TakeDamage( pThis.pev, pThis.pev, iDamage, iDmgType );
			pEntity.TraceAttack( pThis.pev, 5, g_Engine.v_forward, tr, DMG_SLASH );
		}

		return pEntity;
	}

	return null;
}

CBaseEntity@ CheckTraceBleed( CBaseMonster@ pThis, float flDist, int iDamage, int iDmgType )
{
	TraceResult tr;

	if (pThis.IsPlayer())
		Math.MakeVectors( pThis.pev.angles );
	else
		Math.MakeAimVectors( pThis.pev.angles );

	Vector vecStart = pThis.pev.origin;
	vecStart.z += pThis.pev.size.z * 0.5;
	Vector vecEnd = vecStart + (g_Engine.v_forward * flDist );

	g_Utility.TraceHull( vecStart, vecEnd, dont_ignore_monsters, head_hull, pThis.edict(), tr );
	
	if ( tr.pHit !is null )
	{
		CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

		if ( iDamage > 0 )
		{
			pEntity.TakeDamage( pThis.pev, pThis.pev, iDamage, iDmgType );
			pEntity.TraceAttack( pThis.pev, 5, g_Engine.v_forward, tr, DMG_SLASH );
			pEntity.TraceBleed( iDamage, g_Engine.v_forward, tr, iDmgType );
		}

		return pEntity;
	}

	return null;
}