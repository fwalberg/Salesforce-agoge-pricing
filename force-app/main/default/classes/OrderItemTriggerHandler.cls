public with sharing class OrderItemTriggerHandler {
    List<OrderItem> oldRecords {get; set;}
    List<OrderItem> newRecords {get; set;}
    Map<Id, OrderItem> oldMap {get; set;}
    Map<Id, OrderItem> newMap {get; set;}

    public OrderItemTriggerHandler(List<OrderItem> oldRecords, List<OrderItem> newRecords, Map<Id, OrderItem> oldMap, Map<Id, OrderItem> newMap) {
        this.oldRecords = oldRecords;
        this.newRecords = newRecords;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }

    public void beforeInsert() {
        OrderItemHelper.checkOrderItem(this.newRecords);
        OrderItemHelper.searchFreight(this.newRecords);
        OrderItemHelper.searchMargin(this.newRecords);
        OrderItemHelper.searchTax(this.newRecords);
        OrderItemHelper.calcValues(this.newRecords);

    }

    public void beforeUpdate() {
        OrderItemHelper.checkOrderItem(this.oldMap, this.newMap);
        OrderItemHelper.updateOrderItem(this.oldMap, this.newMap);
    }
}