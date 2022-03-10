-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ProcessInstructions
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ProcessInstructions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ProcessInstructions.'
	Drop procedure [dbo].[csw_ProcessInstructions]
End
Print '**** Creating Stored Procedure dbo.csw_ProcessInstructions...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ProcessInstructions
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@ptXMLInstructions	nvarchar(max),
	@pnDebugFlag		tinyint		= 0 --0=off,1=trace execution,2=dump data

)
as
-- PROCEDURE:	csw_ProcessInstructions
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Process the instructions provided in the XML.
--		Logic is written for bulk processing of mulitple cases if necessary.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 Dec 2006	JEK	RFC2982	1	Procedure created
-- 17 Nov 2008	AT	RFC7204	2	Update Occurred Flag on existing events.
-- 27 May 2015  MS      R47412  3       Changed datatype of #TEMPINSTRUCTIONS.NOTES from ntext to nvarchar(max)	
-- 15 Jun 2015  MS      R24564  4       Add COLLATE database_default to Notes colunm
-- 02 Aug 2016	MF	64248	5	CaseEvent for EventNo -14 will now be updated by database trigger so no need to perform this directly.	
-- 14 Nov 2018  AV  75198/DR-45358	6   Date conversion errors when creating cases and opening names in Chinese DB


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(4000)
Declare @idoc 		int 	-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument

declare	@dtInstructionDate	datetime
declare	@dtToday		datetime
declare	@sTimeStamp		nvarchar(24)
declare @sDate			nvarchar(20)
declare @nRowCount		int
declare @sRowCount		nvarchar(12)

create table #TEMPINSTRUCTIONS
		(	SEQUENCENO		int	identity(1,1) not null,
			CASEKEY			int	not null,
			INSTRUCTIONCYCLE	smallint not null default 1,
			FIREEVENTNO		int	not null,
			NOTES			nvarchar(max) COLLATE database_default null
		)

-- Initialise variables
Set @nErrorCode = 0

If  @pnDebugFlag>0
Begin
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s csw_ProcessInstructions-Commence Processing',0,1,@sTimeStamp ) with NOWAIT
End

-- Get current application date
If @nErrorCode = 0
Begin
	exec @nErrorCode=ip_GetCurrentDate
		@pdtCurrentDate=@dtToday	output,
		@pnUserIdentityId=@pnUserIdentityId,
		@psDateType='A', -- application date
		@pbIncludeTime=0
End

-- Extract information from XML document
If @nErrorCode = 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLInstructions

	Set @nErrorCode=@@ERROR

	If @nErrorCode = 0
	Begin
		Set @sSQLString =
		"Select @dtInstructionDate	= InstructionDate"+CHAR(10)+	
		"from	OPENXML (@idoc, '//Instructions',2)"+CHAR(10)+
		"	WITH (InstructionDate		datetime	'InstructionDate/text()')"
	
		exec @nErrorCode = sp_executesql @sSQLString,
			N'@idoc			int,					  
			@dtInstructionDate	datetime		output',
			@idoc			= @idoc,
			@dtInstructionDate	= @dtInstructionDate	output


		set @dtInstructionDate=isnull(@dtInstructionDate, @dtToday)

		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			set	@sDate=convert(nvarchar,@dtInstructionDate,106)
			RAISERROR ('%s csw_ProcessInstructions-Instruction Date %s',0,1,@sTimeStamp,@sDate ) with NOWAIT
		End
	End

	If @nErrorCode = 0
	Begin
		Set @sSQLString =
		"insert into #TEMPINSTRUCTIONS(CASEKEY, INSTRUCTIONCYCLE, FIREEVENTNO, NOTES)"+CHAR(10)+
		"Select CaseKey, InstructionCycle, R.FIREEVENTNO, Notes"+CHAR(10)+
		"from	OPENXML (@idoc, '//Instructions/Instruction',2)"+CHAR(10)+
		"	WITH (CaseKey			int	'CaseKey/text()',
			      InstructionDefinitionKey	int	'InstructionDefinitionKey/text()',
			      InstructionCycle		smallint	'InstructionCycle/text()',
			      ResponseNo		tinyint	'ResponseNo/text()',
			      Notes			nvarchar(max)	'Notes/text()'
			     ) X
		join	INSTRUCTIONRESPONSE R	on (R.DEFINITIONID=X.InstructionDefinitionKey
						and R.SEQUENCENO=X.ResponseNo)"
	
		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int',
					@idoc				= @idoc

		set @nRowCount=@@ROWCOUNT

		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			set	@sRowCount=cast(@nRowCount as nvarchar(12))
			RAISERROR ('%s csw_ProcessInstructions-Rows inserted into #TEMPINSTRUCTIONS %s',0,1,@sTimeStamp,@sRowCount ) with NOWAIT
		End

		If  @pnDebugFlag>1
		Begin
			SELECT * FROM #TEMPINSTRUCTIONS
		End
	End

	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error

