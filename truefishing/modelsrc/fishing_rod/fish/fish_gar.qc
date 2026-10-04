$modelname "fishing/fish_gar.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_gar_reference.smd"
$sequence "idle" "fish_gar_reference.smd" fps 30
$collisionmodel "fish_gar_physics.smd"
{
    $mass 8.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 16.23 0.00 0.00
