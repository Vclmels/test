$modelname "fishing/fish_blobfish.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_blobfish_reference.smd"
$sequence "idle" "fish_blobfish_reference.smd" fps 30
$collisionmodel "fish_blobfish_physics.smd"
{
    $mass 4.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 14.73 0.00 0.00
