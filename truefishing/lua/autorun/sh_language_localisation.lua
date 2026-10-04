/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
-------------------------------------------------------------*/

local Languages = {}

function TrueFishLocal(name, ...)
	return string.format(Languages[TrueFish.LOCALISATION_LANGUAGE][name], ...)
end

function TrueFishLanguages()
	return Languages
end

Languages["English"] =
{
cant_afford = "You can't afford that!",
fish_limit_reached = "You've reached your %s limit!",
fisherman_spots_full = "Can't find an empty spot near the Fisherman!",
bought_gear = "You bought %s!",
sold_fish = "You made $%s for selling your fish!",
no_water_detected = "No water detected under the cage!",
cant_find_water_surface = "Couldn't find the water surface!",
water_surface_shallow = "This is too shallow!",
carry_limit_reached = "You already have %s fishes!",
no_fish_containers_near = "There are no Fish Containers near you!",
fish_containers_full = "All the nearby Fish Containers are full!",
no_fish_bait = "You don't have any fish bait. Use some!",
didnt_catch_anything = "You didn't catch anything.",
money_bag_caught = "You caught a money bag with $%s inside!",
fish_caught = "You caught a %s!",
empty_fish_containers_near = "Can't find any empty containers near you to put fish in!",
hook_caught = "You caught something! Use(E) your hook.",
picked_up_fish_bait = "You now have %s Fish Bait.",
buoy_too_far = "Too far away from the buoy!",

fish_market = "Fish Market",
no_fish_to_sell = "You have no fish\nto sell",
reward_txt = "Reward: $%s",
price_txt = "Price: $%s",
purchase_txt = "Purchase",
fish_sells_for = "Your fish sells for $%s",
sell_all = "Sell all",
fisherman = "Fisherman",

deploy_fish_cage = "Deploy Fish Cage",
collect_fish = "Collect fish",
close_menu = "Close Menu",
untie_fish_cage = "Untie Fish Cage" ,
tie_down_fish_cage = "Tie down Fish Cage",
discard_fish = "Discard %s",
untie_fish_container = "Untie Fish Container",
tie_down_fish_container = "Tie down Fish Container",
empty_container_text = "Empty container",
retrieve_fish_cage = "Retrieve Fish Cage",

fishing_rod_phys_tip = "You can press R(Reload) to adjust the throwing strength of the fishing rod.",
throw_str = "Throw Strength",
throw_desc = "Pick how hard to throw your fishing pole. Higher number means your hook will be thrown farther away.",
fishing_hud = "Fishing",

fish_finder_no_fish = "No Fish",
fish_finder_depth_text = "Depth",
}

Languages["German"] =
{
cant_afford = "You can't afford that!",
fish_limit_reached = "You've reached your %s limit!",
fisherman_spots_full = "Can't find an empty spot near the Fisherman!",
bought_gear = "You bought %s!",
sold_fish = "You made $%s for selling your fish!",
no_water_detected = "No water detected under the cage!",
cant_find_water_surface = "Couldn't find the water surface!",
water_surface_shallow = "This is too shallow!",
carry_limit_reached = "You already have %s fishes!",
no_fish_containers_near = "There are no Fish Containers near you!",
fish_containers_full = "All the nearby Fish Containers are full!",
no_fish_bait = "You don't have any fish bait. Use some!",
didnt_catch_anything = "You didn't catch anything.",
money_bag_caught = "You caught a money bag with $%s inside!",
fish_caught = "You caught a %s!",
empty_fish_containers_near = "Can't find any empty containers near you to put fish in!",
hook_caught = "You caught something! Use(E) your hook.",
picked_up_fish_bait = "You now have %s Fish Bait.",
buoy_too_far = "Too far away from the buoy!",

fish_market = "Fish Market",
no_fish_to_sell = "You have no fish\nto sell",
reward_txt = "Reward: $%s",
price_txt = "Price: $%s",
purchase_txt = "Purchase",
fish_sells_for = "Your fish sells for $%s",
sell_all = "Sell all",
fisherman = "Fisherman",

deploy_fish_cage = "Deploy Fish Cage",
collect_fish = "Collect fish",
close_menu = "Close Menu",
untie_fish_cage = "Untie Fish Cage" ,
tie_down_fish_cage = "Tie down Fish Cage",
discard_fish = "Discard %s",
untie_fish_container = "Untie Fish Container",
tie_down_fish_container = "Tie down Fish Container",
empty_container_text = "Empty container",
retrieve_fish_cage = "Retrieve Fish Cage",

fishing_rod_phys_tip = "You can press R(Reload) to adjust the throwing strength of the fishing rod.",
throw_str = "Throw Strength",
throw_desc = "Pick how hard to throw your fishing pole. Higher number means your hook will be thrown farther away.",
fishing_hud = "Fishing",

fish_finder_no_fish = "No Fish",
fish_finder_depth_text = "Depth",
}

