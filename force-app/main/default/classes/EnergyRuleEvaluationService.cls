/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-27-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class EnergyRuleEvaluationService {

    /**
     * Avalia uma lista de leituras de energia frente às regras de consumo ativas
     * e gera alertas caso os limites sejam ultrapassados.
     */
    public static void evaluateReadings(List<Leitura_de_Energia__c> readings) {
        if (readings == null || readings.isEmpty()) {
            return;
        }

        // 1. Mapear IDs dos Medidores para buscar a qual Unidade Consumidora pertencem
        Set<Id> meterIds = new Set<Id>();
        for (Leitura_de_Energia__c reading : readings) {
            if (reading.Medidor_de_Energia__c != null) {
                meterIds.add(reading.Medidor_de_Energia__c);
            }
        }

        if (meterIds.isEmpty()) {
            return;
        }

        // 2. Consultar medidores para obter o vínculo com a Unidade Consumidora (Site_de_Energia__c)
        Map<Id, Id> meterToUnitMap = new Map<Id, Id>();
        Set<Id> unitIds = new Set<Id>();
        for (Medidor_de_Energia__c meter : [
            SELECT Id, Site_de_Energia__c 
            FROM Medidor_de_Energia__c 
            WHERE Id IN :meterIds
        ]) {
            if (meter.Site_de_Energia__c != null) {
                meterToUnitMap.put(meter.Id, meter.Site_de_Energia__c);
                unitIds.add(meter.Site_de_Energia__c);
            }
        }

        if (unitIds.isEmpty()) {
            return;
        }

        // 3. Buscar Regras de Consumo ativas para essas Unidades Consumidoras
        List<Regra_de_Consumo__c> activeRules = [
            SELECT Id, Unidade_Consumidora__c, Limite_maximo_por_leitura_hora_em_kWh__c, Gravidade__c, Name
            FROM Regra_de_Consumo__c
            WHERE Unidade_Consumidora__c IN :unitIds
            AND Esta_Ativo__c = true
        ];

        // Organizar regras por Unidade Consumidora
        Map<Id, List<Regra_de_Consumo__c>> unitRulesMap = new Map<Id, List<Regra_de_Consumo__c>>();
        for (Regra_de_Consumo__c rule : activeRules) {
            if (!unitRulesMap.containsKey(rule.Unidade_Consumidora__c)) {
                unitRulesMap.put(rule.Unidade_Consumidora__c, new List<Regra_de_Consumo__c>());
            }
            unitRulesMap.get(rule.Unidade_Consumidora__c).add(rule);
        }

        // 4. Avaliar as leituras e coletar alertas a serem criados
        List<Alerta_de_Energia__c> alertsToInsert = new List<Alerta_de_Energia__c>();

        for (Leitura_de_Energia__c reading : readings) {
            Id meterId = reading.Medidor_de_Energia__c;
            if (meterId == null || !meterToUnitMap.containsKey(meterId)) {
                continue;
            }

            Id unitId = meterToUnitMap.get(meterId);
            if (!unitRulesMap.containsKey(unitId)) {
                continue;
            }

            // Verificar cada regra aplicável à unidade
            for (Regra_de_Consumo__c rule : unitRulesMap.get(unitId)) {
                if (rule.Limite_maximo_por_leitura_hora_em_kWh__c != null && 
                    reading.Consumo__c != null && 
                    reading.Consumo__c > rule.Limite_maximo_por_leitura_hora_em_kWh__c) {

                    // Criar o Alerta de Energia
                   Alerta_de_Energia__c alert = new Alerta_de_Energia__c(
                       Unidade_Consumidora__c = unitId,
                       Leitura_de_Energia__c = reading.Id,
                       Regra_de_Consumo__c = rule.Id,
                       Data_e_Hora_do_Alerta__c = System.now(),
                       Descricao_do_Alerta__c = 'Consumo de ' + reading.Consumo__c + ' kWh excedeu o limite da regra "' + rule.Name + '" (' + rule.Limite_maximo_por_leitura_hora_em_kWh__c + ' kWh).',
                       Gravidade__c = rule.Gravidade__c != null ? rule.Gravidade__c : 'Medio',
                       Status__c = 'Novo' // <-- Usando o valor correto da picklist da Org!
);
                    alertsToInsert.add(alert);
                }
            }
        }

        // 5. Inserir os alertas gerados em lote
        if (!alertsToInsert.isEmpty()) {
            insert alertsToInsert;
        }
    }
}