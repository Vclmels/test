$modelname "fishing/fish_tigerfish.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_tigerfish_reference.smd"
$sequence "idle" "fish_tigerfish_reference.smd" fps 30
$collisionmodel "fish_tigerfish_physics.smd"
{
    $mass 9.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 17.17 0.00 0.00
