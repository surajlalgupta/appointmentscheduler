public class GoogleCalendarInfo{
    @AuraEnabled
    public List<CalendarItem> items{get;set;}
    
    public class CalendarItem{
        @AuraEnabled
        public String id{get;set;}
        @AuraEnabled
        public String summary{get;set;}
        @AuraEnabled
        public boolean primary{get;set;}
        @AuraEnabled
        public String timeZone{get;set;}
    }
}