import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import processPayment from '@salesforce/apex/PaymentService.processPayment';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class PaymentGenerator extends LightningElement {
    @api recordId; // ID da Oportunidade atual injetado automaticamente pelo Salesforce
    @track isLoading = false;
    @track message = '';

    handleGeneratePayment() {
        this.isLoading = true;
        this.message = '';

        processPayment({ opportunityId: this.recordId })
            .then(result => {
                this.isLoading = false;
                this.message = result;
                
                // Dispara notificação toast de sucesso
                this.showToast('Sucesso!', result, 'success');
                
                // Atualiza o cache do registro na tela para refletir os novos campos
                getRecordNotifyChange([{recordId: this.recordId}]);
            })
            .catch(error => {
                this.isLoading = false;
                let errorMessage = 'Erro desconhecido';
                if (error.body && error.body.message) {
                    errorMessage = error.body.message;
                }
                this.showToast('Erro ao processar', errorMessage, 'error');
            });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}