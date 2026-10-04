$modelname "fishing/fish_clam.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_clam_reference.smd"
$sequence "idle" "fish_clam_reference.smd" fps 30
$collisionmodel "fish_clam_physics.smd"
{
    $mass 3.0
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 8.79 0.00 0.00
