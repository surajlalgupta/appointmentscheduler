({
	doInit : function(component, event, helper) {
        component.set("v.showSpinner", true);
        var action = component.get("c.getEvents");
        action.setParams({
            'email': component.get("v.email")
        });
        action.setCallback(this, function(result){
            if (component.isValid() && result.getState() == 'SUCCESS'){
                var events = result.getReturnValue();
                helper.initializeCalendar(component, event, events);
            }
            component.set("v.showSpinner", false);
        });
		$A.enqueueAction(action);
	},
    afterScriptLoaded: function(component, event, helper){
        
    },
    showModal: function(component, event, helper){
        helper.showModal(component, event);
        
    },
    hideModal: function(component, event, helper){
		helper.hideModal(component, event);        
    },
    bookAppointment: function(component, event, helper){
    	helper.bookAppointment(component, event);
	}
})