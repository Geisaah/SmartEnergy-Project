import { LightningElement, track, wire } from 'lwc';
import getRecentAlerts from '@salesforce/apex/EnergyAlertController.getRecentAlerts';

const columns = [
    { label: 'Nome do Alerta', fieldName: 'Name', type: 'text' },
    { label: 'Gravidade', fieldName: 'Gravidade__c', type: 'text' },
    { label: 'Status', fieldName: 'Status__c', type: 'text' },
    { label: 'Data e Hora', fieldName: 'Data_e_Hora_do_Alerta__c', type: 'date' }
];

export default class EnergyAlertList extends LightningElement {
    @track columns = columns;
    @track alerts = [];
    @track error;

    @wire(getRecentAlerts)
    wiredAlerts({ error, data }) {
        if (data) {
            this.alerts = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.alerts = undefined;
        }
    }
}