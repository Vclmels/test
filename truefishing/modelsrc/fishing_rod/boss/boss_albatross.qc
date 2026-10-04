$modelname "fishing/boss_albatross.mdl"
$cdmaterials "models/fishing/"
$body "body" "boss_albatross_reference.smd"
$sequence "idle" "boss_albatross_reference.smd" fps 30
$collisionmodel "boss_albatross_physics.smd"
{
	$mass 45.0
	$inertia 1
	$damping 0
	$rotdamping 0
}
$surfaceprop "flesh"
