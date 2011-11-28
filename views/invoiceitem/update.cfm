
<cfscript>
	param name="rc.id" default="";
	param name="rc.isFormSubmitted" default="no";
	param name="rc.description" default="";
	param name="rc.amount" default="100";
	
	if (rc.isFormSubmitted EQ "yes")
	{
		stripe = createObject("component", "stripe.Stripe").init(secretKey=application.stripeSecretKey);												
		stripeResponse = stripe.updateInvoiceItem(id=rc.id,amount=rc.amount,description=rc.description);
	}
</cfscript>

<h2>Update Invoice Item</h2>

<cfoutput>
<cfif isDefined('stripeResponse')>
	<cfif stripeResponse.getSuccess()>
		id: #stripeResponse.getRawResponse().id#<br />
		description: #stripeResponse.getRawResponse().description#<br />
		amount: #stripeResponse.getRawResponse().amount#<br />
	<cfelse>
		errorType: #stripeResponse.getErrorType()#<br />
		errorMessage: #stripeResponse.getErrorMessage()#<br />
	</cfif>
	<br />
	<cfdump var=#stripeResponse# expand="no">	
</cfif>
</cfoutput>

<form action="<cfoutput>#buildUrl('invoiceitem.update')#</cfoutput>" method="post">
	<input type="hidden" name="isFormSubmitted" value="yes" />
	<p>
		Invoice Item ID:<br />
		<input type="text" name="id" value="<cfoutput>#htmlEditFormat( rc.id)#</cfoutput>" size="20" />
	</p>
	
	<p>
		Description:<br />
		<input type="text" name="description" value="<cfoutput>#htmlEditFormat( rc.description)#</cfoutput>" size="20" />
	</p>
	
	<p>
		Amount:<br />
		<input type="text" name="amount" value="<cfoutput>#htmlEditFormat( rc.amount)#</cfoutput>" size="20" />
	</p>
			
	<p>
		<input type="submit" value="Update Invoice Item" />
	</p>
</form>