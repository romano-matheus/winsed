import { LightningElement, track, api, wire } from "lwc";
import getTerminalIds from "@salesforce/apex/DeviceController.getTerminalIds";
import PICKED_UP_FIELD from "@salesforce/schema/SerializedProduct.Picked_Up__c";
import RETURNED_FIELD from "@salesforce/schema/SerializedProduct.Returned__c";
import ID_FIELD from "@salesforce/schema/SerializedProduct.Id";
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class MobileDevicePickupReturn extends LightningElement {
  @track records = [];
  @track showPickedUp = false;
  @track showReturned = false;
  _recordsUpdatable = false;
  _recordId;
  @track recordsAvailable = false;
  @api
  set recordId(value) {
    this._recordId = value;
    // this.getRecords(value)
    //   .then(() => {})
    //   .catch(() => {});
  }
  get recordId() {
    return this._recordId;
  }

  

  @wire(getTerminalIds)
  wiredTerminalIds({ error, data }) {
    console.log('#getTerminalIds')
      if (data) {
          console.log('###data = '+ JSON.stringify(data));
          this.recordsAvailable = true;
          this.records = data.terminalIds;

          if(data.isStandardUser == true){
            this.showReturned = true;
          } else {
            this.showPickedUp = true;
          }
          this.error = undefined;
      } else if (error) {
        console.error('###error');
        // console.error('###error = '+ error.message);
        console.log('###error = '+ error);
        console.log('###error = '+ JSON.stringify(error));

          this.error = error;
          this.records = undefined;
      }

      console.error('###error = '+ error.message);
  }


  updateDataValues(updateItem) {
    let copyData = JSON.parse(JSON.stringify(this.records));
    console.log("New copyData", JSON.stringify(copyData));

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
        const fields = {};
        console.log("New record.returnLineItemId", JSON.stringify(record.serializedProduct));
        console.log("New record.pickedUp", JSON.stringify(record.pickedUp));

        fields[ID_FIELD.fieldApiName] = record.serializedProduct;
        fields[PICKED_UP_FIELD.fieldApiName] = record.pickedUp;
        fields[RETURNED_FIELD.fieldApiName] = record.returned;
        const recordInput = { fields };
        console.log("New recordInput", JSON.stringify(recordInput));

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

  handlePickedUpChange(event){
    const deviceId = event.target.dataset.id;
    const isChecked = event.target.checked;
    console.log("New isChecked", JSON.stringify(isChecked));


    console.log("New deviceId", JSON.stringify(deviceId));

    this.updateDataValues({
      returnLineItemId: deviceId,
      pickedUp: isChecked
    });
    this._recordsUpdatable = true;

  }

  handleReturnedChange(event){
    const deviceId = event.target.dataset.id;
    const isChecked = event.target.checked;
    console.log("New isChecked", JSON.stringify(isChecked));


    console.log("New deviceId", JSON.stringify(deviceId));

    this.updateDataValues({
      returnLineItemId: deviceId,
      returned: isChecked
    });
    this._recordsUpdatable = true;

  }

}