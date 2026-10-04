$modelname "fishing/fish_rockcrab.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_rockcrab_reference.smd"
$sequence "idle" "fish_rockcrab_reference.smd" fps 30
$collisionmodel "fish_rockcrab_physics.smd"
{
    $mass 2.5
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 10.31 0.00 0.00
