---------------------------------------------------------------------------------------------
--	Drop SCREENCONTROL' triggers														--
---------------------------------------------------------------------------------------------

IF EXISTS (SELECT * FROM   sysobjects WHERE  type = 'TR' AND NAME = 'tI_SCREENCONTROL_Sync') 
  BEGIN 
      PRINT 'Drop trigger tI_SCREENCONTROL_Sync...' 
      DROP TRIGGER tI_SCREENCONTROL_Sync 
  END 
GO
IF EXISTS (SELECT * FROM   sysobjects WHERE  type = 'TR' AND NAME = 'tU_SCREENCONTROL_Sync') 
  BEGIN 
      PRINT 'Drop trigger tU_SCREENCONTROL_Sync...' 
      DROP TRIGGER tU_SCREENCONTROL_Sync 
  END 
GO
IF EXISTS (SELECT * FROM   sysobjects WHERE  type = 'TR' AND NAME = 'tD_SCREENCONTROL_Sync') 
  BEGIN 
      PRINT 'Drop trigger tD_SCREENCONTROL_Sync...' 
      DROP TRIGGER tD_SCREENCONTROL_Sync 
  END 
GO

---------------------------------------------------------------------------------------------
--	Drop TOPICCONTROL' triggers															--
---------------------------------------------------------------------------------------------

IF EXISTS (SELECT * FROM   sysobjects WHERE  type = 'TR' AND NAME = 'tI_TOPICCONTROL_Sync') 
  BEGIN 
      PRINT 'Drop trigger tI_TOPICCONTROL_Sync...' 
      DROP TRIGGER tI_TOPICCONTROL_Sync 
  END 
GO
IF EXISTS (SELECT * FROM   sysobjects WHERE  type = 'TR' AND NAME = 'tU_TOPICCONTROL_Sync') 
  BEGIN 
      PRINT 'Drop trigger tU_TOPICCONTROL_Sync...' 
      DROP TRIGGER tU_TOPICCONTROL_Sync 
  END 
GO
IF EXISTS (SELECT * FROM   sysobjects WHERE  type = 'TR' AND NAME = 'tD_TOPICCONTROL_Sync') 
  BEGIN 
      PRINT 'Drop trigger tD_TOPICCONTROL_Sync...' 
      DROP TRIGGER tD_TOPICCONTROL_Sync 
  END 
GO

---------------------------------------------------------------------------------------------
--	Drop TOPICCONTROLFILTER' triggers													--
---------------------------------------------------------------------------------------------

IF EXISTS (SELECT * FROM   sysobjects WHERE  type = 'TR' AND NAME = 'tI_TOPICCONTROLFILTER_Sync') 
  BEGIN 
      PRINT 'Drop trigger tI_TOPICCONTROLFILTER_Sync...' 
      DROP TRIGGER tI_TOPICCONTROLFILTER_Sync 
  END 
GO
IF EXISTS (SELECT * FROM   sysobjects WHERE  type = 'TR' AND NAME = 'tU_TOPICCONTROLFILTER_Sync') 
  BEGIN 
      PRINT 'Drop trigger tU_TOPICCONTROLFILTER_Sync...' 
      DROP TRIGGER tU_TOPICCONTROLFILTER_Sync 
  END 
GO
IF EXISTS (SELECT * FROM   sysobjects WHERE  type = 'TR' AND NAME = 'tD_TOPICCONTROLFILTER_Sync') 
  BEGIN 
      PRINT 'Drop trigger tD_TOPICCONTROLFILTER_Sync...' 
      DROP TRIGGER tD_TOPICCONTROLFILTER_Sync 
  END 
GO


---------------------------------------------------------------------------------------------
--	Add 'Case Entry Event' step in entry criterion if missing                            --
---------------------------------------------------------------------------------------------

	insert SCREENCONTROL (CRITERIANO, SCREENNAME, SCREENID, SCREENTITLE)
	select C.CRITERIANO, 'frmCaseDetail', isnull(MAXSC.MaxScreenId,-1)+1, 'Case Entry Event'
	from CRITERIA C
	left join (
		select max(SCMAX.SCREENID) as [MaxScreenId], SCMAX.CRITERIANO
		from SCREENCONTROL SCMAX
		group by SCMAX.CRITERIANO) as MAXSC on (MAXSC.CRITERIANO = C.CRITERIANO) 
	where C.PURPOSECODE = 'E'
	and not exists (	
		select *
		from SCREENCONTROL SC
		where SC.CRITERIANO = C.CRITERIANO
		and SC.SCREENNAME in ('frmCaseDetail'))

	go

---------------------------------------------------------------------------------------------
--	Add 'Letters' step in entry criterion if missing                                       --
---------------------------------------------------------------------------------------------

	insert SCREENCONTROL (CRITERIANO, SCREENNAME, SCREENID, SCREENTITLE)
	select C.CRITERIANO, 'frmLetters', isnull(MAXSC.MaxScreenId,-1)+1, 'Letters'
	from CRITERIA C
	left join (
		select max(SCMAX.SCREENID) as [MaxScreenId], SCMAX.CRITERIANO
		from SCREENCONTROL SCMAX
		group by SCMAX.CRITERIANO) as MAXSC on (MAXSC.CRITERIANO = C.CRITERIANO) 
	where C.PURPOSECODE = 'E'
	and not exists (	
		select *
		from SCREENCONTROL SC
		where SC.CRITERIANO = C.CRITERIANO
		and SC.SCREENNAME in ('frmLetters'))

	go

---------------------------------------------------------------------------------------------
--	One time migration of Screen Control data into Window Control / Topic Control          --
---------------------------------------------------------------------------------------------

