$modelname "fishing/fish_catfish.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_catfish_reference.smd"
$sequence "idle" "fish_catfish_reference.smd" fps 30
$collisionmodel "fish_catfish_physics.smd"
{
    $mass 6.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 15.91 0.00 0.00
