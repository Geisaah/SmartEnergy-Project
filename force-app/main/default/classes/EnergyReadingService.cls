/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-26-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class EnergyReadingService {

    /**
     * Processa e persiste uma lista de novas leituras de energia.
     * Valida duplicidades usando o ID_Externo__c.
     */
    public static void processReadings(List<Leitura_de_Energia__c> newReadings) {
        if (newReadings == null || newReadings.isEmpty()) {
            return;
        }

        // 1. Extrair IDs externos para checagem de duplicidade em lote (Bulk)
        Set<String> externalIds = new Set<String>();
        for (Leitura_de_Energia__c reading : newReadings) {
            if (reading.ID_Externo__c != null) {
                externalIds.add(reading.ID_Externo__c);
            }
        }

        // 2. Buscar leituras já existentes na base com esses IDs
        Set<String> existingIds = new Set<String>();
        if (!externalIds.isEmpty()) {
            for (Leitura_de_Energia__c existing : [
                SELECT ID_Externo__c 
                FROM Leitura_de_Energia__c 
                WHERE ID_Externo__c IN :externalIds
            ]) {
                existingIds.add(existing.ID_Externo__c);
            }
        }

        // 3. Filtrar apenas leituras novas (que não estão duplicadas)
        List<Leitura_de_Energia__c> readingsToInsert = new List<Leitura_de_Energia__c>();
        for (Leitura_de_Energia__c reading : newReadings) {
            if (reading.ID_Externo__c != null && existingIds.contains(reading.ID_Externo__c)) {
                reading.Status_do_Processamento__c = 'Error';
                reading.Mensagem_de_Error__c = 'Leitura duplicada detectada (External ID já existe).';
            } else {
                reading.Status_do_Processamento__c = 'Pendente';
                readingsToInsert.add(reading);
            }
        }

        // 4. Persistir as leituras válidas
        if (!newReadings.isEmpty()) {
            upsert newReadings ID_Externo__c;
        }
    }
}


