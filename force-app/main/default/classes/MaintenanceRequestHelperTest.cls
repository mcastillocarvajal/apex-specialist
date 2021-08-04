
@isTest
public with sharing class MaintenanceRequestHelperTest {

    private static final String STATUS_NEW  = 'New';
    private static final String WORKING = 'Working';
    private static final String CLOSED = 'Closed';
    private static final String REPAIR = 'Repair';
    private static final String REQUEST_ORIGIN = 'Web';
    private static final String REQUEST_TYPE = 'Routine Maintenance';
    private static final String REQUEST_SUBJECT = 'Testing subject';

    PRIVATE STATIC Vehicle__c createVehicle(){

        Vehicle__c Vehicle = new Vehicle__c(name='Supertruck');
        return Vehicle;
    }
    PRIVATE STATIC Product2 createEq(){

        Product2 equipment = new Product2(name = 'SuperEquipment',
                                            lifespan_months__C = 10,
                                            maintenance_cycle__C = 10,
                                            replacement_part__c = true);
        return equipment;
    }

    PRIVATE STATIC Case createMaintenanceRequest(id vehicleId, id equipmentId){

        case cs = new Case(Type=REPAIR,
                            Status=STATUS_NEW,
                            Origin=REQUEST_ORIGIN,
                            Subject=REQUEST_SUBJECT,
                            Equipment__c=equipmentId,
                            Vehicle__c=vehicleId );
        return cs;                            
    }

    PRIVATE STATIC Equipment_Maintenance_Item__c createWorkPart(id equipmentId,id requestId){

        Equipment_Maintenance_Item__c wp = new Equipment_Maintenance_Item__c(Equipment__c = equipmentId,
                                                                            Maintenance_Request__c = requestId);
        return wp;
    }

    @isTest
    private static void testMaintenanceRequestPositive(){

        Vehicle__c Vehicle = createVehicle();
        insert Vehicle;
        id vehicleId = Vehicle.id;

        Product2 equipment = createEq();
        insert equipment;
        id equipmentId = equipment.id;

        case somethingToUpdate = createMaintenanceRequest(vehicleId, equipmentId);
        insert somethingToUpdate;

        Equipment_Maintenance_Item__c workP = createWorkPart(equipmentId, somethingToUpdate.id);
        insert workP;

        test.startTest();
        somethingToUpdate.status = CLOSED;
        update somethingToUpdate;
        test.stopTest();

        Case newReq = [Select id, subject, type, Equipment__c, Date_Reported__c, Vehicle__c, Date_Due__c
                        from case
                        where status =:STATUS_NEW];

        Equipment_Maintenance_Item__c workPart = [select id
                                                    from Equipment_Maintenance_Item__c
                                                    where Maintenance_Request__c =:newReq.Id];         
        System.assert(workPart != null );                                                    
        System.assert(newReq.Subject != null );                                                    
        System.assert(newReq.Type, REQUEST_TYPE );                                                    
        System.assert(newReq.Equipment__c, equipmentId );                                                    
        System.assert(newReq.Vehicle__c, vehicleId );                                                    
        System.assert(newReq.Date_Reported__c, system.today());                                                    
    }

    @isTest
    private static void testMaintenanceRequestNegative(){

        Vehicle__c Vehicle = createVehicle();
        insert Vehicle;
        id vehicleId = Vehicle.id;

        Product2 equipment = createEq();
        insert equipment;
        id equipmentId = equipment.id;

        case emptyReq = createMaintenanceRequest(vehicleId,equipmentId);
        insert emptyReq;

        Equipment_Maintenance_Item__c workP = createWorkPart(equipmentId, emptyReq.Id);
        insert workP;

        test.startTest();
        emptyReq.Status = WORKING;
        update emptyReq;
        test.stopTest();

        List<Case> allRequest = [SELECT id FROM Case];

        Equipment_Maintenance_Item__c workPart = [SELECT id FROM Equipment_Maintenance_Item__c
                                                    WHERE Maintenance_Cycle__c = :emptyReq.Id];

        System.assert(workPart != null );                                                    
        System.assert(allRequest.size() == 1);  
    }

    @isTest
    private static void testMaintenanceRequestBulk(){

        List<Vehicle__c> vehicleList = new List<Vehicle__c>();
        List<Product2> equipmentList = new List<Product2>();
        List<Equipment_Maintenance_Item__c> workPartList = new List<Equipment_Maintenance_Item__c>();
        List<Case> requestList = new List<Case>();
        List<id> oldRequestIds = new List<id>();
        
        for(integer i = 0; i < 300; i++){

            vehicleList.add(createVehicle());
            equipmentList.add(createEq());
        }
        insert vehicleList;
        insert equipmentList;

        for(integer i = 0; i < 300; i++){
            requestList.add(createMaintenanceRequest(vehicleList.get(i).id, equipmentList.get(i).id ));
        }
        insert requestList;

        for(integer i = 0; i < 300; i++){
            workPartList.add(createWorkPart(equipmentList.get(i).id, requestList.get(i).id));
        }
        insert workPartList;

        test.startTest();
        for(case req : requestList){
            req.Status = CLOSED;
            oldRequestIds.add(req.Id);
        }
        update requestList;
        test.stopTest();
        
        List<case> allRequests = [SELECT id FROM case WHERE status = :STATUS_NEW];

        List<Equipment_Maintenance_Item__c> workParts = [SELECT id FROM Equipment_Maintenance_Item__c WHERE Maintenance_Request__c IN :oldRequestIds];

        System.assert(allRequest.size() == 300);
    }                                               
}
