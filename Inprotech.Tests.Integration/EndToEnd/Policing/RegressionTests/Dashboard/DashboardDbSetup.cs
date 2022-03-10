using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Policing.Monitoring;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Policing;
using InprotechKaizen.Model.Rules;
#pragma warning disable 618

namespace Inprotech.Tests.Integration.EndToEnd.Policing.RegressionTests.Dashboard
{
    public class DashboardDbSetup : DbSetup
    {
        readonly string _eventName = @"e2e-event-" + typeof(DashboardDbSetup).Name;

        public DashboardDbSetup WithPolicingServerOff()
        {
            Helpers.SetPolicingServerOff(DbContext);
            return this;
        }
        
        public void EnsureLogExists()
        {
            if (RevertLog())
                return;

            const string script = "CREATE TABLE POLICING_iLOG(LOGDATETIMESTAMP datetime, LOGACTION nchar (1), CREATEDBYE2E bit Default 1)";

            DbContext.CreateSqlCommand(script).ExecuteNonQuery();
        }

        public void EnsureLogDoesNotExists()
        {
            if (!new SqlDbArtifacts(DbContext).Exists("POLICING_iLOG", SysObjects.Table, SysObjects.View))
                return;
            if (new SqlDbArtifacts(DbContext).Exists("POLICING_iLOGTempZ", SysObjects.Table, SysObjects.View))
            {
                const string scriptDeleteTempTable = "Drop table POLICING_iLOGTempZ";
                DbContext.CreateSqlCommand(scriptDeleteTempTable).ExecuteNonQuery();
            }

            const string script = "EXEC sp_rename 'POLICING_iLOG', 'POLICING_iLOGTempZ'";
            DbContext.CreateSqlCommand(script).ExecuteNonQuery();
        }

        public bool RevertLog()
        {
            if (new SqlDbArtifacts(DbContext).Exists("POLICING_iLOG", SysObjects.Table, SysObjects.View))
                return true;

            if (!new SqlDbArtifacts(DbContext).Exists("POLICING_iLOGTempZ", SysObjects.Table, SysObjects.View))
                return false;

            const string script = "EXEC sp_rename 'POLICING_iLOGTempZ', 'POLICING_iLOG'";
            DbContext.CreateSqlCommand(script).ExecuteNonQuery();

            return true;
        }

        public Case GetCase(string irn = null)
        {
            var prefixedIrn = Fixture.Prefix(irn);

            return DbContext.Set<Case>().SingleOrDefault(_ => _.Irn == prefixedIrn + "irn") ?? new CaseBuilder(DbContext).Create(prefixedIrn);
        }

        public PolicingRequest EnqueueFor(string status, string typeOfRequest, Case @case, DateTime? start = null, int? eventNo = null, int? criteriaId = null)
        {
            var startAdjusted = start == null ? Helpers.UniqueDateTime() : Helpers.UniqueDateTime(start);

            return Insert(new PolicingRequest(null)
                          {
                              OnHold = KnownValues.StringToHoldFlag[status],
                              IsSystemGenerated = 1,
                              Name = "E2E Test " + RandomString.Next(6),
                              DateEntered = startAdjusted,
                              Case = @case,
                              SequenceNo = 1,
                              User = new OtherUserBuilder(DbContext).Create().John,
                              TypeOfRequest = (short) KnownValues.StringToTypeOfRequest[typeOfRequest],
                              Irn = @case?.Irn,
                              EventNo = eventNo,
                              CriteriaNo = criteriaId
                          });
        }

        public Data WithWorkflowData()
        {
            var criteria = InsertWithNewId(new Criteria
                                           {
                                               PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                                           });

            var @event = InsertWithNewId(new Event
                                         {
                                             Description = _eventName
                                         });

            Insert(new ValidEvent(criteria, @event, _eventName));

            return new Data
                   {
                       Criteria = criteria,
                       Event = @event
                   };
        }

        public PolicingError CreateErrorFor(PolicingRequest request)
        {
            var log = DbContext.Set<PolicingLog>()
                               .SingleOrDefault(_ => _.StartDateTime == request.DateEntered &&
                                                     _.PolicingName == request.Name);

            if (log == null)
            {
                Insert(new PolicingLog
                       {
                           StartDateTime = request.DateEntered,
                           PolicingName = request.Name,
                           FailMessage = "Fail message" + RandomString.Next(6)
                       });
            }

            var withWorkflowData = WithWorkflowData();

            return InsertWithNewId(new PolicingError
                                   {
                                       StartDateTime = request.DateEntered,
                                       CaseId = request.Case?.Id,
                                       CriteriaNo = withWorkflowData.Criteria.Id,
                                       EventNo = withWorkflowData.Event.Id,
                                       CycleNo = 1,
                                       Message = "E2E Error" + RandomString.Next(6)
                                   },
                                   x => x.ErrorSeqNo,
                                   x => x.StartDateTime == request.DateEntered);
        }

