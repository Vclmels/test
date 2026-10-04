$modelname "fishing/fish_pike.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_pike_reference.smd"
$sequence "idle" "fish_pike_reference.smd" fps 30
$collisionmodel "fish_pike_physics.smd"
{
    $mass 5.5
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 16.79 0.00 0.00
