<cfparam name="url.oauth_token" default="" />
<cfparam name="url.oauth_verifier" default="" />

<cfif isdefined("form.btnTwitter")>
		<!--- Create our session to store the required keys for this user --->
		<cfset session.user = {}>
		<!--- Create our cfScribe object --->
		<cfset session.cfscribe = createObject("component", "cfScribe").twitterInit()>
		<!--- Create our twitter object --->
		<cfset session.cfTwitterAPI = createObject("component", "cfTwitterAPI").init(cfScribeObject=session.cfscribe)>
        <cfif !isDefined("session.user.requestToken")>
            <cfset session.user.requestToken = session.cfscribe.getRequestToken()>
        </cfif>
		<cflocation url="#session.cfscribe.getAuthorizationUrl(session.user.requestToken)#" addtoken="false">
</cfif>

<cfif len(url.oauth_token) AND len(url.oauth_verifier)>
	<cfset session.user.verifier = session.cfscribe.getVerifier(url.oauth_verifier)>
	<cfset session.user.accessToken = session.cfscribe.getAccessToken(verifier=session.user.verifier,requestToken=session.user.requestToken)>
	<cflocation url="success.cfm" addtoken="false" />
</cfif>


<html lang="en">
    <head>
        <title>cfScribe</title>
        <meta name="keywords" content="" />
		<meta name="description" content="" />
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <!-- <link rel="shortcut icon" href="images/favicon.ico"> -->
        <!-- Fonts -->
        <link href='http://fonts.googleapis.com/css?family=Open+Sans:400,300,300italic,400italic,600,600italic,700,700italic,800,800italic' rel='stylesheet' type='text/css'>
        
        <!-- Stylesheets -->
        <link rel="stylesheet" href="//maxcdn.bootstrapcdn.com/font-awesome/4.2.0/css/font-awesome.min.css">
        <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap.min.css">
        <link rel="stylesheet" type="text/css" href="css/style.css">
    </head>

	<body class="bg-black">

        <div class="form-box" id="login-box">
            <div class="header">cfScribe Examples</div>
            <form action="<cfoutput>#CGI.SCRIPT_NAME#</cfoutput>" method="post">
                <div class="body bg-gray">
                    <div class="form-group">
                        <button type="submit" name="btnTwitter" class="btn btn-info btn-block">Twitter</button>
                    </div> 
                    <div class="form-group">
                        <button type="submit" name="btnFacebook" class="btn btn-primary btn-block">Facebook</button>
                    </div>         
                    <div class="form-group">
                        <button type="submit" name="btnGoogle" class="btn btn-danger btn-block">Google+</button>
                    </div>
                </div>
                <div class="footer">                                                               
                    <button type="submit" class="btn bg-olive btn-block disabled">Sign me in</button>
                </div>
            </form>

            <div class="margin">
                <span><a href="/">home</a></span>
                <br/>
            </div>
        </div>

        <!-- javascripts -->
		<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/2.0.2/jquery.min.js"></script>
        <script type="text/javascript" src="https://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/js/bootstrap.min.js"></script>
        <script type="text/javascript" src="js/script.js"></script>   

    </body>

    <!---
	<body>
		<cfoutput>
		<div id="main">
			<form class="col-md-12" action="#CGI.SCRIPT_NAME#">
				<div class="row text-center">
					<div class="col-md-4 col-sm-12">
						<button type="button" class="btn btn-primary btn-block">Facebook</button>
					</div>
					<div class="col-md-4 col-sm-12">
						<button type="button" class="btn btn-info btn-block">Twitter</button>
					</div>
					<div class="col-md-4 col-sm-12">
						<button type="button" class="btn btn-danger btn-block">Google+</button>
					</div>
				</div>
			</form>

			<cfform action="#CGI.SCRIPT_NAME#" name="frmYahoo">
				<cfinput type="submit" name="btnSubmit" value="Sign in with Yahoo">
			</cfform>
		</div>
		</cfoutput>

		<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/2.0.2/jquery.min.js"></script>
        <script type="text/javascript" src="https://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/js/bootstrap.min.js"></script>
        <script type="text/javascript" src="js/script.js"></script>
	</body>
	--->
</html>