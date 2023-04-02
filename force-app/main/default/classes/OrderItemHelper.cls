public with sharing class OrderItemHelper {

    public static void checkOrderItem(List<OrderItem> orderItemList) {
        for (OrderItem orderItem : orderItemList) {
            if (orderItem.Quantity <= 0) {
                orderItem.addError('Quantidade não pode ser menor ou igual a zero.');
            }
            else if (orderItem.UnitPrice <= 0) {
                orderItem.addError('O preço não pode ser menor ou igual a zero.');
            }
        }
    }

    public static void checkOrderItem(Map<Id, OrderItem> oldOrderItemMap, Map<Id, OrderItem> newOrderItemMap) {
        List<OrderItem> orderItemUpdated = new List<OrderItem>();

        for (OrderItem newOrderItem : newOrderItemMap.values()) {
            OrderItem oldOrderitem = oldOrderItemMap.get(newOrderItem.Id);

            if ((newOrderItem.Quantity != oldOrderitem.Quantity) ||
                (newOrderItem.UnitPrice != oldOrderitem.UnitPrice)) {
                    orderItemUpdated.add(newOrderItem);
            }
        }

        if (!orderItemUpdated.isEmpty()) {
            checkOrderItem(orderItemUpdated);
        }
    }

    public static Map<String, Set<Id>> searchData(List<OrderItem> orderItemList) {
        Map<String, Set<Id>> setIdMap = new Map<String, Set<Id>>();

        Set<Id> productIdSet = new Set<Id>();
        Set<Id> orderIdSet = new Set<Id>();
        Set<Id> hierarchyIdSet = new Set<Id>();
        Set<Id> distributionIdSet = new Set<Id>();
        Set<Id> addressIdSet = new Set<Id>();
        Set<Id> cityIdSet = new Set<Id>();
        Set<Id> stateIdSet = new Set<Id>();
        Set<Id> countryIdSet = new Set<Id>();  
        Set<Id> accountsIdSet = new Set<Id>();
        Set<Id> groupIdSet = new Set<Id>();

        for (OrderItem orderItem : orderItemList) {
            productIdSet.add(orderItem.Product2Id);
            orderIdSet.add(orderItem.OrderId);
        }
        
        Map<Id, Order> orderMap = new Map<Id, Order>([
            SELECT Id, AccountId, DistributionCenter__c,
            Address__r.City__c,
            Address__r.City__r.State__c,
            Address__r.City__r.State__r.Country__c
            FROM Order
            WHERE Id IN: orderIdSet
        ]);
        
        for (Order order : orderMap.values()) {
            accountsIdSet.add(order.AccountId);
            distributionIdSet.add(order.DistributionCenter__c);
            addressIdSet.add(order.Address__c);
        }

        List<AccountAddress__c> addressList = [
            SELECT Id, Account__c, City__c
            FROM AccountAddress__c
            WHERE Id IN: addressIdSet
        ];

        for (AccountAddress__c address : addressList) {
            cityIdSet.add(address.City__c);
        }

        List<City__c> cityList = [
            SELECT Id, State__c
            FROM City__c
            WHERE Id IN: cityIdSet
        ];

        for (City__c city : cityList) {
            stateIdSet.add(city.State__c);
        }

        List<State__c> stateList = [
            SELECT Id, Country__c
            FROM State__c
            WHERE Id IN: stateIdSet
        ];

        for (State__c state : stateList) {
            countryIdSet.add(state.Country__c);
        }

        Map<Id, Product2> productMap = new Map<Id, Product2>([
            SELECT Id, ProductHierarchy__c, ProductionCost__c
            FROM Product2
            WHERE Id IN: productIdSet
        ]);

        for (Product2 product : productMap.values()) {
            hierarchyIdSet.add(product.ProductHierarchy__c);
        }

        List<Account> accountList = [
            SELECT Id, AccountGroup__c
            FROM Account
            WHERE Id IN: accountsIdSet
        ];

        for (Account account : accountList) {
            groupIdSet.add(account.AccountGroup__c);
        }

        setIdMap.put('productIdSet', productIdSet);
        setIdMap.put('orderIdSet', orderIdSet);
        setIdMap.put('hierarchyIdSet', hierarchyIdSet);
        setIdMap.put('distributionIdSet', distributionIdSet);
        setIdMap.put('addressIdSet', addressIdSet);
        setIdMap.put('cityIdSet', cityIdSet);
        setIdMap.put('stateIdSet', stateIdSet);
        setIdMap.put('countryIdSet', countryIdSet);
        setIdMap.put('accountsIdSet', accountsIdSet);
        setIdMap.put('groupIdSet', groupIdSet);
        return setIdMap;
    }

    // FRETE
    public static Map<OrderItem, Freight__c> searchFreight(List<OrderItem> orderItemList) {
        Map<String, Set<Id>> idSetMap = searchData(orderItemList);
        
        List<Freight__c> freightList = [
            SELECT Id, Product__c, ProductHierarchy__c, DistributionCenter__c, City__c, State__c, Country__c, Value__c, Score__c, Status__c
            FROM Freight__c
            WHERE (Product__c IN: idSetMap.get('roductIdSet') OR Product__c = null) AND 
            (ProductHierarchy__c IN: idSetMap.get('hierarchyIdSet') OR ProductHierarchy__c = null) AND
            (DistributionCenter__c IN: idSetMap.get('distributionIdSet') OR DistributionCenter__c = null) AND
            (City__c IN: idSetMap.get('cityIdSet') OR  City__c = null) AND
            (State__c IN: idSetMap.get('stateIdSet') OR  State__c = null) AND
            (Country__c IN: idSetMap.get('countryIdSet') OR  Country__c = null) AND Status__c = 'Aprovado'
            ORDER BY Score__c  DESC
        ];

        Map<Id, Order> orderMap = new Map<Id, Order>([
            SELECT Id, AccountId, DistributionCenter__c,
            Address__r.City__c,
            Address__r.City__r.State__c,
            Address__r.City__r.State__r.Country__c
            FROM Order
            WHERE Id IN: idSetMap.get('orderIdSet')
        ]);

        Map<Id, Product2> productMap = new Map<Id, Product2>([
            SELECT Id, ProductHierarchy__c, ProductionCost__c
            FROM Product2
            WHERE Id IN: idSetMap.get('productIdSet')
        ]);

        Map<OrderItem, Freight__c> orderItemToFreight = orderItemToFreigth(orderItemList, freightList, orderMap, productMap);

        return orderItemToFreight;
    }

    public static Map<OrderItem, Freight__c> orderItemToFreigth(List<OrderItem> orderItemList, List<Freight__c> freightList, Map<Id, Order> orderMap, Map<Id, Product2> productMap) {       
        Map<OrderItem, Freight__c> orderItemToFreight = new Map<OrderItem, Freight__c>();
         
        for(OrderItem orderItem: orderItemList) {
            orderItemToFreight.put(orderItem, null);

            for (Freight__c freight : freightList) {
                if(matchFreight(freight, OrderItem, orderMap, productMap)) {
                    orderItemToFreight.put(orderItem, freight);
                    break;
                }
            }
        }

        for (OrderItem orderItemWithFreight : orderItemToFreight.keySet()) {
            
            Freight__c freight = orderItemToFreight.get(orderItemWithFreight);
        
            if (freight != null) {
                orderItemWithFreight.Freight__c = freight.Id;
                orderItemWithFreight.FreightValue__c = freight.Value__c;
            }
        }
        return orderItemToFreight;
    }

    public static Boolean matchFreight (Freight__c freight, OrderItem orderItem, Map<Id, Order> orderMap, Map<Id, Product2> productMap) {
        Boolean product = (String.isBlank(freight.Product__c) || freight.Product__c == orderItem.Product2Id);
        Boolean hierarchy = (String.isBlank(freight.ProductHierarchy__c) || freight.ProductHierarchy__c == productMap.get(orderItem.Product2Id).ProductHierarchy__c);
        Boolean distribution = (String.isBlank(freight.DistributionCenter__c) || freight.DistributionCenter__c == orderMap.get(orderItem.OrderId).DistributionCenter__c);
        Boolean city = (String.isBlank(freight.City__c) || freight.City__c == orderMap.get(orderItem.OrderId).Address__r.City__c);
        Boolean state = (String.isBlank(freight.State__c) || freight.State__c == orderMap.get(orderItem.OrderId).Address__r.City__r.State__c);
        Boolean country = (String.isBlank(freight.Country__c) || freight.Country__c == orderMap.get(orderItem.OrderId).Address__r.City__r.State__r.Country__c);
        
        return (product || hierarchy) && (city || state || country) && distribution;
    }

    // Margem
    public static Map<OrderItem, Margin__c> searchMargin (List<OrderItem> orderItemList) {
        Map<String, Set<Id>> idSetMap = searchData(orderItemList);

        List<Margin__c> marginList = [
            SELECT Id, Product__c, ProductHierarchy__c, Account__c, AccountGroup__c, DistributionCenter__c, City__c, State__c, Country__c, Value__c, Score__c
            FROM Margin__c
            WHERE (Product__c IN: idSetMap.get('productIdSet') OR Product__c = null) AND 
            (ProductHierarchy__c IN: idSetMap.get('hierarchyIdSet') OR ProductHierarchy__c = null) AND
            (Account__c IN: idSetMap.get('accountsIdSet') OR Account__c = null) AND
            (AccountGroup__c IN: idSetMap.get('groupIdSet') OR AccountGroup__c = null) AND
            (DistributionCenter__c IN: idSetMap.get('distributionIdSet') OR DistributionCenter__c = null) AND
            (State__c IN: idSetMap.get('stateIdSet') OR  State__c = null) AND Status__c = 'Aprovado'
            ORDER BY Score__c DESC 
        ];

        Map<Id, Order> orderMap = new Map<Id, Order>([
            SELECT Id, AccountId, Account.AccountGroup__c, DistributionCenter__c,
            Address__r.City__c,
            Address__r.City__r.State__c,
            Address__r.City__r.State__r.Country__c
            FROM Order
            WHERE Id IN: idSetMap.get('orderIdSet')
        ]);

        Map<Id, Product2> productMap = new Map<Id, Product2>([
            SELECT Id, ProductHierarchy__c
            FROM Product2
            WHERE Id IN: idSetMap.get('productIdSet')
        ]);

        Map<OrderItem, Margin__c> orderItemToMargin = orderItemToMargin(orderItemList, MarginList, orderMap, productMap);

        return orderItemToMargin;
    }

    public static Map<OrderItem, Margin__c> orderItemToMargin(List<OrderItem> orderItemList, List<Margin__c> marginList, Map<Id, Order> orderMap,  Map<Id, Product2> ProductMap) {
        
        Map<OrderItem, Margin__c> orderItemToMargin = new Map<OrderItem, Margin__c>();

        for(OrderItem orderItem: orderItemList) {
            orderItemToMargin.put(orderItem, null);

            for(Margin__c margin : marginList) {

                if(matchMargin(margin, OrderItem, orderMap, productMap)) {
                    orderItemToMargin.put(orderItem, margin);
                    break;
                }
            }
        }
    
        for(OrderItem orderItem : orderItemToMargin.keySet()) {
            Margin__c priceMargin = orderItemToMargin.get(orderItem);

            if(priceMargin != null) {
                orderItem.MarginPercentage__c = priceMargin.Value__c;
            }
        }
        return orderItemToMargin;
    }
 
    public static Boolean matchMargin(Margin__c margin, OrderItem orderItem, Map<Id, Order> orderMap, Map<Id, Product2> productMap) {    
        Boolean product = (String.isBlank(margin.Product__c) || margin.Product__c == orderItem.Product2Id);
        Boolean hierarchy = (String.isBlank(margin.ProductHierarchy__c) || margin.ProductHierarchy__c == productMap.get(orderItem.Product2Id).ProductHierarchy__c);
        Boolean account = (String.isBlank(margin.Account__c) || margin.Account__c == orderMap.get(orderItem.OrderId).AccountId);
        Boolean accountGroup = (String.isBlank(margin.AccountGroup__c) || margin.AccountGroup__c == orderMap.get(orderItem.OrderId).Account.AccountGroup__c);
        Boolean distribution = (String.isBlank(margin.DistributionCenter__c) || margin.DistributionCenter__c == orderMap.get(orderItem.OrderId).DistributionCenter__c);
        Boolean city = (String.isBlank(margin.City__c) || margin.City__c == orderMap.get(orderItem.OrderId).Address__r.City__c);
        Boolean state = (String.isBlank(margin.State__c) || margin.State__c == orderMap.get(orderItem.OrderId).Address__r.City__r.State__c);
        Boolean country = (String.isBlank(margin.Country__c) || margin.Country__c == orderMap.get(orderItem.OrderId).Address__r.City__r.State__r.Country__c);
        
        return (product || hierarchy) && (account || accountGroup) && (city || state || country) && distribution;
    }

    // IMPOSTO - SELECIONAR O IMPOSTO COM BASE NO PRODUTO, CENTRO DE DISTRIBUIÇÃO E ESTADO 
    public static Map<OrderItem, Tax__c> searchTax(List<OrderItem> orderItemList) {
        Map<String, Set<Id>> idSetMap = searchData(orderItemList);

        Map<Id, Order> orderMap = new Map<Id, Order>([
            SELECT Id, DistributionCenter__c, Address__r.City__r.State__c
            FROM Order
            WHERE Id IN: idSetMap.get('orderIdSet')
        ]);
        
        List<Tax__c> taxList = [
            SELECT Id, Product__c, DistributionCenter__c, State__c, TaxCost__c, Status__c
            FROM Tax__c
            WHERE Status__c = 'Aprovado'
        ];

        Map<OrderItem, Tax__c> orderItemToTax = orderItemToTax(orderItemList, taxList, orderMap);

        return orderItemToTax;
    }

    public static Map<OrderItem, Tax__c> orderItemToTax(List<OrderItem> orderItemList, List<Tax__c> taxList, Map<Id, Order> orderMap) {
        Map<OrderItem, Tax__c> orderItemToTax = new Map<OrderItem, Tax__c>();

        for(OrderItem orderItem: orderItemList) {
            orderItemToTax.put(orderItem, null);

            for(Tax__c tax : taxList) {
                if(matchTax(tax, OrderItem, orderMap)) {
                    orderItemToTax.put(orderItem, tax);
                    break;
                }
            }
        }

        for (OrderItem orderItemWithTax : orderItemToTax.keySet()) {   
            Tax__c tax = orderItemToTax.get(orderItemWithTax);

            if (tax != null) {
               orderItemWithTax.TaxPercentage__c = tax.TaxCost__c;
            }
        }
        return orderItemToTax;  
    }

    public static Boolean matchTax(Tax__c tax, OrderItem orderItem, Map<Id, Order> orderMap) {
        return (tax.Product__c == orderItem.Product2Id) &&
        (tax.DistributionCenter__c == orderMap.get(orderItem.OrderId).DistributionCenter__c) &&
        (tax.State__c == orderMap.get(orderItem.OrderId).Address__r.City__r.State__c);
    }

    public static void calcValues(List<OrderItem> orderItemList) { 
        calcCost(orderItemList);
        for (OrderItem orderItem : orderItemList) {
            calcPrices(orderItem);
        }       
    }

    public static void calcCost(List<orderItem> orderItemList) {
       
        Map<String, Set<Id>> idSetMap = searchData(orderItemList);
        
        List<Product2> productList = [
            SELECT Id, ProductionCost__c FROM Product2 WHERE Id IN: idSetMap.get('productIdSet')
        ];

        for (OrderItem orderitem : orderItemList) {
            for (Product2 product : productList) {
                if (orderItem.Product2Id == product.Id)
                    orderItem.ProductionCost__c = product.ProductionCost__c;
            }
        }
    }

    public static void calcPrices(OrderItem orderitem) {
        if (orderItem.ProductionCost__c != null && orderItem.FreightValue__c != null) {
            orderItem.PriceWithoutMargin__c = ((orderItem.ProductionCost__c + orderItem.FreightValue__c) * (1 + (orderItem.TaxPercentage__c / 100)));
            orderItem.FinalPrice__c = ((orderItem.ProductionCost__c + orderItem.FreightValue__c) * (1 + (orderItem.TaxPercentage__c/100)) * (1 + (orderItem.MarginPercentage__c / 100)));
            orderItem.Discount__c = ((orderItem.FinalPrice__c - orderItem.UnitPrice) / orderItem.FinalPrice__c) * 100;
            orderItem.TotalPriceFinal__c = orderItem.Quantity * OrderItem.FinalPrice__c;
        } else {
            orderItem.PriceWithoutMargin__c = 0.0;
            orderItem.FinalPrice__c = 0.0;     
        }
    }
}