if not exists(select * from WINDOWCONTROL where WINDOWNAME = N'WorkflowWizard')
begin
	print '*** importing Entry ScreenControl into WindowControl, TopicControl'

	declare @error nvarchar(1000)
	declare @TranCountStart int
	select @TranCountStart = @@TRANCOUNT

	declare @tcInterim table (
			ID int identity (1,1) not null,
			CRITERIANO int not null,
			ENTRYNUMBER int null,
			TOPICNAME nvarchar(max) collate database_default not null,
			TOPICTITLE nvarchar(max) collate database_default null,
			TOPICSUFFIX nvarchar(100) collate database_default null,
			SCREENTIP nvarchar(max) collate database_default null,
			FILTERNAME1 nvarchar(max) collate database_default null,
			FILTERVALUE1 nvarchar(max) collate database_default null,
			FILTERNAME2 nvarchar(max) collate database_default null,
			FILTERVALUE2 nvarchar(max) collate database_default null,
			ISMANDATORY bit not null,
			ISINHERITED bit not null,
			DISPLAYSEQUENCE int not null
			)

	begin try
	
		begin transaction
	
			---------------------------------------------------------------------------------------------
			--	          Derive application software screen controls to be migrated				   --
			---------------------------------------------------------------------------------------------

			insert @tcInterim 
				(CRITERIANO, ENTRYNUMBER, TOPICNAME,TOPICSUFFIX, TOPICTITLE, SCREENTIP, ISINHERITED, ISMANDATORY, 
					FILTERNAME1, FILTERVALUE1, FILTERNAME2, FILTERVALUE2, DISPLAYSEQUENCE)

			select 
				CRITERIANO, ENTRYNUMBER, SC.SCREENNAME,cast(SC.SCREENID as nvarchar(100)), SC.SCREENTITLE, SCREENTIP, isnull(INHERITED, 0), isnull(MANDATORYFLAG, 0),

				FILTERNAME1 = 
					case 
						when S.SCREENTYPE = N'C' then 'ChecklistTypeKey'
						when S.SCREENTYPE = N'F' then 'CountryFlag'
						when S.SCREENTYPE = N'P' then 'NameGroupKey'
						when S.SCREENTYPE = N'T' then 'TextTypeKey'
						when S.SCREENTYPE = N'N' then 'NameTypeKey'
						when S.SCREENTYPE = N'A' then 'CreateActionKey'
						when S.SCREENTYPE = N'R' then 'CaseRelationKey'
						when S.SCREENTYPE = N'M' then 'CaseRelationKey'
						when S.SCREENTYPE = N'O' then 'NumberTypeKeys'
						when S.SCREENTYPE = N'X' then 'NameTypeKey'
					end,

				FILTERVALUE1 = 
					case 
						when S.SCREENTYPE = N'C' and SC.CHECKLISTTYPE is not null then cast(SC.CHECKLISTTYPE as nvarchar(15))
						when S.SCREENTYPE = N'F' and SC.FLAGNUMBER is not null then cast(SC.FLAGNUMBER as nvarchar(15))
						when S.SCREENTYPE = N'P' and SC.NAMEGROUP is not null then cast(SC.NAMEGROUP as nvarchar(15))
						when S.SCREENTYPE = N'T' then SC.TEXTTYPE
						when S.SCREENTYPE = N'N' then SC.NAMETYPE
						when S.SCREENTYPE = N'A' then SC.CREATEACTION
						when S.SCREENTYPE = N'R' then SC.RELATIONSHIP
						when S.SCREENTYPE = N'M' then SC.RELATIONSHIP
						when S.SCREENTYPE = N'O' then SC.GENERICPARAMETER
						when S.SCREENTYPE = N'X' then SC.NAMETYPE
					end,

				FILTERNAME2 = 
					case 
						when S.SCREENTYPE = N'X' then 'TextTypeKey'
					end,

				FILTERVALUE2 = 
					case 
						when S.SCREENTYPE = N'X' then SC.TEXTTYPE
					end,

				DISPLAYSEQUENCE = 
					case
						when S.SCREENNAME = N'frmCaseDetail' then -20
						when S.SCREENNAME = N'frmLetters' then -10
					else
						SC.DISPLAYSEQUENCE
					end
				from SCREENCONTROL SC
				join SCREENS S on (SC.SCREENNAME = S.SCREENNAME)
				where 
					((SC.ENTRYNUMBER is not null) or 
					(SC.ENTRYNUMBER is null and SC.SCREENNAME in (N'frmCaseDetail', N'frmLetters')))
				order by 
					SC.CRITERIANO, 
					SC.ENTRYNUMBER, 
					case 
						when SC.SCREENNAME = N'frmCaseDetail' then -20 
						when SC.SCREENNAME = N'frmLetters' then -10
						else SC.DISPLAYSEQUENCE
					end

			---------------------------------------------------------------------------------------------
			--	          Create a WindowControl for each workflow entry criterion				       --
			--            1. From entry controls with existing screens set up                          --
			--            2. From default placeholders screens of entry criterion (no entry number)    --
			---------------------------------------------------------------------------------------------

			insert WINDOWCONTROL (CRITERIANO, ENTRYNUMBER, WINDOWNAME, ISINHERITED)
			select DC.CRITERIANO, DC.ENTRYNUMBER, N'WorkflowWizard', 0
			from DETAILCONTROL DC
			join SCREENCONTROL SC1 on (SC1.CRITERIANO = DC.CRITERIANO 
								and SC1.ENTRYNUMBER = DC.ENTRYNUMBER 
								and SC1.ENTRYNUMBER is not null)
			union
			select SC.CRITERIANO, null, N'WorkflowWizard', 0
			from SCREENCONTROL SC
			left join INHERITS I on (I.CRITERIANO = SC.CRITERIANO)
			where SC.SCREENNAME in (N'frmCaseDetail')
			and not exists (
				select * 
				from DETAILCONTROL DC
				where SC.CRITERIANO = DC.CRITERIANO
				and SC.ENTRYNUMBER = DC.ENTRYNUMBER
				and SC.ENTRYNUMBER is not null
			)
			
			---------------------------------------------------------------------------------------------
			--	          For each WindowControl now populate the resolved screens into TopicControl   --
			---------------------------------------------------------------------------------------------

			insert TOPICCONTROL (	
						WINDOWCONTROLNO, TOPICNAME, ROWPOSITION, COLPOSITION, TOPICTITLE, 
						TOPICSUFFIX, SCREENTIP, ISHIDDEN, ISMANDATORY, ISINHERITED, 
						FILTERNAME, FILTERVALUE)
			select		WC.WINDOWCONTROLNO, TOPICNAME, T.DISPLAYSEQUENCE, 0, TOPICTITLE,
						TOPICSUFFIX, SCREENTIP, 0, ISMANDATORY, T.ISINHERITED,
						N'Import-Topic-Control-Id', cast(T.ID as nvarchar(15))
			from @tcInterim T
			join WINDOWCONTROL WC on WC.CRITERIANO = T.CRITERIANO and (WC.ENTRYNUMBER = T.ENTRYNUMBER or (WC.ENTRYNUMBER is null and T.ENTRYNUMBER is null))

			---------------------------------------------------------------------------------------------
			--	          For each TopicControl now populate their filters into TopicControlFilter     --
			---------------------------------------------------------------------------------------------

			insert TOPICCONTROLFILTER (TOPICCONTROLNO, FILTERNAME, FILTERVALUE)
			select TOPICCONTROLNO, FILTERNAME1, FILTERVALUE1
			from @tcInterim T
			join TOPICCONTROL TC on (TC.FILTERNAME = N'Import-Topic-Control-Id' and TC.FILTERVALUE = cast(T.ID as nvarchar(15)))
			where T.FILTERVALUE1 is not null
			union 
			select TOPICCONTROLNO, FILTERNAME2, FILTERVALUE2
			from @tcInterim T 
			join TOPICCONTROL TC on (TC.FILTERNAME = N'Import-Topic-Control-Id' and TC.FILTERVALUE = cast(T.ID as nvarchar(15)))
			where T.FILTERVALUE2 is not null
			
			---------------------------------------------------------------------------------------------
			--	          Remove import indicators as final clean up                                   --
			---------------------------------------------------------------------------------------------

			update TOPICCONTROL
				set FILTERNAME = null, 
					FILTERVALUE = null
			where FILTERNAME = N'Import-Topic-Control-Id'

		commit transaction

		print '*** imported Entry ScreenControl into WindowControl, TopicControl'
	end try
	begin catch

		if @@TRANCOUNT > @TranCountStart rollback transaction
			
		set @error = ERROR_MESSAGE() + ' Line ' + cast(ERROR_LINE() as nvarchar(5))
			
		RAISERROR (@error, 16, 1)
		
	end catch
