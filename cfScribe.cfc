<cfcomponent output="false">

	<!--- VARIABLES --->
    <cfset variables.instance = {}>
   

    <!--- SERVICE INIT --->
	<cffunction name="twitterInit" returntype="Any">
		<cfargument name="force_login" type="boolean" required="true" default="false">
		<cfargument name="callback" type="string" required="false" default="" hint="used to customize the default callback URL">
		<cfset var local = {}>
		<cfset local.config = createObject("component", "config").twitterInit()>
		<cfset local.paths = []>
		<cfset local.paths[1] = local.config.getScribePath()>
		<cfset local.paths[2] = local.config.getCommonsCodecPath()>
		<cfset local.paths[3] = local.config.getHttpCorePath()>
		<cfset local.paths[4] = local.config.getHttpMimePath()>
		<cfset variables.instance.javaloader = createObject("component", "components.javaloader.JavaLoader").init(local.paths)>
		<cfif arguments.force_login>
			<cfset variables.instance.TwitterApi = variables.instance.javaloader.create("org.scribe.builder.api.TwitterApi$AuthorizeForce")>
		<cfelse>
			<cfset variables.instance.TwitterApi = variables.instance.javaloader.create("org.scribe.builder.api.TwitterApi")>
		</cfif>
		<cfif arguments.callback neq "">
			<cfset local.config.setCallback(arguments.callback)>
		</cfif>
		<cfset variables.instance.token = variables.instance.javaloader.create("org.scribe.model.Token")>
		<cfset variables.instance.verb = variables.instance.javaloader.create("org.scribe.model.Verb")>
		<cfset variables.instance.scribeService = variables.instance.javaloader.create("org.scribe.builder.ServiceBuilder").init()
									   			  .provider(variables.instance.TwitterApi.getClass())
									   			  .apiKey(local.config.getConsumerKey())
									   			  .apiSecret(local.config.getConsumerSecret())
									   			  .callback(local.config.getCallback())
									   			  .build()>
		<cfreturn this />
	</cffunction>


    <!--- GETTER FUNCTIONS---> 
	<cffunction name="getRequestToken" output="false" access="public" returntype="string">
		<cfset getRequestToken = variables.instance.scribeService.getRequestToken()>
		<cfreturn getRequestToken>
	</cffunction>
	
	<cffunction name="getAuthorizationUrl" output="false" access="public" returntype="any">
		<cfargument name="requestToken" required="true">
		<cfreturn variables.instance.scribeService.getAuthorizationUrl(arguments.requestToken) />
	</cffunction>
	
	<cffunction name="getVerifier" output="false" access="public" returntype="string">
		<cfargument name="oAuthVerifier" required="true">
		<cfreturn variables.instance.javaloader.create("org.scribe.model.Verifier").init(arguments.oAuthVerifier) />
	</cffunction>
	
	<cffunction name="getAccessToken" output="false" access="public" returntype="string">
		<cfargument name="requestToken" required="true">
		<cfargument name="verifier" required="true">
		<cfreturn variables.instance.scribeService.getAccessToken(arguments.requestToken,arguments.verifier) />
	</cffunction>
	
	<!--- SETTER FUNCTIONS---> 
	<cffunction name="setRequestToken" output="false" access="public" returntype="any">
		<cfargument name="token" required="true" type="string">
		<cfargument name="tokenSecret" required="true" type="string">
		<cfreturn variables.instance.token.init(arguments.token,arguments.tokenSecret)>
	</cffunction>
	
	<cffunction name="setRequest" output="false" access="public" returntype="string">
		<cfargument name="URI" required="true">
		<cfargument name="method" required="true">
		<cfswitch expression="#arguments.method#">
			<!---
			dunno if we need all of these, but they are valid options in scribe:
			GET, POST, PUT, DELETE, HEAD, OPTIONS, TRACE
			--->
			<cfcase value="post">
				<cfreturn variables.instance.javaloader.create("org.scribe.model.OAuthRequest").init(variables.instance.verb.post,arguments.URI) />
			</cfcase>
			<cfdefaultcase>
				<cfreturn variables.instance.javaloader.create("org.scribe.model.OAuthRequest").init(variables.instance.verb.get,arguments.URI) />
			</cfdefaultcase>
		</cfswitch>
	</cffunction>
	
	<cffunction name="setSignRequest" output="false" access="public" returntype="string">
		<cfargument name="accessToken" required="true">
		<cfargument name="request" required="true">
		<cfreturn variables.instance.scribeService.signRequest(arguments.accessToken,arguments.request) />
	</cffunction>

	<cffunction name="setRequestParams" output="false" access="public" returntype="string" hint="I take a request object and add a set of params to it">
		<cfargument name="method" required="true" type="string">
		<cfargument name="stctParams" required="true" type="struct">
		<cfargument name="objRequest" required="true" type="string">
		<cfswitch expression="#arguments.method#">
			<cfcase value="post">
				<cfloop collection="#arguments.stctParams#" item="theVar">
					<!--- only add a param if it contains a value --->
					<cfif structFind(arguments.stctParams, theVar) neq "">
						<cfset objRequest.addBodyParameter(theVar, structFind(arguments.stctParams, theVar))>
					</cfif>
				</cfloop>
			</cfcase>
			<cfdefaultcase>
				<cfloop collection="#arguments.stctParams#" item="theVar">
					<!--- only add a param if it contains a value --->
					<cfif structFind(arguments.stctParams, theVar) neq "">
						<cfset objRequest.addQuerystringParameter(theVar, structFind(arguments.stctParams, theVar))>
					</cfif>
				</cfloop>
			</cfdefaultcase>
		</cfswitch>
		<cfreturn objRequest>
	</cffunction>

	<cffunction name="setRequestParamsWithMedia" output="true" access="public" returntype="string" hint="I take a media object, convert it to base64, and add it to the request payload">
		<cfargument name="objRequest" required="true" type="string">
		<cfargument name="stctParams" required="true" type="struct">
		<cfargument name="media" required="true" type="string" hint="local system path to media file">
		<cfargument name="mediaLabel" required="true" default="image" type="string" hint="The label the API needs to identify the image value">

		<!--- scribe doesn't create a multipart request for us, so we have to create it ourselves --->
		<!--- start by init'ing the classes we need to build a multipart request --->
		<cfset variables.instance.ctEntity = variables.instance.javaloader.create("org.apache.http.entity.ContentType")>
		<cfset variables.instance.mpBuilder = variables.instance.javaloader.create("org.apache.http.entity.mime.MultipartEntityBuilder")>

		<!--- TODO checkmedia --->

		<!--- read the file into binary --->
		<cflock type="readonly" name="MimeLock#Hash(arguments.media)#" timeout="10" throwontimeout="no">
			<cffile action="readbinary" file="#arguments.media#" variable="theBinaryFile" />
		</cflock>

		<!--- create a new http request entity that we can add our image and params to --->
		<cfset var reqEntity = variables.instance.mpBuilder.create()>

		<!--- add the text (form field) params --->
		<cfloop collection="#arguments.stctParams#" item="theVar">
			<!--- only add a param if it contains a value --->
			<cfif structFind(arguments.stctParams, theVar) neq "">
				<cfset reqEntity.addTextBody(theVar, structFind(arguments.stctParams, theVar), variables.instance.ctEntity.TEXT_PLAIN)>
			</cfif>
		</cfloop>

		<!--- add the image as multipart binary data --->
		<cfset reqEntity.addBinaryBody(arguments.mediaLabel,
										theBinaryFile,
										variables.instance.ctEntity.MULTIPART_FORM_DATA,
										GetFileFromPath(arguments.media)
										)>

		<!--- add the image to a binary output stream that we'll need to extract values from to properly form our request --->
		<cfset var bos = createObject("java", "java.io.ByteArrayOutputStream").init()>
		<cfset var msg = reqEntity.build()>
		<cfset msg.writeTo(bos)>
		<cfset var contentType = msg.getContentType()>
		<cfset objRequest.addHeader("Content-length", msg.getContentLength())>
		<cfset objRequest.addHeader(contentType.getName(), contentType.getValue())>

		<!--- add our newly formed http request (with images and fields) to our OAuth request object --->
		<cfset objRequest.addPayload(bos.toByteArray())>

		<cfreturn objRequest>
	</cffunction>

</cfcomponent>


