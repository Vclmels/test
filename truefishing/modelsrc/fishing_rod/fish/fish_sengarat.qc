$modelname "fishing/fish_sengarat.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_sengarat_reference.smd"
$sequence "idle" "fish_sengarat_reference.smd" fps 30
$collisionmodel "fish_sengarat_physics.smd"
{
    $mass 6.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 17.42 0.00 0.00
