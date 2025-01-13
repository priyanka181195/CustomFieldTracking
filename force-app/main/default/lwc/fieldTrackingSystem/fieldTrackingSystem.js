import { LightningElement, track, wire } from 'lwc';
import getFieldChanges from '@salesforce/apex/FieldChangeLogController.getFieldChanges';
import getAllSObjects from '@salesforce/apex/FieldChangeLogController.getAllSObjects';
import getFields from '@salesforce/apex/FieldChangeLogController.getFields';

export default class FieldTrackingSystem extends LightningElement {
    @track startDate = '';
    @track endDate = '';

    @track objectOptions = [];
    @track selectedObject = '';

    @track fieldOptions = [];
    @track selectedField = '';
    @track isDatatableVisible = false; // Controls datatable visibility

    @track changes = {
        data: null,
        error: null
    };

    connectedCallback() {
        this.fetchObjects();
    }

    fetchObjects() {
        getAllSObjects()
            .then((result) => {
                this.objectOptions = result;
            })
            .catch((error) => {
                console.error(error);
            });
    }

    handleObjectChange(event) {
        this.selectedObject = event.detail.value;
        this.fetchFields(this.selectedObject);
    }

    fetchFields(objectName) {
        getFields({ sObjectName: objectName })
            .then((result) => {
                if (result && result.length > 0) {
                    this.fieldOptions = result;
                }
            })
            .catch((error) => {
                console.error(error);
            });
    }

    handleFieldChange(event) {
        this.selectedField = event.detail.value;
    }

    columns = [
        { label: 'Object Name', fieldName: 'Object_Name__c', type: 'text' },
        { label: 'Record Id', fieldName: 'Record_Id__c', type: 'text' },
        { label: 'Field Name', fieldName: 'Field_Name__c', type: 'text' },
        { label: 'Old Value', fieldName: 'Old_Value__c', type: 'text' },
        { label: 'New Value', fieldName: 'New_Value__c', type: 'text' },
        { label: 'Changed By', fieldName: 'Changed_By__c', type: 'text' },
        {
            label: 'Change Date/Time',
            fieldName: 'Change_Date_Time__c',
            type: 'date'
        }
    ];

    handleStartDateChange(event) {
        this.startDate = event.target.value;
    }

    handleEndDateChange(event) {
        this.endDate = event.target.value;
    }

    handleFetchChanges() {
        this.isDatatableVisible = true;
        getFieldChanges({
            objectName: this.selectedObject,
            fieldName: this.selectedField,
            startDate: this.startDate,
            endDate: this.endDate
        })
            .then((result) => {
                this.changes.data = result;
                this.changes.error = null;
            })
            .catch((error) => {
                this.changes.error = error.body
                    ? error.body.message
                    : error.message;
                this.changes.data = null;
            });
    }
}
