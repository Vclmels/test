$modelname "fishing/fish_stonefish.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_stonefish_reference.smd"
$sequence "idle" "fish_stonefish_reference.smd" fps 30
$collisionmodel "fish_stonefish_physics.smd"
{
    $mass 3.5
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 14.31 0.00 0.00