Languages["Thai"] =
{
cant_afford = "คุณไม่สามารถจ่ายได้!",
fish_limit_reached = "คุณถึงขีดจำกัด %s แล้ว!",
fisherman_spots_full = "ไม่พบพื้นที่ว่างใกล้ๆชาวประมง!",
bought_gear = "คุณซื้อ %s!",
sold_fish = "คุณได้ $%s สำหรับการขายปลาของคุณ!",
no_water_detected = "ไม่มีน้ำอยู่ใต้กรง!",
cant_find_water_surface = "ไม่พบพื้นผิวน้ำ!",
water_surface_shallow = "น้ำนี้ตื้นเกินไป!",
carry_limit_reached = "คุณมีปลา %s ตัวแล้ว!",
no_fish_containers_near = "ไม่มีลังปลาอยู่ใกล้คุณ!",
fish_containers_full = "ภาชนะทั้งหมดที่อยู่ในบริเวณใกล้เคียงเต็มแล้ว!",
no_fish_bait = "คุณไม่มีเหยื่อปลาเลย ซื้อมันซิ!",
didnt_catch_anything = "คุณตกอะไรไม่ได้เลย",
money_bag_caught = "คุณตกได้ประเป๋าเงินที่มีเงิน $%s อยู่ข้างใน!",
fish_caught = "คุณตกได้ %s!",
empty_fish_containers_near = "ไม่พบภาชนะที่ว่างเปล่าที่อยู่ใกล้คุณเพื่อใส่ปลา!",
hook_caught = "คุณตกได้บางอย่าง! Use(E) ดึงเบ็ด",
picked_up_fish_bait = "ขณะนี้คุณมีเหยื่อปลา %s ชิ้น",
buoy_too_far = "ไกลจากทุ่นเกินไป!",

fish_market = "ตลาดปลา",
no_fish_to_sell = "คุณไม่มีปลา\nเพื่อขาย",
reward_txt = "เงินรางวัล: $%s",
price_txt = "ราคา: $%s",
purchase_txt = "ซื้อ",
fish_sells_for = "ปลาของคุณขายได้ $%s",
sell_all = "ขายทั้งหมด",
fisherman = "ชาวประมง",

deploy_fish_cage = "ตั้งทุ่นกรงปลา",
collect_fish = "เก็บปลา",
close_menu = "ปิดเมนู",
untie_fish_cage = "แก้กรงปลา" ,
tie_down_fish_cage = "ผูกกรงปลา",
discard_fish = "ทิ้ง %s",
untie_fish_container = "แกะลังปลา",
tie_down_fish_container = "ผูกลังปลา",
empty_container_text = "ภาชนะเปล่า",
retrieve_fish_cage = "กู้กรงปลา",

fishing_rod_phys_tip = "<c=255,0,0>[DARKRP]</c>: คุณสามารถกด R(รีโหลด) เพื่อปรับความแรงของการขว้างเบ็ดได้",
throw_str = "ความแรงการขว้าง",
throw_desc = "เลือกความแรงในการขว้างคับเบ็ดของคุณ ยิงเพิ่มมากยิ่งทำให้เบ็ดของคุณไปไกลขึ้น",
fishing_hud = "กำลังตกปลา",

fish_finder_no_fish = "ไม่มีปลา",
fish_finder_depth_text = "ความลึก",
}