end
GO

---------------------------------------------------------------------------------------------
--	Create SCREENCONTROL triggers														--
---------------------------------------------------------------------------------------------
--PRINT 'Creating trigger tI_SCREENCONTROL_Sync...' 

create trigger tI_SCREENCONTROL_Sync on SCREENCONTROL
after insert not for replication
as
  -- TRIGGER :  tI_SCREENCONTROL_Sync
  -- VERSION :	2
  -- DESCRIPTION:	Adds a row in WINDOWCONTROL table if not exists.
  --				Adds a new record in  TOPICCONTROL
  --				Adds new records in TOPICCONTROLFILTER
  -- MODIFICATIONS :
  -- Date			Who		Change	Version	Description
  -- -----------	-------	------	-------	----------------------------------------------- 
  -- 06 Dec 2016	HM		1		Trigger created
  -- 12 Dec 2016	SF		2		Default WINDOWCONTROL as uninherited
    
  if exists (select 1 from inserted where ENTRYNUMBER is not null)
    and (trigger_nestlevel(object_id('tI_TOPICCONTROL_Sync'), 'After', 'DML') = 0)
  begin
		insert WINDOWCONTROL (CRITERIANO, ENTRYNUMBER, WINDOWNAME, ISINHERITED)
		select CRITERIANO, ENTRYNUMBER, N'WorkflowWizard', 0 
		from inserted SC 
		where ENTRYNUMBER IS NOT NULL
		and not exists (
			select	1 
			from	WINDOWCONTROL WC 
			where	SC.CRITERIANO = WC.CRITERIANO 
			and		SC.ENTRYNUMBER = WC.ENTRYNUMBER 
			and		WC.WINDOWNAME = N'WorkflowWizard')
	  
		declare @tcInterim table (
			ID int identity (1, 1) NOT NULL,
			CRITERIANO int NOT NULL,
			ENTRYNUMBER int NULL,
			TOPICNAME nvarchar(max) COLLATE database_default NOT NULL,
			TOPICTITLE nvarchar(max) COLLATE database_default NOT NULL,
			TOPICSUFFIX nvarchar(100) COLLATE database_default NULL,
			SCREENTIP nvarchar(max) COLLATE database_default NULL,
			FILTERNAME1 nvarchar(max) COLLATE database_default NULL,
			FILTERVALUE1 nvarchar(max) COLLATE database_default NULL,
			FILTERNAME2 nvarchar(max) COLLATE database_default NULL,
			FILTERVALUE2 nvarchar(max) COLLATE database_default NULL,
			ISMANDATORY bit NOT NULL,
			ISINHERITED bit NOT NULL,
			DISPLAYSEQUENCE int NOT NULL
		);

		insert @tcInterim (
				CRITERIANO, ENTRYNUMBER, TOPICNAME, 
				TOPICSUFFIX, TOPICTITLE, SCREENTIP, ISINHERITED, ISMANDATORY,
				FILTERNAME1, FILTERVALUE1, FILTERNAME2, FILTERVALUE2, DISPLAYSEQUENCE)
		select	CRITERIANO, ENTRYNUMBER, SC.SCREENNAME, 
				cast(SC.SCREENID AS nvarchar(100)), SC.SCREENTITLE, SCREENTIP, isnull(INHERITED, 0), isnull(MANDATORYFLAG, 0),
				FILTERNAME1 =
                     case
                       when S.SCREENTYPE = N'C' then 'ChecklistTypeKey'
                       when S.SCREENTYPE = N'F' then 'CountryFlag'
                       when S.SCREENTYPE = N'P' then 'NameGroupKey'
                       when S.SCREENTYPE = N'T' then 'TextTypeKey'
                       when S.SCREENTYPE = N'N' then 'NameTypeKey'
                       when S.SCREENTYPE = N'A' then 'CreateActionKey'
                       when S.SCREENTYPE = N'R' then 'CaseRelationKey'
                       when S.SCREENTYPE = N'M' then 'CaseRelationKey'
                       when S.SCREENTYPE = N'O' then 'NumberTypeKeys'
                       when S.SCREENTYPE = N'X' then 'NameTypeKey'
                     end,
				FILTERVALUE1 =
                      case
                        when S.SCREENTYPE = N'C' and SC.CHECKLISTTYPE is not null then cast(SC.CHECKLISTTYPE as nvarchar(15))
                        when S.SCREENTYPE = N'F' and SC.FLAGNUMBER is not null then cast(SC.FLAGNUMBER as nvarchar(15))
                        when S.SCREENTYPE = N'P' and SC.NAMEGROUP is Not null then cast(SC.NAMEGROUP as nvarchar(15))
                        when S.SCREENTYPE = N'T' then SC.TEXTTYPE
                        when S.SCREENTYPE = N'N' then SC.NAMETYPE
                        when S.SCREENTYPE = N'A' then SC.CREATEACTION
                        when S.SCREENTYPE = N'R' then SC.RELATIONSHIP
                        when S.SCREENTYPE = N'M' then SC.RELATIONSHIP
                        when S.SCREENTYPE = N'O' then SC.GENERICPARAMETER
                        when S.SCREENTYPE = N'X' then SC.NAMETYPE
                      end,
				FILTERNAME2 =
					  case
                        when S.SCREENTYPE = N'X' then 'TextTypeKey'
                      end,
				FILTERVALUE2 =
                      case
                        when S.SCREENTYPE = N'X' then SC.TEXTTYPE
                      end,
				DISPLAYSEQUENCE =
                      case
                        when S.SCREENNAME = N'frmCaseDetail' then -20
                        when S.SCREENNAME = N'frmLetters' then -10
                        else isnull(SC.DISPLAYSEQUENCE, 0)
                      end
		from inserted SC
		join SCREENS S on (SC.SCREENNAME = S.SCREENNAME)
		where ((SC.ENTRYNUMBER is not null) or (SC.ENTRYNUMBER is null and SC.SCREENNAME in (N'frmCaseDetail', N'frmLetters')))
		order by	SC.CRITERIANO,
					SC.ENTRYNUMBER,
					case
						when SC.SCREENNAME = N'frmCaseDetail' then -20
						when SC.SCREENNAME = N'frmLetters' then -10
						else isnulL(SC.DISPLAYSEQUENCE, 0)
					end

    ---------------------------------------------------------------------------------------------
    --	          Populate TopicControl   --
    ---------------------------------------------------------------------------------------------

		insert TOPICCONTROL (WINDOWCONTROLNO, TOPICNAME, ROWPOSITION, COLPOSITION, TOPICTITLE, TOPICSUFFIX, SCREENTIP, ISHIDDEN, ISMANDATORY, ISINHERITED)
		select WC.WINDOWCONTROLNO, TOPICNAME, T.DISPLAYSEQUENCE, 0, TOPICTITLE, TOPICSUFFIX, SCREENTIP, 0, ISMANDATORY,T.ISINHERITED
		from @tcInterim T
		join WINDOWCONTROL WC on (	WC.CRITERIANO = T.CRITERIANO and 
									(WC.ENTRYNUMBER = T.ENTRYNUMBER or (WC.ENTRYNUMBER is null and T.ENTRYNUMBER is null)))

    ---------------------------------------------------------------------------------------------
    --	          For TopicControl now populate their filters into TopicControlFilter     --
    ---------------------------------------------------------------------------------------------
		insert TOPICCONTROLFILTER (TOPICCONTROLNO, FILTERNAME, FILTERVALUE)
		select TOPICCONTROLNO, FILTERNAME1, FILTERVALUE1
		from @tcInterim T
		inner join TOPICCONTROL TC on (TC.TOPICNAME = T.TOPICNAME and TC.TOPICSUFFIX = T.TOPICSUFFIX)
		inner join WINDOWCONTROL WC on (WC.WINDOWCONTROLNO = TC.WINDOWCONTROLNO and WC.CRITERIANO = T.CRITERIANO and (WC.ENTRYNUMBER = T.ENTRYNUMBER or (WC.ENTRYNUMBER is null and T.ENTRYNUMBER is null)))
		where T.FILTERVALUE1 is not null
		union
		select TOPICCONTROLNO, FILTERNAME2, FILTERVALUE2
		from @tcInterim T
		inner join TOPICCONTROL TC ON (TC.TOPICNAME = T.TOPICNAME and TC.TOPICSUFFIX = T.TOPICSUFFIX)
		inner join WINDOWCONTROL WC ON (WC.WINDOWCONTROLNO = TC.WINDOWCONTROLNO and WC.CRITERIANO = T.CRITERIANO and (WC.ENTRYNUMBER = T.ENTRYNUMBER or (WC.ENTRYNUMBER is null and T.ENTRYNUMBER is null)))
		where T.FILTERVALUE2 is not null
  END
