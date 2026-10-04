$modelname "fishing/fish_titantriggerfish.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_titantriggerfish_reference.smd"
$sequence "idle" "fish_titantriggerfish_reference.smd" fps 30
$collisionmodel "fish_titantriggerfish_physics.smd"
{
    $mass 6.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 14.16 0.00 0.00
