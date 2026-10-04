$modelname "fishing/fish_blueshark.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_blueshark_reference.smd"
$sequence "idle" "fish_blueshark_reference.smd" fps 30
$collisionmodel "fish_blueshark_physics.smd"
{
    $mass 35.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 28.93 0.00 0.00
