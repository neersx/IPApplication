exec naw_FetchOrganisation
	@pnUserIdentityId		= 26,		-- Mandatory
	@psCulture			= N'EN-AU', --ZH-CHS'
	@pbCalledFromCentura		= 0,
	@pnNameKey			= 45		-- Mandatory


SELECT O.NAMENO, O.NAMENO, O.REGISTRATIONNO, O.VATNO, O.INCORPORATED, O.PARENT, N.NAME, N.NAMECODE
FROM ORGANISATION O JOIN NAME N ON (N.NAMENO = O.PARENT)
WHERE O.NAMENO = 45
ORDER BY NAME