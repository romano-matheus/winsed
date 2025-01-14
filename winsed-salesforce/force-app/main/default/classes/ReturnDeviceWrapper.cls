/**
 * @description       : 
 * @author            : Matheus Romano
 * @group             : 
 * @last modified on  : 11-28-2023
 * @last modified by  : Matheus Romano
**/

public with sharing class ReturnDeviceWrapper {
    @AuraEnabled
    public String id { get; set; }
    @AuraEnabled
    public String workOrderId { get; set; }
    @AuraEnabled
    public String bankName { get; set; }
    @AuraEnabled
    public String merchantName { get; set; }
    @AuraEnabled
    public String merchantAddress { get; set; }
    @AuraEnabled
    public String tid { get; set; }
    @AuraEnabled
    public String model { get; set; }
    @AuraEnabled
    public String serialNumber { get; set; }
    @AuraEnabled
    public Boolean pickedUp { get; set; }
    @AuraEnabled
    public Boolean returned { get; set; }
    @AuraEnabled
    public String serializedProduct { get; set; }
    @AuraEnabled
    public Boolean installed { get; set; }
    @AuraEnabled
    public String notInstalledReason { get; set; }

    public ReturnDeviceWrapper(Terminal_ID__c terminalId){
        this.id = terminalId.Id;
        this.workOrderId = terminalId.Work_Order_Id__c;
        this.bankName = terminalId.Bank_Name_text__c;
        this.merchantName = terminalId.Merchant_Name__r.Name;
        this.merchantAddress = terminalId.Merchant_Location_Address_calc__c;
        this.tid = terminalId.Name;
        this.model = terminalId.Device_Model_Type_ID__r.Name;
        this.serialNumber = terminalId.Serial_Number__c;
        this.serializedProduct = terminalId.POS_Id__c;
        this.installed = terminalId.POS_Id__r.Installed__c;
        this.pickedUp = terminalId.POS_Id__r.Picked_Up__c;
        this.returned = terminalId.POS_Id__r.Returned__c;
        this.notInstalledReason = terminalId.POS_Id__r.Not_Installed_Reason__c;
    }
}