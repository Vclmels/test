$modelname "fishing/hook_quality.mdl"
$cdmaterials "models/fishing/"
$body "body" "hook_quality_reference.smd"
$sequence "idle" "hook_quality_reference.smd" fps 30
$collisionmodel "hook_quality_physics.smd"
{
	$mass 0.5
	$inertia 1
	$damping 0
	$rotdamping 0
}
$surfaceprop "metal"
$attachment "line_attach" "root" 0 0 0
