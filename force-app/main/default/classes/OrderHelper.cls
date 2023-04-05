public with sharing class OrderHelper {
    public static void blockAccountUpdated(Map<Id, Order> oldMap, Map<Id, Order> newMap) {
        for (Order newOrder : newMap.values()) {
            Order oldOrder = oldMap.get(newOrder.Id);

            if (newOrder.AccountId != oldOrder.AccountId)
                newOrder.addError('Não é possível atualizar a conta do pedido');
        }
    }

    public static void blockOrderUpdated(Map<Id, Order> oldMap, Map<Id, Order> newMap) {
        for (Order newOrder : newMap.values()) {
            Order oldOrder = oldMap.get(newOrder.Id);

            if (oldOrder.Status == 'Activated' && oldMap.values() != oldMap.values()) {
                newOrder.addError('Status não permite edição.');
            }
        }       
    }
}