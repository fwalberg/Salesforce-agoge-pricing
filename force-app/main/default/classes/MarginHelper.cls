public with sharing class MarginHelper {
    public static void validateMarginCategory(List<Margin__c> marginList) {
        for (Margin__c margin : marginList) {
            if (!validateProductCategories(margin)) margin.addError('Verifique o preenchimento das informações do produto');
            else if (!validateAccountCategories(margin)) margin.addError('Verifique o preenchimento das informações do Cliente');
            else if (!validateLocaleCategories(margin))  margin.addError('Verifique o preenchimento das informações de localidade');
        }
    }

    public static void validateMarginCategory(Map<Id, Margin__c> oldMap, Map<Id, Margin__c> newMap) {
        List<Margin__c> marginList = new List<Margin__c>();

        for (Margin__c newMargin : newMap.values()) {
            Margin__c oldMargin = oldMap.get(newMargin.Id);

            if ((newMargin.Product__c != oldMargin.Product__c) ||
                (newMargin.ProductHierarchy__c != oldMargin.ProductHierarchy__c) ||
                (newMargin.Account__c != oldMargin.Account__c) ||
                (newMargin.AccountGroup__c != oldMargin.AccountGroup__c) ||
                (newMargin.City__c != oldMargin.City__c) ||
                (newMargin.State__c != oldMargin.State__c) ||
                (newMargin.Country__c != oldMargin.Country__c)        
            ) marginList.add(newMargin);
        }
        validateMarginCategory(marginList);
        calcScore(marginList);
    }
    
    public static Boolean validateProductCategories(Margin__c margin) {
        if ((String.isBlank(margin.Product__c) && String.isBlank(margin.ProductHierarchy__c)) ||
            (String.isNotBlank(margin.Product__c) && String.isNotBlank(margin.ProductHierarchy__c))      
        ) return false;
        return true;
    }

    public static Boolean validateAccountCategories(Margin__c margin) {
        if ((String.isBlank(margin.Account__c) && String.isBlank(margin.AccountGroup__c)) ||
            (String.isNotBlank(margin.Account__c) && String.isNotBlank(margin.AccountGroup__c))      
        ) return false;
        return true;
    }

    public static Boolean validateLocaleCategories(Margin__c margin) {
        if ((String.isBlank(margin.City__c) && String.isBlank(margin.State__c) && (String.isBlank(margin.Country__c))) ||
            (String.isNotBlank(margin.City__c) && (String.isNotBlank(margin.State__c) || (String.isNotBlank(margin.Country__c)))) ||
            (String.isNotBlank(margin.State__c) && (String.isNotBlank(margin.City__c) || (String.isNotBlank(margin.Country__c))))     
        ) return false;
        return true;
    }

    public static void validateMarginCategory(List<Margin__c> oldRecords, List<Margin__c> newRecords) {
        if (newRecords.hashCode() != oldRecords.hashCode()) {
            validateMarginCategory(newRecords);
        }
    }

    public static void calcScore(List<Margin__c> marginList) {
        Integer score = 0;
        for (Margin__c margin : marginList) {
            if (String.isNotBlank(margin.Product__c)) score += 2000;
            else if (String.isNotBlank(margin.ProductHierarchy__c)) score += 1000;
    
            if (String.isBlank(margin.Account__c)) score += 500;
            else if (String.isBlank(margin.AccountGroup__c)) score += 200;

            if (String.isNotBlank(margin.City__c)) score += 100;
            else if (String.isNotBlank(margin.State__c)) score += 50;
            else if (String.isNotBlank(margin.Country__c)) score += 25;
            margin.Score__c = score;
        }    
    }
}