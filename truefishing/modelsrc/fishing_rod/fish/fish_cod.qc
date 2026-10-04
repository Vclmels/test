$modelname "fishing/fish_cod.mdl"
$cdmaterials "models/fishing/"
$body "body" "fish_cod_reference.smd"
$sequence "idle" "fish_cod_reference.smd" fps 30
$collisionmodel "fish_cod_physics.smd"
{
    $mass 4.5
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}
$surfaceprop "flesh"
$attachment "mouth" "root" 13.86 0.00 0.00
