/**
 * @description       : Serviço de Ingestão e Deduplicação de Leituras de Energia
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-27-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class EnergyReadingService {

    /**
     * Processa uma lista de novas leituras de energia.
     * Valida duplicidades usando o ID_Externo__c (compatível com contexto Before Insert).
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

        // Set local para controlar duplicidades enviadas no mesmo lote (bulk)
        Set<String> seenInBatch = new Set<String>();

        // 3. Processar e marcar os status diretamente nos registros (sem DML em Trigger.new)
        for (Leitura_de_Energia__c reading : newReadings) {
            if (reading.ID_Externo__c != null) {
                // Verifica se já existe no banco OU se já passou neste mesmo lote
                if (existingIds.contains(reading.ID_Externo__c) || seenInBatch.contains(reading.ID_Externo__c)) {
                    reading.Status_do_Processamento__c = 'Error';
                    reading.Mensagem_de_Error__c = 'Leitura duplicada detectada (External ID já existe ou duplicado no lote).';
                } else {
                    reading.Status_do_Processamento__c = 'Pendente';
                    seenInBatch.add(reading.ID_Externo__c);
                }
            } else {
                reading.Status_do_Processamento__c = 'Pendente';
            }
        }
        // Nota: Como estamos em 'before insert', nenhum DML (upsert/insert) é necessário aqui!
    }
}

