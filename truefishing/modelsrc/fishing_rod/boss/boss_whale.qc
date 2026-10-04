$modelname "fishing/boss_whale.mdl"
$cdmaterials "models/fishing/"
$body "body" "boss_whale_reference.smd"
$sequence "idle" "boss_whale_reference.smd" fps 30
$collisionmodel "boss_whale_physics.smd"
{
	$mass 300.0
	$inertia 1
	$damping 0
	$rotdamping 0
}
$surfaceprop "flesh"