End

-- 1. Update any existing events
If @nErrorCode=0
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s csw_ProcessInstructions-Commence updating existing events',0,1,@sTimeStamp ) with NOWAIT
	End

	Set @sSQLString="
	Update	CASEEVENT
	set	EVENTDATE=@dtInstructionDate,
		OCCURREDFLAG=1,
		EVENTTEXT = case when isnull(datalength(T.NOTES),0)=0 then EVENTTEXT
				 when datalength(T.NOTES)<=508 THEN T.NOTES
				 else null
			    end,
		EVENTLONGTEXT = case when isnull(datalength(T.NOTES),0)=0 then EVENTLONGTEXT
				     when datalength(T.NOTES)<=508 then null
				      else T.NOTES
			        end,
		LONGFLAG = case when isnull(datalength(T.NOTES),0)=0 then LONGFLAG
				when datalength(T.NOTES)>508 then 1
				else 0
			    end
	from	#TEMPINSTRUCTIONS T
	where	CASEEVENT.CASEID=T.CASEKEY
	and	CASEEVENT.EVENTNO=T.FIREEVENTNO
	and	CASEEVENT.CYCLE=T.INSTRUCTIONCYCLE"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@dtInstructionDate	datetime',
				@dtInstructionDate	= @dtInstructionDate

	set @nRowCount=@@ROWCOUNT

	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		set	@sRowCount=cast(@nRowCount as nvarchar(12))
		RAISERROR ('%s csw_ProcessInstructions-Existing events updated %s',0,1,@sTimeStamp,@sRowCount ) with NOWAIT
	End
End

-- 2. Insert any new events
If @nErrorCode=0
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s csw_ProcessInstructions-Commence inserting new events',0,1,@sTimeStamp ) with NOWAIT
	End

	Set @sSQLString="
	insert into CASEEVENT (CASEID,EVENTNO,CYCLE,EVENTDATE,OCCURREDFLAG,
				DATEDUESAVED,EVENTTEXT,EVENTLONGTEXT,LONGFLAG)
	select	CASEKEY,
		FIREEVENTNO,
		INSTRUCTIONCYCLE,
		@dtInstructionDate,
		1,
		0,
		case when datalength(T.NOTES)<=508 then T.NOTES
		     else null
		end,
		case when datalength(T.NOTES)<=508 then null
		     else T.NOTES
		end,
		case when datalength(T.NOTES)>508 then 1
		     else 0
		end
	from	#TEMPINSTRUCTIONS T
	left join CASEEVENT CE		on (CE.CASEID=T.CASEKEY
					and CE.EVENTNO=T.FIREEVENTNO
					and CE.CYCLE=T.INSTRUCTIONCYCLE)
	where	CE.CASEID is null"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@dtInstructionDate	datetime',
				@dtInstructionDate	= @dtInstructionDate

	set @nRowCount=@@ROWCOUNT

	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		set	@sRowCount=cast(@nRowCount as nvarchar(12))
		RAISERROR ('%s csw_ProcessInstructions-events inserted %s',0,1,@sTimeStamp,@sRowCount ) with NOWAIT
	End
End

-- 3. Police all the events
If @nErrorCode=0
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s csw_ProcessInstructions-Commence adding to policing queue',0,1,@sTimeStamp ) with NOWAIT
	End

	Set @sSQLString="
	insert into POLICING (DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, ONHOLDFLAG, 
		CASEID, EVENTNO, CYCLE, 
		TYPEOFREQUEST, SQLUSER, IDENTITYID)
	select getdate(), T.SEQUENCENO, convert(varchar, getdate(), 109)+' '+convert(varchar,T.SEQUENCENO), 1,0,
		T.CASEKEY, T.FIREEVENTNO, T.INSTRUCTIONCYCLE, 
		3, -- Police Occurred Event
		SYSTEM_USER, @pnUserIdentityId
	from #TEMPINSTRUCTIONS T"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnUserIdentityId	int',
				@pnUserIdentityId	= @pnUserIdentityId

	set @nRowCount=@@ROWCOUNT

	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		set	@sRowCount=cast(@nRowCount as nvarchar(12))
		RAISERROR ('%s csw_ProcessInstructions-events added to policing %s',0,1,@sTimeStamp,@sRowCount ) with NOWAIT
	End

End

Return @nErrorCode
GO

Grant execute on dbo.csw_ProcessInstructions to public
GO
