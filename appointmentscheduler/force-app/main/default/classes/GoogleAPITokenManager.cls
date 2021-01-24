public class GoogleAPITokenManager{
    public static String getAccessToken(String email){
        try{
            List<Physician__c> physicians = [select Id, (select Id, Expires_In__c, IssuedAt__c, access_token__c, refresh_token__c from Google_API_Credentials__r) from Physician__c where email__c = :email limit 1];
            if (physicians != null){
                Physician__c physician = physicians[0];
                if (physician.Google_API_Credentials__r != null && physician.Google_API_Credentials__r.size() > 0){
                    Google_API_Credential__c cred = physician.Google_API_Credentials__r[0];
                    if (hasExpired(cred)){
                        return renewAccessToken(cred);
                    }
                    else{
                        return cred.access_token__c;
                    }
                }
                else{
                    throw new CustomException('Google credentials are missing for the physician. Please request re-authorization.');
                }
            }
            else{
                throw new CustomException('Physician was not found in the system');
            }
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
            throw ex;
        }
    }
    
    public static boolean hasExpired(Google_API_Credential__c cred){
        Datetime now = System.now();
        if (cred.IssuedAt__c.addSeconds(Integer.valueOf(cred.Expires_In__c)-5) < now){
            return true;
        }
        return false;
    }
    
    public static String renewAccessToken(Google_API_Credential__c cred){
        try{
            String token_URL = System.Label.Google_APIs_RefreshToken_URL;
            
            token_URL = token_URL.replace('{!CLIENT_ID}', GoogleAPIConstants.CLIENT_ID)
                        .replace('{!CLIENT_SECRET}', GoogleAPIConstants.CLIENT_SECRET)
                        .replace('{!REFRESH_TOKEN}',cred.refresh_token__c)
                        .replace('{!REDIRECT_URI}', GoogleAPIConstants.REDIRECT_URI);
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndPoint(token_URL);
            req.setBody('');
            HttpResponse resp = http.send(req); 
            if (resp.getStatusCode() >= 200 && resp.getStatusCode() < 300){
                GoogleAPIToken tokenObj = (GoogleAPIToken)JSON.deserialize(resp.getBody(), GoogleAPIToken.class); 
                // TO-DO: refactor this as an internal SFDC Rest API call so as to optimize on number of API callouts to google servers
                // updateCredentials(cred.Id, System.now(), tokenObj.expires_in, tokenObj.access_token);
                return tokenObj.access_token;
            }
            else{
                throw new CustomException('Physician has revoked access. Please request re-authorization.');
            }
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
            throw ex;
        }    
    }
    
    @future
    public static void updateCredentials(Id credentialId, Datetime issuedAt, Integer expires_in, String access_token){
        Google_API_Credential__c cred = [Select Id, IssuedAt__c, expires_in__c, access_token__c from Google_API_Credential__c where Id = :credentialId limit 1];
        cred.IssuedAt__c = issuedAt;
        cred.Expires_In__c = expires_in;
        cred.Access_Token__c = access_token;
        update cred;
    }
}