        public static E2ESummary RawSummaryFromSql()
        {
            //DONOT REMOVE: This sql is given by Mike. 
            //In case functionality changes ensure it is modified here
            const string sql =
                @"select  count(*) as [TotalRows],
      SUM(CASE WHEN(E.CASEID is NULL and P.ONHOLDFLAG in (2,3,4) 
		and datediff(SECOND, P.LOGDATETIMESTAMP, getdate())<=120)
								THEN 1 ELSE 0 END) as [InProgressGreen],
      SUM(CASE WHEN(E.CASEID is NULL and P.ONHOLDFLAG in (2,3)   
		and datediff(SECOND, P.LOGDATETIMESTAMP, getdate()) between 121 and 600)
								THEN 1 ELSE 0 END) as [InProgressAmber],
      SUM(CASE WHEN(E.CASEID is NULL and P.ONHOLDFLAG in (2,3)   
		and datediff(SECOND, P.LOGDATETIMESTAMP, getdate()) > 600)
								THEN 1 ELSE 0 END) as [InProgressRed],
      SUM(CASE WHEN(E.CASEID is NULL and P.ONHOLDFLAG in (4)     
		and datediff(SECOND, P.LOGDATETIMESTAMP, getdate()) between 121 and 600)
								THEN 1 ELSE 0 END) as [FailedAmber],
      SUM(CASE WHEN(E.CASEID is NULL and P.ONHOLDFLAG in (4)     
		and datediff(SECOND, P.LOGDATETIMESTAMP, getdate()) > 600)
								THEN 1 ELSE 0 END) as [FailedRed],
      SUM(CASE WHEN(P.ONHOLDFLAG=9)				THEN 1 ELSE 0 END) as [OnHold],
      
      SUM(CASE WHEN(P.ONHOLDFLAG=0 and COALESCE(P1.CASEID,P2.CASEID,P3.CASEID) is not null
		and datediff(SECOND, P.LOGDATETIMESTAMP, getdate())<=120)
								THEN 1 ELSE 0 END) as [BlockedGreen],
      SUM(CASE WHEN(P.ONHOLDFLAG=0 and COALESCE(P1.CASEID,P2.CASEID,P3.CASEID) is not null
		and datediff(SECOND, P.LOGDATETIMESTAMP, getdate()) between 121 and 600)
								THEN 1 ELSE 0 END) as [BlockedAmber],
      SUM(CASE WHEN(P.ONHOLDFLAG=0 and COALESCE(P1.CASEID,P2.CASEID,P3.CASEID) is not null
		and datediff(SECOND, P.LOGDATETIMESTAMP, getdate())>600)
								THEN 1 ELSE 0 END) as [BlockedRed],
      SUM(CASE WHEN(P.ONHOLDFLAG in (0,1) and COALESCE(P1.CASEID,P2.CASEID,P3.CASEID) is null 
		and datediff(SECOND, P.LOGDATETIMESTAMP, getdate())<=120)
								THEN 1 ELSE 0 END) as [WaitingToStartGreen],
      SUM(CASE WHEN(P.ONHOLDFLAG in (0,1) and COALESCE(P1.CASEID,P2.CASEID,P3.CASEID) is null 
		and datediff(SECOND, P.LOGDATETIMESTAMP, getdate()) between 121 and 600)
								THEN 1 ELSE 0 END) as [WaitingToStartAmber],
      SUM(CASE WHEN(P.ONHOLDFLAG in (0,1) and COALESCE(P1.CASEID,P2.CASEID,P3.CASEID) is null 
		and datediff(SECOND, P.LOGDATETIMESTAMP, getdate())>600)
								THEN 1 ELSE 0 END) as [WaitingToStartRed],
      SUM(CASE WHEN(E.CASEID is NOT NULL 
		and datediff(SECOND, P.LOGDATETIMESTAMP, getdate())<=120)
								THEN 1 ELSE 0 END) as [ErrorGreen],
      SUM(CASE WHEN(E.CASEID is NOT NULL 
		and datediff(SECOND, P.LOGDATETIMESTAMP, getdate()) between 121 and 600)
								THEN 1 ELSE 0 END) as [ErrorAmber],
      SUM(CASE WHEN(E.CASEID is NOT NULL 
		and datediff(SECOND, P.LOGDATETIMESTAMP, getdate())>600)
								THEN 1 ELSE 0 END) as [ErrorRed]
                                from POLICING P
                                -----------------------------------
                                -- Looking for Policing Errors
                                -----------------------------------
                                left join (select distinct CASEID
                                           from POLICINGERRORS PE
                                           where PE.LOGDATETIMESTAMP>=( Select MIN(P1.DATEENTERED)
					                                from POLICING P1
					                                where P1.ONHOLDFLAG<>1
					                                and P1.SYSGENERATEDFLAG=1
					                                and P1.ONHOLDFLAG between 2 and 4)
					                                ) E on (E.CASEID=P.CASEID
					                                    and P.ONHOLDFLAG between 2 and 4)
                                -----------------------------------------------------------------
                                -- Looking for BLOCKING rows caused by an Action to be opened
                                -----------------------------------------------------------------
                                left join (Select DISTINCT CASEID
	                                   from POLICING
	                                   where TYPEOFREQUEST=1
	                                   and SYSGENERATEDFLAG=1
	                                   and BATCHNO is null) P1	on (P1.CASEID=P.CASEID
					                                and P.ONHOLDFLAG=0
					                                and P.TYPEOFREQUEST<>1)

                                -----------------------------------------------------------------
                                -- If the Case to be processed has already commenced processing 
                                -- then this will block requests for the same Case
                                -----------------------------------------------------------------
                                left join (Select DISTINCT CASEID
	                                   from POLICING
	                                   where ONHOLDFLAG<>9
	                                   and SYSGENERATEDFLAG<>0
	                                   and SPIDINPROGRESS is not null) P2
					                                on (P2.CASEID=P.CASEID
					                                and P.ONHOLDFLAG=0)

                                -----------------------------------------------------------------
                                -- if multiple Users have issued a request against the same Case
                                -- then TYPEOFREQUEST=1 requests process first, otherwise the 
                                -- earlier request of a different user will block a row from being
                                -- processed.
                                -----------------------------------------------------------------
                                left join (Select CASEID, IDENTITYID, MIN(DATEENTERED) as DATEENTERED, MIN(TYPEOFREQUEST) as TYPEOFREQUEST
	                                   from	POLICING
	                                   where ONHOLDFLAG<3
	                                   and SYSGENERATEDFLAG>0
	                                   group by CASEID, IDENTITYID) P3	
					                                on (P3.CASEID     =P.CASEID
					                                and P3.IDENTITYID<>P.IDENTITYID
					                                and P3.DATEENTERED<P.DATEENTERED
					                                and(P3.TYPEOFREQUEST=1 and P.TYPEOFREQUEST=1 OR (P.TYPEOFREQUEST>1))
					                                and P.ONHOLDFLAG  =0)
                                where P.SYSGENERATEDFLAG=1";

            var summary = Do(x =>
                             {
                                 var interim = x.DbContext.SqlQuery<QuerySummaryResult>(sql).Single();

                                 return new Summary
                                        {
                                            Total = interim.TotalRows.GetValueOrDefault(),
                                            Failed = new Detail
                                                     {
                                                         Tolerable = interim.FailedAmber.GetValueOrDefault(),
                                                         Stuck = interim.FailedRed.GetValueOrDefault()
                                                     },
                                            OnHold = new Detail
                                                     {
                                                         Fresh = interim.OnHold.GetValueOrDefault()
                                                     },
                                            InError = new Detail
                                                      {
                                                          Fresh = interim.ErrorGreen.GetValueOrDefault(),
                                                          Tolerable = interim.ErrorAmber.GetValueOrDefault(),
                                                          Stuck = interim.ErrorRed.GetValueOrDefault()
                                                      },
                                            InProgress = new Detail
                                                         {
                                                             Fresh = interim.InProgressGreen.GetValueOrDefault(),
                                                             Tolerable = interim.InProgressAmber.GetValueOrDefault(),
                                                             Stuck = interim.InProgressRed.GetValueOrDefault()
                                                         },
                                            WaitingToStart = new Detail
                                                             {
                                                                 Fresh = interim.WaitingToStartGreen.GetValueOrDefault(),
                                                                 Tolerable = interim.WaitingToStartAmber.GetValueOrDefault(),
                                                                 Stuck = interim.WaitingToStartRed.GetValueOrDefault()
                                                             }
                                        };
                             });

            return new E2ESummary
                   {
                       Total = summary.Total,
                       Progressing = summary.InProgress.Total + summary.WaitingToStart.Total,
                       RequiresAttention = summary.InError.Total + summary.Failed.Total + summary.Blocked.Total,
                       OnHold = summary.OnHold.Total
                   };
        }
    }

    public class E2ESummary
    {
        public int Total { get; set; }
        public int Progressing { get; set; }
        public int OnHold { get; set; }
        public int RequiresAttention { get; set; }
    }

    public class QuerySummaryResult
    {
        public int? TotalRows { get; set; }
        public int? InProgressGreen { get; set; }
        public int? InProgressAmber { get; set; }
        public int? InProgressRed { get; set; }
        public int? FailedAmber { get; set; }
        public int? FailedRed { get; set; }
        public int? OnHold { get; set; }
        public int? WaitingToStartGreen { get; set; }
        public int? WaitingToStartAmber { get; set; }
        public int? WaitingToStartRed { get; set; }
        public int? ErrorGreen { get; set; }
        public int? ErrorAmber { get; set; }
        public int? ErrorRed { get; set; }
    }

    public class Data
    {
        public Criteria Criteria { get; set; }

        public Event Event { get; set; }
    }
}