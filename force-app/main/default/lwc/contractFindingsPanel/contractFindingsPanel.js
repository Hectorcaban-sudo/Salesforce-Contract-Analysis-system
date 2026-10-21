import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import captureOverride from '@salesforce/apex/CaptureOverrideAction.captureOverrideAura';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const FIELDS = ['Contract_Review__c.Name', 'Contract_Review__c.Overall_Risk_Score__c', 'Contract_Review__c.Status__c'];

export default class ContractFindingsPanel extends LightningElement {
    @api recordId;
    reviewName;
    riskScore;
    status;
    findingsResult;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredReview({ data }) {
        if (data) {
            this.reviewName = getFieldValue(data, 'Contract_Review__c.Name');
            this.riskScore = getFieldValue(data, 'Contract_Review__c.Overall_Risk_Score__c');
            this.status = getFieldValue(data, 'Contract_Review__c.Status__c');
        }
    }

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Findings__r',
        fields: ['Contract_Finding__c.Id', 'Contract_Finding__c.Clause_Type__c', 'Contract_Finding__c.Risk_Level__c', 'Contract_Finding__c.Excerpt__c', 'Contract_Finding__c.Review_Status__c', 'Contract_Finding__c.Override_Note__c']
    })
    wiredFindings(result) {
        this.findingsResult = result;
        this.findings = result;
    }

    get hasFindings() {
        return this.findings && this.findings.data && this.findings.data.records.length > 0;
    }

    async handleAccept(event) {
        await this.updateStatus(event.target.dataset.id, 'Accepted', null);
    }

    async handleOverride(event) {
        const findingId = event.target.dataset.id;
        const noteInput = this.template.querySelector(`lightning-textarea[data-id="${findingId}"]`);
        const note = noteInput ? noteInput.value : null;
        await this.updateStatus(findingId, 'Overridden', note);
    }

    async updateStatus(findingId, status, note) {
        try {
            await captureOverride({ requests: [{ findingId, status, note }] });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Updated',
                message: `Finding marked as ${status}`,
                variant: 'success'
            }));
            await refreshApex(this.findingsResult);
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: error.body?.message || 'Update failed',
                variant: 'error'
            }));
        }
    }
}
