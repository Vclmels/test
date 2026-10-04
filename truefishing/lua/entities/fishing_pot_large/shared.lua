/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
-------------------------------------------------------------*/

ENT.Type 			= "anim"
ENT.Base 			= "base_anim"
ENT.PrintName		= "Big Fishing Pot"
ENT.Author			= "Tomasas"
ENT.Category		= "TrueFishing"
ENT.Spawnable		= true


function ENT:GetSpace()
	local space = 0
	
	for i=1, FISH_HIGHNUMBER do
		if self.FishTable[i] then
			space = space + self.FishTable[i]
		end
	end
	return space
end

/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
-------------------------------------------------------------*/
