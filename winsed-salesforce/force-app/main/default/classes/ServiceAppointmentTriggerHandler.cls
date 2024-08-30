public class ServiceAppointmentTriggerHandler implements ITriggerHandler{
    public void beforeInsert(List<SObject> newItems) {
        List<ServiceAppointment> newServiceAppointment = (List<ServiceAppointment>)newItems;
    }
    public void beforeUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
        Map<Id, ServiceAppointment> oldMap = (Map<Id, ServiceAppointment>)oldItems;
    }
    public void beforeDelete(Map<Id, SObject> oldItems) {}

    public void afterInsert(List<SObject> newItems) {
        List<ServiceAppointment> newServiceAppointment = (List<ServiceAppointment>)newItems;
    }

    public void afterUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
        Map<Id, ServiceAppointment> oldMap = (Map<Id, ServiceAppointment>)oldItems;

        ServiceAppointmentDomain.changeAssignedResource(newItems, oldMap);
    }   

    public void afterDelete(Map<Id, SObject> oldItems) {}

    public void afterUndelete(Map<Id, SObject> oldItems) {}
}