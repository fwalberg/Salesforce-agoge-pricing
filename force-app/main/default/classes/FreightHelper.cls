public with sharing class FreightHelper {

    public static void validateFreightCategories (List<Freight__c> freightList) {
        for (Freight__c freight : freightList) {
            if (!validateProductCategory(freight)) {
                freight.addError(System.label.FreightProductInformationError);
            }
            else if (!validateLocaleCategory(freight)) {
                freight.addError(System.label.FreightLocaleError);
            } else {
                checkFreightDuplicate(freight);
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
                (newFreight.Country__c != oldFreight.Country__c) ||
                (newFreight.Status__c != oldFreight.Status__c)                
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

    public static void checkFreightDuplicate(Freight__c freight) {
        Map<Id, Freight__c> freightStoredMap = new Map<Id, Freight__c>([
            SELECT Id, UniqueIdentifier__c, Name
            FROM Freight__c
            WHERE UniqueIdentifier__c <> null
        ]);
         
        String uniqueIdentifier = '';
        if (String.isNotBlank(freight.Product__c)) {
            uniqueIdentifier += freight.Product__c;
        }
        else if (String.isNotBlank(freight.ProductHierarchy__c)) {
            uniqueIdentifier += freight.ProductHierarchy__c;
        }
        if(String.isNotBlank(freight.City__c)) {
            uniqueIdentifier += freight.City__c;
        }
        else if (String.isNotBlank(freight.State__c)) {
            uniqueIdentifier += freight.State__c;
        }
        else if (String.isNotBlank(freight.Country__c)) {
            uniqueIdentifier += freight.Country__c;
        }
        uniqueIdentifier += freight.DistributionCenter__c;

        for(Freight__c oldFreight : freightStoredMap.values()) {
            if (oldFreight.UniqueIdentifier__c.equals(uniqueIdentifier) && freight.Name != oldFreight.Name) {
                freight.addError(System.label.DuplicatedFreightError + oldfreight.Name);
            }
        }
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
            String uniqueIdentifier = '';
            Integer score = 0;
            if (String.isNotBlank(freight.Product__c)) {
                score += 1000;
                uniqueIdentifier += freight.Product__c;
            }
            else if (String.isNotBlank(freight.ProductHierarchy__c)) {
                score += 500;
                uniqueIdentifier += freight.ProductHierarchy__c;
            }
            if(String.isNotBlank(freight.City__c)) {
                score += 200;
                uniqueIdentifier += freight.City__c;
            }
            else if (String.isNotBlank(freight.State__c)) {
                score += 100;
                uniqueIdentifier += freight.State__c;
            }
            else if (String.isNotBlank(freight.Country__c)) {
                score += 50;
                uniqueIdentifier += freight.Country__c;
            }
            freight.Score__c = score;
            freight.uniqueIdentifier__c = uniqueIdentifier+freight.DistributionCenter__c;
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