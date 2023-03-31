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

    // FRETE - CORREÇÃO DE BUGS  
    public static Map<OrderItem, Freight__c> searchFreight(List<OrderItem> orderItemList) {
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

        List<Freight__c> freightList = [
            SELECT Id, Product__c, ProductHierarchy__c, DistributionCenter__c, City__c, State__c, Country__c, Value__c, Score__c, Status__c
            FROM Freight__c
            WHERE (Product__c IN: productIdSet OR Product__c = null) AND 
            (ProductHierarchy__c IN: hierarchyIdSet OR ProductHierarchy__c = null) AND
            (DistributionCenter__c IN: distributionIdSet OR DistributionCenter__c = null) AND
            (City__c IN: cityIdSet OR  City__c = null) AND
            (State__c IN: stateIdSet OR  State__c = null) AND
            (Country__c IN: countryIdSet OR  Country__c = null) 
            ORDER BY Score__c  DESC
        ];

        Map<OrderItem, Freight__c> orderItemToFreight = new Map<OrderItem, Freight__c>();

        for(OrderItem orderItem: orderItemList) {
            orderItemToFreight.put(orderItem, null);

            for(Freight__c freight : freightList) {
                if(matchFreight(freight, OrderItem, orderMap, productMap)) {
                    orderItemToFreight.put(orderItem, freight);
                    System.debug('matchFreight => ' + matchFreight(freight, OrderItem, orderMap, productMap));
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

        calcPrice(orderItemList, productMap.values());

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
    public static void searchMargin (List<OrderItem> orderItemList) {
        Set<Id> orderIdSet = new Set<Id>();
        Set<Id> productIdSet = new Set<Id>();

        for (OrderItem orderItem : orderItemList) {
            orderIdSet.add(orderItem.OrderId);
            productIdSet.add(orderItem.product2Id);
        }

        Map<Id, Order> orderMap = new Map<Id, Order>([
            SELECT Id, AccountId, Account.AccountGroup__c, DistributionCenter__c,
            Address__r.City__c,
            Address__r.City__r.State__c,
            Address__r.City__r.State__r.Country__c
            FROM Order
            WHERE Id IN: orderIdSet
        ]);

        Map<Id, Product2> productMap = new Map<Id, Product2>([
            SELECT Id, ProductHierarchy__c
            FROM Product2
            WHERE Id IN: productIdSet
        ]);

        Map<OrderItem, Margin__c> orderItemToMargin = searchMargin(orderItemList, orderMap, productMap);

        for(OrderItem orderItem : orderItemToMargin.keySet()) {
            Margin__c priceMargin = orderItemToMargin.get(orderItem);

            if(priceMargin != null) {
                orderItem.MarginPercentage__c = priceMargin.Value__c;

            }
        }
        //return new List<OrderItem> (orderItemToMargin.keySet());
    }

    public static Map<OrderItem, Margin__c> searchMargin(List<OrderItem> orderItemList,  Map<Id, Order> orderMap,  Map<Id, Product2> ProductMap) {
        Set<Id> productIdSet = new Set<Id>();
        Set<Id> hierarchyIdSet = new Set<Id>();
        Set<Id> accountsIdSet = new Set<Id>();
        Set<Id> groupIdSet = new Set<Id>();
        Set<Id> distributionIdSet = new Set<Id>();
        Set<Id> stateIdSet = new Set<Id>();

        for (Order order : orderMap.values()) {
            accountsIdSet.add(order.AccountId);
            groupIdSet.add(order.Account.AccountGroup__c);
            distributionIdSet.add(order.DistributionCenter__c);
        }

        for (Product2 product : productMap.values()) {
            productIdSet.add(product.Id);
            productIdSet.add(product.ProductHierarchy__c);
        }

        List<Margin__c> MarginList = [
            SELECT Id, Product__c, ProductHierarchy__c, Account__c, AccountGroup__c, DistributionCenter__c, City__c, State__c, Country__c, Value__c, Score__c
            FROM Margin__c
            WHERE (Product__c IN: productIdSet OR Product__c = null) AND 
            (ProductHierarchy__c IN: hierarchyIdSet OR ProductHierarchy__c = null) AND
            (Account__c IN: accountsIdSet OR Account__c = null) AND
            (AccountGroup__c IN: groupIdSet OR AccountGroup__c = null) AND
            (DistributionCenter__c IN: distributionIdSet OR DistributionCenter__c = null) AND
            (State__c IN: stateIdSet OR  State__c = null) 
            ORDER BY Score__c DESC 
        ];

        Map<OrderItem, Margin__c> orderItemToMargin = new Map<OrderItem, Margin__c>();

        for(OrderItem orderItem: orderItemList) {
            orderItemToMargin.put(orderItem, null);

            for(Margin__c margin : MarginList) {
                if(matchMargin(margin, OrderItem, orderMap, productMap)) {
                    orderItemToMargin.put(orderItem, margin);
                    break;
                }
            }
        }
        return orderItemToMargin;
    }
 
    public static Boolean matchMargin(Margin__c margin, OrderItem orderItem, Map<Id, Order> orderMap, Map<Id, Product2> productMap) {
        return (String.isBlank(margin.Product__c) || margin.Product__c == orderItem.Product2Id) &&
        (String.isBlank(margin.ProductHierarchy__c) || margin.ProductHierarchy__c == productMap.get(orderItem.Product2Id).ProductHierarchy__c) &&
        (String.isBlank(margin.Account__c) || margin.Account__c == orderMap.get(orderItem.OrderId).AccountId) &&
        (String.isBlank(margin.AccountGroup__c) || margin.AccountGroup__c == orderMap.get(orderItem.OrderId).Account.AccountGroup__c) &&
        (String.isBlank(margin.DistributionCenter__c) || margin.DistributionCenter__c == orderMap.get(orderItem.OrderId).DistributionCenter__c) &&
        (String.isBlank(margin.City__c) || margin.City__c == orderMap.get(orderItem.OrderId).Address__r.City__c) &&
        (String.isBlank(margin.State__c) || margin.State__c == orderMap.get(orderItem.OrderId).Address__r.City__r.State__c) &&
        (String.isBlank(margin.Country__c) || margin.Country__c == orderMap.get(orderItem.OrderId).Address__r.City__r.State__r.Country__c);
    }

    // IMPOSTO
    /**
        SELECIONAR O IMPOSTO COM BASE NO PRODUTO, CENTRO DE DISTRIBUIÇÃO E ESTADO 
     */
    public static Map<OrderItem, Tax__c> searchTax(List<OrderItem> orderItemList) {
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

        List<Tax__c> taxList = [
            SELECT Id, Product__c, DistributionCenter__c, State__c, TaxCost__c, Status__c
            FROM Tax__c
            WHERE Status__c = 'Aprovado'
        ];

        System.debug('TaxList => ' + taxList);

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
            System.debug('OrderItem with tax => ' + tax);
            
            System.debug('OrderItem => ' + orderItemWithTax);
            System.debug('Tax => ' + tax);
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

    public static void calcPrice(List<OrderItem> orderItemList, List<Product2> productList) {
        
        Map<OrderItem, Product2> calcProductPriceMap= new Map<OrderItem, Product2>();

        for(OrderItem orderItem: orderItemList) {
            calcProductPriceMap.put(orderItem, null);

            for(Product2 product : productList) {
                if (orderItem.Product2Id == product.Id) {
                    calcProductPriceMap.put(orderItem, product);
                }
            }
        }

        for (OrderItem orderItemPrice : calcProductPriceMap.keySet()) {
            
            Product2 product = calcProductPriceMap.get(orderItemPrice);
        
            if (product != null) {
                orderItemPrice.ProductionCost__c = product.ProductionCost__c;
                // orderItemPrice.PriceWithoutMargin__c = ((product.ProductionCost__c + orderItemPrice.FreightValue__c) * (1 + (orderItemPrice.TaxPercentage__c / 100)));
                // orderItemPrice.FinalPrice__c = (orderItemPrice.ProductionCost__c + orderItemPrice.FreightValue__c) * (1 + (orderItemPrice.TaxPercentage__c/100)) * (1 + (orderItemPrice.MarginPercentage__c / 100));
                // orderItemPrice.Discount__c = (orderItemPrice.FinalPrice__c - orderItemPrice.UnitPrice) / orderItemPrice.FinalPrice__c;
            }
        }
    }
}