-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ChangeCriteriaNo
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ChangeCriteriaNo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ChangeCriteriaNo.'
	Drop procedure [dbo].[ip_ChangeCriteriaNo]
End
Print '**** Creating Stored Procedure dbo.ip_ChangeCriteriaNo...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ip_ChangeCriteriaNo
(
	@pnOldCriteriaNo	int,
	@pnNewCriteriaNo	int
)
as
-- PROCEDURE:	ip_ChangeCriteriaNo
-- VERSION:	7
-- DESCRIPTION:	Used to modify the CriteriaNo of a Criteria from one value to another.
--		The CriteriaNo is used in multiply places and referential integrity
--		will stop it from just being updated in the base CRITERIA table.
-- COPYRIGHT:	Copyright 1993 - 2006 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 09-Mar-2005  MF		1	Procedure created
-- 19-May-2006  DL		2	Add new columns in the CRITERIA table (NEWCASETYPE, NEWCOUNTRYCODE, NEWPROPERTYTYPE, NEWCASECATEGORY, PROFILENAME, SYSTEMID)
-- 31-Jan-2008	JS		3	Added new columns PARENTCRITERIANO and PARENTENTRYNUMBER in DETAILCONTROL.
-- 04-Jul-2009	MF	17926	4	REMINDERS table changed from UPDATE to an INSERT and DELETE because INSTEAD OF trigger on table was
--					resetting the CRITERIANO back to the original value.
-- 25-Feb-2010	DL	8892	5	Change CRITERIANO for table TOPICDEFAULTSETTINGS and WINDOWCONTROL
-- 23-Jul-2013  DL	21395	6	Add new columns in the CRITERIA table NEWSUBTYPE.
-- 23 Mar 2017	MF	61729	7	Cater for new ROLESCONTROL table that can be used to indicate who has access to an Entry.
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @ErrorCode 	int
Declare @TranCountStart	int

Declare @sSQLString	nvarchar(4000)

Set 	@ErrorCode      = 0

Select @TranCountStart = @@TranCount

Begin TRANSACTION

-- If the NewCriteriaNo already exists in the CRITERIA table
-- then set the @ErrorCode to terminate processing
	
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @ErrorCode=count(*)
	from CRITERIA
	where CRITERIANO=@pnNewCriteriaNo"

	exec sp_executesql @sSQLString,
				N'@ErrorCode		int		OUTPUT,
				  @pnNewCriteriaNo	int',
				  @ErrorCode=@ErrorCode	OUTPUT,
				  @pnNewCriteriaNo=@pnNewCriteriaNo
End

-- Copy the details of the existing CRITERIA row with the NewCriteriaNo if it does not already exist.

If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into CRITERIA(CRITERIANO,PURPOSECODE, CASETYPE, ACTION, CHECKLISTTYPE, PROGRAMID, PROPERTYTYPE, PROPERTYUNKNOWN, COUNTRYCODE, COUNTRYUNKNOWN, CASECATEGORY, CATEGORYUNKNOWN, SUBTYPE, SUBTYPEUNKNOWN, BASIS, REGISTEREDUSERS, LOCALCLIENTFLAG, TABLECODE, RATENO, DATEOFACT, USERDEFINEDRULE, RULEINUSE, STARTDETAILENTRY, PARENTCRITERIA, BELONGSTOGROUP, DESCRIPTION, TYPEOFMARK, RENEWALTYPE, DESCRIPTION_TID, CASEOFFICEID, LINKTITLE, LINKTITLE_TID, LINKDESCRIPTION, LINKDESCRIPTION_TID, DOCITEMID, URL, ISPUBLIC, GROUPID, PRODUCTCODE, NEWCASETYPE, NEWCOUNTRYCODE, NEWPROPERTYTYPE, NEWCASECATEGORY, NEWSUBTYPE, PROFILENAME, SYSTEMID)
	select         @pnNewCriteriaNo,PURPOSECODE, CASETYPE, ACTION, CHECKLISTTYPE, PROGRAMID, PROPERTYTYPE, PROPERTYUNKNOWN, COUNTRYCODE, COUNTRYUNKNOWN, CASECATEGORY, CATEGORYUNKNOWN, SUBTYPE, SUBTYPEUNKNOWN, BASIS, REGISTEREDUSERS, LOCALCLIENTFLAG, TABLECODE, RATENO, DATEOFACT, USERDEFINEDRULE, RULEINUSE, STARTDETAILENTRY, PARENTCRITERIA, BELONGSTOGROUP, DESCRIPTION, TYPEOFMARK, RENEWALTYPE, DESCRIPTION_TID, CASEOFFICEID, LINKTITLE, LINKTITLE_TID, LINKDESCRIPTION, LINKDESCRIPTION_TID, DOCITEMID, URL, ISPUBLIC, GROUPID, PRODUCTCODE, NEWCASETYPE, NEWCOUNTRYCODE, NEWPROPERTYTYPE, NEWCASECATEGORY, NEWSUBTYPE, PROFILENAME, SYSTEMID 
	from CRITERIA C
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