Languages["French"] =  
{  
cant_afford = "Vous ne pouvez pas faire ça!",  
fish_limit_reached = "Vous avez atteint votre limite de %s !",  
fisherman_spots_full = "Impossible de trouver un endroit vide près du pêcheur!",  
bought_gear = "Tu as acheté %s!",  
sold_fish = "Vous avez fait $%s pour avoir vendu votre poisson!",  
no_water_detected = "Aucune eau détectée sous la cage!",  
cant_find_water_surface = "Impossible de trouver la surface de l'eau!",  
water_surface_shallow = "C'est trop peu profond!",  
carry_limit_reached = "Tu as déjà %s poissons!",  
no_fish_containers_near = "Il n'y a pas de conteneurs de poissons près de vous!",  
fish_containers_full = "Tous les conteneurs de poissons à proximité sont pleins!",  
no_fish_bait = "Vous n'avez pas d'appât de poisson!",  
didnt_catch_anything = "Vous n'avez rien attrapé.",  
money_bag_caught = "Vous avez attrapé un sac d'argent avec $%s dedans!",  
fish_caught = "Vous avez attrapé un %s!",  
empty_fish_containers_near = "Impossible de trouver des conteneurs vides près de chez vous pour mettre du poisson!",  
hook_caught = "Vous avez attrapé quelque chose! Utilisez (E) sur votre hammeçon.",  
picked_up_fish_bait = "Vous avez maintenant %s Appât de poisson.",  
buoy_too_far = "Trop loin de la bouée!",  
 
fish_market = "Marché aux poissons",  
no_fish_to_sell = "Vous n'avez pas de\npoisson à vendre",  
reward_txt = "Récompense: $%s",  
price_txt = "Prix: $%s",  
purchase_txt = "Achat",  
fish_sells_for = "Votre poisson se vend pour $%s",  
sell_all = "Tout vendre",  
fisherman = "Pêcheur",  
 
deploy_fish_cage = "Déployer la cage de poisson",  
collect_fish = "Recueillir des poissons",  
close_menu = "Fermer le menu",  
untie_fish_cage = "Détacher la cage à poisson" ,  
tie_down_fish_cage = "Attachez la cage de poisson",  
discard_fish = "Jeter %s",  
untie_fish_container = "Détacher le Conteneur de poisson",  
tie_down_fish_container = "Attacher le Conteneur de poisson",  
empty_container_text = "Conteneur vide",  
retrieve_fish_cage = "Récupérer la cage de poisson",  
 
fishing_rod_phys_tip = "Vous pouvez appuyer sur R(Reload) Pour ajuster la force de lancer de la canne à pêche.",  
throw_str = "Force de jet",  
throw_desc = "Choisissez la difficulté à jeter votre canne à pêche. Un nombre plus élevé signifie que votre hammeçon sera jeté plus loin.",  
fishing_hud = "Pêche",  

fish_finder_no_fish = "Il ñ'y a\npas de poisson",
fish_finder_depth_text = "Profondeur",
}

Languages["Lithuanian"] =
{
cant_afford = "Tu negali to išsimokėti!",
fish_limit_reached = "Jau pasiekiai %s limitą!",
fisherman_spots_full = "Negalima surasti laisvos vietos prie Žvejybininko!",
bought_gear = "Tu nusipirkai %s!",
sold_fish = "Gavai $%s už žuvų pardavimą!",
no_water_detected = "Vanduo nebuvo rastas po tavo žuvų narvu!",
cant_find_water_surface = "Nebuvo galima rasti vandens paviršiaus!",
water_surface_shallow = "Čia yra perdaug nuoseklu!",
carry_limit_reached = "Tu jau turi %s žuvų!",
no_fish_containers_near = "Prie tavęs nėra Žuvų Konteinerio!",
fish_containers_full = "Visi Žuvų Konteineriai, kurie yra prie tavęs, yra pilni!",
no_fish_bait = "Tu neruti Žuvų Masalo. Panaudok Masalą!",
didnt_catch_anything = "Nieko nepagavai.",
money_bag_caught = "Tu pagavai Pinigų Maišą, kuriame buvo $%s!",
fish_caught = "Tu pagavai %s!",
empty_fish_containers_near = "Nebuvo galima rasti tušia Žuvų Konteinerį, kuris būtu šalia tavęs!",
hook_caught = "Tu kažka pagavai! Panaudok(E) savo kablį.",
picked_up_fish_bait = "Tu dabar turi %s Žuvų Masalo.",
buoy_too_far = "Per toli nuo plūduro!",

fish_market = "Žuvų Turgus",
no_fish_to_sell = "Tu neturi jokių žuvų,\nkurias būtu galima parduoti.",
reward_txt = "Supirkimo kaina: $%s",
price_txt = "Kaina: $%s",
purchase_txt = "Pirkti",
fish_sells_for = "Tavo žuvys parsiduota už $%s",
sell_all = "Parduoti viską",
fisherman = "Žvejybininkas",

deploy_fish_cage = "Paleisti Žuvų Narvą",
collect_fish = "Surinkti Žuvis",
close_menu = "Uždaryti Meniu",
untie_fish_cage = "Atrišti Žuvų narvą" ,
tie_down_fish_cage = "Pririšti Žuvų Narvą",
discard_fish = "Išmesti %s",
untie_fish_container = "Atrišti Žuvų Konteinerį",
tie_down_fish_container = "Pririšti Žuvų Konteinerį",
empty_container_text = "Tuščias konteineris",
retrieve_fish_cage = "Pasiimti Žuvų Narvą",

fishing_rod_phys_tip = "Tu gali paspausti Reload(R). Tai leidžia nustatyti metimo stiprumą.",
throw_str = "Metimo Stiprumas",
throw_desc = "Pasirink kaip stipriai mesi kablį. Didesni skaičiai reiškia stipresni metimą.",
fishing_hud = "Žvėjojema",

fish_finder_no_fish = "Nėra žuvų",
fish_finder_depth_text = "Gylis",
}
/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
-------------------------------------------------------------*/