import { LightningElement, track, wire } from 'lwc';
import getFieldChanges from '@salesforce/apex/FieldChangeLogController.getFieldChanges';
import getAllSObjects from '@salesforce/apex/FieldChangeLogController.getAllSObjects';
import getFields from '@salesforce/apex/FieldChangeLogController.getFields';

export default class FieldTrackingSystem extends LightningElement {
    @track startDate;
    @track endDate;

    @track objectOptions = [];
    @track selectedObject = '';

    @track fieldOptions = [];
    @track selectedField = '';
    @track isDatatableVisible = false;
    @track noChangesFound = false;
    @track isDateError = false; // Track date error

    @track changes = {
        data: null,
        error: null
    };

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

    connectedCallback() {
        this.fetchObjects();
    }

    async fetchObjects() {
        try {
            this.objectOptions = await getAllSObjects();
        } catch (error) {
            console.error('Error fetching SObjects:', error);
        }
    }

    handleObjectChange(event) {
        this.selectedObject = event.detail.value;
        this.fetchFields(this.selectedObject);
    }

    async fetchFields(objectName) {
        try {
            const result = await getFields({ sObjectName: objectName });
            if (result && result.length > 0) {
                this.fieldOptions = result;
            }
        } catch (error) {
            console.error('Error fetching fields:', error);
        }
    }

    handleFieldChange(event) {
        this.selectedField = event.detail.value;
    }

    handleStartDateChange(event) {
        this.startDate = event.target.value;
    }

    handleEndDateChange(event) {
        this.endDate = event.target.value;
        this.validateDates();
    }

    validateDates() {
        if (this.startDate && this.endDate && this.endDate < this.startDate) {
            this.isDateError = true;
        } else {
            this.isDateError = false;
        }
    }

    async handleFilter() {
        if (this.isDateError) {
            // Do not proceed if there's a date error
            return;
        }

        try {
            const result = await getFieldChanges({
                objectName: this.selectedObject,
                fieldName: this.selectedField,
                startDate: this.startDate,
                endDate: this.endDate
            });

            this.isDatatableVisible = false;
            this.noChangesFound = false;

            if (result && result.length > 0) {
                this.changes.data = result;
                this.isDatatableVisible = true; // Show datatable if changes are found
            } else {
                this.noChangesFound = true; // Set message flag if no changes
            }
        } catch (error) {
            console.error('Error fetching changes:', error);
        }
    }

    handleClearFilters() {
        this.selectedObject = '';
        this.selectedField = '';
        this.startDate = null;
        this.endDate = null;
        this.isDatatableVisible = false;
        this.noChangesFound = false;
        this.isDateError = false;
    }
}
