/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-03-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class EnergyAlertControllerTest {
    
    @TestSetup
static void makeData(){
    Alerta_de_Energia__c alert = new Alerta_de_Energia__c(
        Gravidade__c = 'Alto',
        Status__c = 'Novo',
        Data_e_Hora_do_Alerta__c = System.now() // Preenche com a data e hora atual
    );
    insert alert;
}

    @isTest
    static void testGetRecentAlerts() {
        Test.startTest();
        List<Alerta_de_Energia__c> results = EnergyAlertController.getRecentAlerts();
        Test.stopTest();

        // Valida se o controlador retornou o registro criado
        System.assert(results != null, 'A lista de alertas não deveria ser nula.');
        System.assert(results.size() > 0, 'Deveria retornar pelo menos um alerta.');
        System.assertEquals('Alto', results[0].Gravidade__c, 'A gravidade do alerta deve ser Alta.');
    }
}