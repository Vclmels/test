$modelname "fishing/fish_footsnail.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_footsnail_reference.smd"
$sequence "idle" "fish_footsnail_reference.smd" fps 30
$collisionmodel "fish_footsnail_physics.smd"
{
    $mass 1.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 6.46 0.00 0.00