GO

--PRINT 'Creating trigger tU_SCREENCONTROL_Sync...' 

CREATE TRIGGER tU_SCREENCONTROL_Sync ON SCREENCONTROL
AFTER UPDATE NOT FOR REPLICATION
AS
  -- TRIGGER :  tU_SCREENCONTROL_Sync
  -- VERSION :	1
  -- DESCRIPTION:	Updates TopicControl, Insert, Update or Deletes values from TopicControlFilter
  -- MODIFICATIONS :
  -- Date		Who	Change	Version	Description
  -- -----------	-------	------	-------	----------------------------------------------- 
  -- 06 Dec 2016	HM		1	Trigger created

 IF NOT UPDATE(LOGDATETIMESTAMP) AND EXISTS (SELECT 1 FROM inserted WHERE ENTRYNUMBER IS NOT NULL) AND EXISTS (SELECT 1 FROM deleted)
    AND (TRIGGER_NESTLEVEL(OBJECT_ID(OBJECT_NAME(@@PROCID)), 'After', 'DML') <= 1
    AND TRIGGER_NESTLEVEL() = 1)
  BEGIN
    ---------------------------------------------------------------------------------------------
    --	          TopicControl																  --
    ---------------------------------------------------------------------------------------------
    UPDATE TC
    SET TOPICNAME = sc.SCREENNAME,
        TOPICSUFFIX = sc.SCREENID,
        ROWPOSITION = isnull(sc.DISPLAYSEQUENCE,0),
        TOPICTITLE = sc.SCREENTITLE,
        SCREENTIP = sc.SCREENTIP,
        ISMANDATORY = ISNULL(sc.MANDATORYFLAG, 0),
        ISINHERITED = ISNULL(sc.INHERITED, 0)
    FROM TOPICCONTROL TC
    INNER JOIN inserted SC ON (SC.SCREENNAME = TC.TOPICNAME AND sc.SCREENID = TC.TOPICSUFFIX)
    INNER JOIN WINDOWCONTROL WC ON WC.WINDOWCONTROLNO = TC.WINDOWCONTROLNO AND WC.CRITERIANO = SC.CRITERIANO AND (WC.ENTRYNUMBER = SC.ENTRYNUMBER OR (WC.ENTRYNUMBER IS NULL AND SC.ENTRYNUMBER IS NULL));

    ---------------------------------------------------------------------------------------------
    --	          TopicControlFilter														 --
    ---------------------------------------------------------------------------------------------
    WITH del
    AS (SELECT CRITERIANO, ENTRYNUMBER, SC.SCREENNAME TOPICNAME, CAST(SC.SCREENID AS nvarchar(100)) TOPICSUFFIX,
      FILTERNAME1 =
                   CASE
                     WHEN S.SCREENTYPE = N'C' THEN 'ChecklistTypeKey'
                     WHEN S.SCREENTYPE = N'F' THEN 'CountryFlag'
                     WHEN S.SCREENTYPE = N'P' THEN 'NameGroupKey'
                     WHEN S.SCREENTYPE = N'T' THEN 'TextTypeKey'
                     WHEN S.SCREENTYPE = N'N' THEN 'NameTypeKey'
                     WHEN S.SCREENTYPE = N'A' THEN 'CreateActionKey'
                     WHEN S.SCREENTYPE = N'R' THEN 'CaseRelationKey'
                     WHEN S.SCREENTYPE = N'M' THEN 'CaseRelationKey'
                     WHEN S.SCREENTYPE = N'O' THEN 'NumberTypeKeys'
                     WHEN S.SCREENTYPE = N'X' THEN 'NameTypeKey'
                   END,
      FILTERVALUE1 =
                    CASE
                      WHEN S.SCREENTYPE = N'C' AND SC.CHECKLISTTYPE IS NOT NULL THEN CAST(SC.CHECKLISTTYPE AS nvarchar(15))
                      WHEN S.SCREENTYPE = N'F' AND SC.FLAGNUMBER IS NOT NULL THEN CAST(SC.FLAGNUMBER AS nvarchar(15))
                      WHEN S.SCREENTYPE = N'P' AND SC.NAMEGROUP IS NOT NULL THEN CAST(SC.NAMEGROUP AS nvarchar(15))
                      WHEN S.SCREENTYPE = N'T' THEN SC.TEXTTYPE
                      WHEN S.SCREENTYPE = N'N' THEN SC.NAMETYPE
                      WHEN S.SCREENTYPE = N'A' THEN SC.CREATEACTION
                      WHEN S.SCREENTYPE = N'R' THEN SC.RELATIONSHIP
                      WHEN S.SCREENTYPE = N'M' THEN SC.RELATIONSHIP
                      WHEN S.SCREENTYPE = N'O' THEN SC.GENERICPARAMETER
                      WHEN S.SCREENTYPE = N'X' THEN SC.NAMETYPE
                    END,
      FILTERNAME2 =
                   CASE
                     WHEN S.SCREENTYPE = N'X' THEN 'TextTypeKey'
                   END,
      FILTERVALUE2 =
                    CASE
                      WHEN S.SCREENTYPE = N'X' THEN SC.TEXTTYPE
                    END
    FROM deleted SC
    JOIN SCREENS S ON (SC.SCREENNAME = S.SCREENNAME)
    WHERE ((SC.ENTRYNUMBER IS NOT NULL) OR (SC.ENTRYNUMBER IS NULL AND SC.SCREENNAME IN (N'frmCaseDetail', N'frmLetters'))))
    DELETE TCF
      FROM TOPICCONTROLFILTER TCF
      INNER JOIN (SELECT TOPICCONTROLNO, FILTERNAME1 FILTERNAME
					FROM del T
					INNER JOIN TOPICCONTROL TC ON TC.TOPICNAME = T.TOPICNAME AND TC.TOPICSUFFIX = T.TOPICSUFFIX
					INNER JOIN WINDOWCONTROL WC ON WC.WINDOWCONTROLNO = TC.WINDOWCONTROLNO AND WC.CRITERIANO = T.CRITERIANO AND (WC.ENTRYNUMBER = T.ENTRYNUMBER OR (WC.ENTRYNUMBER IS NULL AND T.ENTRYNUMBER IS NULL))
					WHERE T.FILTERVALUE1 IS NOT NULL
					UNION
					SELECT TOPICCONTROLNO, FILTERNAME2 FILTERNAME
					FROM del T
					INNER JOIN TOPICCONTROL TC ON TC.TOPICNAME = T.TOPICNAME AND TC.TOPICSUFFIX = T.TOPICSUFFIX
					INNER JOIN WINDOWCONTROL WC ON WC.WINDOWCONTROLNO = TC.WINDOWCONTROLNO AND WC.CRITERIANO = T.CRITERIANO AND (WC.ENTRYNUMBER = T.ENTRYNUMBER OR (WC.ENTRYNUMBER IS NULL AND T.ENTRYNUMBER IS NULL)) 
					WHERE T.FILTERVALUE2 IS NOT NULL) T
	ON TCF.TOPICCONTROLNO = T.TOPICCONTROLNO
	AND TCF.FILTERNAME = T.FILTERNAME;



    WITH ins
    AS (SELECT CRITERIANO, ENTRYNUMBER, SC.SCREENNAME TOPICNAME, CAST(SC.SCREENID AS nvarchar(100)) TOPICSUFFIX,
      FILTERNAME1 =
                   CASE
                     WHEN S.SCREENTYPE = N'C' THEN 'ChecklistTypeKey'
                     WHEN S.SCREENTYPE = N'F' THEN 'CountryFlag'
                     WHEN S.SCREENTYPE = N'P' THEN 'NameGroupKey'
                     WHEN S.SCREENTYPE = N'T' THEN 'TextTypeKey'
                     WHEN S.SCREENTYPE = N'N' THEN 'NameTypeKey'
                     WHEN S.SCREENTYPE = N'A' THEN 'CreateActionKey'
                     WHEN S.SCREENTYPE = N'R' THEN 'CaseRelationKey'
                     WHEN S.SCREENTYPE = N'M' THEN 'CaseRelationKey'
                     WHEN S.SCREENTYPE = N'O' THEN 'NumberTypeKeys'
                     WHEN S.SCREENTYPE = N'X' THEN 'NameTypeKey'
                   END,
      FILTERVALUE1 =
                    CASE
                      WHEN S.SCREENTYPE = N'C' AND
                        SC.CHECKLISTTYPE IS NOT NULL THEN CAST(SC.CHECKLISTTYPE AS nvarchar(15))
                      WHEN S.SCREENTYPE = N'F' AND
                        SC.FLAGNUMBER IS NOT NULL THEN CAST(SC.FLAGNUMBER AS nvarchar(15))
                      WHEN S.SCREENTYPE = N'P' AND
                        SC.NAMEGROUP IS NOT NULL THEN CAST(SC.NAMEGROUP AS nvarchar(15))
                      WHEN S.SCREENTYPE = N'T' THEN SC.TEXTTYPE
                      WHEN S.SCREENTYPE = N'N' THEN SC.NAMETYPE
                      WHEN S.SCREENTYPE = N'A' THEN SC.CREATEACTION
                      WHEN S.SCREENTYPE = N'R' THEN SC.RELATIONSHIP
                      WHEN S.SCREENTYPE = N'M' THEN SC.RELATIONSHIP
                      WHEN S.SCREENTYPE = N'O' THEN SC.GENERICPARAMETER
                      WHEN S.SCREENTYPE = N'X' THEN SC.NAMETYPE
                    END,
      FILTERNAME2 =
                   CASE
                     WHEN S.SCREENTYPE = N'X' THEN 'TextTypeKey'
                   END,
      FILTERVALUE2 =
                    CASE
                      WHEN S.SCREENTYPE = N'X' THEN SC.TEXTTYPE
                    END
    FROM inserted SC
    INNER JOIN SCREENS S ON (SC.SCREENNAME = S.SCREENNAME)
    WHERE ((SC.ENTRYNUMBER IS NOT NULL) OR (SC.ENTRYNUMBER IS NULL AND SC.SCREENNAME IN (N'frmCaseDetail', N'frmLetters'))))
    INSERT TOPICCONTROLFILTER (TOPICCONTROLNO, FILTERNAME, FILTERVALUE)
      SELECT TOPICCONTROLNO, FILTERNAME1, FILTERVALUE1
      FROM ins T
      INNER JOIN TOPICCONTROL TC ON TC.TOPICNAME = T.TOPICNAME AND TC.TOPICSUFFIX = T.TOPICSUFFIX
      INNER JOIN WINDOWCONTROL WC ON WC.WINDOWCONTROLNO = TC.WINDOWCONTROLNO AND WC.CRITERIANO = T.CRITERIANO AND (WC.ENTRYNUMBER = T.ENTRYNUMBER OR (WC.ENTRYNUMBER IS NULL AND T.ENTRYNUMBER IS NULL))
      WHERE T.FILTERVALUE1 IS NOT NULL
      UNION
      SELECT TOPICCONTROLNO, FILTERNAME2, FILTERVALUE2
      FROM ins T
      INNER JOIN TOPICCONTROL TC ON TC.TOPICNAME = T.TOPICNAME AND TC.TOPICSUFFIX = T.TOPICSUFFIX
      INNER JOIN WINDOWCONTROL WC ON WC.WINDOWCONTROLNO = TC.WINDOWCONTROLNO AND WC.CRITERIANO = T.CRITERIANO AND (WC.ENTRYNUMBER = T.ENTRYNUMBER OR (WC.ENTRYNUMBER IS NULL AND T.ENTRYNUMBER IS NULL))
      WHERE T.FILTERVALUE2 IS NOT NULL;
  END
