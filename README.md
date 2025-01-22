Enhanced Salesforce Custom Field Tracking System:

This project has a custom Field Tracking System in Salesforce that monitors the fields across multiple Standard and Custom Objects. These objects and their monitored fields have been added in the Custom Metadata configuration so as to track the fields and observe its changed values. Some fields that are considered as High Priority across the objects have also been monitored and any change in these fields will trigger a real-time notification across the platform and the users will be informed through email about the change. A Field Tracking Log record will also be created for the tracked fields that are changed. A dashboard and reports can be created for these and played around. This custom Field Tracking System(FTS) displays the records of the changed fields with and without filters specified. This ensures that this FTS is not using any built in Field History Tracking capability of Salesforce.

Please find the complete guide to the Field Tracking System(FTS) in "Custom Field Tracking System.pdf" file. 
This guide has access to the data model, data configurations, a detailed explanation, and ideas for enchancements.

Set up Instructions:
1. Unzip the code in your code editor and Authorize/Open the Developer Edition Org using the credentials.
2. Make sure the entire code is deployed to your org using the command "sf project deploy start"
3. Go to Setup > Object Manager and observe that we have a custom object created named "Field Tracking Log" with custom fields.
4. Also, check if the custom objects like "Employee" and "Project" are also present in the Object Manager with their custom fields.
5. From the Quick Find search box, find "Custom Metadata Types" and check that there are two custom metadata type records available namely, "Email Recipient" and "Field Tracking Log Config"
6. (Optional) - If we click on "Manage Records" of "Field Tracking Log Config", we will see that Field Tracking Configs have been created for Standard Objects like Account, Contact and Opportunity and Custom Objects, "Employee" and "Project". We can also see that some configs have "Is High Priority" field checked.
7. (Optional) - If we click on "Manage Records" of "Email Recipient", we will see that there are three teams created for System users where they can configure email id. This email configuration will be used for sending email(real time notification) to the configured receiver.
8. Go to Field Tracking System from App Launcher and we will see an App Page which shows four filters for Object Name, Field Name, Start Date and End date. Alongwith that we can see that there are two buttons, out of which "Fetch Tracked Field(s) Changes" will fetch field changes with/without added filters and display in a table and "Clear Filters" will clear all the specified filters and the results.
9. Also, observe that Field Tracking Logs get created that display the changed records with details.

Tracking Field Changes:
1. Navigate to Setup > Custom Metadata Types. If we observe again the "Manage Records" of "Field Tracking Log Config" we can see that there are configurations for Standard and Custom objects. 
Let's say we are monitoring changes for "Account Name Config". 
2. Now, go to Accounts and create an account record or navigate to any of the existing records. 
3. Change the Account Name of the record. Once this is changed, because this is a High Priority Tracking Field, an email mentioning the details and changes of this record will be sent to the email id configured in the "Dev Team" record of "Email Recipient" custom metadata type. We can always change the email id and configuration of the "Email Recipient" metadata record. 
4. You can observe these tracked field changes using Filters in Field Tracking System.
5. you can also see that a Field Tracking Log will be created for the same mentioning the details.

Creating Field Changes:
1. In order to track a new field, go to Custom Metadata types from Setup and navigate to "Manage Records"
2. Click on "New" and create a Field Tracking Log Config by specifying the values of the asked fields.

Example:
Label: Contact Email Config
Field Tracking Log Config Name: Contact_Email_Config
Master Label: Contact_Email_Config
Object API Name: Contact
Field API Name: Email
Is High Priority?: checked		 	 
Field Name: Email
Object Name: Contact	

3. Navigate to the specified SObject record and change the said field and see that an email has been sent to the email id of the configured email record. 

Note: There is a trigger created on the some Standard and Custom Objects which are mentioned above. But other than the above mentioned objects(Account, Contact, Opportunity, Employee, Project), if we create any field changes on another objects we will have to create that object's trigger in order to facilitate the changes. This trigger only needs sObjectName and won't require any difficult or hard code changes because ultimately it calls a generic function of FiedChangeTracker apex class to do the operations.

Create the trigger using the following code:
trigger <SObject>FieldTracking on <SObject>(before update) {
    // We only track changes on update
    if (Trigger.isBefore && Trigger.isUpdate) {
        FieldChangeTracker.trackFieldChanges(
            Trigger.new,
            Trigger.old,
            '<SObejct>'
        );
    }
}

Imp: Replace <SOject> with the name of the actual Standard or Custom Object 






