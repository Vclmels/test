$modelname "fishing/fish_needlefish.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_needlefish_reference.smd"
$sequence "idle" "fish_needlefish_reference.smd" fps 30
$collisionmodel "fish_needlefish_physics.smd"
{
    $mass 1.8
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 13.82 0.00 0.00
