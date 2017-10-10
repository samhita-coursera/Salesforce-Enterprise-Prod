public with sharing class TriggerHandlerClass 
{
    public TriggerHandlerClass(){ 
    }

    public void OnCustomerPulseBeforeInsert(List<Customer_Pulse__c> newList){
        // EXECUTE BEFORE INSERT LOGIC                  
        Set<String> client_slug_set = new Set<String>();
        Map<String,Case> case_map = new Map<String,Case>();
        for(Customer_Pulse__c cp: newList) {
            client_slug_set.add(cp.Enterprise_Customer_Slug__c);
        }
        for(Case c: [Select id, Opportunity__r.AccountId, Client_Slug__c from Case where Client_Slug__c IN :client_slug_set]) {
            case_map.put(c.Client_Slug__c,c);
        }
        for(Customer_Pulse__c cp: newList) {
            Case c1 = case_map.get(cp.Enterprise_Customer_Slug__c); 
            if(c1 != null) cp.AccountName__c = c1.Opportunity__r.AccountId;         
        }       
    }

    //Execute this method before insertion of leads
    public void OnLeadBeforeInsert(List<Lead> newLeads) {
        List<Lead> leadsToUpdate = new List<Lead>();   
        for (Lead l: newLeads) {
            if(l.Industry != Null){
                leadsToUpdate.add(l);
            }
        }
        if(leadsToUpdate.size() > 0) UpdateLeadsWithIndustryGroup(leadsToUpdate);

    }

    //Execute this method before updating leads
    public void OnLeadBeforeUpdate(List<Lead> newLeads) {
        List<Lead> leadsToUpdate = new List<Lead>();    
        for (Lead l: newLeads) {
            if(l.Industry_Group__c == Null && l.Industry != Null){
                leadsToUpdate.add(l);
            }
        }
        if(leadsToUpdate.size() > 0) UpdateLeadsWithIndustryGroup(leadsToUpdate);
    }

    public void UpdateLeadsWithIndustryGroup(List<Lead> leadsToUpdate) {
        Map<String,String> ib_map = new Map<String,String>();
        for(IndustryBuckets__c ib: IndustryBuckets__c.getall().Values()){
            ib_map.put(ib.Industry__c, ib.Industry_Group__c);
        }
        for(Lead l: leadsToUpdate) {
            if(l.Industry_Group_Clearbit__c != null) {
                l.Industry_Group__c = l.Industry_Group_Clearbit__c;
            } else if(ib_map.keySet().Contains(l.Industry)){
                l.Industry_Group__c = ib_map.get(l.Industry);                
            }
        }
    }

    public void OnTaskAfterUpdate (List<Task> updatedTasks) {
        List<Task> completedQBRs = new List<Task>();
        for(Task t: updatedTasks) {
            system.debug('owner role name is:'+t.Owner.UserRole.Name);
            if (t.status == 'Completed' && t.Type == 'QBR') {
                completedQBRs.add(t);
            }
        }
        if(completedQBRs.size()>0) createNewQBRs(completedQBRs);
    }

    public void createNewQBRs(List<Task> completedQBRs) {
        List<Task> newQBRs = new List<Task>();
        for(Task t: completedQBRs) {
            Task newTask = new Task(whoId = t.whoId, whatId = t.whatId, ActivityDate = system.today().addDays(90), ownerId = t.ownerId,status = 'Open', priority = t.priority, type = t.type);
            Integer quarter = Integer.valueOf(t.subject.mid(1,1));
            if(quarter==4) quarter = 1;
            else quarter++;            
            String year = String.valueOf(Integer.valueOf(t.subject.mid(3,4)) + 1);
            String subject  = 'Q' + String.valueOf(quarter) + '-' + year + ' QBR';
            newTask.subject = subject; 
            newQBRs.add(newTask);                     
        }
        insert newQBRs;
    }

    
}