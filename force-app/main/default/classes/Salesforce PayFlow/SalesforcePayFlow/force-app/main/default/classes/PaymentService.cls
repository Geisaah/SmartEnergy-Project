/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-05-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class PaymentService {

    // Método chamado para gerar a cobrança (Pix/Boleto)
    @AuraEnabled
    public static String processPayment(Id opportunityId) {
        try {
            // 1. Buscar dados da Oportunidade
            Opportunity opp = [SELECT Id, Name, Amount, StageName FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
            
            // 2. Instanciar o HttpRequest
            HttpRequest req = new HttpRequest();
            // Usaremos uma API pública de teste/mock para simular o gateway de pagamento
            req.setEndpoint('https://api.mercadopago.com/v1/payments'); // Exemplo de endpoint corporativo
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer SEU_TOKEN_DE_AUTORIZACAO');
            
            // 3. Montar o corpo da requisição (Payload JSON)
            String jsonBody = '{"transaction_amount": ' + opp.Amount + ', "description": "' + opp.Name + '", "payment_method_id": "pix"}';
            req.setBody(jsonBody);
            
            // 4. Enviar a requisição usando a classe Http
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            // 5. Verificar o retorno da API
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                // Sucesso: Fazer o parsing do JSON de resposta aqui nas próximas etapas
                Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                // Atualizar dados na Oportunidade
                opp.Status_de__c = 'Pendente';
                update opp;
                
                return 'Cobrança gerada com sucesso!';
            } else {
                // Tratamento de Erro da API
                throw new CalloutException('Erro na API de Pagamento: ' + res.getBody());
            }
            
        } catch (Exception e) {
            System.debug('Erro no PaymentService: ' + e.getMessage());
            throw new AuraHandledException('Erro ao processar pagamento: ' + e.getMessage());
        }
    }
}