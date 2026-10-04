$modelname "fishing/hook_professional.mdl"
$cdmaterials "models/fishing/"
$body "body" "hook_professional_reference.smd"
$sequence "idle" "hook_professional_reference.smd" fps 30
$collisionmodel "hook_professional_physics.smd"
{
	$mass 0.5
	$inertia 1
	$damping 0
	$rotdamping 0
}
$surfaceprop "metal"
$attachment "line_attach" "root" 0 0 0
