// Precaches an array of sounds
void PrecacheSounds( const array<string> pSound )
{
	for( uint i = 0; i < pSound.length(); i++ )
	{
		g_SoundSystem.PrecacheSound( pSound[i] );
		g_Game.PrecacheGeneric( "sound/" + pSound[i] );
		//g_Game.AlertMessage( at_console, "Precached: sound/" + pSound[i] + "\n" );
	}
}