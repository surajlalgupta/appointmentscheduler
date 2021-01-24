public with sharing class PhysicianCalendarController {
	@AuraEnabled
    public Static List<GoogleCalendarEvent.CalendarItem> getEvents(String email){
        if (String.isBlank(email)){
            return new List<GoogleCalendarEvent.CalendarItem>();
        }
        try{
            String primaryCalendarId = GoogleCalendarManager.getPrimaryCalendarId(email);
            String startTime = String.valueOf(system.today())+'T00:00:00-05:30';
            String endTime = String.valueOf(system.today()+7)+'T00:00:00-05:30';
            GoogleCalendarEvent calEvent = GoogleCalendarManager.getCalendarEvents(email, startTime, endTime, primaryCalendarId);
            return calEvent.items;
        }
        catch (AuraHandledException ex){
            System.debug(ex.getStackTraceString());
            throw ex;
        }
        catch (Exception ex){
            System.debug(ex.getStackTraceString());
            throw new AuraHandledException('There was some issue while fetching booking details');
        }
    }
    
    @AuraEnabled
    public static String createEvent(String email, String startTime, String endTime, String summary, String patientId, String specialization){
        try{
            String primaryCalendarId = GoogleCalendarManager.getPrimaryCalendarId(email);
            startTime += '+05:30';
            String timeZone = 'Asia/Kolkata';
            endTime += '+05:30';
            String retVal = GoogleCalendarManager.insertCalendarEvent(primaryCalendarId, summary, startTime, endTime, timeZone, email);
            system.debug(retVal);
            if (String.isNotBlank(retVal)){
                createAppointment(email, patientId, summary, startTime, endTime, specialization, retVal);
                return retVal;
            }
            else{
                throw new AuraHandledException('Appointment booking failed');
            }
        }
        catch (AuraHandledException ex){
            System.debug(ex.getStackTraceString());
            throw ex;
        }
        catch (Exception ex){
            System.debug(ex.getStackTraceString());
            throw new AuraHandledException('There was some issue while booking appointment');
        }
    }
    
    public static void createAppointment(String email, String patientId, String summary, String startTime, String endTime, String specializationName, String eventId){
        Physician__c physician = [Select Id from Physician__c where Email__c = :email limit 1];
        Specialization__c specialization = [Select Id from Specialization__c where Name = :specializationName limit 1];
        Patient__c patient = [Select Id, Email__c from Patient__c where Id = :patientId limit 1];
        Appointment__c appointment = new Appointment__c(Patient__c = patientId, 
                                                        Physician__c = physician.Id, 
                                                        Summary__c = summary, Status__c = 'Active', 
                                                        Specialization__c=specialization.Id, 
                                                        StartTime__c = startTime, 
                                                        EndTime__c = endTime,
                                                        EventId__c = eventId,
                                                        Patient_Email__c = patient.Email__c);
        insert appointment;
    }
    
    @AuraEnabled
    public static String updatePatient(String relationshipNumber, String patientName, String patientEmail, Date patientDOB){
        try{
            if (String.isNotBlank(relationshipNumber)){
                List<Patient__c> patients = [Select Id from Patient__c where name = :relationshipNumber limit 1];
                if (patients != null && patients.size() > 0){
                    return patients[0].Id;
                }
                else{
                    throw new AuraHandledException('Patient with RN: '+relationshipNumber +' was not found. Please enter a valid RN');
                }
            }
            else{
                if (String.isNotBlank(patientName) && String.isNotBlank(patientEmail) && patientDOB != null){
                    Patient__c patient = new Patient__c(Name__c = patientName, Email__c = patientEmail, DOB__c = patientDOB);
                    insert patient;
                    return patient.Id;
                }
                else{
                    throw new AuraHandledException('Patient details are missing.');
                }
            }
        }
        catch (AuraHandledException ex){
            System.debug(ex.getStackTraceString());
            throw ex;
        }
        catch (Exception ex){
            System.debug(ex.getStackTraceString());
            throw new AuraHandledException('There was some issue while updating patient details');
        }
    }
    
    @AuraEnabled
    public static void deleteEvent(String email, String id){
        try{
            String primaryCalendarId = GoogleCalendarManager.getPrimaryCalendarId(email);
            GoogleCalendarManager.deleteCalendarEvent(primaryCalendarId, id, email);
            List<Appointment__c> appointments = [Select Id, Status__c from Appointment__c where EventId__c = :id limit 1];
            if (appointments != null && appointments.size() > 0){
                appointments[0].Status__c = 'Cancelled';
                update appointments[0];
            }
        }
        catch (AuraHandledException ex){
            System.debug(ex.getStackTraceString());
            throw ex;
        }
        catch (Exception ex){
            System.debug(ex.getStackTraceString());
            throw new AuraHandledException('There was some issue while cancelling appointment');
        }
    }
    
    
}