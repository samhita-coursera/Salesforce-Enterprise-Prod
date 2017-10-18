public with sharing class TriggerHandlerClass 
{
    public Map<id,Case> caseOpportunityAccountMap = new Map<id, Case>();
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

    public void OnCaseAfterUpdate (Map<id,Case> updatedCasesMap) {
        Map<id,Case> closedCasesMap = new Map<id, Case>();        
        Set<Id> accountIds = new Set<ID>();
        for(Case c: [Select Opportunity__r.Type, Account.Account_Manager__c from Case where id IN :updatedCasesMap.keySet()]) {
            caseOpportunityAccountMap.put(c.id, c);
        } 
        Id caseRecordTypeId = Schema.Sobjecttype.Case.getRecordTypeInfosByName().get('Provisioning').getRecordTypeId();       
        for(Case c: updatedCasesMap.Values()) {
            system.debug('The opportunity type is: '+c.Opportunity__r);
            if (c.RecordTypeId == caseRecordTypeId && caseOpportunityAccountMap.get(c.id).Opportunity__r.Type == 'New Business' && c.Implementation_Status__c == 'Launched' ) {
                system.debug('In the inside method2');
                closedCasesMap.put(c.id,c);
                accountIds.add(c.AccountId);
            }
        }
        if(closedCasesMap.size()>0) createNewQBRsForNewBusiness(closedCasesMap, accountIds);
    }

    public void createNewQBRsForNewBusiness(Map<id,Case> closedCasesMap, Set<Id> AccountIds) {
        Map<Id, Customer_Management__c>  cmAccountMap= new Map<Id, Customer_Management__c>();
        for(Customer_Management__c cm: [Select id, Account__r.Id from Customer_Management__c where Account__r.id IN :accountIds]) {
            cmAccountMap.put(cm.Account__r.id, cm);
        }
        List<Task> newQBRs = new List<Task>();
        for(Case c: closedCasesMap.Values()) {
            Task newTask = new Task(whatId = cmAccountMap.get(c.AccountId).id, ActivityDate = c.Actual_Launch_Date__c.addDays(90), ownerId = caseOpportunityAccountMap.get(c.id).Account.Account_Manager__c,status = 'Open', priority = 'Normal', type = 'QBR');
            Integer month = c.Actual_Launch_Date__c.month();
            String quarter = '';
            if(month >=1 && month < 4) quarter = 'Q2';
            else if(month >= 4 && month < 7) quarter = 'Q3';
            else if(month >= 7 && month < 10) quarter = 'Q4';
            else quarter = 'Q1';
            Integer year = c.Actual_Launch_Date__c.year();
            if (quarter == 'Q1') year++;
            newTask.subject = quarter + '-' + String.valueOf(year) + ' QBR';                        
            newQBRs.add(newTask);                     
        }
        insert newQBRs;
    }

    
}