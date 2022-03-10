-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_ProcessCaseNames
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_ProcessCaseNames]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_ProcessCaseNames.'
	Drop procedure [dbo].[crm_ProcessCaseNames]
End
Print '**** Creating Stored Procedure dbo.crm_ProcessCaseNames...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.crm_ProcessCaseNames
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey			int, -- Mandatory
	@psNameTypeKey		nvarchar(6), -- Mandatory
	@psOperation		nvarchar(50), -- Mandatory
	@psObjectKey		nvarchar(15) = null,
	@ptXMLDetails	ntext, -- Mandatory
	@pnDebugFlag		bit = 0
)
as
-- PROCEDURE:	crm_ProcessCaseNames
-- VERSION:	8
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Allow Bulk processing of CRM Case Names, e.g. 
--				(a) Add or remove a large number of case names at once.
--				(b) Update details of a large number of case names at once
--				This stored procedure is invoked from a screen with a name type that 
--				- has NAMETYPE.BULKENTRYFLAG set
--				- is a CRM name type
--				- has "show data fields - Correspondence" set against it

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 Aug 2008	SF		RFC5715	1		Procedure created
-- 03 Sep 2008	SF		RFC5713	2		Implement Add Case Names in bulk functionality
-- 04 Sep 2008	SF		RFC5713 3		Implement review feedback
-- 22 Sep 2008	SF		RFC5713	4		Change Alert message ids to ones not yet allocated.
-- 24 Sep 2008	SF		RFC5713 5		Implement logic to default DERIVEDCORRNAME for new names added
-- 30 Sep 2008	SF		RFC7119	6		Unable to add the first case name because SEQUENCE yield null
-- 05 Jan 2009	SF		RFC7450 	7		Default IsCorrespondenceSent to 0 when adding.
-- 14 Nov 2018  AV  75198/DR-45358	8   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(4000)
Declare @idoc 		int 	-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument


declare	@dtToday		datetime
declare	@sTimeStamp		nvarchar(24)
declare @sDate			nvarchar(20)
declare @nRowCount		int
declare @sRowCount		nvarchar(12)
declare @sAlertXML		nvarchar(400)
declare @nMaxSequence	int

declare @sNameTypeDescription nvarchar(100)

create table #TEMPCRMCASENAMES
		(	ROWID		int	identity(1,1) not null,
			NAMENO			int	not null,
			SEQUENCE		int null,  -- will be available nontheless.
		)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
and @psOperation not in ('AddCaseNames','RemoveCaseNames','SetResponse','SetSentStatus')
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('CS86', '%s is not a supported operation.',
      							@psOperation, null, null, null, null)
    RAISERROR(@sAlertXML, 14, 1, @psOperation)
    Set @nErrorCode = @@ERROR
End 

If @nErrorCode = 0
and exists (select * 
			from NAMETYPE 
			where NAMETYPE = @psNameTypeKey 
			and ((Cast(COLUMNFLAGS & 2048 as bit) = 0 
				  and @psOperation in ('SetSentStatus', 'SetResponse'))	/* CORRESPONDENCE DETAILS can be altered */
			or (PICKLISTFLAGS & 32 <> 32)				/* A CRM Name Type */
			or NAMETYPE.BULKENTRYFLAG = 0))				/* A Name Type that can be processed in bulk */
Begin	
	Select @sNameTypeDescription = DESCRIPTION
	from NAMETYPE 
	where NAMETYPE = @psNameTypeKey

	Set @sAlertXML = dbo.fn_GetAlertXML('CS87', 'The %s name type does not meet requirements for bulk processing.',
      							@sNameTypeDescription, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1, @sNameTypeDescription)
    Set @nErrorCode = @@ERROR
End

