/**
 * @description       : 
 * @author            : Remario Richards
 * @group             : 
 * @last modified on  : 01-02-2024
 * @last modified by  : Remario Richards
**/
@isTest
public with sharing class DeviceControllerTest {
    @isTest
    static void testGetRelatedAssets() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Asset testAsset = new Asset(
            Name = 'Test Asset',
            AccountId = testAccount.Id
        );
        insert testAsset;

        // Call the method
        List<Id> accountIds = new List<Id>{testAsset.Id};
        List<AssetWrapper> result = DeviceController.getRelatedAssets(accountIds);

        // Assert the result
        System.assertEquals(1, result.size(), 'Expected one AssetWrapper in the result');

        AssetWrapper assetWrapper = result[0];
        System.assertEquals(testAsset.Id, assetWrapper.id, 'Asset Id should match');
        System.assertEquals(testAsset.Name, assetWrapper.name, 'Asset Name should match');

    }
    @isTest
    static void testFindRecords() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Call the method
        String objectName = 'Account';
        String value = 'Test';
        List<sObject> result = DeviceController.findRecords(objectName, value);

        // Assert the result
        System.assertNotEquals(null, result, 'Result should not be null');

        // Since we are querying for Account records, we can assume the result is a list of Account sObjects
        // Adjust this assertion based on the specific object you are querying
        System.assertNotEquals(0, result.size(), 'Expected size is not 0 because test data was inserted');
    }
    @isTest
    static void testGetReturnOrderLineItems() {
        List<String> recordIds = new List<String>{null};
        List<ReturnOrderLineItemWrapper> results = DeviceController.getReturnOrderLineItems(recordIds);
        Assert.areEqual(0,results.size(),'Expected 0 return order line');
        ReturnOrderLineItem record = new ReturnOrderLineItem(Id= null,Work_Order_Id__c = null, Status_list__c = null);
        ReturnOrderLineItemWrapper wrapper = new ReturnOrderLineItemWrapper(record);
        Assert.isNotNull(wrapper, 'wrapper should not be null');
    }
}