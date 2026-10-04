$modelname "fishing/fish_superdwarffish.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_superdwarffish_reference.smd"
$sequence "idle" "fish_superdwarffish_reference.smd" fps 30
$collisionmodel "fish_superdwarffish_physics.smd"
{
    $mass 0.4
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 5.91 0.00 0.00
