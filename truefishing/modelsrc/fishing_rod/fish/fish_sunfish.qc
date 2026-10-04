$modelname "fishing/fish_sunfish.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_sunfish_reference.smd"
$sequence "idle" "fish_sunfish_reference.smd" fps 30
$collisionmodel "fish_sunfish_physics.smd"
{
    $mass 28.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 17.11 0.00 0.00
