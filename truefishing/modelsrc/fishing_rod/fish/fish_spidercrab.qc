$modelname "fishing/fish_spidercrab.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_spidercrab_reference.smd"
$sequence "idle" "fish_spidercrab_reference.smd" fps 30
$collisionmodel "fish_spidercrab_physics.smd"
{
    $mass 12.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 26.44 0.00 0.00