GO

--PRINT 'Creating trigger tD_SCREENCONTROL_Sync...' 

CREATE TRIGGER tD_SCREENCONTROL_Sync ON SCREENCONTROL
AFTER DELETE NOT FOR REPLICATION
AS
  -- TRIGGER :  tD_SCREENCONTROL_Sync
  -- VERSION :	1
  -- DESCRIPTION:	Deletes records from WindowControl table
  --				It doesnt execute if delete is coming from TOPICCONTROL table's delete trigger
  -- MODIFICATIONS :
  -- Date		Who	Change	Version	Description
  -- -----------	-------	------	-------	----------------------------------------------- 
  -- 06 Dec 2016	HM		1	Trigger created

  IF EXISTS (SELECT 1 FROM deleted WHERE ENTRYNUMBER IS NOT NULL)
    AND (TRIGGER_NESTLEVEL(OBJECT_ID('tD_TOPICCONTROL_Sync'), 'After', 'DML') = 0)
  BEGIN
    DELETE TC
      FROM TOPICCONTROL TC 
	  inner join WINDOWCONTROL WC on WC.WINDOWCONTROLNO=TC.WINDOWCONTROLNO
	  inner join deleted DEL on DEL.CRITERIANO = WC.CRITERIANO
      AND DEL.ENTRYNUMBER = WC.ENTRYNUMBER
      AND WC.WINDOWNAME = N'WorkflowWizard'
	  AND DEL.SCREENNAME=TC.TOPICNAME
	  AND DEL.SCREENID=TC.TOPICSUFFIX
  END
