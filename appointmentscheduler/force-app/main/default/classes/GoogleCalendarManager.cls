public class GoogleCalendarManager{
    public static final String BEARER = 'Bearer ';
    public static final String AUTHORIZATION = 'Authorization';
    public static Map<String, String> primaryCalendarMap = new Map<String, String>();
    public static String getPrimaryCalendarId(String email){
        try{
            if(primaryCalendarMap.get(email) != null){
                return primaryCalendarMap.get(email);
            }
            String accessToken = GoogleAPITokenManager.getAccessToken(email);
            String bearerToken = BEARER+accessToken; 
            if(String.isNotBlank(accessToken)){
                String calendarList_URL = System.Label.Google_APIs_CalendarList_URL;
                Http http = new Http();
                HttpRequest req = new HttpRequest();
                req.setMethod('GET');
                req.setEndpoint(calendarList_URL);
                req.setHeader(AUTHORIZATION, bearerToken);
                HttpResponse resp = http.send(req);
                if(resp.getStatusCode() >= 200 && resp.getStatusCode() < 300){
                    GoogleCalendarInfo calendarObj = (GoogleCalendarInfo)JSON.deserialize(resp.getBody(), GoogleCalendarInfo.class);
                    List<GoogleCalendarInfo.CalendarItem> items = calendarObj.items;
                    if (items != null && items.size() > 0){
                        for (GoogleCalendarInfo.CalendarItem item: items){
                            system.debug(item);
                            if (item.primary != null && item.primary == true){
                                primaryCalendarMap.put(email, item.id);
                                return item.id;
                            }
                        }
                    }
                    throw new PrimaryCalendarMissingException('Primary calendar does not exist');
                }
                else{
                    throw new CustomException('There was some issue while fetching primary calendar');
                }
            }
            else{
                throw new MissingOAuthTokenException('Oauth token is missing');
            }
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
            throw ex;
        }
    }
    
    public static String insertCalendarEvent(String calendarId, String summary, String startTime, String endTime, String timeZone, String email){
        try{
            InsertEventRequest requestObj = new InsertEventRequest();
            requestObj.summary = summary;
            DateTimeInfo start = new DateTimeInfo(timeZone, startTime);
            DateTimeInfo x_end = new DateTimeInfo(timeZone, endTime);
            requestObj.start = start;
            requestObj.x_end = x_end;
            
            String requestBody = JSON.serialize(requestObj);
            requestBody = requestBody.replace('x_dateTime', 'dateTime')
                          .replace('x_end', 'end');
                          
            String accessToken = GoogleAPITokenManager.getAccessToken(email);
            if(String.isNotBlank(accessToken)){
                String bearerToken = BEARER+accessToken;              
                String event_URL = System.Label.Google_APIs_InsertEvent_URL;
                event_URL = event_URL.replace('{!CALENDAR_ID}', calendarId);
                Http http = new Http();
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndpoint(event_URL);
                req.setHeader(AUTHORIZATION, bearerToken);
                system.debug(requestBody);
                req.setBody(requestBody);
                HttpResponse resp = http.send(req);  
                if (resp.getStatusCode() >= 200 && resp.getStatusCode() < 300){
                    GoogleCalendarEvent.CalendarItem item = (GoogleCalendarEvent.CalendarItem)JSON.deserialize(resp.getBody(), GoogleCalendarEvent.CalendarItem.class);
                    system.debug(item);
                    return item.id;
                }
                else{
                    throw new CustomException('There was some issue while booking appointment');
                }
            }
            else{
                throw new MissingOAuthTokenException('Oauth token is missing');
            }
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
            throw ex;
        }    
    }
    
    public static void deleteCalendarEvent(String calendarId, String eventId, String email){
        try{
            String accessToken = GoogleAPITokenManager.getAccessToken(email);
            if(String.isNotBlank(accessToken)){
                String bearerToken = BEARER+accessToken;              
                String event_URL = System.Label.Google_APIs_InsertEvent_URL;
                event_URL = event_URL.replace('{!CALENDAR_ID}', calendarId);
                event_URL += '/'+eventId;
                Http http = new Http();
                HttpRequest req = new HttpRequest();
                req.setMethod('DELETE');
                req.setEndpoint(event_URL);
                req.setHeader(AUTHORIZATION, bearerToken);
                HttpResponse resp = http.send(req);
                if (resp.getStatusCode() > 299){
                    throw new CustomException('There was some issue while cancelling appointment');
                }
            }
            else{
                throw new MissingOAuthTokenException('Oauth token is missing');
            }
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
            throw ex;
        }    
    }
    
    public static GoogleCalendarEvent getCalendarEvents(String email, String startTime, String endTime, String calendarId){
        try{        
            String accessToken = GoogleAPITokenManager.getAccessToken(email);
            if(String.isNotBlank(accessToken)){
                String bearerToken = BEARER+accessToken;              
                String event_URL = System.Label.Google_APIs_InsertEvent_URL;
                event_URL += '?timeMin='+startTime;
                event_URL += '&timeMax='+endTime;
                event_URL = event_URL.replace('{!CALENDAR_ID}', calendarId);
                Http http = new Http();
                HttpRequest req = new HttpRequest();
                req.setMethod('GET');
                req.setEndpoint(event_URL);
                req.setHeader(AUTHORIZATION, bearerToken);
                HttpResponse resp = http.send(req);  
                if (resp.getStatusCode() >= 200 && resp.getStatusCode() < 300){
                    String responseBody = resp.getBody();
                    responseBody = responseBody.replace('dateTime', 'x_dateTime')
                                   .replace('end', 'x_end');
                    GoogleCalendarEvent event = (GoogleCalendarEvent)JSON.deserialize(responseBody, GoogleCalendarEvent.class);
                    return event;
                }
                else{
                    throw new CustomException('There was some issue while fetching appointment details');
                }
            }
            else{
                throw new MissingOAuthTokenException('Oauth token is missing');
            }
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
            throw ex;
        }
    }
    
    public class DateTimeInfo{
        @AuraEnabled
        public String timeZone{get;set;}
        @AuraEnabled
        public String x_dateTime{get;set;}
        
        public DateTimeInfo(String timeZone, String x_dateTime){
            this.x_dateTime = x_dateTime;
            this.timeZone = timeZone;
        }
    }
    
    public class InsertEventRequest{
        @AuraEnabled
        public String summary{get;set;}
        @AuraEnabled
        public DateTimeInfo start{get;set;}
        @AuraEnabled
        public DateTimeInfo x_end{get;set;}
    }
}