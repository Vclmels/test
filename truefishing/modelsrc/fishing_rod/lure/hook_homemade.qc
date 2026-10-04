$modelname "fishing/hook_homemade.mdl"
$cdmaterials "models/fishing/"
$body "body" "hook_homemade_reference.smd"
$sequence "idle" "hook_homemade_reference.smd" fps 30
$collisionmodel "hook_homemade_physics.smd"
{
	$mass 0.5
	$inertia 1
	$damping 0
	$rotdamping 0
}
$surfaceprop "metal"
$attachment "line_attach" "root" 0 0 0
