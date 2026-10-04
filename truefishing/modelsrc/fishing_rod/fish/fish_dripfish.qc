$modelname "fishing/fish_dripfish.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_dripfish_reference.smd"
$sequence "idle" "fish_dripfish_reference.smd" fps 30
$collisionmodel "fish_dripfish_physics.smd"
{
    $mass 3.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 15.04 0.00 0.00
