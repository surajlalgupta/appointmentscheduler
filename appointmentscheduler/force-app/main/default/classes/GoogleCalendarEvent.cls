public class GoogleCalendarEvent{
    @AuraEnabled
    public List<CalendarItem> items{get;set;}
    @AuraEnabled
    public String timeZone{get;set;}
    
    public class CalendarItem{
        @AuraEnabled
        public String id{get;set;}
        @AuraEnabled
        public String summary{get;set;}
        @AuraEnabled
        public DateTimeInfo start{get;set;}
        @AuraEnabled
        public DateTimeInfo x_end{get;set;}
    }
    
    public class DateTimeInfo{
        @AuraEnabled
        public String x_dateTime{get;set;}
    }
}