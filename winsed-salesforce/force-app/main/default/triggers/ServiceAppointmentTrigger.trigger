trigger ServiceAppointmentTrigger on ServiceAppointment (after update) {
    TriggerSetting__c settings = TriggerSetting__c.getInstance();
    if(settings.Disable_ServiceAppointment_Trigger__c) {return;}
    TriggerDispatcher.Run(new ServiceAppointmentTriggerHandler());
}