$modelname "fishing/fish_flyingfish.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_flyingfish_reference.smd"
$sequence "idle" "fish_flyingfish_reference.smd" fps 30
$collisionmodel "fish_flyingfish_physics.smd"
{
    $mass 2.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 14.39 0.00 0.00
