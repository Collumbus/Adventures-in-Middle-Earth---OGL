-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("corruptionsave", modCorruptionSave);
	ActionsManager.registerResultHandler("corruptionsave", onCorruptionSave);
end

function performRoll(draginfo, rActor, sSave, nTargetDC, bSecretRoll, rSource, bRemoveOnMiss, sSaveDesc)
	local rRoll = {};
	rRoll.sType = "save";
	rRoll.aDice = { "d20" };
	local nMod, bADV, bDIS, sAddText = ActorManager2.getSave(rActor, sSave);
	rRoll.nMod = nMod;
	
	rRoll.sDesc = "[SAVE] Corruption";
	if sAddText and sAddText ~= "" then
		rRoll.sDesc = rRoll.sDesc .. " " .. sAddText;
	end
	if bADV then
		rRoll.sDesc = rRoll.sDesc .. " [ADV]";
	end
	if bDIS then
		rRoll.sDesc = rRoll.sDesc .. " [DIS]";
	end
	
	rRoll.bSecret = bSecretRoll;
	
	rRoll.nTarget = nTargetDC;
	if not nTargetDC then
		nTargetDC = 15;
	end

	if bRemoveOnMiss then
		rRoll.bRemoveOnMiss = "true";
	end
	if sSaveDesc then
		rRoll.sSaveDesc = sSaveDesc;
	end
	if rSource then
		rRoll.sSource = ActorManager.getCTNodeName(rSource);
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modCorruptionSave(rSource, rTarget, rRoll)
	local bAutoFail = false;

	local sSave = string.match(rRoll.sDesc, "%[SAVE%] (%w+)");
	if sSave then
		sSave = sSave:lower();
	end

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

	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;
	
	local nCover = 0;
	if sSave == "dexterity" then
		if rRoll.sSaveDesc then
			nCover = tonumber(rRoll.sSaveDesc:match("%[COVER %-(%d)%]")) or 0;
		else
			if ModifierStack.getModifierKey("DEF_SCOVER") then
				nCover = 5;
			elseif ModifierStack.getModifierKey("DEF_COVER") then
				nCover = 2;
			end
		end
	end
	
	if rSource then
		local bEffects = false;

		-- Build filter
		local aSaveFilter = {};
		if sSave then
			table.insert(aSaveFilter, sSave);
		end

		-- Get effect modifiers
		local rSaveSource = nil;
		if rRoll.sSource then
			rSaveSource = ActorManager.getActor("ct", rRoll.sSource);
		end
		local aAddDice, nAddMod, nEffectCount = EffectManager.getEffectsBonus(rSource, {"SAVE"}, false, aSaveFilter, rSaveSource);
		if nEffectCount > 0 then
			bEffects = true;
		end
		
		-- Get condition modifiers
		if EffectManager.hasEffect(rSource, "ADVSAV", rTarget) then
			bADV = true;
			bEffects = true;
		elseif #(EffectManager.getEffectsByType(rSource, "ADVSAV", aSaveFilter, rTarget)) > 0 then
			bADV = true;
			bEffects = true;
		end
		if EffectManager.hasEffect(rSource, "DISSAV", rTarget) then
			bDIS = true;
			bEffects = true;
		elseif #(EffectManager.getEffectsByType(rSource, "DISSAV", aSaveFilter, rTarget)) > 0 then
			bDIS = true;
			bEffects = true;
		end
		if sSave == "dexterity" then
			if EffectManager.hasEffectCondition(rSource, "Restrained") then
				bDIS = true;
				bEffects = true;
			end
			if nCover < 5 then
				if EffectManager.hasEffect(rSource, "SCOVER", rTarget) then
					nCover = 5;
					bEffects = true;
				elseif nCover < 2 then
					if EffectManager.hasEffect(rSource, "COVER", rTarget) then
						nCover = 2;
						bEffects = true;
					end
				end
			end
		end
		if StringManager.contains({ "strength", "dexterity" }, sSave) then
			if EffectManager.hasEffectCondition(rSource, "Paralyzed") then
				bAutoFail = true;
				bEffects = true;
			end
			if EffectManager.hasEffectCondition(rSource, "Stunned") then
				bAutoFail = true;
				bEffects = true;
			end
			if EffectManager.hasEffectCondition(rSource, "Unconscious") then
				bAutoFail = true;
				bEffects = true;
			end
		end
		if StringManager.contains({ "strength", "dexterity", "constitution" }, sSave) then
			if EffectManager.hasEffectCondition(rSource, "Encumbered") then
				bEffects = true;
				bDIS = true;
			end
		end
		if sSave == "dexterity" and EffectManager.hasEffectCondition(rSource, "Dodge") and 
				not (EffectManager.hasEffectCondition(rSource, "Paralyzed") or
				EffectManager.hasEffectCondition(rSource, "Stunned") or
				EffectManager.hasEffectCondition(rSource, "Unconscious") or
				EffectManager.hasEffectCondition(rSource, "Incapacitated") or
				EffectManager.hasEffectCondition(rSource, "Grappled") or
				EffectManager.hasEffectCondition(rSource, "Restrained")) then
			bEffects = true;
			bADV = true;
		end

		-- Get ability modifiers
		local nBonusStat, nBonusEffects = ActorManager2.getAbilityEffectsBonus(rSource, sSave);
		if nBonusEffects > 0 then
			bEffects = true;
			nAddMod = nAddMod + nBonusStat;
		end
		
		-- Get exhaustion modifiers
		local nExhaustMod, nExhaustCount = EffectManager.getEffectsBonus(rSource, {"EXHAUSTION"}, true);
		if nExhaustCount > 0 then
			bEffects = true;
			if nExhaustMod >= 3 then
				bDIS = true;
			end
		end
		
		-- If effects apply, then add note
		if bEffects then
			for _, vDie in ipairs(aAddDice) do
				if vDie:sub(1,1) == "-" then
					table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
				else
					table.insert(rRoll.aDice, "p" .. vDie:sub(2));
				end
			end
			rRoll.nMod = rRoll.nMod + nAddMod;
			
			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			if sMod ~= "" then
				sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
			else
				sEffects = "[" .. Interface.getString("effects_tag") .. "]";
			end
			rRoll.sDesc = rRoll.sDesc .. " " .. sEffects;
		end
	end
	
	if nCover > 0 then
		rRoll.nMod = rRoll.nMod + nCover;
		rRoll.sDesc = rRoll.sDesc .. string.format(" [COVER +%d]", nCover);
	end
	
	ActionsManager2.encodeDesktopMods(rRoll);
	ActionsManager2.encodeAdvantage(rRoll, bADV, bDIS);
	
	if bAutoFail then
		rRoll.sDesc = rRoll.sDesc .. " [AUTOFAIL]";
	end
