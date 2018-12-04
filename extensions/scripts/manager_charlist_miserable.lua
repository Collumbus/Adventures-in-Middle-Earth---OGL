-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	DB.addHandler("charsheet.*.miserable", "onUpdate", onUpdate);
	CharacterListManager.addDecorator("miserable", addMiserableWidget);
end

function onUpdate(nodeMiserable)
	updateWidgets(nodeMiserable.getChild("..").getName());
end

function addMiserableWidget(control, sIdentity)
	local widget = control.addBitmapWidget("charlist_miserable");
	widget.setPosition("center", 25, 9);
	widget.setVisible(false);
	widget.setName("miserable");

	local textwidget = control.addTextWidget("mini_name", "");
	textwidget.setPosition("center", 25, 9);
	textwidget.setVisible(false);
	textwidget.setName("miserabletext");
	
	updateWidgets(sIdentity);
end

function updateWidgets(sIdentity)
	local ctrlChar = CharacterListManager.getEntry(sIdentity);
	if not ctrlChar then
		return;
	end
	
	local widget = ctrlChar.findWidget("miserable");
	local textwidget = ctrlChar.findWidget("miserabletext");
	if not widget or not textwidget then
		return;
	end	
	
	local nMiserable = DB.getValue("charsheet." .. sIdentity .. ".miserable", 0);
	if nMiserable <= 0 then
		widget.setVisible(false);
		textwidget.setVisible(false);
	elseif nMiserable == 1 then
		widget.setVisible(true);
		textwidget.setVisible(false);
	else
		widget.setVisible(true);
		textwidget.setVisible(true);
		textwidget.setText(nMiserable);
	end
end
