using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Policing;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;

#pragma warning disable 618

namespace Inprotech.Tests.Integration.EndToEnd.Policing.Scenarios.Viewer
{
    public class ViewerDbSetup : DbSetup
    {
        readonly string _eventName = @"e2e-event-" + typeof (ViewerDbSetup).Name;

        public ViewerDbSetup()
        {
            OtherUsers = new OtherUserBuilder(DbContext);
        }

        internal ViewerDbSetup WithPolicingServerOff()
        {
            Helpers.SetPolicingServerOff(DbContext);
            return this;
        }

        public Case GetCase(string irn = null)
        {
            var prefixedIrn = Fixture.Prefix(irn);
            return DbContext.Set<Case>().SingleOrDefault(_ => _.Irn == prefixedIrn + "irn") ?? new CaseBuilder(DbContext).Create(prefixedIrn);
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
        
        public OtherUserBuilder OtherUsers { get; }

        public PolicingRequest EnqueueFor(User user, string status, string typeOfRequest, Case @case, DateTime? start = null, int? eventNo = null, int? criteriaId = null)
        {
            var startAdjusted = start == null ? Helpers.UniqueDateTime() : Helpers.UniqueDateTime(start);

            return Insert(new PolicingRequest
                          {
                              OnHold = KnownValues.StringToHoldFlag[status],
                              IsSystemGenerated = 1,
                              Name = "E2E Test " + RandomString.Next(6),
                              DateEntered = startAdjusted,
                              Case = @case,
                              SequenceNo = 1,
                              User = user,
                              TypeOfRequest = (short) KnownValues.StringToTypeOfRequest[typeOfRequest],
                              Irn = @case.Irn,
                              EventNo = eventNo,
                              CriteriaNo = criteriaId
                          });
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
        
        public class Data
        {
            public Criteria Criteria { get; set; }

            public Event Event { get; set; }
        }
    }
}