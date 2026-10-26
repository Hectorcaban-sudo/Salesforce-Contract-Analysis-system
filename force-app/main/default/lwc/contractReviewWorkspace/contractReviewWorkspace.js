import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import captureOverride from '@salesforce/apex/CaptureOverrideAction.captureOverrideAura';
import runAnalysis from '@salesforce/apex/ContractIntakeController.runAnalysis';
import getFindings from '@salesforce/apex/ContractIntakeController.getFindings';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const REVIEW_FIELDS = [
    'Contract_Review__c.Name',
    'Contract_Review__c.Overall_Risk_Score__c',
    'Contract_Review__c.Status__c',
    'Contract_Review__c.ContentDocumentId__c',
    'Contract_Review__c.Document_Type__c',
    'Contract_Review__c.Agency__c',
    'Contract_Review__c.Agent_Response__c'
];

export default class ContractReviewWorkspace extends NavigationMixin(LightningElement) {
    @api recordId;
    reviewName;
    riskScore;
    status;
    contentDocumentId;
    documentType;
    agency;
    agentResponse;
    findingsResult;
    findings = [];
    selectedFindingId;
    selectedExcerpt = '';
    selectedClauseType = '';
    selectedRiskLevel = '';
    isRerunning = false;

    @wire(getRecord, { recordId: '$recordId', fields: REVIEW_FIELDS })
    wiredReview({ data }) {
        if (data) {
            this.reviewName = getFieldValue(data, 'Contract_Review__c.Name');
            this.riskScore = getFieldValue(data, 'Contract_Review__c.Overall_Risk_Score__c');
            this.status = getFieldValue(data, 'Contract_Review__c.Status__c');
            this.contentDocumentId = getFieldValue(data, 'Contract_Review__c.ContentDocumentId__c');
            this.documentType = getFieldValue(data, 'Contract_Review__c.Document_Type__c');
            this.agency = getFieldValue(data, 'Contract_Review__c.Agency__c');
            this.agentResponse = getFieldValue(data, 'Contract_Review__c.Agent_Response__c');
        }
    }

    get hasFile() {
        return !!this.contentDocumentId;
    }

    @wire(getFindings, { reviewId: '$recordId' })
    wiredFindings(result) {
        this.findingsResult = result;
        if (result.data) {
            this.findings = result.data.map((rec) => {
                const risk = rec.Risk_Level__c || 'Medium';
                const isSelected = rec.Id === this.selectedFindingId;
                return {
                    id: rec.Id,
                    clauseType: rec.Clause_Type__c || 'Clause',
                    riskLevel: risk,
                    excerpt: rec.Excerpt__c || '',
                    reviewStatus: rec.Review_Status__c,
                    overrideNote: rec.Override_Note__c,
                    riskClass: this.riskClass(risk),
                    badgeClass: this.badgeClass(risk),
                    cardClass: isSelected ? this.riskClass(risk) + ' selected' : this.riskClass(risk)
                };
            });
            if (this.findings.length && !this.selectedFindingId) {
                this.selectFinding(this.findings[0]);
            }
        } else {
            this.findings = [];
        }
    }

    get hasFindings() {
        return this.findings && this.findings.length > 0;
    }

    get selectedBadgeClass() {
        return this.badgeClass(this.selectedRiskLevel || 'Medium');
    }

    get overallRiskLabel() {
        const score = this.riskScore || 0;
        if (score >= 70) return 'High Risk';
        if (score >= 40) return 'Medium Risk';
        return 'Low Risk';
    }

    get overallRiskClass() {
        const score = this.riskScore || 0;
        if (score >= 70) return 'risk-high';
        if (score >= 40) return 'risk-medium';
        return 'risk-low';
    }

    riskClass(level) {
        if (level === 'High') return 'finding-card risk-high';
        if (level === 'Low') return 'finding-card risk-low';
        return 'finding-card risk-medium';
    }

    badgeClass(level) {
        if (level === 'High') return 'badge badge-high';
        if (level === 'Low') return 'badge badge-low';
        return 'badge badge-medium';
    }

    selectFinding(found) {
        this.selectedFindingId = found.id;
        this.selectedExcerpt = found.excerpt;
        this.selectedClauseType = found.clauseType;
        this.selectedRiskLevel = found.riskLevel;
        this.findings = this.findings.map((f) => ({
            ...f,
            cardClass: f.id === found.id ? f.riskClass + ' selected' : f.riskClass
        }));
    }

    handleSelectFinding(event) {
        const id = event.currentTarget.dataset.id;
        const found = this.findings.find((f) => f.id === id);
        if (found) {
            this.selectFinding(found);
        }
    }

    handleOpenDocument() {
        if (!this.contentDocumentId) {
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: this.contentDocumentId
            }
        });
    }

    async handleRerun() {
        if (!this.contentDocumentId) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'No file',
                message: 'This review has no attached contract file.',
                variant: 'warning'
            }));
            return;
        }
        this.isRerunning = true;
        try {
            const result = await runAnalysis({ reviewId: this.recordId });
            if (result.errorMessage) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Re-run finished with warnings',
                    message: result.errorMessage,
                    variant: 'warning'
                }));
            } else {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Re-run complete',
                    message: 'Findings created.',
                    variant: 'success'
                }));
            }
            await refreshApex(this.findingsResult);
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: error.body?.message || 'Re-run failed',
                variant: 'error'
            }));
        } finally {
            this.isRerunning = false;
        }
    }

    async handleAccept(event) {
        event.stopPropagation();
        await this.updateStatus(event.target.dataset.id, 'Accepted', null);
    }

    async handleOverride(event) {
        event.stopPropagation();
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
