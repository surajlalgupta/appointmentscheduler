({
	initializeCalendar : function(component, event, events) {
        var eventsArr = [];
        events.forEach((item, index, self) => {
            var eventObj = {
            	title : item.summary,
            	start : item.start.x_dateTime,
            	end   : item.x_end ? item.x_end.x_dateTime : undefined,
            	id    : item.id
        	};
            eventsArr.push(eventObj);           
        });
    	var that = this;
		$('#calendar').fullCalendar({
            header: {
                left: 'prev,next today',
                center: 'title',
                right: 'agendaWeek,agendaDay'
            },
            defaultDate: new Date(),
            navLinks: true,
            selectable: true,
            selectHelper: true,
            defaultView: 'agendaWeek',
            minTime: "09:00:00",
            maxTime: "18:00:00", 
            height: 590,
            select: function(startTime, endTime) {
                component.set("v.startTime", startTime);
                component.set("v.endTime", endTime);
                component.set("v.summary", component.get("v.specialization")+" Consultation: #Enter patient symptoms or other details here#")
                that.showModal(component, event, startTime, endTime);
            },
            eventClick: function(calEvent, jsEvent, view) {
                var confirmation = confirm('Are you sure you want to cancel this appointment?');
                if (confirmation == true){
                	that.deleteEvent(component, event, calEvent);
                	$('#calendar').fullCalendar( 'removeEvents', calEvent.id );
                }
                else{
                    $('#calendar').fullCalendar('unselect');
                }
            },     
            editable: true,
            eventLimit: true,
            events: eventsArr
        });
	},
    createEvent: function(component, event, eventObj){
        component.set("v.showSpinner", true);
        var that  = this;
        var updatePatientAction = component.get("c.updatePatient");
        updatePatientAction.setParams({
            'relationshipNumber': component.get("v.relationshipNumber"),
            'patientName': component.get("v.patientName"),
            'patientEmail': component.get("v.patientEmail"),
            'patientDOB': component.get("v.patientDOB")
        });
        
    	var createEvtAction = component.get("c.createEvent");
        
        updatePatientAction.setCallback(this, function(result){
            if (component.isValid() && result.getState() == 'SUCCESS'){
                createEvtAction.setParams({
                    'email': component.get("v.email"),
                    'startTime': eventObj.start,
                    'endTime': eventObj.end,
                    'summary' : eventObj.title,
                    'patientId': result.getReturnValue(),
                    'specialization': component.get('v.specialization')
                });
                $A.enqueueAction(createEvtAction);
            }
            else{
                $('#calendar').fullCalendar('unselect');
                that.handleErrors(result.getError());
            	component.set("v.showSpinner", false);
            }    
        });
        createEvtAction.setCallback(this, function(result){
            if (component.isValid()){ 
                if (result.getState() == 'SUCCESS'){
                    eventObj.id = result.getReturnValue();
                    $('#calendar').fullCalendar('renderEvent', eventObj, true);
                    $('#calendar').fullCalendar( 'rerenderEvents' )
                }
                else if (result.getState() == 'ERROR'){
                    component.set("v.showSpinner", false);
                }
                component.set("v.showSpinner", false);
            }    
        });
        $A.enqueueAction(updatePatientAction);
        
    },
	deleteEvent: function(component, event, eventObj){
        component.set("v.showSpinner", true);
    	var action = component.get("c.deleteEvent");
        action.setParams({
            'email': component.get("v.email"),
            'id': eventObj.id
        });
        action.setCallback(this, function(result){
            if (component.isValid()){
                if (result.getState() == 'SUCCESS'){
                    //eventObj.id = result.getReturnValue();
                    this.handleSuccess('Appointment was cancelled successfully!');
                }
                else if (result.getState() == 'ERROR'){
                    this.handleErrors(result.getError());
                }
                component.set("v.showSpinner", false);
            }
        });
        $A.enqueueAction(action);
    },
    showModal: function(component, event){
    	component.set("v.showModal", true);        
    },
    hideModal: function(component, event){
    	component.set("v.showModal", false);        
    },
    bookAppointment: function(component, event){
        component.set("v.showSpinner", true);
    	var eventObj = {
            title : component.get("v.summary"),
            start : component.get("v.startTime"),
            end   : component.get("v.endTime")
        };
        this.createEvent(component, event, eventObj);
        this.hideModal(component, event);    
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
    },
    handleSuccess : function(message) {
        let toastParams = {
            title: "Success",
            message: message,
            type: "success"
        };
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams(toastParams);
        toastEvent.fire();
    }
})