-- Update the LASTINTERNALCODE to ensure the CriteriaNo just inserted is taken care of.

If @ErrorCode=0
Begin
	Set @sSQLString="
	Update 	LASTINTERNALCODE
	set 	INTERNALSEQUENCE= (select CASE 	WHEN max( CRITERIANO ) is null THEN 500
                                           	WHEN max( CRITERIANO ) < 0     THEN 500
		                                ELSE max( CRITERIANO )
	                              	   END 
				   from CRITERIA)
	where TABLENAME='CRITERIA'"

	exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	Update LASTINTERNALCODE 
	set INTERNALSEQUENCE=  (select CASE 	WHEN min( CRITERIANO ) is null THEN 0
                                           	WHEN min( CRITERIANO ) > 0     THEN 0
		                                ELSE min( CRITERIANO )
	                              	   END
				from CRITERIA)
	where TABLENAME='CRITERIA_MAXIM'"

	exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into EVENTCONTROL(CRITERIANO,EVENTNO, EVENTDESCRIPTION, DISPLAYSEQUENCE, PARENTCRITERIANO, PARENTEVENTNO, NUMCYCLESALLOWED, IMPORTANCELEVEL, WHICHDUEDATE, COMPAREBOOLEAN, CHECKCOUNTRYFLAG, SAVEDUEDATE, STATUSCODE, SPECIALFUNCTION, INITIALFEE, PAYFEECODE, CREATEACTION, STATUSDESC, CLOSEACTION, UPDATEFROMEVENT, FROMRELATIONSHIP, FROMANCESTOR, UPDATEMANUALLY, ADJUSTMENT, DOCUMENTNO, NOOFDOCS, MANDATORYDOCS, NOTES, INHERITED, INSTRUCTIONTYPE, FLAGNUMBER, SETTHIRDPARTYON, RELATIVECYCLE, CREATECYCLE, ESTIMATEFLAG, EXTENDPERIOD, EXTENDPERIODTYPE, INITIALFEE2, PAYFEECODE2, ESTIMATEFLAG2, EVENTDESCRIPTION_TID, NOTES_TID, STATUSDESC_TID, PTADELAY, SETTHIRDPARTYOFF,RECEIVINGCYCLEFLAG)
	select             @pnNewCriteriaNo,EVENTNO, EVENTDESCRIPTION, DISPLAYSEQUENCE, PARENTCRITERIANO, PARENTEVENTNO, NUMCYCLESALLOWED, IMPORTANCELEVEL, WHICHDUEDATE, COMPAREBOOLEAN, CHECKCOUNTRYFLAG, SAVEDUEDATE, STATUSCODE, SPECIALFUNCTION, INITIALFEE, PAYFEECODE, CREATEACTION, STATUSDESC, CLOSEACTION, UPDATEFROMEVENT, FROMRELATIONSHIP, FROMANCESTOR, UPDATEMANUALLY, ADJUSTMENT, DOCUMENTNO, NOOFDOCS, MANDATORYDOCS, NOTES, INHERITED, INSTRUCTIONTYPE, FLAGNUMBER, SETTHIRDPARTYON, RELATIVECYCLE, CREATECYCLE, ESTIMATEFLAG, EXTENDPERIOD, EXTENDPERIODTYPE, INITIALFEE2, PAYFEECODE2, ESTIMATEFLAG2, EVENTDESCRIPTION_TID, NOTES_TID, STATUSDESC_TID, PTADELAY, SETTHIRDPARTYOFF,RECEIVINGCYCLEFLAG
	from EVENTCONTROL
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End


