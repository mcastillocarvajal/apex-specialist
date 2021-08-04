
@isTest
private class WarehouseCalloutServiceTest {

    @isTest
    static void testWareHouseCallout() {

        test.startTest();

        //implement mock callout test here
        test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());
        WarehouseCalloutService.runWarehouseEquipmentSync();
        test.stopTest();
        System.assert(1, [SELECT count() FROM Product2]);
    }
}
