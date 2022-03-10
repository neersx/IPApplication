-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pt_CreateActivityForDocument
-----------------------------------------------------------------------------------------------------------------------------

if exists (select * from sysobjects where id = object_id(N'[dbo].[pt_CreateActivityForDocument]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.pt_CreateActivityForDocument.'
	drop procedure dbo.pt_CreateActivityForDocument
	print '**** Creating procedure dbo.pt_CreateActivityForDocument...'
	print ''
end
go

create procedure dbo.pt_CreateActivityForDocument
			-- Optional Parameters 
			@psEntryPoint	varchar(254),
			@psCaseId	varchar(11)	= NULL,	-- Caseid if file is to be attached against a Case
			@psNameNo	varchar(11)	= NULL,	-- NameNo if file is to be attached against a Name
			@psReference	varchar(20)	= NULL,	-- User generated reference
			@psSummary	varchar(254),		-- Title to appear on Activity is mandatory
			@psDocName	varchar(254)	= NULL,	-- The name of the document
			-- Mandatory Parameters
			@psFileName	varchar(254)		-- The name and location of the file		
as

-- PROCEDURE :	pt_CreateActivityForDocument
-- VERSION :	6
-- DESCRIPTION:	Link a generated document to either a Case or a Name.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05/02/2002	MF	7362	1	Procedure created
-- 06/02/2002	ZA		2	Input Items changed.  Entry Point added and all inputs must be
--					varchars and converted
-- 06 Nov 2007	MF	15539	3	The @psSummary parameter is not allowed to be NULL.
-- 07 May 2008	MF	16355	4	Provide a validation check that mandatory parameters are not
--					null.
-- 15 Dec 2008	MF	17136	5	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 04 Jun 2010	MF	18703	6	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE which need to be NULL.

set nocount on

declare @nActivityNo	int,
	@ErrorCode	int,
	@TranCountStart int,
	@pnCaseId	int,
	@pnNameNo	int

set @ErrorCode	=0
set @nActivityNo=null

--------------------------------
-- D A T A   V A L I D A T I O N
-- Validate the input parameters
--------------------------------

----------------------
-- Validate @psSummary
----------------------
If  @ErrorCode = 0
and @psSummary is null
Begin
	RAISERROR('@psSummary must not be NULL', 14, 1)
	Set @ErrorCode = @@ERROR
End

-----------------------
-- Validate @psFileName
-----------------------
If  @ErrorCode = 0
and @psFileName is null
Begin
	RAISERROR('@psFileName must not be NULL', 14, 1)
	Set @ErrorCode = @@ERROR
End

-- Next two lines added by ZA to convert the varchars to integers.
select @pnCaseId = convert(int,@psCaseId)
select @pnNameNo = convert(int,@psNameNo)

-----------------------------------
-- Validate @pnCaseId and @pnNameNo
-- are both not Null
-----------------------------------
If  @ErrorCode = 0
and @pnCaseId is null
and @pnNameNo is null
Begin
	RAISERROR('@pnCaseId and @pnNameNo must not both be NULL', 14, 1)
	Set @ErrorCode = @@ERROR
End

-- Get the next unique Activity Number

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update	LASTINTERNALCODE
	set	INTERNALSEQUENCE=INTERNALSEQUENCE+1,
		@nActivityNo    =INTERNALSEQUENCE+1
	where	TABLENAME='ACTIVITY'

	select @ErrorCode=@@Error
End

if  @nActivityNo is null
and @ErrorCode = 0
Begin
	select @nActivityNo=1
	insert into LASTINTERNALCODE(TABLENAME, INTERNALSEQUENCE) values ('ACTIVITY', @nActivityNo)

	select @ErrorCode=@@Error
End

If @ErrorCode=0
begin
	If @pnCaseId is not null
	begin
		insert into ACTIVITY (ACTIVITYNO, ACTIVITYDATE, CASEID, INCOMPLETE, SUMMARY, ACTIVITYCATEGORY, ACTIVITYTYPE, REFERENCENO, EMPLOYEENO, LONGFLAG)
		select @nActivityNo, getdate(), @pnCaseId, 0, @psSummary, 5902, 5806,  @psReference, isnull(NA.NAMENO, S.COLINTEGER), 0
		from SITECONTROL S
		left join NAMEALIAS NA	on (NA.ALIAS=system_user
					and NA.ALIASTYPE='U'
					and NA.ALIASNO=	(select min(NA1.ALIASNO)
							 from NAMEALIAS NA1
							 where NA1.ALIAS=NA.ALIAS
							 and   NA1.ALIASTYPE=NA.ALIASTYPE
							 and   NA1.COUNTRYCODE  is null
							 and   NA1.PROPERTYTYPE is null) )
		where S.CONTROLID='CMDEFAULTEMPLOYEE'

		select @ErrorCode=@@Error
	End
	Else begin
		insert into ACTIVITY (ACTIVITYNO, ACTIVITYDATE, NAMENO, INCOMPLETE, SUMMARY, ACTIVITYCATEGORY, ACTIVITYTYPE, REFERENCENO, EMPLOYEENO, LONGFLAG)
		select @nActivityNo, getdate(), @pnNameNo, 0, @psSummary, 5902, 5806,  @psReference, isnull(NA.NAMENO, S.COLINTEGER), 0
		from SITECONTROL S
		left join NAMEALIAS NA	on (NA.ALIAS=system_user
					and NA.ALIASTYPE='U'
					and NA.ALIASNO=	(select min(NA1.ALIASNO)
							 from NAMEALIAS NA1
							 where NA1.ALIAS=NA.ALIAS
							 and   NA1.ALIASTYPE=NA.ALIASTYPE
							 and   NA1.COUNTRYCODE  is null
							 and   NA1.PROPERTYTYPE is null) )
		where S.CONTROLID='CMDEFAULTEMPLOYEE'

		select @ErrorCode=@@Error
	End
End

If @ErrorCode=0
Begin
	insert into ACTIVITYATTACHMENT (ACTIVITYNO, SEQUENCENO, ATTACHMENTNAME, FILENAME)
	values (@nActivityNo, 0, @psDocName, @psFileName)

	select @ErrorCode=@@Error
End

-- Commit or Rollback the transaction

If @@TranCount > @TranCountStart
Begin
	If @ErrorCode = 0
		COMMIT TRANSACTION
	Else
		ROLLBACK TRANSACTION
End

select @psCaseId -- Modified by ZA needs to bring something back

Return (@ErrorCode)
go

grant execute on dbo.pt_CreateActivityForDocument to public
go
