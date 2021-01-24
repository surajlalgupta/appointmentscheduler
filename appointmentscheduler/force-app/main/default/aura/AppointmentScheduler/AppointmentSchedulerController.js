({
	doInit : function(component, event, helper) {
		helper.doInit(component, event);
	},
    handleChange: function (component, event, helper) {
        var calendarCmp = component.find("calendarCmp");
        if (calendarCmp) calendarCmp.destroy();
        var values = event.getParam('value').split('_');
        var email = values[0];
        var specialization = values[1];
        console.log(email, specialization);
        if (email != 'default'){
            $A.createComponent(
                "c:PhysicianCalendar",
                {
                    email: email,
                    specialization: specialization,
                    "aura:id": 'calendarCmp'
                },
                function(cmp, status, errorMsg){  
                    if (component.isValid()) {
                        var targetCmp = component.find('calendar');
                        var body = targetCmp.get("v.body");
                        body.push(cmp);
                        targetCmp.set("v.body", body); 
                    }
                }
            );
        }
    }  
})