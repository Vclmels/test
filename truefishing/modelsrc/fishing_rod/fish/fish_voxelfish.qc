$modelname "fishing/fish_voxelfish.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_voxelfish_reference.smd"
$sequence "idle" "fish_voxelfish_reference.smd" fps 30
$collisionmodel "fish_voxelfish_physics.smd"
{
    $mass 3.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 12.73 0.00 0.00
