public with sharing class AccountHelper {
    
    public static void checkCnpj(List<Account> accountList) {
        for (Account account : accountList) {
            if (String.isNotBlank(account.Cnpj__c)) {
                if (!cnpjValidator(account)) {
                    account.addError('CNPJ inválido');
                }
                else {
                    cnpjFormat(account);
                    checkCnjpDuplicate(account);
                }
            }
            else {
                account.addError('O campo CNPJ é obrigatório!');
            }
        }
    }

    public static void checkCnpj(Map<Id, Account> oldMap, Map<Id, Account> newMap) {
        List<Account> accountListUpdated = new List<Account>();
        for (Account newAccount : newMap.values()) {
            Account oldAccount = oldMap.get(newAccount.Id);
            
            if (newAccount.Cnpj__c != oldAccount.Cnpj__c) {
                accountListUpdated.add(newAccount);
            }
        }
        if(!accountListUpdated.isEmpty()) checkCnpj(accountListUpdated);
    }
    
    public static void checkCnjpDuplicate(Account account) {
        Map<Id, Account> accountStoredMap = new Map<Id, Account>([
            SELECT Id, Name, Cnpj__c
            FROM Account
            WHERE Cnpj__c <> null
        ]);

        for (Account oldAccount : accountStoredMap.values()) {
            String oldCnpj = oldAccount.Cnpj__c.replaceAll('[^0-9]', '');
            String newCnpj = account.Cnpj__c.replaceAll('[^0-9]', '');
           
            if (newCnpj.equals(oldCnpj)) {
                account.addError('CNJP já cadastrado para a conta ' + oldAccount.Name);
            }
        }    
    }

    public static Boolean cnpjValidator(Account Account) {
        String cnpj = account.Cnpj__c;
        cnpj = cnpj.replaceAll('[^0-9]', '');

        if (cnpj.equals('00000000000000') || cnpj.equals('11111111111111') ||
        cnpj.equals('22222222222222') || cnpj.equals('33333333333333') ||
        cnpj.equals('44444444444444') || cnpj.equals('55555555555555') ||
        cnpj.equals('66666666666666') || cnpj.equals('77777777777777') ||
        cnpj.equals('88888888888888') || cnpj.equals('99999999999999') ||
       (cnpj.length() != 14))
       return false;

        Integer sm, i, r, num, peso, dig13, dig14;
        List<String> cnpjString = cnpj.split('');
        sm = 0;
        peso = 2;
        for (i=11; i>=0; i--) {
            num = Integer.valueOf(cnpjString[i]);
            sm = sm + (num * peso);
            peso = peso + 1;
            if (peso == 10)
                peso = 2;
        }

        r = math.mod(sm, 11);
        if ((r == 0) || (r == 1))
            dig13 = 0;
        else dig13 = Integer.valueOf(11-r);
        sm = 0;
        peso = 2;
        for (i=12; i>=0; i--) {
            num = Integer.valueOf(cnpjString[i]);
            sm = sm + (num * peso);
            peso = peso + 1;
            if (peso == 10)
                peso = 2;
      }

        r = math.mod(sm, 11);
        if ((r == 0) || (r == 1))
            dig14 = 0;
        else dig14 = Integer.valueOf(11-r);
        if (dig13 == Integer.valueOf(cnpjString[12]) && dig14 == Integer.valueOf(cnpjString[13]))
        
         return true;
        else return false ;
    }

    public static String cnpjFormat(Account account) {
        String cnpj = account.Cnpj__c;
        String cnpjFormatted = cnpj.replaceAll('(\\d{2})(\\d{3})(\\d{3})(\\d{4})(\\d{2})', '$1.$2.$3/$4-$5');
        account.Cnpj__c = cnpjFormatted;
        return cnpjFormatted;
    }
}