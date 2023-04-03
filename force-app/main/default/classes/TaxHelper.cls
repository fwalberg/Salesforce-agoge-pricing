public with sharing class TaxHelper {
    public static void validateTaxCategory(List<Tax__c> taxList) {
        for (Tax__c tax : taxList) {
            if(!validateTax(tax)) {
                tax.addError('O valor do Imposto não pode ser menor ou igual a zero');
            }
            else if(!validateProduct(tax)) {
                tax.addError('Informe um produto');
            }
            generateUniqueIdentifier(tax);            
        }
    }

    public static void validateTaxCategory(Map<Id, Tax__c> oldMap, Map<Id, Tax__c> newMap) {
        List<Tax__c> taxListUpdated = new List<Tax__c>();
        for (Tax__c newTax : newMap.values()) {
            Tax__c oldTax = oldMap.get(newTax.Id);

            if((newTax.DistributionCenter__c != oldTax.DistributionCenter__c) ||
                (newTax.Product__c != oldTax.Product__c) || (newTax.State__c != oldTax.State__c)
            ) taxListUpdated.add(newTax);
            else if (newTax.UniqueIdentifier__c != oldTax.UniqueIdentifier__c)
                newTax.addError('O Identifcado Único não pode ser modificado');
        }
        validateTaxCategory(taxListUpdated);
    }
    
    public static void generateUniqueIdentifier (Tax__c tax) {
        String uniqueIdentifier = '';
        if ((String.isNotBlank(tax.DistributionCenter__c)) &&
            (String.isNotBlank(tax.State__c)) &&
            (String.isNotBlank(tax.Product__c))) {
                tax.UniqueIdentifier__c = (String)tax.DistributionCenter__c + (String)tax.State__c + (String)tax.Product__c;
        }
    }
    public static Boolean validateTax (Tax__c tax) {
        if ((tax.TaxCost__c <= 0.0 || tax.TaxCost__c == null)) return false;
        return true;
    }

    public static Boolean validateProduct(Tax__c tax) {
        if ((tax.Product__c == null)) return false;
        return true;
    }
}