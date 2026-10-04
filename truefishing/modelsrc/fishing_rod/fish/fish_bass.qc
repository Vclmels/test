$modelname "fishing/fish_bass.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_bass_reference.smd"
$sequence "idle" "fish_bass_reference.smd" fps 30
$collisionmodel "fish_bass_physics.smd"
{
    $mass 4.5
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 16.61 0.00 0.00
