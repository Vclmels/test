$modelname "fishing/pole.mdl"
$cdmaterials "models/fishing"

// The source asset is authored in metres; Source uses Hammer units.
$scale 30
$origin 0 18 0

$body "body" "FishingRod.smd"
$sequence "idle" "FishingRod.smd" fps 1

$surfaceprop "metal"
$mostlyopaque
$bbox -8 -8 -8 120 8 8
