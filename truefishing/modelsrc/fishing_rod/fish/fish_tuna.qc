$modelname "fishing/fish_tuna.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_tuna_reference.smd"
$sequence "idle" "fish_tuna_reference.smd" fps 30
$collisionmodel "fish_tuna_physics.smd"
{
    $mass 22.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 28.84 0.00 0.00
