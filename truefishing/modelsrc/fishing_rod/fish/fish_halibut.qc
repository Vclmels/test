$modelname "fishing/fish_halibut.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_halibut_reference.smd"
$sequence "idle" "fish_halibut_reference.smd" fps 30
$collisionmodel "fish_halibut_physics.smd"
{
    $mass 14.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 17.22 0.00 0.00
