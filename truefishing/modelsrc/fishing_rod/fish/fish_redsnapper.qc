$modelname "fishing/fish_redsnapper.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_redsnapper_reference.smd"
$sequence "idle" "fish_redsnapper_reference.smd" fps 30
$collisionmodel "fish_redsnapper_physics.smd"
{
    $mass 4.5
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 13.51 0.00 0.00
