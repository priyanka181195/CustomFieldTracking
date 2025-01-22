import { LightningElement, track, wire } from 'lwc';
import getFieldChanges from '@salesforce/apex/FieldChangeLogController.getFieldChanges';
import getAllSObjects from '@salesforce/apex/FieldChangeLogController.getAllSObjects';
import getFields from '@salesforce/apex/FieldChangeLogController.getFields';

export default class FieldTrackingSystem extends LightningElement {
    //variables for dates
    @track startDate;
    @track endDate;
    @track isDateError = false; // Track date error

    //variables for SObject
    @track objectOptions = [];
    @track selectedObject = '';

    //variables for Fields
    @track fieldOptions = [];
    @track selectedField = '';

    @track isDatatableVisible = false;
    @track noChangesFound = false;

    @track changes = {
        data: null,
        error: null
    };

    // Pagination properties
    @track currentPage = 1;
    @track pageSize = 20; // Number of records per page
    @track totalPages = 0;
    @track paginatedData = [];

    columns = [
        { label: 'Number', fieldName: 'rowNumber', type: 'number' },
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
        },
        {
            label: 'Is High Priority?',
            fieldName: 'Is_High_Priority__c',
            type: 'checkbox'
        }
    ];

    connectedCallback() {
        this.fetchObjects();
    }

    //Retrieving Object's data
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

    //Retrieving Fields' data
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

    //Method to handle selected Filters
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
                this.changes.data = result.map((item, index) => {
                    return { ...item, rowNumber: index + 1 };
                });

                // Setup pagination
                this.totalPages = Math.ceil(
                    this.changes.data.length / this.pageSize
                );
                this.currentPage = 1;
                this.updatePaginatedData();
                this.isDatatableVisible = true; // Show datatable if changes are found
            } else {
                this.noChangesFound = true; // Set message flag if no changes
            }
        } catch (error) {
            console.error('Error fetching changes:', error);
        }
    }

    // Method to update paginated data based on current page
    updatePaginatedData() {
        const startIndex = (this.currentPage - 1) * this.pageSize;
        const endIndex = startIndex + this.pageSize;
        this.paginatedData = this.changes.data.slice(startIndex, endIndex);
    }

    // Handle next page
    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePaginatedData();
        }
    }

    // Handle previous page
    handlePrevPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePaginatedData();
        }
    }
    //getters for Pagination
    get isPrevDisabled() {
        return this.currentPage === 1;
    }

    get isNextDisabled() {
        return this.currentPage === this.totalPages;
    }

    //Method to clear all the selected Filters
    handleClearFilters() {
        // Reset selected filters
        this.selectedObject = '';
        this.selectedField = '';
        this.fieldOptions = [];
        this.startDate = null;
        this.endDate = null;

        // Reset data visibility flags
        this.isDatatableVisible = false;
        this.noChangesFound = false;
        this.isDateError = false;

        // Reset changes to its default structure
        this.changes = {
            data: null,
            error: null
        };

        // Reset pagination variables
        this.currentPage = 1;
        this.totalPages = 0;
        this.paginatedData = [];
    }
}
