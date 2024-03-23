public with sharing class ClsInvokeApexAsync {

    public class KeyValuePair {
        @AuraEnabled public String key { get; set; }
        @AuraEnabled public String value { get; set; }
      }
    
    public class JobResult{
        @AuraEnabled
        public String JobStatus {get;set;}
        @AuraEnabled
        public String ErrorMessage {get;set;}
       
        public JobResult(String jobStatus, String errorMessage ){
         this.JobStatus = jobStatus;
         this.ErrorMessage = errorMessage;
       }

       public JobResult(String jobStatus ){
        this.JobStatus = jobStatus;
      }
    }

    public class AsyncExectionException extends Exception {}

    public class AsyncExecution implements Queueable, Database.AllowsCallouts {
        private String invokableClassName;
        private Map<String, Object> inputParams;
        
        public AsyncExecution(String invokableClassName, Map<String, Object> inputParams){
            this.invokableClassName = invokableClassName;
            this.inputParams = inputParams;
        }

        public void execute(QueueableContext context) {
            System.debug('Async Execution execute: ' +  this.invokableClassName + ' Params: '+ inputParams);
            
            Invocable.Action action = Invocable.Action.createCustomAction('apex', this.invokableClassName);
            
            if (this.inputParams != null){
                for (String paramName : inputParams.keySet()){
                    action.setInvocationParameter(paramName, inputParams.get(paramName));
                }
            }
            List<Invocable.Action.Result> results = action.invoke();
            
            System.debug('Action executed ' + results);
            if (results.size() > 0 && results[0].isSuccess()) {
                Map<String,Object> outputParams = results[0].getOutputParameters();
                System.debug('Output params ' + outputParams);
            } else
            if (results.size() == 0 || !results[0].isSuccess()) {
                throw new AsyncExectionException('Error while executing action: ' + results);           
            }  
        }
    }

    @AuraEnabled
    public static String enqueueAsync(
        String classToInvoke,
        List<KeyValuePair> inputParams
    ){
        try {
            System.debug('Enqueue Async: ' + classToInvoke + ' ' + inputParams);
            Map<String, Object> inputParamsMap = new Map<String, Object>();

            //marshal input parameters
            if (inputParams!=null){
                for (KeyValuePair item: inputParams){
                    inputParamsMap.put(item.key, item.value);
                }
            }

            ID jobID = System.enqueueJob(new AsyncExecution(classToInvoke, inputParamsMap));
            System.debug('EnqueueAsync success with job id: ' + jobID);
            return jobID;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static JobResult checkJobStatus(String jobId){
        try {
            AsyncApexJob jobInfo = [SELECT Status,NumberOfErrors,ExtendedStatus FROM AsyncApexJob WHERE Id=:jobID];
            if (jobInfo!=null) {
              return new JobResult(jobInfo.Status,jobInfo.ExtendedStatus) ;
            }
            return new JobResult('NoSuchJob','Something went wrong') ;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}