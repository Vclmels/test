$modelname "fishing/fish_lobster.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_lobster_reference.smd"
$sequence "idle" "fish_lobster_reference.smd" fps 30
$collisionmodel "fish_lobster_physics.smd"
{
    $mass 3.5
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 7.36 0.00 0.00
