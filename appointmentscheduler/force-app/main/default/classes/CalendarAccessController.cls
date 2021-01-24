public class CalendarAccessController {

    public PageReference getCalendarAccess() {
        try{
            String auth_code = ApexPages.currentPage().getParameters().get('code');
            if (String.isNotBlank(auth_code)){
                String token_URL = System.Label.Google_APIs_Token_URL;
                token_URL = token_URL.replace('{!AUTH_CODE}', auth_code)
                            .replace('{!CLIENT_ID}', GoogleAPIConstants.CLIENT_ID)
                            .replace('{!CLIENT_SECRET}', GoogleAPIConstants.CLIENT_SECRET)
                            .replace('{!CALENDAR_SCOPE}', GoogleAPIConstants.CALENDAR_SCOPE)
                            .replace('{!REDIRECT_URI}', GoogleAPIConstants.REDIRECT_URI);
                Http http = new Http();
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndPoint(token_URL);
                req.setBody('');
                HttpResponse resp = http.send(req); 
                if (resp.getStatusCode() == 200){
                    GoogleAPIToken tokenObj = (GoogleAPIToken)JSON.deserialize(resp.getBody(), GoogleAPIToken.class);  
                    updateGAPICredentials(tokenObj);     
                    return new PageReference(GoogleAPIConstants.REDIRECT_URI+'?confirmation=success');
                }
                else{
                    return null;
                }    
            }
            else{
                String oauth_URL = System.Label.Google_APIs_OAuth_URL;
                String email = ApexPages.currentPage().getParameters().get('email');
                String confirmation = ApexPages.currentPage().getParameters().get('confirmation');
                if (confirmation == 'success'){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Info, 'Authorization succeeded! You can close this tab.'));
                    return null;
                }
                else if (String.isNotBlank(email)){
                    oauth_URL = oauth_URL.replace('{!CALENDAR_SCOPE}', GoogleAPIConstants.CALENDAR_SCOPE)
                                .replace('{!CLIENT_ID}', GoogleAPIConstants.CLIENT_ID)
                                .replace('{!REDIRECT_URI}', GoogleAPIConstants.REDIRECT_URI)
                                .replace('{!STATE}', email);
                    system.debug(oauth_URL);
                    return new PageReference(oauth_URL);
                }
                else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, 'Email parameter is missing. Bad URL!'));
                    return null;
                }
            }
        }
        catch (Exception ex){
            System.debug(ex.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, 'Some issue occured while authorizing the app'));
            return null;
        }
    }
    
    public void updateGAPICredentials(GoogleAPIToken token){
        String email = ApexPages.currentPage().getParameters().get('state');
        List<Physician__c> physicians = [select Id, (select id, expires_in__c, issuedat__c, access_token__c, refresh_token__c from Google_API_Credentials__r) from Physician__c where email__c = :email limit 1];
        if (physicians != null){
            Physician__c physician = physicians[0];
            if (physician.Google_API_Credentials__r != null && physician.Google_API_Credentials__r.size() > 0){
                Google_API_Credential__c cred = physician.Google_API_Credentials__r[0];
                populateCredential(cred, token, physician.Id);
                update cred;
            }
            else{
                Google_API_Credential__c cred = new Google_API_Credential__c();
                populateCredential(cred, token, physician.Id);
                insert cred;
            }
        }
    }
    
    public void populateCredential(Google_API_Credential__c cred, GoogleAPIToken token, Id physicianId){
        cred.issuedat__c = System.now();
        cred.expires_in__c = token.expires_in;
        cred.refresh_token__c = token.refresh_token;
        cred.access_token__c = token.access_token;
        cred.physician__c = physicianId;
    }

}