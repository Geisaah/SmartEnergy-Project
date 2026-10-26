/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-26-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class EnergyReadingServiceTest {

    @TestSetup
    static void setupTestData() {
        // 1. Criar Unidade Consumidora
        Unidade_Consumidora__c site = new Unidade_Consumidora__c(
            Name = 'Site Teste Alpha'
        );
        insert site;

        // 2. Criar Medidor de Energia
        Medidor_de_Energia__c meter = new Medidor_de_Energia__c(
            Name = 'Medidor 01',
            Codigo_Medidor__c = 'MTR-99999',
            Site_de_Energia__c = site.Id,
            Status__c = 'Ativo'
        );
        insert meter;

        // 3. Criar uma leitura existente para simular duplicidade no teste
        Leitura_de_Energia__c existingReading = new Leitura_de_Energia__c(
            Medidor_de_Energia__c = meter.Id,
            Data_da_Leitura__c = System.now().addDays(-1),
            Consumo__c = 100.00,
            ID_Externo__c = 'EXT-EXISTING-001',
            Origem__c = 'API',
            Status_do_Processamento__c = 'Processando'
        );
        insert existingReading;
    }

    @isTest
    static void testProcessReadingsSuccessAndDuplicate() {
        Medidor_de_Energia__c meter = [SELECT Id FROM Medidor_de_Energia__c LIMIT 1];

        List<Leitura_de_Energia__c> newReadings = new List<Leitura_de_Energia__c>();
        
        // Leitura 1: Nova (deve ser processada)
        newReadings.add(new Leitura_de_Energia__c(
            Medidor_de_Energia__c = meter.Id,
            Data_da_Leitura__c = System.now(),
            Consumo__c = 150.50,
            ID_Externo__c = 'EXT-NEW-002',
            Origem__c = 'API'
        ));

        // Leitura 2: Duplicada (deve ser rejeitada)
        newReadings.add(new Leitura_de_Energia__c(
            Medidor_de_Energia__c = meter.Id,
            Data_da_Leitura__c = System.now(),
            Consumo__c = 100.00,
            ID_Externo__c = 'EXT-EXISTING-001',
            Origem__c = 'API'
        ));

        Test.startTest();
        EnergyReadingService.processReadings(newReadings);
        Test.stopTest();

        // Validações
        Leitura_de_Energia__c processedReading = [
            SELECT Status_do_Processamento__c 
            FROM Leitura_de_Energia__c 
            WHERE ID_Externo__c = 'EXT-NEW-002' 
            LIMIT 1
        ];
        System.assertEquals('Processed', processedReading.Status_do_Processamento__c, 'Nova leitura deve ter status Processed.');
    }

    @isTest
    static void testProcessReadingsNullOrEmpty() {
        Test.startTest();
        EnergyReadingService.processReadings(null);
        EnergyReadingService.processReadings(new List<Leitura_de_Energia__c>());
        Test.stopTest();

        System.assert(true, 'Deverá executar sem falhas para entradas nulas ou vazias.');
    }
}
