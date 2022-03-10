-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ev_MaintainSuppressCalcFlag
-----------------------------------------------------------------------------------------------------------------------------
If exists (Select * from dbo.sysobjects where id = object_id(N'[dbo].[ev_MaintainSuppressCalcFlag]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	Print '**** Drop Stored Procedure dbo.ev_MaintainSuppressCalcFlag.'
	Drop procedure [dbo].[ev_MaintainSuppressCalcFlag]
end
Print '**** Creating Stored Procedure dbo.ev_MaintainSuppressCalcFlag...'
Print ''
GO

Set QUOTED_IDENTIFIER OFF
GO
Set ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ev_MaintainSuppressCalcFlag
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@ptXMLFilter		nvarchar(max)		-- XML string containing change details to apply to events and eventcontrol tables
)
as
-- PROCEDURE:	ev_MaintainSuppressCalcFlag
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	- Update the SUPRRESSCALCULATION in EVENTS and EVENTCONTROL table based on the filter.
--
-- MODIFICATIONS :
-- Date			Who		Change	 	Version	Description
-- -----------	----- 	-------- 	-------	----------------------------------------------- 
-- 8 July 2013	DL    	21404 		1		Procedure created.

Set NOCOUNT ON
Set CONCAT_NULL_YIELDS_NULL OFF


Declare @nDocHandle 		int
Declare @nErrorCode		int
Declare @TranCountStart		int
Declare	@sSQLString		nvarchar(max)

Select @TranCountStart = @@TranCount
BEGIN TRANSACTION

-- Get a handle for the XML (required for OPENXML)
exec sp_xml_preparedocument @nDocHandle OUTPUT, @ptXMLFilter

Update EVENTS
set SUPPRESSCALCULATION = XML.SuppressFlag
from EVENTS E
join (SELECT  *
	FROM OPENXML(@nDocHandle, N'/Root/Events/Event') 
	WITH (EventNo int, CriteriaNo int, SuppressFlag int )) XML on XML.EventNo = E.EVENTNO
where XML.CriteriaNo is null

select @nErrorCode = @@ERROR

If @nErrorCode = 0
Begin
	Update EVENTCONTROL
	set SUPPRESSCALCULATION = XML.SuppressFlag
	from EVENTCONTROL EC
	join (SELECT  *
		FROM OPENXML(@nDocHandle, N'/Root/Events/Event') 
		WITH (EventNo int, CriteriaNo int, SuppressFlag int )) XML on XML.EventNo = EC.EVENTNO AND XML.CRITERIANO = EC.CRITERIANO

	select @nErrorCode = @@ERROR
End

exec sp_xml_removedocument @nDocHandle



-- Commit the transaction if it has successfully completed
If @@TranCount > @TranCountStart
Begin
	If @nErrorCode = 0
		COMMIT TRANSACTION
	Else
		ROLLBACK TRANSACTION
End


RETURN @nErrorCode
go

Grant execute on dbo.ev_MaintainSuppressCalcFlag to public
GO
