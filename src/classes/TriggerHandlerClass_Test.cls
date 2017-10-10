@isTest
private class TriggerHandlerClass_Test {
	static Profile p;
	static UserRole ur;
	static User standardUser;
	static Account a;
	static Contact contact;
	static Opportunity o;
	static Case c;
	static Customer_Management__c cm;
	static Task task;

	@isTest static void test_UpdateAccountOnCustomerPulse() {
		data();
		Test.startTest();
		Customer_Pulse__c cp = new Customer_Pulse__c(Enterprise_Contract_ID__c = '12324', Enterprise_Customer_Slug__c = 'xyz');
		insert cp;	
		Test.stopTest();	
	}
	
	@isTest static void test_InsertOrUpdate_IndustryGroupOnLead() {
		IndustryBuckets__c ib = new IndustryBuckets__c(Name = 'TestName', Industry__c = 'Household Durables', Industry_Group__c ='Consumer Durables & Apparel');
		insert ib;
		List<Lead> leadsToInsert = new List<Lead>();		
		Lead l1 = new Lead(LastName = 'TestLastName1', Company = 'Test Company1', Status = 'Working');
		leadsToInsert.add(l1);
		Lead l2 = new Lead(LastName = 'TestLastName2', Company = 'Test Company2', Status = 'Working', Industry='xyz');
		leadsToInsert.add(l2);
		Lead l3 = new Lead(LastName = 'TestLastName3', Company = 'Test Company3', Status = 'Working', Industry='Household Durables', Industry_Group_Clearbit__c = 'Consumer Durables & Apparel');
		leadsToInsert.add(l3);
		insert leadsToInsert;
		l1.Industry='Household Durables';
		update l1;		
	}

	@isTest static void test_CreateNewQBRsForCompletedQBRs() {
		data();
		task = new Task(whoId = contact.id, whatId = cm.id, ActivityDate = system.today(), Status = 'Open', Priority = 'Normal', Type = 'QBR',subject = 'Q3-2017 QBR');
        insert task; 
		Test.startTest();
		task.Status = 'Completed';
		update task;
		Test.stopTest();		
	}

	static void data(){
		p = [SELECT p.Name,p.Id from Profile p where p.Name='Standard User' limit 1]; 
		
		ur = [Select id from UserRole where Name = 'Customer Success-APAC' limit 1];               
        
        standardUser = new User(UserName='testMexyz@google.com',LastName='Test',email='test@google.com',alias='testMeXy',communitynickname='testMex',
        TimeZoneSidKey='America/New_York',LocaleSidKey='en_US',EmailEncodingKey='ISO-8859-1',ProfileId=p.Id,LanguageLocaleKey='en_US',UserRoleId=ur.Id);
        //insert standardUser;

        a = new Account(Name = 'TestAccount', Type = 'B2B: Corporate');
		insert a;
		
		contact = new Contact(AccountID = a.id, LastName = 'xyz');
		insert contact;
		
		o = new Opportunity(Name = 'TestOppty', AccountId = a.id, CloseDate = System.Today()+7, StageName = 'Proposal');
		insert o;
		
		c = new Case (Status = 'New', Origin = 'Email', Client_Slug__c = 'xyz', Opportunity__c = o.id);
		insert c;
    	
    	cm = new Customer_Management__c (Account__c = a.id);
    	insert cm;   	    	
    	
	}
	
}