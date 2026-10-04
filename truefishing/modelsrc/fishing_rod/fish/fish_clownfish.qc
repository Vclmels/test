$modelname "fishing/fish_clownfish.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_clownfish_reference.smd"
$sequence "idle" "fish_clownfish_reference.smd" fps 30
$collisionmodel "fish_clownfish_physics.smd"
{
    $mass 1.2
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 6.97 0.00 0.00
