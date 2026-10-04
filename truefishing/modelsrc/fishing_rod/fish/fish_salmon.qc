$modelname "fishing/fish_salmon.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_salmon_reference.smd"
$sequence "idle" "fish_salmon_reference.smd" fps 30
$collisionmodel "fish_salmon_physics.smd"
{
    $mass 4.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 13.66 0.00 0.00
