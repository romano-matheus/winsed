/**
 * @description       :
 * @author            : Remario Richards
 * @group             :
 * @last modified on  : 03-18-2024
 * @last modified by  : Remario Richards
 **/
@isTest(seeAllData=true)
public with sharing class CaseTest {
  public static Map<String, Id> caseRecordTypes = CaseSelector.getRecordTypeNames(
    'Case'
  );
  public static Map<String, Id> mappedEntitlements = CaseSelector.getEntitlements();
  static void makeData() {
    User admin = createAdminUser();
    List<Account> accounts = new List<Account>();
    System.runAs(admin) {
      Account outsideAccount = createAccount('Outside Parish', 'JMD', false);
      Account chiefOfficeJn = createAccount(
        'JN Bank Chief Office',
        'JMD',
        false
      );
      chiefOfficeJn.Parish__c = 'Kingston';
      accounts.add(outsideAccount);

      insert accounts;
    }
    //create accounts
    //create milestones
    //service appoinments
    //work orders
  }

  /**
   * @description JN Bank Regular within Radius Installation scenario 1
   * @author Remario Richards | 09-20-2023
   **/
  @isTest
  public static void shouldAssignRegularEntitlementsScenario1() {
    Test.startTest();
    makeData();
    List<Account> accounts = [
      SELECT Id, Name, Parish__c
      FROM Account
      WHERE Name = 'JN Bank Chief Office' 
    ];
    Assert.areEqual(1, accounts.size(), 'Only 1 accounts are expected');

    Case insideCase = createRegularCase();
    insideCase.Merchant_Name_ID__c = accounts[0].Id;
    insideCase.AccountId = accounts[0].Id;
    insideCase.Service_Type_list__c = 'Device Installation';
    insert insideCase;
    Map<Id, Account> merchantAccounts = new Map<Id, Account>(accounts);
    CaseDomain.assignAllEntitlementsV2(
      new List<Case>{ insideCase },
      merchantAccounts,
      mappedEntitlements
    );
    Assert.isNotNull(
      insideCase.EntitlementId,
      'JN Bank Regular within Radius Installation entitlement should be assigned'
    );
    Test.stopTest();
  }
  /**
   * @description JN Bank Regular Within Radius Troubleshoot and Training scenario 1
   * @author Remario Richards | 09-20-2023
   **/
  @isTest
  public static void shouldAssignRegularEntitlementsScenario2() {
    Test.startTest();
    makeData();
    List<Account> accounts = [
      SELECT Id, Name, Parish__c
      FROM Account
      WHERE Name = 'JN Bank Chief Office' 
    ];
    Assert.areEqual(1, accounts.size(), 'Only 1 accounts are expected');

    Case insideCase = createRegularCase();
    insideCase.Merchant_Name_ID__c = accounts[0].Id;
    insideCase.AccountId = accounts[0].Id;
    insideCase.Service_Type_list__c = 'Merchant Training';
    insert insideCase;
    Map<Id, Account> merchantAccounts = new Map<Id, Account>(accounts);
    CaseDomain.assignAllEntitlementsV2(
      new List<Case>{ insideCase },
      merchantAccounts,
      mappedEntitlements
    );
    Assert.isNotNull(
      insideCase.EntitlementId,
      'JN Bank Regular Within Radius Troubleshoot and Training should be assigned'
    );
    Test.stopTest();
  }

  /**
   * @description JN Bank Premium Within Radius Troubleshoot and Training
   * @author Remario Richards | 09-22-2023
   **/
  @isTest
  public static void shouldAssignPremiumEntitlementsScenario1() {
    Test.startTest();
    makeData();
    List<Account> accounts = [
      SELECT Id, Name, Parish__c
      FROM Account
      WHERE Name = 'JN Bank Chief Office' 
    ];
    Assert.areEqual(1, accounts.size(), 'Only 1 accounts are expected');

    Case outsideCase = createPremiumCase();
    outsideCase.Merchant_Name_ID__c = accounts[0].Id;
    outsideCase.AccountId = accounts[0].Id;
    insert outsideCase;
    Map<Id, Account> merchantAccounts = new Map<Id, Account>(accounts);
    CaseDomain.assignAllEntitlementsV2(
      new List<Case>{ outsideCase },
      merchantAccounts,
      mappedEntitlements
    );
    Assert.isNotNull(
      outsideCase.EntitlementId,
      'JN Bank Premium Within Radius Troubleshoot and Training should be assigned'
    );
    Test.stopTest();
  }
  /**
   * @description process paused cases
   * @author Remario Richards | 10-05-2023
   **/
  @isTest
  public static void shouldProcessAutomaticSLAPauseScenarios() {
    makeData();
    Case outsideCase = createPremiumCase();
    outsideCase.Sub_Status_FS__c = 'Awaiting Client Response';
    outsideCase.IsStopped = false;
    CaseDomain.processAutomaticSLAPauseScenarios(new List<Case>{ outsideCase });
    Assert.areEqual(
      'Awaiting Client Response',
      outsideCase.SLA_Pause_Reason_list__c,
      'Expected client response for pause reason'
    );
  }
  /**
   * @description test unstopped and stopped cases
   * @author Remario Richards | 10-06-2023
   **/
  @isTest
  public static void shouldProcessUnStoppedCases() {
    makeData();
    Case outsideCase = createPremiumCase();
    outsideCase.Sub_Status_FS__c = 'Awaiting Client Response';
    outsideCase.IsStopped = false;
    insert outsideCase;
    outsideCase.IsStopped = true;
    outsideCase.Accumulated_Paused_Time__c = '1:2'; // 1 hour 2 minutes
    outsideCase.Sub_Status_FS__c = 'Received Device/Parts';
    update outsideCase;
    Assert.areNotEqual(
      null,
      outsideCase.Id,
      'Expected the case to be updated successfully'
    );
  }
  /**
   * @description should premium milestone completion criteria
   * @author Remario Richards | 10-06-2023
   **/
  @isTest
  public static void shouldRegularAndPremiumMilestoneCompletionCriteria_Scenarios() {
    makeData();
    Case outsideCase = createPremiumCase();
    outsideCase.Sub_Status_FS__c = 'Awaiting Client Response';
    outsideCase.IsStopped = false;
    insert outsideCase;
    //scenario 1
    outsideCase.Status = 'Acknowledged';
    outsideCase.Work_Order_ID__c = null;
    outsideCase.Submitted_to_Programming__c = true;
    update outsideCase;
    //scenario 2
    outsideCase.Transferred_to_Senior_POS_Logistics__c = true;
    update outsideCase;
    //scenario 3
    outsideCase.Transferred_to_Lead_Contractor_MSO__c = true;
    update outsideCase;
    //scenario 4
    outsideCase.Service_Appointment_Created__c = true;
    update outsideCase;
    //scenario 5
    outsideCase.Status = 'Closed';
    update outsideCase;
    Assert.areNotEqual(
      null,
      outsideCase.Id,
      'Expected the case to be updated successfully'
    );
  }
  public static Case createRegularCase() {
    Case record = new Case(RecordTypeId = caseRecordTypes.get('POS'));
    record.Accumulated_Paused_Time__c = null;
    record.Merchant_Name_ID__c = [
      SELECT Id
      FROM Account
      WHERE Name = 'JN Bank Chief Office' 
      LIMIT 1
    ]
    .Id;
    record.Status = 'New';
    record.Priority = 'Medium';
    record.SLA_Expected_Time__c = 'Regular Service';
    record.Service_Type_list__c = 'Device Collection';
    record.AccountId = [
      SELECT Id
      FROM Account
      WHERE Name = 'JN Bank Chief Office' 
      LIMIT 1
    ]
    .Id;
    return record;
  }
  public static Case createPremiumCase() {
    Case record = new Case(RecordTypeId = caseRecordTypes.get('POS'));
    record.Accumulated_Paused_Time__c = null;
    record.Merchant_Name_ID__c = [
      SELECT Id
      FROM Account
      WHERE Name = 'JN Bank Chief Office' 
      LIMIT 1
    ]
    .Id;
    record.Status = 'New';
    record.Priority = 'Medium';
    record.SLA_Expected_Time__c = 'Premium Service';
    record.Service_Type_list__c = 'Troubleshooting Terminal Issue';
    record.AccountId = [
      SELECT Id
      FROM Account
      WHERE Name = 'JN Bank Chief Office' 
      LIMIT 1
    ]
    .Id;
    return record;
  }
  public static Account createAccount(
    String accName,
    String currencyCode,
    Boolean isInsert
  ) {
    Account account = new Account(
      Name = accName,
      CurrencyIsoCode = currencyCode,
      Parish__c = 'St. Mary',
      Country__c = 'Jamaica'
    );
    if (isInsert) {
      insert account;
    }
    return account;
  }
  public static User createAdminUser() {
    Profile profile1 = [
      SELECT Id
      FROM Profile
      WHERE name = 'System Administrator'
    ];
    User record = new User(
      ProfileId = profile1.Id,
      Username = System.now().millisecond() + 'test2@mcs.com',
      Alias = 'batman',
      Email = 'admin.tester@mcs.com',
      EmailEncodingKey = 'UTF-8',
      Firstname = 'Admin',
      Lastname = 'Tester',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = 'America/Chicago'
    );
    insert record;
    return record;
  }
}