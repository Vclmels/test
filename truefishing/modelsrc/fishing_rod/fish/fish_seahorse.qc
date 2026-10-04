$modelname "fishing/fish_seahorse.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_seahorse_reference.smd"
$sequence "idle" "fish_seahorse_reference.smd" fps 30
$collisionmodel "fish_seahorse_physics.smd"
{
    $mass 1.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 18.92 0.00 0.00
