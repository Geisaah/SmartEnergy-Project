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
public class PaymentServiceTest {

    // 1. Classe auxiliar que simula a resposta da API (Mock)
    private class MercadoPagoMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(201); // Simula o sucesso de criação da cobrança
            res.setBody('{"id": 123456789, "status": "pending", "point_of_interaction": {"transaction_data": {"qr_code": "00020126580014br.gov.bcb.pix..."}}}');
            return res;
        }
    }

    @isTest
    static void testProcessPaymentSuccess() {
        // 2. Criar dados de teste (Opportunity) na base simulada do teste
        Opportunity testOpp = new Opportunity(
            Name = 'Teste PayFlow',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5),
            Amount = 150.00
        );
        insert testOpp;

        // 3. Configurar o Mock para interceptar o callout
        Test.setMock(HttpCalloutMock.class, new MercadoPagoMock());

        // 4. Executar o método da nossa classe de serviço
        Test.startTest();
        String result = PaymentService.processPayment(testOpp.Id);
        Test.stopTest();

        // 5. Validar os resultados (Assertions)
        System.assertEquals('Cobrança gerada com sucesso!', result, 'O retorno do pagamento deveria ser bem-sucedido.');
        
        // Verificar se a Oportunidade foi atualizada corretamente
        Opportunity updatedOpp = [SELECT Status_de__c FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals('Pendente', updatedOpp.Status_de__c, 'O status de pagamento da oportunidade deveria estar como Pendente.');
    }
}