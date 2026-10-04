$modelname "fishing/fish_goby.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_goby_reference.smd"
$sequence "idle" "fish_goby_reference.smd" fps 30
$collisionmodel "fish_goby_physics.smd"
{
    $mass 0.8
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 9.09 0.00 0.00
