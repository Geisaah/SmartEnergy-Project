/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class LeituraDeEnergiaTriggerTest {

    @isTest
    static void testTriggerExecutionFlow() {
        // 1. Criar Unidade Consumidora
        Unidade_Consumidora__c site = new Unidade_Consumidora__c(
            Name = 'Site Trigger Test'
        );
        insert site;

        // 2. Criar Medidor de Energia
        Medidor_de_Energia__c meter = new Medidor_de_Energia__c(
            Name = 'Medidor Trig 01',
            Codigo_Medidor__c = 'TRG-001',
            Site_de_Energia__c = site.Id,
            Status__c = 'Ativo'
        );
        insert meter;

        // 3. Criar Regra de Consumo Ativa (Limite de 80 kWh)
        Regra_de_Consumo__c rule = new Regra_de_Consumo__c(
            Name = 'Regra Trigger',
            Unidade_Consumidora__c = site.Id,
            Limite_maximo_por_leitura_hora_em_kWh__c = 80.00,
            Esta_Ativo__c = true,
            Gravidade__c = 'Alto'
        );
        insert rule;

        Test.startTest();
        // Inserir leitura que estoura o limite (120 kWh > 80 kWh)
        // Isso vai disparar o Before Insert (EnergyReadingService) e o After Insert (EnergyRuleEvaluationService)
        Leitura_de_Energia__c reading = new Leitura_de_Energia__c(
            Medidor_de_Energia__c = meter.Id,
            Data_da_Leitura__c = System.now(),
            Consumo__c = 120.00,
            ID_Externo__c = 'EXT-TRG-001',
            Origem__c = 'API'
        );
        insert reading;
        Test.stopTest();

        // 4. Validar se a leitura foi processada corretamente e o alerta foi gerado pela trigger
        Leitura_de_Energia__c insertedReading = [
            SELECT Id, Status_do_Processamento__c 
            FROM Leitura_de_Energia__c 
            WHERE ID_Externo__c = 'EXT-TRG-001'
        ];
        System.assertEquals('Pendente', insertedReading.Status_do_Processamento__c, 'A leitura válida deve ter status Pendente.');

        List<Alerta_de_Energia__c> alerts = [
            SELECT Id, Gravidade__c 
            FROM Alerta_de_Energia__c
        ];
        System.assertEquals(1, alerts.size(), 'A trigger deve ter gerado 1 alerta de energia automaticamente.');
        System.assertEquals('Alto', alerts[0].Gravidade__c, 'A gravidade do alerta deve ser Alto.');
    }
}