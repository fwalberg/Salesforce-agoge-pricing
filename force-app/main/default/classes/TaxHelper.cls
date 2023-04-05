public with sharing class TaxHelper {
    public static void validateTaxCategory(List<Tax__c> taxList) {
        for (Tax__c tax : taxList) {
            if(!validateTax(tax)) {
                tax.addError('O valor do Imposto não pode ser menor ou igual a zero');
            }
            else if(!validateProduct(tax)) {
                tax.addError('Informe um produto');
            } else {
                generateUniqueIdentifier(tax);  
                checkTaxDuplicate(tax);  
            }          
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
    
    public static String generateUniqueIdentifier (Tax__c tax) {
        String uniqueIdentifier = '';
        if ((String.isNotBlank(tax.DistributionCenter__c)) &&
            (String.isNotBlank(tax.State__c)) &&
            (String.isNotBlank(tax.Product__c))) {
            uniqueIdentifier = (String)tax.DistributionCenter__c + (String)tax.State__c + (String)tax.Product__c;
            tax.UniqueIdentifier__c = uniqueIdentifier;
        }
        return uniqueIdentifier;
    }

    public static void checkTaxDuplicate(Tax__c tax) {
        Map<Id, Tax__c> taxStoredMap = new Map<Id, Tax__c>([
            SELECT UniqueIdentifier__c, Name
            FROM Tax__c
            WHERE UniqueIdentifier__c <> null
        ]);
        String uniqueIdentifier = generateUniqueIdentifier(tax);

        for(Tax__c oldTax : taxStoredMap.values()) {
            System.debug('OldTax ' + oldTax.UniqueIdentifier__c);
            System.debug('Unique ' + uniqueIdentifier);
            if(oldTax.UniqueIdentifier__c.equals(uniqueIdentifier) && tax.Name != oldTax.Name) {
                tax.addError('Informações já cadastradas no Imposto ' + oldTax.Name);
            }
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