if @ErrorCode=0
Begin
	Set @sSQLString="
	insert into REMINDERS(CRITERIANO, EVENTNO, REMINDERNO, PERIODTYPE, LEADTIME, FREQUENCY, STOPTIME, UPDATEEVENT, LETTERNO, CHECKOVERRIDE, MAXLETTERS, LETTERFEE, PAYFEECODE, EMPLOYEEFLAG, SIGNATORYFLAG, INSTRUCTORFLAG, CRITICALFLAG, REMINDEMPLOYEE, USEMESSAGE1, MESSAGE1, MESSAGE2, INHERITED, NAMETYPE, SENDELECTRONICALLY, EMAILSUBJECT, ESTIMATEFLAG, FREQPERIODTYPE, STOPTIMEPERIODTYPE, DIRECTPAYFLAG, RELATIONSHIP)
	select          @pnNewCriteriaNo, EVENTNO, REMINDERNO, PERIODTYPE, LEADTIME, FREQUENCY, STOPTIME, UPDATEEVENT, LETTERNO, CHECKOVERRIDE, MAXLETTERS, LETTERFEE, PAYFEECODE, EMPLOYEEFLAG, SIGNATORYFLAG, INSTRUCTORFLAG, CRITICALFLAG, REMINDEMPLOYEE, USEMESSAGE1, MESSAGE1, MESSAGE2, INHERITED, NAMETYPE, SENDELECTRONICALLY, EMAILSUBJECT, ESTIMATEFLAG, FREQPERIODTYPE, STOPTIMEPERIODTYPE, DIRECTPAYFLAG, RELATIONSHIP
	from REMINDERS
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into DETAILCONTROL(CRITERIANO,ENTRYNUMBER, ENTRYDESC, TAKEOVERFLAG, DISPLAYSEQUENCE, STATUSCODE, RENEWALSTATUS, FILELOCATION, NUMBERTYPE, ATLEAST1FLAG, USERINSTRUCTION, INHERITED, ENTRYCODE, CHARGEGENERATION, DISPLAYEVENTNO, HIDEEVENTNO, DIMEVENTNO, SHOWTABS, SHOWMENUS, SHOWTOOLBAR, PARENTCRITERIANO, PARENTENTRYNUMBER)
	select              @pnNewCriteriaNo,ENTRYNUMBER, ENTRYDESC, TAKEOVERFLAG, DISPLAYSEQUENCE, STATUSCODE, RENEWALSTATUS, FILELOCATION, NUMBERTYPE, ATLEAST1FLAG, USERINSTRUCTION, INHERITED, ENTRYCODE, CHARGEGENERATION, DISPLAYEVENTNO, HIDEEVENTNO, DIMEVENTNO, SHOWTABS, SHOWMENUS, SHOWTOOLBAR, PARENTCRITERIANO, PARENTENTRYNUMBER
	from DETAILCONTROL
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into FEESCALCULATION(CRITERIANO,UNIQUEID, AGENT, DEBTORTYPE, DEBTOR, CYCLENUMBER, VALIDFROMDATE, DEBITNOTE, COVERINGLETTER, GENERATECHARGES, FEETYPE, IPOFFICEFEEFLAG, DISBCURRENCY, DISBTAXCODE, DISBNARRATIVE, DISBWIPCODE, DISBBASEFEE, DISBMINFEEFLAG, DISBVARIABLEFEE, DISBADDPERCENTAGE, DISBUNITSIZE, DISBBASEUNITS, SERVICECURRENCY, SERVTAXCODE, SERVICENARRATIVE, SERVWIPCODE, SERVBASEFEE, SERVMINFEEFLAG, SERVVARIABLEFEE, SERVADDPERCENTAGE, SERVDISBPERCENTAGE, SERVUNITSIZE, SERVBASEUNITS, INHERITED, PARAMETERSOURCE, DISBMAXUNITS, SERVMAXUNITS, DISBEMPLOYEENO, SERVEMPLOYEENO, VARBASEFEE, VARBASEUNITS, VARVARIABLEFEE, VARUNITSIZE, VARMAXUNITS, VARMINFEEFLAG, WRITEUPREASON, VARWIPCODE, VARFEEAPPLIES, OWNER, INSTRUCTOR, PRODUCTCODE)
	select                @pnNewCriteriaNo,UNIQUEID, AGENT, DEBTORTYPE, DEBTOR, CYCLENUMBER, VALIDFROMDATE, DEBITNOTE, COVERINGLETTER, GENERATECHARGES, FEETYPE, IPOFFICEFEEFLAG, DISBCURRENCY, DISBTAXCODE, DISBNARRATIVE, DISBWIPCODE, DISBBASEFEE, DISBMINFEEFLAG, DISBVARIABLEFEE, DISBADDPERCENTAGE, DISBUNITSIZE, DISBBASEUNITS, SERVICECURRENCY, SERVTAXCODE, SERVICENARRATIVE, SERVWIPCODE, SERVBASEFEE, SERVMINFEEFLAG, SERVVARIABLEFEE, SERVADDPERCENTAGE, SERVDISBPERCENTAGE, SERVUNITSIZE, SERVBASEUNITS, INHERITED, PARAMETERSOURCE, DISBMAXUNITS, SERVMAXUNITS, DISBEMPLOYEENO, SERVEMPLOYEENO, VARBASEFEE, VARBASEUNITS, VARVARIABLEFEE, VARUNITSIZE, VARMAXUNITS, VARMINFEEFLAG, WRITEUPREASON, VARWIPCODE, VARFEEAPPLIES, OWNER, INSTRUCTOR, PRODUCTCODE
	from FEESCALCULATION
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into SCREENCONTROL(CRITERIANO,SCREENNAME, SCREENID, ENTRYNUMBER, SCREENTITLE, DISPLAYSEQUENCE, CHECKLISTTYPE, TEXTTYPE, NAMETYPE, NAMEGROUP, FLAGNUMBER, CREATEACTION, RELATIONSHIP, INHERITED, PROFILENAME, SCREENTIP, MANDATORYFLAG, GENERICPARAMETER)
	select              @pnNewCriteriaNo,SCREENNAME, SCREENID, ENTRYNUMBER, SCREENTITLE, DISPLAYSEQUENCE, CHECKLISTTYPE, TEXTTYPE, NAMETYPE, NAMEGROUP, FLAGNUMBER, CREATEACTION, RELATIONSHIP, INHERITED, PROFILENAME, SCREENTIP, MANDATORYFLAG, GENERICPARAMETER
	from SCREENCONTROL SC
	where CRITERIANO=@pnOldCriteriaNo
	and not exists
	(select 1
	 from SCREENCONTROL SC1
	 where SC1.CRITERIANO=@pnNewCriteriaNo
	 and SC1.SCREENNAME=SC.SCREENNAME
	 and SC1.SCREENID  =SC.SCREENID)"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update CHECKLISTITEM
	set CRITERIANO=@pnNewCriteriaNo
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update CHECKLISTLETTER
	set CRITERIANO=@pnNewCriteriaNo
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update CRITERIA
	set PARENTCRITERIA=@pnNewCriteriaNo
	where PARENTCRITERIA=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update CRITERIACHANGES
	set CRITERIANO=@pnNewCriteriaNo
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update CRITERIACHANGES
	set OLDCRITERIANO=@pnNewCriteriaNo
	where OLDCRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update CRITERIACHANGES
	set NEWCRITERIANO=@pnNewCriteriaNo
	where NEWCRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update DATESLOGIC
	set CRITERIANO=@pnNewCriteriaNo
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update DETAILDATES
	set CRITERIANO=@pnNewCriteriaNo
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update DETAILLETTERS
	set CRITERIANO=@pnNewCriteriaNo
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update DUEDATECALC
	set CRITERIANO=@pnNewCriteriaNo
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update EVENTCONTROL
	set PARENTCRITERIANO=@pnNewCriteriaNo
	where PARENTCRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update DETAILCONTROL
	set PARENTCRITERIANO=@pnNewCriteriaNo
	where PARENTCRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update FEESCALCALT
	set CRITERIANO=@pnNewCriteriaNo
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End 

