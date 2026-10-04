$modelname "fishing/v_fishing_rod_cast.mdl"
$cdmaterials "models/fishing/"
$body "cast" "cast_reference.smd"
$sequence "idle" "idle.smd" fps 30 loop activity ACT_VM_IDLE 1
$sequence "cast" "cast.smd" fps 30 activity ACT_VM_PRIMARYATTACK 1
$sequence "reel_in_fish" "reel_in_fish.smd" fps 18 loop
$sequence "reel_ready" "reel_ready.smd" fps 18
$sequence "reel_hold" "reel_hold.smd" fps 18 loop
$sequence "cast_ready" "cast_ready.smd" fps 30
$sequence "cast_ready_hold" "cast_ready_hold.smd" fps 30 loop
$attachment "line_tip" "cast_rod_tip" 0.00 11.11 -0.52
$surfaceprop "metal"
$mostlyopaque
