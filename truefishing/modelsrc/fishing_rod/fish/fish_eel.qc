$modelname "fishing/fish_eel.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_eel_reference.smd"
$sequence "idle" "fish_eel_reference.smd" fps 30
$collisionmodel "fish_eel_physics.smd"
{
    $mass 3.5
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 16.36 0.00 0.00
