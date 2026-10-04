/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
-------------------------------------------------------------*/

ENT.Type 			= "anim"
ENT.Base 			= "base_anim"
ENT.PrintName		= "Fish Container"
ENT.Author			= "Tomasas"
ENT.Category		= "TrueFishing"
ENT.Spawnable		= true

-- Solo se puede agarrar con la Gravity Gun (la PhysGun no lo levanta)
function ENT:PhysgunPickup(ply)
	return false
end

function ENT:GetSpace()
	local space = 0
	
	for i=1, FISH_HIGHNUMBER do
		if self.Fishes[i] then
			space = space + self.Fishes[i]
		end
	end
	return space
end
/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
-------------------------------------------------------------*/
