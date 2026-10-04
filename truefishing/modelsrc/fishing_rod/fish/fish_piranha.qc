$modelname "fishing/fish_piranha.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_piranha_reference.smd"
$sequence "idle" "fish_piranha_reference.smd" fps 30
$collisionmodel "fish_piranha_physics.smd"
{
    $mass 1.5
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 12.57 0.00 0.00
