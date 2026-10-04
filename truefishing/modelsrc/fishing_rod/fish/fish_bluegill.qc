$modelname "fishing/fish_bluegill.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_bluegill_reference.smd"
$sequence "idle" "fish_bluegill_reference.smd" fps 30
$collisionmodel "fish_bluegill_physics.smd"
{
    $mass 1.8
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 11.63 0.00 0.00
