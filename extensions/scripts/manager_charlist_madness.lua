-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	DB.addHandler("charsheet.*.madness", "onUpdate", onUpdate);
	CharacterListManager.addDecorator("madness", addMadnessWidget);
end

function onUpdate(nodeMadness)
	updateWidgets(nodeMadness.getChild("..").getName());
end

function addMadnessWidget(control, sIdentity)
	local widget = control.addBitmapWidget("charlist_madness");
	widget.setPosition("center", 0, -5);
	widget.setVisible(false);
	widget.setName("madness");

	local textwidget = control.addTextWidget("mini_name", "");
	textwidget.setPosition("center", 0, -5);
	textwidget.setVisible(false);
	textwidget.setName("madnesstext");
	
	updateWidgets(sIdentity);
end

function updateWidgets(sIdentity)
	local ctrlChar = CharacterListManager.getEntry(sIdentity);
	if not ctrlChar then
		return;
	end
	
	local widget = ctrlChar.findWidget("madness");
	local textwidget = ctrlChar.findWidget("madnesstext");
	if not widget or not textwidget then
		return;
	end	
	
	local nMadness = DB.getValue("charsheet." .. sIdentity .. ".madness", 0);
	if nMadness <= 0 then
		widget.setVisible(false);
		textwidget.setVisible(false);
	elseif nMadness == 1 then
		widget.setVisible(true);
		textwidget.setVisible(false);
	else
		widget.setVisible(true);
		textwidget.setVisible(true);
		textwidget.setText(nMadness);
	end
end
