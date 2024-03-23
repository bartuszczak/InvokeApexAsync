public class ClsConsumeCPU {
 @InvocableMethod(label='Consume CPU' description='Consume CPU' category='Utils')
     static public void generateLargeCollection(List<Integer> sleep){
        Integer sleepValue = 10000;
         if (sleep!=null && sleep.size()>0){
             sleepValue=sleep.get(0);
         }
         System.debug('Start sleep '+ sleepValue);
         
         for (Integer i=0; i <= sleepValue; i++){
			         for (Integer s=0; s <= 10000; s++){
                         Request.getCurrent();
         } 
         } 
         System.debug('Stop sleep ');
    }
}