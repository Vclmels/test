$modelname "fishing/fish_pufferfish.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_pufferfish_reference.smd"
$sequence "idle" "fish_pufferfish_reference.smd" fps 30
$collisionmodel "fish_pufferfish_physics.smd"
{
    $mass 3.5
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 13.01 0.00 0.00
