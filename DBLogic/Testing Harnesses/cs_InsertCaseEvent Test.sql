
---------------  TEST ---------------------------
select * from CASEEVENT where CASEID = -484 ORDER BY EVENTDATE DESC
SELECT * FROM POLICING WHERE CASEID = -484 
DECLARE @RC int
dECLARE @pdtPolicingDateEntered datetime
Declare @dtEventDate datetime
Set @dtEventDate = GETDATE()
Declare @dtEventDueDate datetime
Set @dtEventDueDate = GETDATE()
exec @RC = cs_InsertCaseEvent 
	@pnUserIdentityId	= 1,
	@psCulture		= NULL,
	@psCaseKey		= '-484',
	@psEventKey		= '-353',
	@pnCycle		= 2,
	@psEventDescription	= null,
	@pdtEventDueDate	= @dtEventDueDate,
	@pdtEventDate		= @dtEventDate,
	@psCreatedByActionKey	= 'TU',
	@pnCreatedByCriteriaKey	= null,
	@pdtPolicingDateEntered	= @pdtPolicingDateEntered output,	-- return as a result of successful insert, for policing
	@pnPolicingSeqNo 	= NULL

select @RC
select @pdtPolicingDateEntered
select * from CASEEVENT 
	where CASEID = -484 
	and CREATEDBYACTION = 'TU'
 	ORDER BY EVENTDATE DESC
SELECT * FROM POLICING WHERE CASEID = -484 