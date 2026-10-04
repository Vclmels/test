$modelname "fishing/fish_oarfish.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_oarfish_reference.smd"
$sequence "idle" "fish_oarfish_reference.smd" fps 30
$collisionmodel "fish_oarfish_physics.smd"
{
    $mass 20.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 21.58 0.00 0.00
