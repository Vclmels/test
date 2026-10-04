$modelname "fishing/fish_seaurchin.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_seaurchin_reference.smd"
$sequence "idle" "fish_seaurchin_reference.smd" fps 30
$collisionmodel "fish_seaurchin_physics.smd"
{
    $mass 1.2
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 9.62 0.00 0.00
