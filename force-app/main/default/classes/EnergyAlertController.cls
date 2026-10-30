/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-30-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class EnergyAlertController {
    
    @AuraEnabled(cacheable=true)
    public static List<Alerta_de_Energia__c> getRecentAlerts() {
        return [
            SELECT Id, Name, Gravidade__c, Status__c, Data_e_Hora_do_Alerta__c 
            FROM Alerta_de_Energia__c 
            ORDER BY CreatedDate DESC 
            LIMIT 10
        ];
    }
}