<!--- cfscript wrapper for  cfcontent so we can use all cfscript--->
<cffunction name="cfcontent" >
	<cfargument name="data" />
	<cfcontent type="text/x-application-json" variable="#arguments.data#" />
</cffunction>

<cfscript>	
	param name="rc.submitted" type="boolean" default="false";
	param name="rc.name" type="string" default="John Doe";
	param name="rc.email" type="string" default="john.doe@gmail.com";
	param name="rc.amount" type="numeric" default="1";
	param name="rc.coupon" default="";
	param name="rc.plan" default="";
	param name="rc.trial_end" default="";
	param name="rc.stripeToken" type="string" default="";
	param name="rc.isAjaxRequest" type="boolean" default="false";
	
	errors = [];
 
 	if (rc.submitted)
 	{
 	 	
		if (!len( rc.name )) 				arrayAppend( errors, "Please enter your name." );
 		if (!isValid( "email", rc.email ) ) arrayAppend( errors, "Please enter a valid email." );
		if (!len( rc.stripeToken )) 		arrayAppend( errors, "Please enter a valid credit card." ); 
		
		if (rc.isAjaxRequest)
		{
			if (arrayLen(errors))
			{				
				response = {};
				response[ "success" ] = false;
				response[ "errors" ] = errors;
			}
			else
			{
				response = {};
				response[ "success" ] = true;						
			}
			responseJSON = serializeJSON( response );
			cfcontent(data="#toBinary( toBase64( responseJSON ) )#");
			request.layout = false; //no layout since just returning data via AJAX		
		}  				
		if (!arrayLen(errors))
		{									
			try
			{									
				stripe = createObject("component", "stripe.Stripe").init(secretKey=application.stripeSecretKey);
				stripeResponse = stripe.createCustomer(card=rc.stripeToken,email=rc.email,description=rc.name,coupon=rc.coupon,plan=rc.plan,trial_end=rc.trial_end);
				
				//check the response and handle it as needed
				if (stripeResponse.getSuccess())
				{
					//handle the success, you may want to update the database and redirect to a confirmation
					//for now we just set a message
					stripeResponseMessage = "The customer was created";
				}
				else
				{
					///handle the failure, you may want to send a notification email or log it
					//for now we just set a message
					stripeResponseMessage = "The were errors creating the customer";									
				}							
			}
			catch(any excp)
			{
				writeDump(excp);
				arrayAppend( errors, "There was an unexpected error during the processing of your request. The error has been logged an our team is looking into it.");			
			}
		}// !arrayLen(errors)
				
 	}				
</cfscript>
 
<h2>Create Customer</h2>

<cfoutput>
 
 
 <!--- Check to see if we have any errors. --->
<cfif (rc.submitted && arrayLen( errors )) > 
	<h3>Please review the following:</h3>
 
	<ul>
		<!--- Output the list of errors. --->
		<cfloop index="error" array="#errors#"> 
			<li>#error#</li>
		</cfloop>
	</ul>
</cfif>
 
<cfif isDefined('stripeResponse')>
	<h3>#stripeResponseMessage#</h3>
	<cfif stripeResponse.getSuccess()>
		id: <a href="#buildUrl('customer.retrieve?id=#stripeResponse.getResult().id#')#">#stripeResponse.getResult().id#</a><br />
	<cfelse>
		#view('common/responseerror')#
	</cfif>
	<cfdump var=#stripeResponse# expand="no">
</cfif>
 

<form method="post" action="#buildUrl('customer.create')#">
 
	<!--- Flag the form submission. --->
	<input type="hidden" name="submitted" value="true" />
	<input type="hidden" name="stripeToken" value="" />
  
	<p>
		Name:<br />
		<input type="text" name="name" value="#htmlEditFormat( rc.name )#" size="20" />
	</p>
 
	<p>
		Email:<br />
		<input type="text" name="email" value="#htmlEditFormat( rc.email )#" size="20" />
	</p>
 
	<p>
		Credit Card:<br />
		<input type="text" value="4242424242424242" size="20" class="creditCard" />
	</p>

	<p>
		Expiration:<br />
		<input type="text" size="5" class="expirationMonth" value="01" />
		<input type="text" size="5" class="expirationYear" value="2013" />
		<em>(MM/YYYY)</em>
	</p>

	<p>
		Security Code:<br />
		<input type="text" size="5" class="securityCode" value="123" />
	</p>
	
	<p>
		Coupon:<br />
		<input type="text" name="coupon" value="#htmlEditFormat( rc.coupon)#" size="20" />
	</p>
	
	<p>
		Plan:<br />
		<input type="text" name="plan" value="#htmlEditFormat( rc.plan )#" size="20" />
	</p>
	
	<p>
		Trial End (date):<br />
		<input type="text" name="trial_end" value="#htmlEditFormat( rc.trial_end)#" size="20" />
	</p>

	<p>
		<input type="submit" value="Create Customer" />
	</p>
 
</form>
 
<script type="text/javascript">

	// Get a reference to our main DOM elements.
	var dom = {};
	dom.form = $( "form" );
	dom.stripeToken = dom.form.find( "input[ name = 'stripeToken' ]" );
	dom.name = dom.form.find( "input[ name = 'name' ]" );
	dom.email = dom.form.find( "input[ name = 'email' ]" );
	dom.creditCard = dom.form.find( "input.creditCard" );
	dom.expirationMonth = dom.form.find( "input.expirationMonth" );
	dom.expirationYear = dom.form.find( "input.expirationYear" );
	dom.securityCode = dom.form.find( "input.securityCode" );

	Stripe.setPublishableKey( "#application.stripePublicKey#" );

	// Take over the submit function, when the user clicks the Stripe API will get a token
	// Then it will do a AJAX call
	// Then it will submit to the server
	dom.form.submit(
		function( event ){

			// prevent the form from submitting to the server
			event.preventDefault();

			// Get a transaction token from the Stripe API.			
			Stripe.createToken(

				{
					number: dom.creditCard.val(),
					exp_month: dom.expirationMonth.val(),
					exp_year: dom.expirationYear.val(),
					cvc: dom.securityCode.val()
				},

				// The callback to handle the token
				tokenHandler
			);

		}
	);


	// handle the response from the Stripe token request.
	function tokenHandler( status, response ){
		
		if (response.hasOwnProperty( "error" )){
	
			alert(
				"Something went wrong!\n\n" +
				response.error.message
			);	
			return;
		}

		// set the hidden form field with the token from the stripe api request
		dom.stripeToken.val( response.id );

		// ajax call to validate
		var validation = $.ajax({
			type: "post",
			url: "#buildUrl('charge.create')#",
			data: {
				submitted: true,
				isAjaxRequest: true,
				name: dom.name.val(),
				email: dom.email.val(),
				stripeToken: response.id
			},
			dataType: "json"
		});

		validation.done(
			function( response ){

				if (response.success){								
					//validation passed so submit to the server
					dom.form
						.unbind( "submit" )
						.submit()
					;

				} else {
					// Alert the errors.
					alert( "Something went wrong!\n\n- " + response.errors.join( "\n- " ) );
				}
			}
		);
	}
</script>
  
</cfoutput>
