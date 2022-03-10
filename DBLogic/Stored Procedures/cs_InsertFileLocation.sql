-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_InsertFileLocation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_InsertFileLocation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_InsertFileLocation.'
	Drop procedure [dbo].[cs_InsertFileLocation]
	Print '**** Creating Stored Procedure dbo.cs_InsertFileLocation...'
	Print ''
End
go

SET QUOTED_IDENTIFIER off
go

CREATE PROCEDURE dbo.cs_InsertFileLocation
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psCaseKey		nvarchar(11)	= null,
	@psFileLocationKey	nvarchar(11)	= null	
)
-- PROCEDURE :	cs_InsertFileLocation
-- VERSION :	4
-- DESCRIPTION:	See CaseData.doc
-- CALLED BY :	cs_UpdateCase, cs_InsertCase
-- ERRORCODE : 	SqlError Codes
--	     	-1	MaxLocations site control not found

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 05/08/2002	SF	Procedure created
-- 07/08/2002	SF	It is perfectly valid for there to be no site control specified (and no deletes performed)
-- 15/04/2013	DV	4 R13270 Increase the length of nvarchar to 11 when casting or declaring integer
as
begin
	declare @nErrorCode int
	declare @nCaseId int
	declare @nFileLocation int
	declare @nMaxLocations int
	declare @dtOldestDate datetime
		
	set @nCaseId = cast(@psCaseKey as int)
	set @nErrorCode = @@error


	if @nErrorCode = 0
	begin
		set @nFileLocation = cast(@psFileLocationKey as int)
		set @nErrorCode = @@error
	end
	
	if @nErrorCode = 0
	and @nCaseId is not null
	and @nFileLocation is not null
	begin
		insert into CASELOCATION (CASEID, FILELOCATION, WHENMOVED)
		values	(@nCaseId, @nFileLocation, getdate())			

		set @nErrorCode = @@Error
	end
	
	if @nErrorCode = 0
	begin
		select 	@nMaxLocations = COLINTEGER
		from 	SITECONTROL 
		where 	CONTROLID = 'MaxLocations'

		if @nMaxLocations is not null
		begin
			while 	@nErrorCode = 0 
			and	((select count(*) 
				from 	CASELOCATION 
				where 	CASEID = @nCaseId) > @nMaxLocations )
			begin
				delete	
				from	CASELOCATION
				where	CASELOCATION.CASEID = @nCaseId
				and	CASELOCATION.WHENMOVED =(	
							select  min(CL2.WHENMOVED)
							from	CASELOCATION CL2
							where 	CL2.CASEID = @nCaseId)
	
	
				set @nErrorCode = @@error			
			end
		end
	end
	return @nErrorCode
end
GO

Grant execute on dbo.cs_InsertFileLocation to public
go