-- Extract information from XML document
If @nErrorCode = 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLDetails

	Set @nErrorCode=@@ERROR

	If @nErrorCode = 0	
	Begin
		If @psOperation = 'AddCaseNames'
		Begin 
			
			Set @sSQLString =
			"insert into #TEMPCRMCASENAMES(NAMENO)"+CHAR(10)+
			"Select NameKey"+CHAR(10)+
			"from	OPENXML (@idoc, '//AddAsCaseName',2)"+CHAR(10)+
			"	WITH (NameKey			int	'NameKey/text()') X"+CHAR(10)+
			"left join CASENAME CN on (CN.CASEID = @pnCaseKey "+CHAR(10)+
			"						and CN.NAMETYPE = @psNameTypeKey "+CHAR(10)+
			"						and CN.NAMENO = X.NameKey)"+CHAR(10)+
			"where CN.NAMENO is null"

			exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int,
						@pnCaseKey		int,
						@psNameTypeKey	nvarchar(6)',
					@idoc				= @idoc,
					@pnCaseKey			= @pnCaseKey,
					@psNameTypeKey		= @psNameTypeKey

			set @nRowCount=@@ROWCOUNT

			If @nErrorCode = 0	
			and @nRowCount > 0
			Begin
				-- some rows have been inserted, so now get the maximum sequence
				Set @sSQLString = "
				Select	@nMaxSequence = isnull(max(CN.SEQUENCE),0)
				from	CASENAME CN
				where	CN.CASEID = @pnCaseKey
				and		CN.NAMETYPE = @psNameTypeKey"
			
				exec @nErrorCode = sp_executesql @sSQLString,
					N'	@nMaxSequence	int output,
						@pnCaseKey		int,
						@psNameTypeKey	nvarchar(6)',
					@nMaxSequence		= @nMaxSequence output,
					@pnCaseKey			= @pnCaseKey,
					@psNameTypeKey		= @psNameTypeKey

				-- update sequence
				Set @sSQLString = 
				"update #TEMPCRMCASENAMES 
					set SEQUENCE = ROWID+@nMaxSequence"

				exec @nErrorCode = sp_executesql @sSQLString,
					N'	@nMaxSequence	int',
						@nMaxSequence	= @nMaxSequence
			End
		End
		Else
		Begin
			Set @sSQLString =
			"insert into #TEMPCRMCASENAMES(NAMENO, SEQUENCE)"+CHAR(10)+
			"Select NameKey, Sequence"+CHAR(10)+
			"from	OPENXML (@idoc, '//CaseName',2)"+CHAR(10)+
			"	WITH (NameKey			int	'NameKey/text()',
					  Sequence	int	'Sequence/text()'
					 ) X
			"

			exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int',
					@idoc				= @idoc

			set @nRowCount=@@ROWCOUNT			
		End
	End
	
	If  @pnDebugFlag>=1
	Begin
		SELECT * FROM #TEMPCRMCASENAMES
	End
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error
End

If @nErrorCode=0
and @psOperation = 'AddCaseNames'
and exists (select * from #TEMPCRMCASENAMES)
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s crm_ProcessCaseNames-Commence adding new names to case',0,1,@sTimeStamp ) with NOWAIT
	End

	/* DERIVEDCORRNAME is set to one because the user interface does not allow attention names to be entered.
		according to business rules: when attention name is null DERIVEDCORRNAME is set to 1 and CORRESPONDNAME it will be defaulted. */
	Set @sSQLString="
	insert	CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, DERIVEDCORRNAME, CORRESPONDNAME, CORRESPSENT)
	select	@pnCaseKey, @psNameTypeKey, T.NAMENO, T.SEQUENCE, 1, 
			dbo.fn_GetDerivedAttnNameNo(T.NAMENO, @pnCaseKey, @psNameTypeKey), 0
	from	#TEMPCRMCASENAMES T"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey	int,
				@psNameTypeKey	nvarchar(6)',
				@pnCaseKey	= @pnCaseKey,
				@psNameTypeKey = @psNameTypeKey

	set @nRowCount=@@ROWCOUNT

	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		set	@sRowCount=cast(@nRowCount as nvarchar(12))
		RAISERROR ('%s crm_ProcessCaseNames-names added to case %s',0,1,@sTimeStamp,@sRowCount ) with NOWAIT
	End

	-- ensure that NameTypeClassification for these names are set as allowed.
	If @nErrorCode=0
	and @nRowCount>0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s crm_ProcessCaseNames-Commence setting NAMETYPECLASSIFICATION for new names to added',0,1,@sTimeStamp ) with NOWAIT
		End

		-- Update existing name type classifications
		Set @sSQLString="
			update	NAMETYPECLASSIFICATION
			set		ALLOW = 1
			from	#TEMPCRMCASENAMES T
			join	NAMETYPECLASSIFICATION NT on (NT.NAMENO=T.NAMENO)
			where	NT.NAMETYPE = @psNameTypeKey"
	
		exec @nErrorCode = sp_executesql @sSQLString,
				N'@psNameTypeKey	nvarchar(6)',				
				@psNameTypeKey = @psNameTypeKey

		set @nRowCount=@@ROWCOUNT

		-- Insert new name type classifications
		If @nErrorCode = 0
		Begin	
			Set @sSQLString="
				insert		into NAMETYPECLASSIFICATION(NAMENO,NAMETYPE,ALLOW)
				select		T.NAMENO, @psNameTypeKey, 1
				from		#TEMPCRMCASENAMES T
				left join	NAMETYPECLASSIFICATION NC on (NC.NAMENO = T.NAMENO and NC.NAMETYPE = @psNameTypeKey)
				where		NC.NAMENO IS NULL"

			exec @nErrorCode = sp_executesql @sSQLString,
				N'@psNameTypeKey	nvarchar(6)',				
				@psNameTypeKey = @psNameTypeKey

			set @nRowCount=@@ROWCOUNT
		End
		
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			set	@sRowCount=cast(@nRowCount as nvarchar(12))
			RAISERROR ('%s crm_ProcessCaseNames-NAMETYPECLASSIFICATION for names added to case have been set %s',0,1,@sTimeStamp,@sRowCount ) with NOWAIT
		End	
	End
