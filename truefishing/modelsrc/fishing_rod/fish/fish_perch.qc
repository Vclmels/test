$modelname "fishing/fish_perch.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_perch_reference.smd"
$sequence "idle" "fish_perch_reference.smd" fps 30
$collisionmodel "fish_perch_physics.smd"
{
    $mass 2.5
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 15.15 0.00 0.00
