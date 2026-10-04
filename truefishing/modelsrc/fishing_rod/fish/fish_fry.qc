$modelname "fishing/fish_fry.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_fry_reference.smd"
$sequence "idle" "fish_fry_reference.smd" fps 30
$collisionmodel "fish_fry_physics.smd"
{
    $mass 0.5
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 2.63 0.00 0.00