GO

---------------------------------------------------------------------------------------------
--	Create TOPICCONTROL triggers														--
---------------------------------------------------------------------------------------------
--PRINT 'Creating trigger tI_TOPICCONTROL_Sync...' 

create trigger tI_TOPICCONTROL_Sync on TOPICCONTROL
after insert not for replication
as
  -- TRIGGER :  tI_TOPICCONTROL_Sync
  -- VERSION :	4
  -- DESCRIPTION:	Adds a new row in SCREENCONTROL table. This ensures that the SCREENCONTROL table remain in sync with TOPICCONTROL
  --				It doesnt execute if Insert is coming from ScreenControl table's Insert trigger
  --				When TopicControl is inserted, the TOPICSUFFIX is required to be unique, in some situations a random character string is
  --				used to force the trigger to convert as it establishes the link to the SCREENID. 
  -- MODIFICATIONS :
  -- Date			Who		Change	Version	Description
  -- -----------	-------	------	-------	----------------------------------------------- 
  -- 06 Dec 2016	HM		1		Trigger created
  -- 12 Dec 2016	SF		2		Generate ScreenId on the fly
  -- 05 Jan 2017	SF		3		ScreenId allocation should not consider Entry Number
  -- 08 Feb 2017	SF		4		Should only update workflow wizard controls

  if exists (select 1 from inserted)
    and trigger_nestlevel(object_id('tI_SCREENCONTROL_Sync'), 'After', 'DML') = 0
  begin 
	
		declare @max int 
		declare @interim table (
			TOPICCONTROLID int not null,
			NEWSCREENID int identity(1,1) not null
		)
  
		select @max = max(SC.SCREENID) 
		from inserted TC
		join WINDOWCONTROL WC on (WC.WINDOWCONTROLNO = TC.WINDOWCONTROLNO and WC.WINDOWNAME = N'WorkflowWizard')
		join SCREENCONTROL SC on (SC.CRITERIANO = WC.CRITERIANO)

		insert into @interim(TOPICCONTROLID) select i.TOPICCONTROLNO from inserted i
    
		insert into SCREENCONTROL (CRITERIANO, SCREENNAME, SCREENID, ENTRYNUMBER, SCREENTITLE, DISPLAYSEQUENCE, INHERITED, MANDATORYFLAG, SCREENTIP)
		select	WC.CRITERIANO,
				TC.TOPICNAME,
				case 
					when isnumeric(TC.TOPICSUFFIX)=1 then TC.TOPICSUFFIX 
					else I1.NEWSCREENID + isnull(@max, 0)
				end,	
				WC.ENTRYNUMBER,
				TC.TOPICTITLE SCREENTITLE,
				TC.ROWPOSITION DISPLAYSEQUENCE,
				TC.ISINHERITED INHERITED,
				TC.ISMANDATORY MANDATORYFLAG,
				TC.SCREENTIP
		from inserted TC
		join @interim I1 on (TC.TOPICCONTROLNO = I1.TOPICCONTROLID)
		inner join WINDOWCONTROL WC on WC.WINDOWCONTROLNO = TC.WINDOWCONTROLNO AND WC.WINDOWNAME = N'WorkflowWizard'
		where not exists (
			select 1 
			from SCREENCONTROL 
			where CRITERIANO = WC.CRITERIANO 
			and SCREENNAME = TC.TOPICNAME 
			and SCREENID = case 
							when isnumeric(TC.TOPICSUFFIX)=1 then TC.TOPICSUFFIX 
							else I1.NEWSCREENID + isnull(@max, 0)
						end
		)

		/* reset link between topic control and screen control */

		update TC 
		set TOPICSUFFIX =	case 
								when isnumeric(TC.TOPICSUFFIX)=1 then TC.TOPICSUFFIX 
								else I1.NEWSCREENID + isnull(@max, 0)
							end
		from TOPICCONTROL TC
		join @interim I1 on (TC.TOPICCONTROLNO = I1.TOPICCONTROLID)
		join WINDOWCONTROL WC on (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO and WC.WINDOWNAME = N'WorkflowWizard')

	end
go

--PRINT 'Creating trigger tU_TOPICCONTROL_Sync...' 

CREATE TRIGGER tU_TOPICCONTROL_Sync ON TOPICCONTROL
AFTER UPDATE NOT FOR REPLICATION
AS
  -- TRIGGER :  tU_TOPICCONTROL_Sync
  -- VERSION :	2
  -- DESCRIPTION:	Updates the corresponding row in SCREENCONTROL table. This ensures that the SCREENCONTROL table remain in sync with TOPICCONTROL
  --				It doesnt execute if Update is coming from ScreenControl table's Update trigger
  -- MODIFICATIONS :
  -- Date		Who	Change	Version	Description
  -- -----------	-------	------	-------	----------------------------------------------- 
  -- 06 Dec 2016	HM		1	Trigger created
  -- 12 Dec 2016	SF		2	TopicSuffix update need not be replicated

  IF NOT UPDATE(LOGDATETIMESTAMP) AND NOT UPDATE(TOPICSUFFIX) AND EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    AND TRIGGER_NESTLEVEL(OBJECT_ID('tU_SCREENCONTROL_Sync'), 'After', 'DML') = 0
  BEGIN
    UPDATE SC
    SET SC.SCREENNAME = TC.TOPICNAME,
        SC.SCREENID = TC.TOPICSUFFIX,
        SC.SCREENTITLE = TC.SCREENTITLE,
        SC.DISPLAYSEQUENCE = TC.DISPLAYSEQUENCE,
        SC.INHERITED = TC.INHERITED,
        SC.MANDATORYFLAG = TC.MANDATORYFLAG,
        SC.SCREENTIP = TC.SCREENTIP
    FROM SCREENCONTROL SC
    INNER JOIN (SELECT
      WC.CRITERIANO,
      TC.TOPICNAME,
      TC.TOPICSUFFIX,
      WC.ENTRYNUMBER,
      TC.TOPICTITLE SCREENTITLE,
      TC.ROWPOSITION DISPLAYSEQUENCE,
      TC.ISINHERITED INHERITED,
      TC.ISMANDATORY MANDATORYFLAG,
      TC.SCREENTIP,
      del.TOPICNAME OriginalScreenName,
      del.TOPICSUFFIX OriginalScreenID
    FROM inserted TC
    INNER JOIN deleted del ON TC.TOPICCONTROLNO = del.TOPICCONTROLNO
    INNER JOIN WINDOWCONTROL WC ON WC.WINDOWCONTROLNO = TC.WINDOWCONTROLNO AND WC.WINDOWNAME = N'WorkflowWizard') TC
      ON SC.CRITERIANO = TC.CRITERIANO
      AND SC.SCREENNAME = TC.OriginalScreenName
      AND SC.SCREENID = TC.OriginalScreenID
  END
