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

#pragma warning disable 618

namespace Inprotech.Tests.Integration.EndToEnd.Policing.RegressionTests.Requestlog
{
    public class RequestLogDbSetup : DbSetup
    {
        readonly string _eventName = @"e2e-event-" + typeof (RequestLogDbSetup).Name;

        public RequestLogDbSetup()
        {
            Users = new Users(DbContext);
        }

        public void DeleteLog(PolicingLog log)
        {
            var logRecord = DbContext.Set<PolicingLog>().SingleOrDefault(_ => _.StartDateTime == log.StartDateTime && _.PolicingName == log.PolicingName);
            if (logRecord == null)
                return;

            DbContext.Set<PolicingLog>().Remove(logRecord);
            DbContext.SaveChanges();
        }

        public Users Users { get; }

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

            var criteria = InsertWithNewId(new Criteria
                                           {
                                               PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                                           });

            var @event = InsertWithNewId(new Event
                                         {
                                             Description = _eventName
                                         });

            Insert(new ValidEvent(criteria, @event, _eventName));

            return InsertWithNewId(new PolicingError
                                   {
                                       StartDateTime = request.DateEntered,
                                       CaseId = request.Case?.Id,
                                       CriteriaNo = criteria.Id,
                                       EventNo = @event.Id,
                                       CycleNo = 1,
                                       Message = "E2E Error" + RandomString.Next(6)
                                   },
                                   x => x.ErrorSeqNo,
                                   x => x.StartDateTime == request.DateEntered);
        }

        public PolicingError CreateError(DateTime dateTime, Case @case = null)
        {
            var log = DbContext.Set<PolicingLog>().SingleOrDefault(_ => _.StartDateTime == dateTime);

            if (log == null)
            {
                Insert(new PolicingLog
                       {
                           StartDateTime = dateTime,
                           PolicingName = RandomString.Next(6),
                           FailMessage = "Fail message" + RandomString.Next(6)
                       });
            }

            return InsertWithNewId(new PolicingError
                                   {
                                       StartDateTime = dateTime,
                                       Message = "E2E Error" + RandomString.Next(6),
                                       Case = @case
                                   },
                                   x => x.ErrorSeqNo,
                                   x => x.StartDateTime == dateTime);
        }

        public Case GetCase(string irn = null)
        {
            var prefixedIrn = Fixture.Prefix(irn);
            return DbContext.Set<Case>().SingleOrDefault(_ => _.Irn == prefixedIrn + "irn") ?? new CaseBuilder(DbContext).Create(prefixedIrn);
        }
    }
}