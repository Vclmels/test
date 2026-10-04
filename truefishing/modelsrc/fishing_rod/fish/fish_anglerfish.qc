$modelname "fishing/fish_anglerfish.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_anglerfish_reference.smd"
$sequence "idle" "fish_anglerfish_reference.smd" fps 30
$collisionmodel "fish_anglerfish_physics.smd"
{
    $mass 6.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 13.41 0.00 0.00
