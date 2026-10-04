$modelname "fishing/fish_bowlfish.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_bowlfish_reference.smd"
$sequence "idle" "fish_bowlfish_reference.smd" fps 30
$collisionmodel "fish_bowlfish_physics.smd"
{
    $mass 1.2
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 11.32 0.00 0.00
