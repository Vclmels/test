$modelname "fishing/boss_piranha.mdl"
$cdmaterials "models/fishing/"
$body "body" "boss_piranha_reference.smd"
$sequence "idle" "boss_piranha_reference.smd" fps 30
$collisionmodel "boss_piranha_physics.smd"
{
	$mass 75.0
	$inertia 1
	$damping 0
	$rotdamping 0
}
$surfaceprop "flesh"