if @ErrorCode=0
Begin
	Set @sSQLString="
	update FIELDCONTROL
	set CRITERIANO=@pnNewCriteriaNo
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update GROUPCONTROL
	set CRITERIANO=@pnNewCriteriaNo
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update INHERITS
	set CRITERIANO=@pnNewCriteriaNo
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update INHERITS
	set FROMCRITERIA=@pnNewCriteriaNo
	where FROMCRITERIA=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update IRFORMAT
	set CRITERIANO=@pnNewCriteriaNo
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update POLICING
	set CRITERIANO=@pnNewCriteriaNo
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update POLICINGERRORS
	set CRITERIANO=@pnNewCriteriaNo
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update RELATEDEVENTS
	set CRITERIANO=@pnNewCriteriaNo
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update REQATTRIBUTES
	set CRITERIANO=@pnNewCriteriaNo
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update USERCONTROL
	set CRITERIANO=@pnNewCriteriaNo
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End 

if @ErrorCode=0
Begin
	Set @sSQLString="
	update ROLESCONTROL
	set CRITERIANO=@pnNewCriteriaNo
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End 

if @ErrorCode=0
Begin
	Set @sSQLString="
	update CASECHECKLIST
	set CRITERIANO=@pnNewCriteriaNo
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update CASEEVENT
	set CREATEDBYCRITERIA=@pnNewCriteriaNo
	where CREATEDBYCRITERIA=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update OPENACTION
	set CRITERIANO=@pnNewCriteriaNo
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

