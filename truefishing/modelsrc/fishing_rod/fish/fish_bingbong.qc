$modelname "fishing/fish_bingbong.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_bingbong_reference.smd"
$sequence "idle" "fish_bingbong_reference.smd" fps 30
$collisionmodel "fish_bingbong_physics.smd"
{
    $mass 5.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 14.86 0.00 0.00
