$modelname "fishing/fish_leech.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_leech_reference.smd"
$sequence "idle" "fish_leech_reference.smd" fps 30
$collisionmodel "fish_leech_physics.smd"
{
    $mass 0.5
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 1.53 0.00 0.00
