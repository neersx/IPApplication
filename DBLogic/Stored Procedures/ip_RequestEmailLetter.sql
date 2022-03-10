-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RequestEmailLetter
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_RequestEmailLetter]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_RequestEmailLetter.'
	Drop procedure [dbo].[ip_RequestEmailLetter]
	Print '**** Creating Stored Procedure dbo.ip_RequestEmailLetter...'
	Print ''
End
go

SET QUOTED_IDENTIFIER off
go

create procedure dbo.ip_RequestEmailLetter
(
	@pnUserIdentityId	int,
	@psCulture		nvarchar(10) = null,	
	@pnCaseId		int = null,
	@pnLetterNo		int = null,
	@psEmailOverride	nvarchar(50) = null
)
-- PROCEDURE :	ip_RequestEmailLetter
-- VERSION :	8
-- DESCRIPTION:	Write an Activity Request for a document to be generated and then sent via EMAILOVERRIDE.  
-- CALLED BY :	CPA.Net

-- MODIFICTIONS :
-- Date         Who  Version  	Change
-- ------------ ---- -------- 	------------------------------------------- 
-- 22/08/2002	SF			Procedure created
-- 14/03/2003	SF	5		remove 18 character truncation on sqluser 
-- 21-Mar-2003	JEK	6		Adjust to call cs_InsertActivityRequest and 
--					change program name.  Was not finding site control
--					on case sensitive server.
-- 04-Apr-2003	JEK	7	RFC120	Change name of site control.
-- 11 Dec 2008	MF	8	17136	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
as
begin
	declare @nErrorCode int	
	declare @nDeliveryId int

	if @pnCaseId is null 
	or @pnLetterNo is null
	or @psEmailOverride is null
		set @nErrorCode = -1
	else
		set @nErrorCode = 0

	if @nErrorCode = 0
	begin
		select 	@nDeliveryId = COLINTEGER
		from	SITECONTROL
		where	CONTROLID = 'CPA Inprostart Email Method'

		-- could be null, 
		-- if null the request will stay on the Document Generator Queue unless someone has specified a delivery method.

		-- insert an Activity Request row
		exec @nErrorCode = ip_InsertActivityRequest
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@psProgramID		= 'CPAStart',
			@pnCaseKey		= @pnCaseId,
			@pnActivityType		= 32,
			@pnActivityCode		= 3204,
			@pnLetterKey		= @pnLetterNo,
			@pbHoldFlag		= 0,
			@pnDeliveryID		= @nDeliveryId,
			@psEmailOverride	= @psEmailOverride
	end
	return @nErrorCode
end
go

grant execute on dbo.ip_RequestEmailLetter to public
go
