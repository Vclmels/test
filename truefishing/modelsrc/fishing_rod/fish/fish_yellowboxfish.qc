$modelname "fishing/fish_yellowboxfish.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_yellowboxfish_reference.smd"
$sequence "idle" "fish_yellowboxfish_reference.smd" fps 30
$collisionmodel "fish_yellowboxfish_physics.smd"
{
    $mass 2.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 11.85 0.00 0.00
