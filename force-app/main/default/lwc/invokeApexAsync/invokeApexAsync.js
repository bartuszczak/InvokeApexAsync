import enqueueAsync from '@salesforce/apex/ClsInvokeApexAsync.enqueueAsync';
import checkJobStatus from '@salesforce/apex/ClsInvokeApexAsync.checkJobStatus';
import { LightningElement, api } from 'lwc';
import { FlowNavigationFinishEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';

export default class ScreenFlowPause extends LightningElement {
    @api waitingText;
    @api classToInvoke;
    @api availableActions = [];
    @api inputParamKeys = [];
    @api inputParamValues = [];
    @api outputParams = [];
    outputText;
    jobId;
    showSpinner = true;
    timeIntervalInstance;
  
   handleNext(event){
      const nextNavigationEvent = new FlowNavigationNextEvent();
      this.dispatchEvent(nextNavigationEvent);
   }
   disconnectedCallback() {
    clearInterval(this.timeIntervalInstance);
   }

    connectedCallback() {
        console.log("connectedCallback started...");
        console.log("Class to invoke: ", this.classToInvoke);
        console.log("Input keys: ", this.inputParamKeys);
        console.log("Input values: ", this.inputParamValues);
        let keyValuePairs = [{key:"sleep",value:"200"}];
        //TODO parameter marshaling
        /*if (this.inputParamKeys){
            keyValuePairs = this.inputParamKeys.array.map(element,index => {
                if (this.inputParamValues.length > index) {
                    return {key: element, 
                            value: this.inputParamValues[index]
                        }
                }
            });
        }*/

        console.log("Key Value Pair", keyValuePairs);

        enqueueAsync({
            classToInvoke: this.classToInvoke,
            inputParams: keyValuePairs
        })
        .then((result) => {
            this.jobId = result;
            this.outputText = this.waitingText ? this.waitingText : 'Please wait, do not close the window !!';
            this.timeIntervalInstance = setInterval(() => {
                console.log(this.jobId);
                console.log('Checking Job status ', this.jobId);
                checkJobStatus({jobId: this.jobId}).then((result)=>{
                    console.log('Job status ', result.JobStatus);
                    if (result.JobStatus === "Completed") {
                        let closeFlowtEvent;
                        if (this.availableActions.find((action) => action === 'NEXT')) {
                          closeFlowtEvent = new FlowNavigationNextEvent();
                        } else {
                          closeFlowtEvent = new FlowNavigationFinishEvent();
                        }
                        this.dispatchEvent(closeFlowtEvent);
                    } else if (result.JobStatus === "Aborted" || result.JobStatus === "Failed" ) {
                        this.showSpinner = false;
                        this.outputText = ('ErrorMessage' in result)? result.ErrorMessage : "The job has failed, contact administrator: " + this.jobId;
                        clearInterval(this.timeIntervalInstance);   
                    }
                });
               
              }, 2000);
        })
        .catch((error) => {
        // console.log('we have an error', error.body);
        this.showSpinner = false;
        this.outputText = 'Error';
        if (error.body.message) {
            this.outputText = `Error: ${error.body.message}`;
      }

    });
}
}