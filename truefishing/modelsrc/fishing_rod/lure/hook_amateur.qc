$modelname "fishing/hook_amateur.mdl"
$cdmaterials "models/fishing/"
$body "body" "hook_amateur_reference.smd"
$sequence "idle" "hook_amateur_reference.smd" fps 30
$collisionmodel "hook_amateur_physics.smd"
{
	$mass 0.5
	$inertia 1
	$damping 0
	$rotdamping 0
}
$surfaceprop "metal"
$attachment "line_attach" "root" 0 0 0
