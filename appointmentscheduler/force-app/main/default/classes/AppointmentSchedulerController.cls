public with sharing class AppointmentSchedulerController {
    @AuraEnabled(cacheable=true)
    public static List<Specialization__c> getSpecializations(){
        try{
        	return [Select Id, Name, Description__c, Consultation_Fee__c, (Select Id, Physician_Name__c, Physician_Email__c from PhysicianSpecializations__r) from Specialization__c];
        }
        catch (AuraHandledException ex){
            System.debug(ex.getStackTraceString());
            throw ex;
        }
        catch (Exception ex){
            System.debug(ex.getStackTraceString());
            throw new AuraHandledException('There was some issue while fetching specialization details');
        }
    }
}