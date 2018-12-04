-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYSHADOW = "applyshadow";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYSHADOW, handleApplyShadow);

	ActionsManager.registerModHandler("shadow", modRoll);
	ActionsManager.registerResultHandler("shadow", onResolve);
end

function handleApplyShadow(msgOOB)
	local rSource = ActorManager.getActor(msgOOB.sSourceType, msgOOB.sSourceNode);
	local nTotal = tonumber(msgOOB.nTotal) or 0;

	--DB.setValue(ActorManager.getCTNode(rSource), "shadowresult", "number", nTotal);
end

function notifyApplyShadow(rSource, nTotal)
	if not rSource then
		return;
	end
	
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYSHADOW;
	
	msgOOB.nTotal = nTotal;

	local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
	msgOOB.sSourceType = sSourceType;
	msgOOB.sSourceNode = sSourceNode;

	Comm.deliverOOBMessage(msgOOB, "");
end

function getRoll(rActor, bSecretRoll)
	local rRoll = {};
	rRoll.sType = "shadow";
	rRoll.aDice = { "d20" };
	rRoll.nMod = 0;
	
	rRoll.sDesc = "[SHADOW]";
	
	rRoll.bSecret = bSecretRoll;

	-- Determine the modifier and ability to use for this roll
	local sAbility = nil;
	local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if nodeActor then
		if sActorType == "pc" then
			--rRoll.nMod = DB.getValue(nodeActor, "shadow.total", 0);
			sAbility = "";
		--else
		--	rRoll.nMod = DB.getValue(nodeActor, "init", 0);
		end
	end
	if sAbility and sAbility ~= "" and sAbility ~= "dexterity" then
		local sAbilityEffect = DataCommon.ability_ltos[sAbility];
		if sAbilityEffect then
			rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect .. "]";
		end
	end
	
	return rRoll;
end

function performRoll(draginfo, rActor, bSecretRoll)
	local rRoll = getRoll(rActor, bSecretRoll);
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modRoll(rSource, rTarget, rRoll)
	local bADV = false;
	local bDIS = false;
	if rRoll.sDesc:match(" %[ADV%]") then
		bADV = true;
		rRoll.sDesc = rRoll.sDesc:gsub(" %[ADV%]", "");
	end
	if rRoll.sDesc:match(" %[DIS%]") then
		bDIS = true;
		rRoll.sDesc = rRoll.sDesc:gsub(" %[DIS%]", "");
	end

	if rSource then
		-- Determine ability used
		local sActionStat = nil;
		local sModStat = string.match(rRoll.sDesc, "%[MOD:(%w+)%]");
		if sModStat then
			sActionStat = DataCommon.ability_stol[sModStat];
		end
		if not sActionStat then
			sActionStat = "dexterity";
		end
		
		-- Determine general effect modifiers
		--[[local bEffects = false;
		local aAddDice, nAddMod, nEffectCount = EffectManager.getEffectsBonus(rSource, {"INIT"});
		if nEffectCount > 0 then
			bEffects = true;
			for _,vDie in ipairs(aAddDice) do
				if vDie:sub(1,1) == "-" then
					table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
				else
					table.insert(rRoll.aDice, "p" .. vDie:sub(2));
				end
			end
			rRoll.nMod = rRoll.nMod + nAddMod;
		end--]]
		
		-- Get ability effect modifiers
		--[[local nBonusStat, nBonusEffects = ActorManager2.getAbilityEffectsBonus(rSource, sActionStat);
		if nBonusEffects > 0 then
			bEffects = true;
			rRoll.nMod = rRoll.nMod + nBonusStat;
		end--]]
		
		-- Get condition modifiers
		--[[if EffectManager.hasEffectCondition(rSource, "ADVINIT") then
			bADV = true;
			bEffects = true;
		end
		if EffectManager.hasEffectCondition(rSource, "DISINIT") then
			bDIS = true;
			bEffects = true;
		end--]]
		
		-- Since initiative is a Dexterity check, do all those checks as well
		--local aCheckFilter = { "dexterity" };
		
		-- Dexterity check modifiers
		--[[local aDexCheckAddDice, nDexCheckAddMod, nDexCheckEffectCount = EffectManager.getEffectsBonus(rSource, {"CHECK"}, false, aCheckFilter);
		if (nDexCheckEffectCount > 0) then
			bEffects = true;
			for _,vDie in ipairs(aDexCheckAddDice) do
				if vDie:sub(1,1) == "-" then
					table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
				else
					table.insert(rRoll.aDice, "p" .. vDie:sub(2));
				end
				table.insert(aAddDice, vDie)
			end
			rRoll.nMod = rRoll.nMod + nDexCheckAddMod;
			nAddMod = nAddMod + nDexCheckAddMod;
		end--]]
		
		-- Dexterity check conditions
		--[[if EffectManager.hasEffectCondition(rSource, "ADVCHK") then
			bADV = true;
			bEffects = true;
		elseif #(EffectManager.getEffectsByType(rSource, "ADVCHK", aCheckFilter)) > 0 then
			bADV = true;
			bEffects = true;
		end
		if EffectManager.hasEffectCondition(rSource, "DISCHK") then
			bDIS = true;
			bEffects = true;
		elseif #(EffectManager.getEffectsByType(rSource, "DISCHK", aCheckFilter)) > 0 then
			bDIS = true;
			bEffects = true;
		end
		if EffectManager.hasEffectCondition(rSource, "Frightened") then
			bDIS = true;
			bEffects = true;
		end
		if EffectManager.hasEffectCondition(rSource, "Intoxicated") then
			bDIS = true;
			bEffects = true;
		end
		if EffectManager.hasEffectCondition(rSource, "Poisoned") then
			bDIS = true;
			bEffects = true;
		end
		if EffectManager.hasEffectCondition(rSource, "Encumbered") then
			bEffects = true;
			bDIS = true;
		end--]]

		-- Get exhaustion modifiers
		--[[local nExhaustMod, nExhaustCount = EffectManager.getEffectsBonus(rSource, {"EXHAUSTION"}, true);
		if nExhaustCount > 0 then
			bEffects = true;
			if nExhaustMod >= 1 then
				bDIS = true;
			end
		end--]]
		
		-- If effects happened, then add note
		--[[if bEffects then
			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			if sMod ~= "" then
				sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
			else
				sEffects = "[" .. Interface.getString("effects_tag") .. "]";
			end
			rRoll.sDesc = rRoll.sDesc .. " " .. sEffects;
		end--]]
	end
	
	ActionsManager2.encodeAdvantage(rRoll, bADV, bDIS);
end

function onResolve(rSource, rTarget, rRoll)
	ActionsManager2.decodeAdvantage(rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);
	
	local nTotal = ActionsManager.total(rRoll);
	notifyApplyShadow(rSource, nTotal);
end
