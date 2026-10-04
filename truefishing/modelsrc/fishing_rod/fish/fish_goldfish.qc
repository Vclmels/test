$modelname "fishing/fish_goldfish.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_goldfish_reference.smd"
$sequence "idle" "fish_goldfish_reference.smd" fps 30
$collisionmodel "fish_goldfish_physics.smd"
{
    $mass 1.2
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 7.31 0.00 0.00
