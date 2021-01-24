({
	doInit : function(component, event) {
		var action = component.get("c.getSpecializations");
        action.setCallback(this, function(result){
            if (component.isValid()){
                if (result.getState() == 'SUCCESS'){
                    var resultObj = result.getReturnValue();
                    if (resultObj){
                        component.set("v.specializations", resultObj);
                    }
                }
                else if (result.getState() == 'ERROR'){
                    this.handleErrors(result.getError());
                }
            }    
        });
        $A.enqueueAction(action);
	},
    handleErrors : function(errors) {
        let toastParams = {
            title: "Error",
            message: "Unknown error",
            type: "error"
        };
        if (errors && Array.isArray(errors) && errors.length > 0) {
            toastParams.message = errors[0].message;
        }
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams(toastParams);
        toastEvent.fire();
    }
})