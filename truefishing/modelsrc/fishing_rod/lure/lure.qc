$modelname "fishing/hook.mdl"
$cdmaterials "models/fishing/"
$body "body" "lure_reference.smd"
$sequence "idle" "lure_reference.smd" fps 30
$collisionmodel "lure_physics.smd"
{
	$mass 0.5
	$inertia 1
	$damping 0
	$rotdamping 0
}
$surfaceprop "metal"
$attachment "line_attach" "root" 0 0 0