GO

--PRINT 'Creating trigger tD_TOPICCONTROL_Sync...' 

CREATE TRIGGER tD_TOPICCONTROL_Sync ON TOPICCONTROL
AFTER DELETE NOT FOR REPLICATION
AS
  -- TRIGGER :  tD_TOPICCONTROL_Sync
  -- VERSION :	1
  -- DESCRIPTION:	deletes the corresponding row in SCREENCONTROL table. This ensures that the SCREENCONTROL table remain in sync with TOPICCONTROL
  -- MODIFICATIONS :
  -- Date		Who	Change	Version	Description
  -- -----------	-------	------	-------	----------------------------------------------- 
  -- 06 Dec 2016	HM		1	Trigger created
  
  IF EXISTS (SELECT 1 FROM deleted)
    AND TRIGGER_NESTLEVEL(OBJECT_ID('tD_SCREENCONTROL_Sync'),'After','DML')=0
  BEGIN    
    DELETE SC
      FROM SCREENCONTROL SC
      INNER JOIN (SELECT
        WC.CRITERIANO,
        TC.TOPICNAME,
        TC.TOPICSUFFIX,
        WC.ENTRYNUMBER,
        TC.TOPICTITLE SCREENTITLE,
        TC.ROWPOSITION DISPLAYSEQUENCE,
        TC.ISINHERITED INHERITED,
        TC.ISMANDATORY MANDATORYFLAG,
        TC.SCREENTIP
      FROM deleted TC
      INNER JOIN WINDOWCONTROL WC ON WC.WINDOWCONTROLNO = TC.WINDOWCONTROLNO AND WC.WINDOWNAME = N'WorkflowWizard') TC
        ON SC.CRITERIANO = TC.CRITERIANO
        AND SC.SCREENNAME = TC.TOPICNAME
        AND SC.SCREENID = TC.TOPICSUFFIX
  END
GO

---------------------------------------------------------------------------------------------
--	Create TOPICCONTROLFILTER triggers														--
---------------------------------------------------------------------------------------------

--PRINT 'Creating trigger tI_TOPICCONTROLFILTER_Sync...' 

CREATE TRIGGER tI_TOPICCONTROLFILTER_Sync ON TOPICCONTROLFILTER
AFTER INSERT NOT FOR REPLICATION
AS
  -- TRIGGER :    tI_TOPICCONTROL_Sync
  -- VERSION :  1
  -- DESCRIPTION:	Updates the corresponding columns in SCREENCONTROL table. This ensures that the SCREENCONTROL table remain in sync with TOPICCONTROL
  --				It doesnt execute if Insert is coming from ScreenControl table's Insert or Update trigger
  -- MODIFICATIONS :
  -- Date		Who	Change	Version	Description
  -- -----------	-------	------	-------	----------------------------------------------- 
  -- 08 Dec 2016	HM		1	Trigger created

  IF EXISTS (SELECT 1 FROM inserted)
    AND TRIGGER_NESTLEVEL(OBJECT_ID('tI_SCREENCONTROL_Sync'), 'After', 'DML') = 0
    AND TRIGGER_NESTLEVEL(OBJECT_ID('tU_SCREENCONTROL_Sync'), 'After', 'DML') = 0
  BEGIN    
    UPDATE SC
    SET SC.CHECKLISTTYPE = (CASE WHEN TCF.FILTERNAME = N'ChecklistTypeKey' THEN TCF.FILTERVALUE ELSE SC.CHECKLISTTYPE END),
        SC.TEXTTYPE = (CASE WHEN TCF.FILTERNAME = N'TextTypeKey' THEN TCF.FILTERVALUE ELSE SC.TEXTTYPE END),
        SC.NAMETYPE = (CASE WHEN TCF.FILTERNAME = N'NameTypeKey' THEN TCF.FILTERVALUE ELSE SC.NAMETYPE END),
        SC.NAMEGROUP = (CASE WHEN TCF.FILTERNAME = N'NameGroupKey' THEN TCF.FILTERVALUE ELSE SC.NAMEGROUP END),
        SC.FLAGNUMBER = (CASE WHEN TCF.FILTERNAME = N'CountryFlag' THEN TCF.FILTERVALUE ELSE SC.FLAGNUMBER END),
        SC.CREATEACTION = (CASE WHEN TCF.FILTERNAME = N'CreateActionKey' THEN TCF.FILTERVALUE ELSE SC.CREATEACTION END),
        SC.RELATIONSHIP = (CASE WHEN TCF.FILTERNAME = N'CaseRelationKey' THEN TCF.FILTERVALUE ELSE SC.RELATIONSHIP END),
        SC.GENERICPARAMETER = (CASE WHEN TCF.FILTERNAME = N'NumberTypeKeys' THEN TCF.FILTERVALUE ELSE SC.GENERICPARAMETER END)
    FROM SCREENCONTROL SC
    INNER JOIN (SELECT
      WC.CRITERIANO,
      TC.TOPICNAME,
      TC.TOPICSUFFIX,
      WC.ENTRYNUMBER,
      TCF.FILTERNAME,
      TCF.FILTERVALUE
    FROM inserted TCF
    INNER JOIN TOPICCONTROL TC ON TC.TOPICCONTROLNO = TCF.TOPICCONTROLNO
    INNER JOIN WINDOWCONTROL WC ON WC.WINDOWCONTROLNO = TC.WINDOWCONTROLNO AND WC.WINDOWNAME = N'WorkflowWizard') TCF
      ON SC.CRITERIANO = TCF.CRITERIANO
      AND SC.SCREENNAME = TCF.TOPICNAME
      AND SC.SCREENID = TCF.TOPICSUFFIX
  END
GO

--PRINT 'Creating trigger tU_TOPICCONTROLFILTER_Sync...' 

