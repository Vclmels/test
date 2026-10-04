$modelname "truefishing/caja_pescados.mdl"
$cdmaterials "models/truefishing/"
$body "caja" "caja_cuerpo.smd"
$bodygroup "tapa"
{
	studio "tapa_cerrada.smd"
	studio "tapa_abierta.smd"
}
$sequence "idle" "caja_cuerpo.smd" fps 30
$collisionmodel "caja_phy.smd"
{
	$mass 10
	$inertia 1
	$damping 0.1
	$rotdamping 0.1
}
$surfaceprop "wood"
