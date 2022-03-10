Modernizr is dual-licensed under the [BSD and MIT licenses](http://www.modernizr.com/license/).

[modernizr.com](http://www.modernizr.com/)

Modernizer 3.5.0 | MIT license

This is an external library which provides a way to build a custom build for with the required features only. The js file added in this folder is thus created using the custom build.

Custom build creation:

I. Using link provided:  
	Link without options selected:
	https://modernizr.com/download

	Link with required features selected:	https://modernizr.com/download?applicationcache-audio-backgroundsize-borderimage-borderradius-boxshadow-canvas-canvastext-cssanimations-cssgradients-cssreflections-csstransforms-csstransforms3d-csstransitions-flexbox-flexboxlegacy-fontface-generatedcontent-geolocation-hashchange-history-hsla-indexeddb-inlinesvg-localstorage-multiplebgs-opacity-postmessage-rgba-sessionstorage-smil-svg-svgclippaths-textshadow-touchevents-video-webgl-websockets-websqldatabase-webworkers-setclasses&q=cssc

	The options selected can also bew reviewed in: modernizr-config.json file added in this folder.
	
	
II. Using npm package:
	1. npm install modernizr						( Get modernizr from npm)
	2. npm install -g modernizr                     ( Install modernizr)
	3. modernizr -c modernizr/lib/config-all.json   ( create custom build. Use the config file with intended features. config-all.json in lib from librarry itself contains all features)