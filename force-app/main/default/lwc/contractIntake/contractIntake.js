import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import startAnalysis from '@salesforce/apex/ContractIntakeController.startAnalysis';
import getOrCreateDraft from '@salesforce/apex/ContractIntakeController.getOrCreateDraft';
import getRecentReviews from '@salesforce/apex/ContractIntakeController.getRecentReviews';
import { refreshApex } from '@salesforce/apex';

export default class ContractIntake extends NavigationMixin(LightningElement) {
    contentDocumentId;
    fileName;
    contractName = '';
    documentType = 'Base Contract';
    agency = '';
    notes = '';
    isRunning = false;
    errorMessage;
    recentResult;
    recentReviews = [];
    draftRecordId;

    typeOptions = [
        { label: 'Base Contract', value: 'Base Contract' },
        { label: 'Modification', value: 'Modification' },
        { label: 'Subcontract Mod', value: 'Subcontract Mod' },
        { label: 'Task Order', value: 'Task Order' },
        { label: 'Government Contract', value: 'Government Contract' },
        { label: 'NDA', value: 'NDA' },
        { label: 'MSA', value: 'MSA' },
        { label: 'SaaS', value: 'SaaS' },
        { label: 'Other', value: 'Other' }
    ];

    connectedCallback() {
        this.ensureDraft();
    }

    async ensureDraft() {
        try {
            this.draftRecordId = await getOrCreateDraft();
        } catch (error) {
            this.errorMessage = error.body?.message || 'Could not prepare upload';
        }
    }

    @wire(getRecentReviews)
    wiredRecent(result) {
        this.recentResult = result;
        if (result.data) {
            this.recentReviews = result.data.map((r) => ({
                ...r,
                url: '/' + r.Id
            }));
        }
    }

    get hasRecent() {
        return this.recentReviews && this.recentReviews.length > 0;
    }

    get isRunDisabled() {
        return this.isRunning || !this.contentDocumentId;
    }

    handleUploadFinished(event) {
        const files = event.detail.files || [];
        if (files.length) {
            this.contentDocumentId = files[0].documentId;
            this.fileName = files[0].name;
            if (!this.contractName) {
                this.contractName = files[0].name;
            }
            this.errorMessage = null;
        }
    }

    handleNameChange(e) { this.contractName = e.target.value; }
    handleTypeChange(e) { this.documentType = e.detail.value; }
    handleAgencyChange(e) { this.agency = e.target.value; }
    handleNotesChange(e) { this.notes = e.target.value; }

    async handleRun() {
        if (!this.contentDocumentId) {
            this.errorMessage = 'Upload a contract file before running analysis.';
            return;
        }

        this.isRunning = true;
        this.errorMessage = null;
        try {
            const result = await startAnalysis({
                contentDocumentId: this.contentDocumentId,
                contractName: this.contractName,
                documentType: this.documentType,
                agency: this.agency,
                notes: this.notes,
                draftReviewId: this.draftRecordId
            });

            if (result.errorMessage) {
                this.errorMessage = result.errorMessage;
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Analysis started with warnings',
                    message: result.errorMessage,
                    variant: 'warning'
                }));
            } else {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Analysis started',
                    message: 'Opening the Contract Review Workspace',
                    variant: 'success'
                }));
            }

            await refreshApex(this.recentResult);

            if (result.reviewId) {
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result.reviewId,
                        objectApiName: 'Contract_Review__c',
                        actionName: 'view'
                    }
                });
            }
        } catch (error) {
            this.errorMessage = error.body?.message || error.message || 'Failed to start analysis';
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: this.errorMessage,
                variant: 'error'
            }));
        } finally {
            this.isRunning = false;
        }
    }
}
