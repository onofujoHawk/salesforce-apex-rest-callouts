/**
 * REST Custom controller
 */
public with sharing class RestHerokuCalloutsCtrl {

    private ApexPages.StandardController stdCtrl;

    //Controller members
    public String animalName {get; set;}
    public Map<Integer, String> animals {get; set;}


    /*********** CONSTRUCTORS *************/

    public RestHerokuCalloutsCtrl() {
        System.debug(LoggingLevel.INFO, 'Init standard');
        animalName = '';
        animals = new Map<Integer, String>();
    }
    

    public RestHerokuCalloutsCtrl(ApexPages.StandardController stdCtrl) {
        System.debug(LoggingLevel.INFO, 'Init extension');
        animalName = '';
        animals = new Map<Integer, String>();
    }


    /************** ACTIONS ***************/

    public PageReference getHerokuData() {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(this.ENDPOINT);
        req.setMethod(this.GET);

        if (animals.size() != 0) {
            this.animals.clear();
        }
        
        //Send
        HttpResponse resp = http.send(req);
        
        //Se la request ha esito positivo, parserizza la response JSON
        if (resp.getStatusCode() == 200) {
            
            this.animals = population(resp);
            
            if (!animals.isEmpty()) {
                displayMessage(ApexPages.Severity.INFO, 'Successfully get data from Heroku!');
            } else {
                displayMessage(ApexPages.Severity.WARNING, 'Unable to call the REST service.');
            }
        }   
        return null;
    }
    

    public PageReference sendHerokuData() {
        if (String.isBlank(animalName)) 
        {
            displayMessage(ApexPages.Severity.ERROR, 'Digit an animal before to save.');
            this.animalName = '';
        } 
        else 
        {
            System.debug('sendHerokuData...');

            //Future callout
            //RestHerokuCalloutsCtrl.sendData(ENDPOINT, POST, animalName, animals);    
            
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            
            req.setEndpoint(ENDPOINT);
            req.setMethod(POST);
            req.setHeader('Content-Type', 'application/json;charset=UTF-8');

            //Settiamo il body come JSON object
            Map<String, String> mapSave = new Map<String, String>{
                'name' => animalName
            };
            req.setBody(asJSON(mapSave));
            
            //Saving
            HttpResponse resp = http.send(req);
            
            if (resp.getStatusCode() != 201) {
                System.debug(LoggingLevel.WARN, 'The status code returned was not expected: ' + resp.getStatusCode()); 
            } else {
                animals.clear();
                System.debug('Success ' + resp.getBody());
                
                animals = population(resp);
                
                if (animals.isEmpty()) { displayMessage(ApexPages.Severity.ERROR, 'An error has occured.'); }
                else { displayMessage(ApexPages.Severity.INFO, 'Saved successfully!'); }
            }
            animalName = '';
        }
        
        return null;
    }


    @future(Callout = true)
    public static void sendData(String ENDPOINT, String POST, String animal, Map<Integer,String> resultMap) {
        System.debug('Callout');
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        
        req.setEndpoint(ENDPOINT);
        req.setMethod(POST);
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');

        //Settiamo il body come JSON object
        Map<String, String> mapSave = new Map<String, String>{
            'name' => animal   
        };
        req.setBody(asJSON(mapSave));
        
        //Saving
        HttpResponse resp = http.send(req);
        
        if (resp.getStatusCode() != 201) {
            System.debug(LoggingLevel.WARN, 'The status code returned was not expected: ' + resp.getStatusCode()); 
        } else {
            resultMap.clear();
            System.debug('Success ' + resp.getBody());
            
            resultMap = population(resp);
        }
        //Clear the input field
        animal = '';
    }
    
    
    public PageReference resetForm() {
        System.debug(LoggingLevel.DEBUG, 'Resetting');
        if (String.isNotBlank(animalName)) { this.animalName = ''; }
        return null;
    }


    /*********** UTILS **************/
    
    private static String asJSON(Object obj) {
        return JSON.serializePretty(obj);
    }


    static private Object asObject(String str) {
        return (Object) JSON.deserializeStrict(str, Object.class);
    }


    private static void displayMessage(ApexPages.Severity severity, String message) {
        ApexPages.addMessage(new ApexPages.Message(severity, message));
    }
    
    
    private static Map<Integer, String> population(HttpResponse response) {
        System.debug(LoggingLevel.DEBUG, 'Population');
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        Map<Integer, String> resultMap = new Map<Integer, String>();
        
        List<Object> objects = (List<Object>) responseBody.get('animals');
        System.debug('Received the following objects: ');
        
        //View in page
        for (Integer i=1; i<objects.size(); i++) {
            System.debug(LoggingLevel.DEBUG, objects.get(i));
            resultMap.put(i, String.valueOf(objects.get(i)));
        }
        
        return resultMap;
    }


    /*********** FINAL MEMBERS ************/

    private final String ENDPOINT = 'https://th-apex-http-callout.herokuapp.com/animals';
    private final String GET = 'GET';
    private final String POST = 'POST';
    
}