End

If @nErrorCode=0
and @psOperation = 'RemoveCaseNames'  -- Remove case names
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s crm_ProcessCaseNames-Commence removing existing casenames',0,1,@sTimeStamp ) with NOWAIT
	End

	Set @sSQLString="
	Delete 	CASENAME
	from	#TEMPCRMCASENAMES T
	where	CASENAME.CASEID = @pnCaseKey
	and		CASENAME.NAMETYPE = @psNameTypeKey
	and		CASENAME.NAMENO = T.NAMENO
	and		CASENAME.SEQUENCE = T.SEQUENCE"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey	int,
				@psNameTypeKey	nvarchar(6)',
				@pnCaseKey	= @pnCaseKey,
				@psNameTypeKey = @psNameTypeKey

	set @nRowCount=@@ROWCOUNT

	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		set	@sRowCount=cast(@nRowCount as nvarchar(12))
		RAISERROR ('%s crm_ProcessCaseNames-Existing casenames removed %s',0,1,@sTimeStamp,@sRowCount ) with NOWAIT
	End
End
Else
If @nErrorCode=0
and @psOperation in ('SetResponse','SetSentStatus')  -- Set correspondence details 
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s crm_ProcessCaseNames-Commence updating existing casenames',0,1,@sTimeStamp ) with NOWAIT
	End

	Set @sSQLString="
	Update	CASENAME
	set	CORRESPSENT = CASE WHEN @psOperation = N'SetSentStatus' THEN cast(@psObjectKey as bit) ELSE CORRESPSENT END,
		CORRESPRECEIVED = CASE WHEN @psOperation = N'SetResponse' THEN cast(@psObjectKey as int) ELSE CORRESPRECEIVED END
	from	#TEMPCRMCASENAMES T
	where	CASENAME.CASEID = @pnCaseKey
	and		CASENAME.NAMETYPE = @psNameTypeKey
	and		CASENAME.NAMENO = T.NAMENO
	and		CASENAME.SEQUENCE = T.SEQUENCE"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey	int,
				@psNameTypeKey	nvarchar(6),
				@psOperation	nvarchar(50),
				@psObjectKey	nvarchar(15)',
				@pnCaseKey		= @pnCaseKey,
				@psNameTypeKey	= @psNameTypeKey,
				@psOperation	= @psOperation,
				@psObjectKey	= @psObjectKey

	set @nRowCount=@@ROWCOUNT

	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		set	@sRowCount=cast(@nRowCount as nvarchar(12))
		RAISERROR ('%s crm_ProcessCaseNames-Existing casenames updated %s',0,1,@sTimeStamp,@sRowCount ) with NOWAIT
	End
End

Return @nErrorCode
GO

Grant execute on dbo.crm_ProcessCaseNames to public
GO
