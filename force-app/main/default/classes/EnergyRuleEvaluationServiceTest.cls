/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-26-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class EnergyRuleEvaluationServiceTest {

    @TestSetup
    static void setupTestData() {
        // 1. Criar Unidade Consumidora
        Unidade_Consumidora__c site = new Unidade_Consumidora__c(
            Name = 'Site Regras Alpha'
        );
        insert site;

        // 2. Criar Medidor de Energia
        Medidor_de_Energia__c meter = new Medidor_de_Energia__c(
            Name = 'Medidor Regras 01',
            Codigo_Medidor__c = 'MTR-001',
            Site_de_Energia__c = site.Id,
            Status__c = 'Ativo'
        );
        insert meter;

        // 3. Criar Regra de Consumo Ativa (Limite de 100 kWh por leitura)
        Regra_de_Consumo__c rule = new Regra_de_Consumo__c(
            Name = 'Regra Limite Máximo',
            Unidade_Consumidora__c = site.Id,
            Limite_maximo_por_leitura_hora_em_kWh__c = 100.00,
            Esta_Ativo__c = true,
            Gravidade__c = 'Alto'
        );
        insert rule;
    }

    @isTest
    static void testEvaluateReadingsExceedsLimit() {
        Medidor_de_Energia__c meter = [SELECT Id FROM Medidor_de_Energia__c LIMIT 1];

        // Criar leitura que ultrapassa o limite (150 kWh > 100 kWh)
        Leitura_de_Energia__c reading = new Leitura_de_Energia__c(
            Medidor_de_Energia__c = meter.Id,
            Data_da_Leitura__c = System.now(),
            Consumo__c = 150.00,
            ID_Externo__c = 'EXT-RULE-TEST-001',
            Origem__c = 'API',
            Status_do_Processamento__c = 'Pendente'
        );
        insert reading;

        Test.startTest();
        // Executar o serviço de avaliação de regras
        EnergyRuleEvaluationService.evaluateReadings(new List<Leitura_de_Energia__c>{ reading });
        Test.stopTest();

        // Validar se o Alerta de Energia foi gerado
        List<Alerta_de_Energia__c> alerts = [
            SELECT Id, Gravidade__c, Status__c, Leitura_de_Energia__c 
            FROM Alerta_de_Energia__c
        ];

        System.assertEquals(1, alerts.size(), 'Deveria ter gerado exatamente 1 alerta de energia.');
        System.assertEquals('Alto', alerts[0].Gravidade__c, 'A gravidade do alerta deve ser Alta conforme a regra.');
        System.assertEquals('Pendente', alerts[0].Status__c, 'O status inicial do alerta deve ser Pendente.');
    }

    @isTest
    static void testEvaluateReadingsWithinLimit() {
        Medidor_de_Energia__c meter = [SELECT Id FROM Medidor_de_Energia__c LIMIT 1];

        // Criar leitura dentro do limite (50 kWh <= 100 kWh)
        Leitura_de_Energia__c reading = new Leitura_de_Energia__c(
            Medidor_de_Energia__c = meter.Id,
            Data_da_Leitura__c = System.now(),
            Consumo__c = 50.00,
            ID_Externo__c = 'EXT-RULE-TEST-002',
            Origem__c = 'API',
            Status_do_Processamento__c = 'Pendente'
        );
        insert reading;

        Test.startTest();
        EnergyRuleEvaluationService.evaluateReadings(new List<Leitura_de_Energia__c>{ reading });
        Test.stopTest();

        // Validar que NENHUM alerta foi gerado
        List<Alerta_de_Energia__c> alerts = [
            SELECT Id 
            FROM Alerta_de_Energia__c
        ];

        System.assert(alerts.isEmpty(), 'Não deveria gerar alertas para consumos dentro do limite.');
    }

    @isTest
    static void testEvaluateReadingsNullOrEmpty() {
        Test.startTest();
        EnergyRuleEvaluationService.evaluateReadings(null);
        EnergyRuleEvaluationService.evaluateReadings(new List<Leitura_de_Energia__c>());
        Test.stopTest();

        System.assert(true, 'Deverá executar sem falhas para entradas nulas ou vazias.');
    }
}