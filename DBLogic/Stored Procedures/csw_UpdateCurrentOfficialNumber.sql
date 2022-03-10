-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateCurrentOfficialNumber
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateCurrentOfficialNumber]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateCurrentOfficialNumber.'
	Drop procedure [dbo].[csw_UpdateCurrentOfficialNumber]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateCurrentOfficialNumber...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_UpdateCurrentOfficialNumber
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	-- The language in which output is to be expressed.
	@pnCaseKey		int		= null	-- The key of a particular case to be processed. If not supplied, all cases will be processed.
)
as
-- PROCEDURE:	csw_UpdateCurrentOfficialNumber
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Manages redundant data stored against the Case containing the official number 
--		issued by an IP authority that is currently in effect for the case.
--		The procedure can be used to recalculate all official numbers, or just 
--		for a particular case.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 06 Dec 2005	TM	RFC3200	1	Procedure created
-- 07 Dec 2005	TM	RFC3200	2	Implement Julie's feedback.
-- 12 Dec 2005	TM	RFC3200	3	Select as CurrentOfficialNumber to match the property name in the business entity.
-- 02 Feb 2010	AT	RFC8858	4	Added Where clause to only update the official number if it has changed.
-- 09 Oct 2012	KR	R100040	5	Update Current official no in the cases table with null if there are no official no available.
-- 23 Apr 2015  SW      R13089  6       Modified If exists check to fix issue where Official number was not set to null even after
--                                      deleting the current official number 


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode 	= 0

If @nErrorCode = 0
Begin

	if exists (select 1 from OFFICIALNUMBERS O 
	                join NUMBERTYPES NT on (NT.NUMBERTYPE = O.NUMBERTYPE)	                
	                where NT.ISSUEDBYIPOFFICE = 1 and NT.DISPLAYPRIORITY is not null and O.CASEID = @pnCaseKey and O.ISCURRENT = 1)
	Begin
		Set @sSQLString = "
			Update CASES
			Set CURRENTOFFICIALNO = substring(O1.OFFICIALNUMBER,14,36)
			from CASES C
			join (	select O.CASEID, 
					-- this finds the best Official Number to use based on 
					-- NumberType priority and Date entered
					max(convert(nchar(5), 99999-NT.DISPLAYPRIORITY )+
						convert(nchar(8), ISNULL(O.DATEENTERED,0),112)+
						O.OFFICIALNUMBER) as OFFICIALNUMBER
					from OFFICIALNUMBERS O
					join NUMBERTYPES NT 	on (NT.NUMBERTYPE = O.NUMBERTYPE)
					where NT.ISSUEDBYIPOFFICE = 1
					and NT.DISPLAYPRIORITY is not null
					and O.ISCURRENT=1
					group by O.CASEID) O1 	on (O1.CASEID=C.CASEID)
				where isnull(C.CURRENTOFFICIALNO,'') <> substring(O1.OFFICIALNUMBER,14,36)"+
		CASE WHEN @pnCaseKey is not null 
			THEN +char(10)+"and C.CASEID = @pnCaseKey" 
		END

		exec @nErrorCode = sp_executesql @sSQLString,
							N'@pnCaseKey	int',
							  @pnCaseKey	= @pnCaseKey
	End
	Else
	Begin
		Set @sSQLString = "Update CASES
			Set CURRENTOFFICIALNO = null
			Where CASEID = @pnCaseKey"
		exec @nErrorCode = sp_executesql @sSQLString,
							N'@pnCaseKey	int',
							  @pnCaseKey	= @pnCaseKey
		
	End

	If  @nErrorCode = 0
	and @pnCaseKey is not null
	Begin
		Set @sSQLString = "
		Select CURRENTOFFICIALNO as CurrentOfficialNumber
		from CASES
		where  CASEID = @pnCaseKey"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey		int',
				  @pnCaseKey		= @pnCaseKey
	End	
End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateCurrentOfficialNumber to public
GO
