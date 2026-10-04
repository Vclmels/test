$modelname "fishing/fish_shrimp.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_shrimp_reference.smd"
$sequence "idle" "fish_shrimp_reference.smd" fps 30
$collisionmodel "fish_shrimp_physics.smd"
{
    $mass 0.5
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 7.15 0.00 0.00