end

function onCorruptionSave(rSource, rTarget, rRoll)
	ActionsManager2.decodeAdvantage(rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	local bAutoFail = string.match(rRoll.sDesc, "%[AUTOFAIL%]");
	if not bAutoFail and rRoll.nTarget then
		local nTotal = ActionsManager.total(rRoll);
		local nTargetDC = tonumber(rRoll.nTarget) or 15; -- set to 15 as per Player's Guide
		
		rMessage.text = rMessage.text .. " (vs. DC " .. nTargetDC .. ")";
		if nTotal >= nTargetDC then
			rMessage.text = rMessage.text .. " [SUCCESS]";

			if rSource and rRoll.sSource then
				if rRoll.sSaveDesc then
					local sAttack = string.match(rRoll.sSaveDesc, "%[SAVE VS[^]]*%] ([^[]+)");
					if sAttack then
						local rRollSource = ActorManager.getActor("ct", rRoll.sSource);
						local bHalfMatch = rRoll.sSaveDesc:match("%[HALF ON SAVE%]");
						
						local bHalfDamage = false;
						local bAvoidDamage = false;
						if bHalfMatch then
							bHalfDamage = true;
						end
						if bHalfDamage then
							if EffectManager.hasEffectCondition(rSource, "Avoidance") then
								bAvoidDamage = true;
								rMessage.text = rMessage.text .. " [AVOIDANCE]";
							elseif EffectManager.hasEffectCondition(rSource, "Evasion") then
								local sSave = string.match(rRoll.sDesc, "%[SAVE%] (%w+)");
								if sSave then
									sSave = sSave:lower();
								end
								if sSave == "dexterity" then
									bAvoidDamage = true;
									rMessage.text = rMessage.text .. " [EVASION]";
								end
							end
						end
						
						if bAvoidDamage then
							ActionDamage.setDamageState(rRollSource, rSource, StringManager.trim(sAttack), "none");
							rRoll.bRemoveOnMiss = false;
						elseif bHalfDamage then
							ActionDamage.setDamageState(rRollSource, rSource, StringManager.trim(sAttack), "half");
							rRoll.bRemoveOnMiss = false;
						else
							ActionDamage.setDamageState(rRollSource, rSource, StringManager.trim(sAttack), "");
						end
					end
				end
			
				local bRemoveTarget = false;
				if OptionsManager.isOption("RMMT", "on") then
					bRemoveTarget = true;
				elseif rRoll.bRemoveOnMiss then
					bRemoveTarget = true;
				end
				
				if bRemoveTarget then
					TargetingManager.removeTarget(rRoll.sSource, ActorManager.getCTNodeName(rSource));
				end
			end
		else
			rMessage.text = rMessage.text .. " [FAILURE]";

			if rRoll.sSaveDesc then
				local sAttack = string.match(rRoll.sSaveDesc, "%[SAVE VS[^]]*%] ([^[]+)");
				if sAttack then
					local rRollSource = ActorManager.getActor("ct", rRoll.sSource);
					local bHalfMatch = rRoll.sSaveDesc:match("%[HALF ON SAVE%]");
					
					local bHalfDamage = false;
					if bHalfMatch then
						if EffectManager.hasEffectCondition(rSource, "Avoidance") then
							bHalfDamage = true;
							rMessage.text = rMessage.text .. " [AVOIDANCE]";
						elseif EffectManager.hasEffectCondition(rSource, "Evasion") then
							local sSave = string.match(rRoll.sDesc, "%[SAVE%] (%w+)");
							if sSave then
								sSave = sSave:lower();
							end
							if sSave == "dexterity" then
								bHalfDamage = true;
								rMessage.text = rMessage.text .. " [EVASION]";
							end
						end
					end
					
					if bHalfDamage then
						ActionDamage.setDamageState(rRollSource, rSource, StringManager.trim(sAttack), "half");
					else
						ActionDamage.setDamageState(rRollSource, rSource, StringManager.trim(sAttack), "");
					end
				end
			end
		end
	end

	Comm.deliverChatMessage(rMessage);
end
