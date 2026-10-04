$modelname "fishing/fish_mackerel.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_mackerel_reference.smd"
$sequence "idle" "fish_mackerel_reference.smd" fps 30
$collisionmodel "fish_mackerel_physics.smd"
{
    $mass 3.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 14.23 0.00 0.00
