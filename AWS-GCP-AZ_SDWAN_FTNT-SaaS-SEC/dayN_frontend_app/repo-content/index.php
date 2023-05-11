<?php

define( 'DVWA_WEB_PAGE_TO_ROOT', '' );
require_once DVWA_WEB_PAGE_TO_ROOT . 'dvwa/includes/dvwaPage.inc.php';

dvwaPageStartup( array( 'authenticated', 'phpids' ) );

$page = dvwaPageNewGrab();
$page[ 'title' ]   = 'Welcome' . $page[ 'title_separator' ].$page[ 'title' ];
$page[ 'page_id' ] = 'home';

$page[ 'body' ] .= "
<div class=\"body_padded\">
	<h1>Welcome to SmartGas DVWA!</h1>
	<p>Damn Vulnerable Web Application (DVWA) is a PHP/MySQL web application that is damn vulnerable. Its main goal is to be an aid for security professionals to test their skills and tools in a legal environment, help web developers better understand the processes of securing web applications and to aid both students & teachers to learn about web application security in a controlled class room environment.</p>
	<p>In this workshop you will use DVWA to practice some few attacks. The most of attacks were removed from this version in order to make it simpler. </p>
	<hr />
	<br />

	<h2>General Instructions</h2>
	<p>Please note, there are <em>many</em> vulnerabilities in this software. This is intentional. However, as this is for Fortinet Xperts Summit, we ask you to follow all the instructions in the student guide.</p>
	<hr />
	<br />

	<h3>Disclaimer</h3>
	<p>Follow all the instructions in the student guide. Do not attack any other part in this or other application. Your activities are being monitored, you can be disconnect and accountable for any other attack that is not listed in Student guide.</p>
	<hr />
	<br />

	<hr />
	<br />
</div>";

dvwaHtmlEcho( $page );

?>
