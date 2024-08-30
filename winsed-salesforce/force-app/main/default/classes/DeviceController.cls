/**
 * @description       :
 * @author            : Remario Richards
 * @group             :
 * @last modified on  : 12-24-2023
 * @last modified by  : Remario Richards
 **/
public with sharing class DeviceController {

  private static final List<String> SERVICEAPPOINTMENT_STATUS = new List<String>{'Complete','Cannot Complete','Canceled By Client', 'None'};
  private static final List<String> LOGISTICS_PROFILES = new List<String>{'LOGISTICS Team','Infrastructure Contractor Team'};


  /**
   * @description get related assets via account ids
   * @author Remario Richards | 11-04-2023
   * @param accountIds
   * @return List<AssetWrapper>
   **/
  @AuraEnabled(cacheable=true)
  public static List<AssetWrapper> getRelatedAssets(List<Id> accountIds) {
    List<AssetWrapper> assetWrappers = new List<AssetWrapper>();
    for (Asset record : [
      SELECT
        Id,
        Name,
        Account.Name,
        SerialNumber,
        AssetProvidedBy.Name,
        AssetProvidedById,
        Product2.Name,
        Product2Id,
        Terminal_id__c,
        Terminal_id__r.Name,
        Sim_Card_1__c,
        Sim_Card_1__r.SerialNumber,
        Sim_Card_2__c,
        Sim_Card_2__r.SerialNumber
      FROM Asset
      WHERE Id IN :accountIdS
      WITH SYSTEM_MODE
    ]) {
      AssetWrapper assetWrapper = new AssetWrapper(record);
      assetWrappers.add(assetWrapper);
    }
    return assetWrappers;
  }
  /**
   * @description GET records via name
   * @author Remario Richards | 11-08-2023
   * @param objectName
   * @param value
   * @return List<sObject>
   **/
  @AuraEnabled(cacheable=true)
  public static List<sObject> findRecords(String objectName, String value) {
    String likeValue = '%' + value + '%';
    String query =
      'SELECT Id, Name FROM ' +
      objectName +
      ' WHERE Name LIKE :likeValue LIMIT 10';
    return Database.query(query);
  }

  /**
   * @description gets a list of return order line items
   * @author Remario Richards | 11-21-2023
   * @param recordIds
   * @return List<ReturnOrderLineItemWrapper>
   **/
  @AuraEnabled
  public static List<ReturnOrderLineItemWrapper> getReturnOrderLineItems(
    List<String> recordIds
  ) {
    List<ReturnOrderLineItemWrapper> wrappers = new List<ReturnOrderLineItemWrapper>();
    try {
      for (ReturnOrderLineItem record : [
        SELECT
          Id,
          Work_Order_Id__c,
          AssetId,
          Status_list__c,
          SIM_Card_1_Status_list__c,
          SIM_Card_2_Status_list__c,
          SIM_Card_1_text__c,
          SIM_Card_2_text__c,
          SIM_Card_1_calc__c,
          SIM_Card_2_calc__c,
          Asset.Id,
          Asset.Name,
          Asset.Account.Name,
          Asset.SerialNumber,
          Asset.AssetProvidedBy.Name,
          Asset.AssetProvidedById,
          Asset.Product2.Name,
          Asset.Product2Id,
          Asset.Terminal_id__c,
          Asset.Terminal_id__r.Name,
          Asset.Sim_Card_1__c,
          Asset.Sim_Card_1__r.SerialNumber,
          Asset.Sim_Card_2__c,
          Asset.Sim_Card_2__r.SerialNumber
        FROM ReturnOrderLineItem
        WHERE Work_Order_Id__c IN :recordIds
        WITH SYSTEM_MODE
        LIMIT 10
      ]) {
        wrappers.add(new ReturnOrderLineItemWrapper(record));
      }
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    return wrappers;
  }

  @AuraEnabled(cacheable=true)
  public static Map<String, Object> getTerminalIds() { // NOPMD
    System.debug('## getTerminalIds ');

    Map<String, Object> mapReturn = new Map<String, Object>();
    List<ReturnDeviceWrapper> terminalIdWrappers = new List<ReturnDeviceWrapper>();
    ServiceResource serviceResource = new ServiceResource();
    List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
    List<Terminal_ID__c> terminalIds = new List<Terminal_ID__c>();
    Set<Id> setWorkOrder = new Set<Id>();
    Boolean isLogisticUser = false;

    User user = [SELECT Profile.Name, UserType FROM User WHERE Id = : UserInfo.getUserId() LIMIT 1];
    System.debug('## user = ' + user);
    
    if (LOGISTICS_PROFILES.contains(user.Profile.Name)) {
      isLogisticUser = true;
    } else {
      isLogisticUser = false;
    }
    System.debug('## user = ' + user);

    mapReturn.put('isLogisticUser', isLogisticUser);
    System.debug('## isLogisticUser = ' + isLogisticUser);

    serviceResource = [SELECT Id, Name FROM ServiceResource WHERE RelatedRecordId =: UserInfo.getUserId() LIMIT 1];

    if(serviceResource == null && !isLogisticUser){
      return mapReturn;
    }

    if(isLogisticUser){
      serviceAppointments = [SELECT Id, FSSK__FSK_Assigned_Service_Resource__c, FSSK__FSK_Work_Order__c FROM ServiceAppointment WHERE Status IN: SERVICEAPPOINTMENT_STATUS AND (FSSK__FSK_Work_Order__r.Service_Type_list__c LIKE '%Collection%' OR FSSK__FSK_Work_Order__r.Service_Type_list__c LIKE '%Installation%' OR FSSK__FSK_Work_Order__r.Service_Type_list__c LIKE '%Replacement%')];
    } else {
      serviceAppointments = [SELECT Id, FSSK__FSK_Assigned_Service_Resource__c, FSSK__FSK_Work_Order__c FROM ServiceAppointment WHERE FSSK__FSK_Assigned_Service_Resource__c =: serviceResource.Id AND (Status = 'None' OR Status = 'In Progress')];

    }
    System.debug('## serviceAppointments = ' +  serviceAppointments);

    for(ServiceAppointment serviceAppointment : serviceAppointments) {
      setWorkOrder.add(serviceAppointment.FSSK__FSK_Work_Order__c);
    }
    System.debug('## setWorkOrder = ' + setWorkOrder);

    if(isLogisticUser){
      terminalIds = [SELECT Id, Name, Bank_Name_text__c, Device_Model_Type_ID__c, Device_Model_Type_ID__r.Name, Merchant_Name__c, Merchant_Name__r.Name, MerchantLocation_ID__c, MerchantLocation_ID__r.Name, Merchant_Location_Address_calc__c, POS_Id__c, POS_Id__r.Picked_Up__c, POS_Id__r.Returned__c, POS_Id__r.Installed__c, POS_Id__r.Not_Installed_Reason__c, Serial_Number__c, Work_Order_ID__c FROM Terminal_ID__c WHERE Work_Order_ID__c IN: setWorkOrder AND POS_Id__r.Installed__c = false];
    } else {
      terminalIds = [SELECT Id, Name, Bank_Name_text__c, Device_Model_Type_ID__c, Device_Model_Type_ID__r.Name, Merchant_Name__c, Merchant_Name__r.Name, MerchantLocation_ID__c, MerchantLocation_ID__r.Name, Merchant_Location_Address_calc__c, POS_Id__c, POS_Id__r.Picked_Up__c, POS_Id__r.Returned__c, POS_Id__r.Installed__c, POS_Id__r.Not_Installed_Reason__c, Serial_Number__c, Work_Order_ID__c FROM Terminal_ID__c WHERE Work_Order_ID__c IN: setWorkOrder];
    }
    System.debug('## terminalIds = ' + terminalIds);

    for(Terminal_ID__c terminalId : terminalIds){
      terminalIdWrappers.add(new ReturnDeviceWrapper(terminalId));
    }

    if(!terminalIdWrappers.isEmpty()){
      mapReturn.put('terminalIds', terminalIdWrappers);
    } 

    return mapReturn; // NOPMD
  }

  
  @AuraEnabled
  public static List<ReturnDeviceWrapper> getPickedUpDevices(List<String> recordIds) {
    List<ReturnDeviceWrapper> terminalIdWrappers = new List<ReturnDeviceWrapper>();
    ServiceResource serviceResource = new ServiceResource();
    List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
    List<Terminal_ID__c> terminalIds = new List<Terminal_ID__c>();
    Set<Id> setWorkOrder = new Set<Id>();

    terminalIds = [SELECT Id, Name, Bank_Name_text__c, Device_Model_Type_ID__c, Device_Model_Type_ID__r.Name, Merchant_Name__c, Merchant_Name__r.Name, MerchantLocation_ID__c, MerchantLocation_ID__r.Name, Merchant_Location_Address_calc__c, POS_Id__c, POS_Id__r.Installed__c, POS_Id__r.Not_Installed_Reason__c, Serial_Number__c, Work_Order_ID__c FROM Terminal_ID__c WHERE Work_Order_ID__c IN: recordIds AND POS_Id__r.Picked_Up__c = true];

    System.debug('## terminalIds = ' + terminalIds);
    for(Terminal_ID__c terminalId : terminalIds){
      terminalIdWrappers.add(new ReturnDeviceWrapper(terminalId));
    }
    return terminalIdWrappers;
  }

}