-- RFC8892
if @ErrorCode=0
Begin
	Set @sSQLString="
	update TOPICDEFAULTSETTINGS
	set CRITERIANO=@pnNewCriteriaNo
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update WINDOWCONTROL
	set CRITERIANO=@pnNewCriteriaNo
	where CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int,
					  @pnNewCriteriaNo	int',
					  @pnOldCriteriaNo,
					  @pnNewCriteriaNo
End


if @ErrorCode=0
Begin	
	Set @sSQLString="
	delete REMINDERS
	where  CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int',
					  @pnOldCriteriaNo
End

if @ErrorCode=0
Begin	
	Set @sSQLString="
	delete EVENTCONTROL
	where  CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int',
					  @pnOldCriteriaNo
End

if @ErrorCode=0
Begin	
	Set @sSQLString="
	delete DETAILCONTROL
	where  CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int',
					  @pnOldCriteriaNo
End

if @ErrorCode=0
Begin	
	Set @sSQLString="
	delete FEESCALCULATION
	where  CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int',
					  @pnOldCriteriaNo
End

if @ErrorCode=0
Begin	
	Set @sSQLString="
	delete SCREENCONTROL
	where  CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int',
					  @pnOldCriteriaNo
End

if @ErrorCode=0
Begin	
	Set @sSQLString="
	delete CRITERIA
	where  CRITERIANO=@pnOldCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldCriteriaNo	int',
					  @pnOldCriteriaNo
End

-- Commit the transaction if it has successfully completed

If @@TranCount > @TranCountStart
Begin
	If @ErrorCode = 0
	Begin
		COMMIT TRANSACTION
	End
	Else Begin
		ROLLBACK TRANSACTION
	End
End

Return @ErrorCode
GO

Grant execute on dbo.ip_ChangeCriteriaNo to public
GO
