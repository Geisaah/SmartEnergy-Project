import { LightningElement, track } from 'lwc';

const columns = [
    { label: 'Nome do Alerta', fieldName: 'Name', type: 'text' },
    { label: 'Severidade', fieldName: 'Severidade__c', type: 'text' },
    { label: 'Status', fieldName: 'Status__c', type: 'text' },
    { label: 'Data', fieldName: 'CreatedDate', type: 'date' }
];

export default class EnergyAlertList extends LightningElement {
    @track columns = columns;
    @track alerts = [
        { id: '1', Name: 'ALT-0001', Severidade__c: 'High', Status__c: 'Novo', CreatedDate: '2026-10-30T10:00:00Z' },
        { id: '2', Name: 'ALT-0002', Severidade__c: 'Medium', Status__c: 'Em Análise', CreatedDate: '2026-10-30T11:30:00Z' }
    ];
}