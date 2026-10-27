/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-27-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger LeituraDeEnergia on Leitura_de_Energia__c (before insert, after insert) {
    
    if (Trigger.isBefore && Trigger.isInsert) {
        // Antes de inserir, executamos a lógica de deduplicação e tratamento de status
        EnergyReadingService.processReadings(Trigger.new);
    }
    
    if (Trigger.isAfter && Trigger.isInsert) {
        // Após inserir, avaliamos as regras e geramos os alertas necessários
        EnergyRuleEvaluationService.evaluateReadings(Trigger.new);
    }
}