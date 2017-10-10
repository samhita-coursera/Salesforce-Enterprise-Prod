trigger TaskTrigger on Task (after Update) {
	TriggerHandlerClass handler = new TriggerHandlerClass();	
	if(Trigger.isUpdate) {
		if(Trigger.isAfter) {
			handler.OnTaskAfterUpdate(Trigger.new);
		}
	}
}