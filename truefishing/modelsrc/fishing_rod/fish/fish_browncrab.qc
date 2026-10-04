$modelname "fishing/fish_browncrab.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_browncrab_reference.smd"
$sequence "idle" "fish_browncrab_reference.smd" fps 30
$collisionmodel "fish_browncrab_physics.smd"
{
    $mass 2.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 10.31 0.00 0.00
