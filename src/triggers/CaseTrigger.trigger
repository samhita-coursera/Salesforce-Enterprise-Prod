trigger CaseTrigger on Case (after update) {
	TriggerHandlerClass handler = new TriggerHandlerClass();	
	if(Trigger.isUpdate) {
		if(Trigger.isAfter) {
			system.debug('in the  main trigger');
			handler.OnCaseAfterUpdate(Trigger.newMap);
		}
	}
}