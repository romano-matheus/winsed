/**
 * @description       :
 * @author            : Remario Richards
 * @group             :
 * @last modified on  : 12-20-2023
 * @last modified by  : Remario Richards
 **/
public with sharing class EntitlementSettingWrapper {
  public Map<String, List<Record>> mappedSettings = new Map<String, List<Record>>();
  /**
   * @description primary constructor
   * @author Remario Richards | 12-02-2023
   **/
  public EntitlementSettingWrapper() {
    for (
      Entitlement_Setting__mdt record : EntitlementSettingWrapper.getAllSettings()
    ) {
      Record setting = new Record(record);
      if (!mappedSettings.containsKey(setting.bank)) {
        mappedSettings.put(setting.bank, new List<record>());
      }
      mappedSettings.get(setting.bank).add(setting);
    }
  }
  /**
   * @description get all settings
   * @author Remario Richards | 12-02-2023
   * @return List<Entitlement_Setting__mdt>
   **/
  public static List<Entitlement_Setting__mdt> getAllSettings() {
    return Entitlement_Setting__mdt.getAll().values();
  }
  /**
   * @description set default business hours for bank
   * @author Remario Richards | 12-02-2023
   * @param businessHoursName
   * @return BusinessHours
   **/
  public static BusinessHours getBusinessHourRecordForBank(
    String businessHoursName
  ) {
    List<BusinessHours> records = [
      SELECT Id
      FROM BusinessHours
      WHERE Name = :businessHoursName
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    if (records.isEmpty()) {
      throw new StringException(
        'No configured business hours for : ' + businessHoursName
      );
    }
    return records[0];
  }
  /**
   * @description get bank business hours configuration
   * @author Remario Richards | 12-04-2023
   * @param bank
   * @return BusinessHours
   **/
  public static BusinessHours searchBusinessHourRecordForBank(String bank) {
    List<Entitlement_Setting__mdt> records = [
      SELECT Id,Business_Hour_for_Bank__c
      FROM Entitlement_Setting__mdt
      WHERE Bank__c = :bank
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    if (records.size() == 1) {
      return getBusinessHourRecordForBank(records[0].Business_Hour_for_Bank__c);
    }
    return null;
  }
  public class Record {
    public String serviceTypes;
    public String slaType;
    public String radiusDistance;
    public String radiusDistanceType;
    public String parishes;
    public String country;
    public String recordTypeName;
    public String bank;
    public String bankBusinessName;
    public String entitlementName;
    public BusinessHours bankBusinessHours;
    public Boolean applyDistanceCheck;
    /**
     * @description primary constructor
     * @author Remario Richards | 12-02-2023
     * @param setting
     **/
    public Record(Entitlement_Setting__mdt setting) {
      this.bank = setting.Bank__c;
      this.bankBusinessName = setting.Business_Hour_for_Bank__c;
      this.recordTypeName = setting.Case_RecordType_Name__c;
      this.entitlementName = setting.Entitlement_Name__c;
      this.radiusDistance = setting.Kilometer_Radius__c;
      this.radiusDistanceType = setting.Kilometer_Radius_Type__c;
      this.parishes = setting.Parishes__c;
      this.country = setting.Country__c;
      this.serviceTypes = setting.Service_Types__c;
      this.slaType = setting.SLA_Type__c;
      this.bankBusinessHours = getBusinessHourRecordForBank(
        this.bankBusinessName
      );
      this.applyDistanceCheck = setting.use_distance_check__c;
    }
  }
}