CREATE TRIGGER tU_TOPICCONTROLFILTER_Sync ON TOPICCONTROLFILTER
AFTER UPDATE NOT FOR REPLICATION
AS
  -- TRIGGER :    tU_TOPICCONTROLFILTER_Sync
  -- VERSION :  1
  -- DESCRIPTION:	Updates the corresponding columns in SCREENCONTROL table. This ensures that the SCREENCONTROL table remain in sync with TOPICCONTROL
  --				It doesnt execute if update is coming from ScreenControl table's Update trigger
  -- MODIFICATIONS :
  -- Date		Who	Change	Version	Description
  -- -----------	-------	------	-------	----------------------------------------------- 
  -- 08 Dec 2016	HM		1	Trigger created
 
  IF NOT UPDATE(LOGDATETIMESTAMP) AND EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    AND TRIGGER_NESTLEVEL(OBJECT_ID('tU_SCREENCONTROL_Sync'), 'After', 'DML') = 0
  BEGIN    
    UPDATE SC
    SET SC.CHECKLISTTYPE = (CASE WHEN TCF.OriginalFilterName = N'ChecklistTypeKey' THEN NULL WHEN TCF.FILTERNAME = N'ChecklistTypeKey' THEN TCF.FILTERVALUE ELSE SC.CHECKLISTTYPE END),
        SC.TEXTTYPE = (CASE WHEN TCF.OriginalFilterName = N'TextTypeKey' THEN NULL WHEN TCF.FILTERNAME = N'TextTypeKey' THEN TCF.FILTERVALUE ELSE SC.TEXTTYPE END),
        SC.NAMETYPE = (CASE WHEN TCF.OriginalFilterName = N'NameTypeKey' THEN NULL WHEN TCF.FILTERNAME = N'NameTypeKey' THEN TCF.FILTERVALUE ELSE SC.NAMETYPE END),
        SC.NAMEGROUP = (CASE WHEN TCF.OriginalFilterName = N'NameGroupKey' THEN NULL WHEN TCF.FILTERNAME = N'NameGroupKey' THEN TCF.FILTERVALUE ELSE SC.NAMEGROUP END),
        SC.FLAGNUMBER = (CASE WHEN TCF.OriginalFilterName = N'CountryFlag' THEN NULL WHEN TCF.FILTERNAME = N'CountryFlag' THEN TCF.FILTERVALUE ELSE SC.FLAGNUMBER END),
        SC.CREATEACTION = (CASE WHEN TCF.OriginalFilterName = N'CreateActionKey' THEN NULL WHEN TCF.FILTERNAME = N'CreateActionKey' THEN TCF.FILTERVALUE ELSE SC.CREATEACTION END),
        SC.RELATIONSHIP = (CASE WHEN TCF.OriginalFilterName = N'CaseRelationKey' THEN NULL WHEN TCF.FILTERNAME = N'CaseRelationKey' THEN TCF.FILTERVALUE ELSE SC.RELATIONSHIP END),
        SC.GENERICPARAMETER = (CASE WHEN TCF.OriginalFilterName = N'NumberTypeKeys' THEN NULL WHEN TCF.FILTERNAME = N'NumberTypeKeys' THEN TCF.FILTERVALUE ELSE SC.GENERICPARAMETER END)
    FROM SCREENCONTROL SC
    INNER JOIN (SELECT
      WC.CRITERIANO,
      TC.TOPICNAME,
      TC.TOPICSUFFIX,
      WC.ENTRYNUMBER,
      TCF.FILTERNAME,
      TCF.FILTERVALUE,
      CASE WHEN del.FILTERNAME = TCF.FILTERNAME THEN '' ELSE del.FILTERNAME END AS OriginalFilterName
    FROM inserted TCF
    INNER JOIN deleted del ON TCF.TOPICCONTROLFILTERNO = del.TOPICCONTROLFILTERNO
    INNER JOIN TOPICCONTROL TC ON TC.TOPICCONTROLNO = TCF.TOPICCONTROLNO
    INNER JOIN WINDOWCONTROL WC ON WC.WINDOWCONTROLNO = TC.WINDOWCONTROLNO AND WC.WINDOWNAME = N'WorkflowWizard') TCF
      ON SC.CRITERIANO = TCF.CRITERIANO
      AND SC.SCREENNAME = TCF.TOPICNAME
      AND SC.SCREENID = TCF.TOPICSUFFIX
  END
GO

--PRINT 'Creating trigger tD_TOPICCONTROLFILTER_Sync...' 

CREATE TRIGGER tD_TOPICCONTROLFILTER_Sync ON TOPICCONTROLFILTER
AFTER DELETE NOT FOR REPLICATION
AS
  -- TRIGGER :    tD_TOPICCONTROLFILTER_Sync
  -- VERSION :  1
  -- DESCRIPTION:	Updates the corresponding columns in SCREENCONTROL table to Null value. This ensures that the SCREENCONTROL table remain in sync with TOPICCONTROL
  --				It doesnt execute if delete is coming from ScreenControl table's Update trigger
  -- MODIFICATIONS :
  -- Date		Who	Change	Version	Description
  -- -----------	-------	------	-------	----------------------------------------------- 
  -- 06 Dec 2016	HM		1	Trigger created
  
  IF EXISTS (SELECT 1 FROM deleted)
    AND TRIGGER_NESTLEVEL(OBJECT_ID('tU_SCREENCONTROL_Sync'), 'After', 'DML') = 0
  BEGIN    
    UPDATE SC
    SET SC.CHECKLISTTYPE = (CASE WHEN TCF.FILTERNAME = N'ChecklistTypeKey' THEN NULL ELSE SC.CHECKLISTTYPE END),
        SC.TEXTTYPE = (CASE WHEN TCF.FILTERNAME = N'TextTypeKey' THEN NULL ELSE SC.TEXTTYPE END),
        SC.NAMETYPE = (CASE WHEN TCF.FILTERNAME = N'NameTypeKey' THEN NULL ELSE SC.NAMETYPE END),
        SC.NAMEGROUP = (CASE WHEN TCF.FILTERNAME = N'NameGroupKey' THEN NULL ELSE SC.NAMEGROUP END),
        SC.FLAGNUMBER = (CASE WHEN TCF.FILTERNAME = N'CountryFlag' THEN NULL ELSE SC.FLAGNUMBER END),
        SC.CREATEACTION = (CASE WHEN TCF.FILTERNAME = N'CreateActionKey' THEN NULL ELSE SC.CREATEACTION END),
        SC.RELATIONSHIP = (CASE WHEN TCF.FILTERNAME = N'CaseRelationKey' THEN NULL ELSE SC.RELATIONSHIP END),
        SC.GENERICPARAMETER = (CASE WHEN TCF.FILTERNAME = N'NumberTypeKeys' THEN NULL ELSE SC.GENERICPARAMETER END)
    FROM SCREENCONTROL SC
    INNER JOIN (SELECT
      WC.CRITERIANO,
      TC.TOPICNAME,
      TC.TOPICSUFFIX,
      WC.ENTRYNUMBER,
      TCF.FILTERNAME,
      TCF.FILTERVALUE
    FROM deleted TCF
    INNER JOIN TOPICCONTROL TC ON TC.TOPICCONTROLNO = TCF.TOPICCONTROLNO
    INNER JOIN WINDOWCONTROL WC ON WC.WINDOWCONTROLNO = TC.WINDOWCONTROLNO AND WC.WINDOWNAME = N'WorkflowWizard') TCF
      ON SC.CRITERIANO = TCF.CRITERIANO
      AND SC.SCREENNAME = TCF.TOPICNAME
      AND SC.SCREENID = TCF.TOPICSUFFIX
  END
GO