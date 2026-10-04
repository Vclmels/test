$modelname "fishing/fish_parrotfish.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_parrotfish_reference.smd"
$sequence "idle" "fish_parrotfish_reference.smd" fps 30
$collisionmodel "fish_parrotfish_physics.smd"
{
    $mass 4.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 16.68 0.00 0.00
