public with sharing class FreightHelper {

    public static void validateFreightCategories (List<Freight__c> freightList) {
        for (Freight__c freight : freightList) {
            if (!validateProductCategory(freight)) {
                freight.addError('Verifique as informações do Produto!');
            }
            else if (!validateLocaleCategory(freight)) {
                freight.addError('Informe apenas uma informação de localidade!');
            }
        }
    }

    public static void validateFreightCategories (Map<Id, Freight__c> oldMap, Map<Id, Freight__c> newMap) {
        List<Freight__c> freightUpdatedList = new List<Freight__c>();

        for (Freight__c newFreight : newMap.values()) {
            Freight__c oldFreight = oldMap.get(newFreight.Id);

            if ((newFreight.Product__c != oldFreight.Product__c) ||
                (newFreight.ProductHierarchy__c != oldFreight.ProductHierarchy__c) ||
                (newFreight.State__c != oldFreight.State__c) ||
                (newFreight.Country__c != oldFreight.Country__c)                
            ) freightUpdatedList.add(newFreight);
        }
        if (!freightUpdatedList.isEmpty()) validateFreightCategories(freightUpdatedList);
    }

    public static Boolean validateProductCategory(Freight__c freight) {
        if ((String.isBlank(freight.Product__c) && String.isBlank(freight.ProductHierarchy__c)) ||
            (String.isNotBlank(freight.Product__c) && String.isNotBlank(freight.ProductHierarchy__c))
        ) return false;
        return true;        
    }

    public static Boolean validateLocaleCategory(Freight__c freight) {
        if ((String.isBlank(freight.City__c) && String.isBlank(freight.State__c) && String.isBlank(freight.Country__c)) ||
            (String.isNotBlank(freight.City__c) && (String.isNotBlank(freight.State__c) || String.isNotBlank(freight.Country__c))) ||
            (String.isNotBlank(freight.State__c) && (String.isNotBlank(freight.Country__c))) 
        ) return false;
        return true;        
    }   
    
    public static void calcScore(List<Freight__c> freightList){

        for (Freight__c freight : freightList) {

            Integer score = 0;
            if (String.isNotBlank(freight.Product__c)) {
                score += 1000;
            }
            else if (String.isNotBlank(freight.ProductHierarchy__c)) {
                score += 500;
            }
            if(String.isNotBlank(freight.City__c)) {
                score += 200;
            }
            else if (String.isNotBlank(freight.State__c)) {
                score += 100;
            }
            else if (String.isNotBlank(freight.Country__c)) {
                score += 50;
            }
            freight.Score__c = score;
        }
    }

    public static void calcScore(Map<Id, Freight__c> oldMap, Map<Id, Freight__c> newMap) {
        List<Freight__c> freightUpdatedList = new List<Freight__c>();

        for (Freight__c newFreight : newMap.values()) {
            Freight__c oldFreight = oldMap.get(newFreight.Id);

            if ((newFreight.Product__c != oldFreight.Product__c) ||
                (newFreight.ProductHierarchy__c != oldFreight.ProductHierarchy__c) ||
                (newFreight.State__c != oldFreight.State__c) ||
                (newFreight.Country__c != oldFreight.Country__c)                
            ) freightUpdatedList.add(newFreight);
        }
        if (!freightUpdatedList.isEmpty()) calcScore(freightUpdatedList);
    }
}