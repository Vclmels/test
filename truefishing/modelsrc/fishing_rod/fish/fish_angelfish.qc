$modelname "fishing/fish_angelfish.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_angelfish_reference.smd"
$sequence "idle" "fish_angelfish_reference.smd" fps 30
$collisionmodel "fish_angelfish_physics.smd"
{
    $mass 1.5
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 11.36 0.00 0.00
