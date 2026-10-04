$modelname "fishing/boss_gaddan.mdl"
$cdmaterials "models/fishing/"
$body "body" "boss_gaddan_reference.smd"
$sequence "idle" "boss_gaddan_reference.smd" fps 30
$collisionmodel "boss_gaddan_physics.smd"
{
	$mass 60.0
	$inertia 1
	$damping 0
	$rotdamping 0
}
$surfaceprop "flesh"
