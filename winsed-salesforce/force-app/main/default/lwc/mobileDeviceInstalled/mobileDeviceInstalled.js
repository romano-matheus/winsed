import { LightningElement, track, api, wire } from "lwc";
import getPickedUpDevices from "@salesforce/apex/DeviceController.getPickedUpDevices";
import INSTALLED_FIELD from "@salesforce/schema/SerializedProduct.Installed__c";
import REASON_FIELD from "@salesforce/schema/SerializedProduct.Not_Installed_Reason__c";
import ID_FIELD from "@salesforce/schema/SerializedProduct.Id";
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class MobileDeviceInstalled extends LightningElement {
  @track records = [];
  _recordsUpdatable = false;
  _recordId;
  @track errorMessage;
  @api
  set recordId(value) {
    this._recordId = value;
    this.getRecords(value)
      .then(() => {})
      .catch(() => {});
  }
  get recordId() {
    console.log('this._recordId = '+this._recordId);
    return this._recordId;
  }

@track reasons = [{
    label: "Select an Option",
    value:"Select an Option"
  },
  {
    label: "Defective Device",
    value:"Defective Device"
  },
  {
    label: "Merchant Rejected Installation of Device",
    value:"Merchant Rejected Installation of Device"
  },
  {
    label: "Features Not Applicable",
    value:"Features Not Applicable"
  },
  {
    label: "Connectivity Issue",
    value:"Connectivity Issue"
  },
  {
    label: "Other",
    value:"Other"
  },
];

  /**
   * get all assets
   * @param {String} recordId
   */
  async getRecords(recordId) {
    try {
    console.log('recordId = '+recordId);

      this.showSpinner = true;
      this.records = [];
      const response = await getPickedUpDevices({ recordIds: [recordId] });
      console.log('#response = '+ JSON.stringify(response));
      // this.records = response;
      for (const returnLineItem of response) {
      console.log('#returnLineItem = '+ JSON.stringify(returnLineItem));
      let reasonValue = '';

      if(returnLineItem.reason != null){
        returnLineItem.installedDisabled = true;
        returnLineItem.reasondDisabled = false;
      } else if(returnLineItem.installed == true){
        returnLineItem.reasondDisabled = true;
        returnLineItem.installedDisabled = false;
      }

      if(returnLineItem.reason == '' || returnLineItem.reason == null){
        reasonValue = 'Select an Option';
      }

        this.records.push({
          returnLineItemId: returnLineItem.id,
          reason: reasonValue,
          ...returnLineItem
        });
      }

    } catch (error) {
      errorMessage = JSON.stringify(error);
      console.log('Error');
      console.warn(error);
      this.showSpinner = false;
    } finally {
      this.showSpinner = false;
    }
  }
  get recordsAvailable() {
    console.log('# recordsAvailable this.records = '+ JSON.stringify(this.records));

    return (
      Array.isArray(this.records) &&
      this.records.length > 0
    );
  }

  updateDataValues(updateItem) {
    let copyData = JSON.parse(JSON.stringify(this.records));
    copyData.forEach((item) => {
      if (item.returnLineItemId === updateItem.returnLineItemId) {
        // eslint-disable-next-line guard-for-in
        for (let field in updateItem) {
          item[field] = updateItem[field];
        }
      }
    });
    //write changes back to original data
    this.records = [...copyData];
    console.log("New ", JSON.parse(JSON.stringify(this.records)));
  }

  async handleSaveChanges() {
    try {
      this.showSpinner = true;
      // Update all records in parallel thanks to the UI API
      const recordUpdatePromises = this.records.slice().map((record) => {
        console.log("New 33", JSON.parse(JSON.stringify(record)));
        let newReason = '';

        if(record.reason == 'Select an Option'){
          newReason = '';
        }else{
          newReason = record.reason;
        }
        console.log("newReason", JSON.stringify(newReason));
        
        const fields = {};
        fields[ID_FIELD.fieldApiName] = record.returnLineItemId;
        fields[INSTALLED_FIELD.fieldApiName] = record.installed;
        fields[REASON_FIELD.fieldApiName] = newReason;
        const recordInput = { fields };
        return updateRecord(recordInput);
      });

      await Promise.all(recordUpdatePromises);
      // Report success with a toast
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Success",
          message: "Records successfully updated!",
          variant: "success"
        })
      );
    } catch (error) {
      console.error(error);
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error updating records",
          message: error,
          variant: "error"
        })
      );
    } finally {
      this.showSpinner = false;
      this._recordsUpdatable = false;
    }
  }
  // handleWorkOrderSelection(event) {
  //   let dataRecieved = event.detail.data;
  //   const selectedId = dataRecieved.selectedId;
  //   this._recordId = selectedId;
  //   console.log("## dataRecieved", JSON.stringify(dataRecieved));
  //   console.log("## selectedId", JSON.stringify(selectedId));
  //   console.log("## this._recordId", JSON.stringify(this._recordId));

  //   this.getRecords(this._recordId)
  //     .then(() => {})
  //     .catch(() => {});
  // }

  handleInstalledChange(event) {
    const deviceId = event.target.dataset.id;
    const newStatus = event.target.value;
    let installedDisabled = false;
    let reasonDisabled = false;

    if(event.target.checked){
      installedDisabled = false;
      reasonDisabled = true;
    } else {
      reasonDisabled = false;
    }

    this.updateDataValues({
      returnLineItemId: deviceId,
      installed: event.target.checked,
      installedDisabled: installedDisabled,
      reasonDisabled: reasonDisabled
    });
    if(!event.target.checked){
      this._recordsUpdatable = false;
    } else {
      this._recordsUpdatable = true;
    }
  }

  handleReasonChange(event) {
    const deviceId = event.target.dataset.id;
    const newReason = event.target.value;
    let installedDisabled = false;
    let reasonDisabled = false;

    if(newReason != 'Select an Option'){
      installedDisabled = true;
      reasonDisabled = false;
      this._recordsUpdatable = true;
    } else {
      installedDisabled = false;
      reasonDisabled = false;
      this._recordsUpdatable = false;
    }

    this.updateDataValues({
      returnLineItemId: deviceId,
      reason: newReason,
      installedDisabled: installedDisabled,
      reasonDisabled: reasonDisabled
    });
  }

}