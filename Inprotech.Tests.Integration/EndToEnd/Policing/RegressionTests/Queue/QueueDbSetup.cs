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

namespace Inprotech.Tests.Integration.EndToEnd.Policing.RegressionTests.Queue
{
    public class QueueDbSetup : DbSetup
    {
        readonly string _eventName = @"e2e-event-" + typeof (QueueDbSetup).Name;

        public QueueDbSetup()
        {
            OtherUsers = new OtherUserBuilder(DbContext);
        }

        public Case GetCase(string irn = null)
        {
            var prefixedIrn = Fixture.Prefix(irn);

            return DbContext.Set<Case>().SingleOrDefault(_ => _.Irn == prefixedIrn + "irn") ?? new CaseBuilder(DbContext).Create(prefixedIrn);
        }

        public void DeletePolicingItemFor(string irn)
        {
            var @case = DbContext.Set<Case>().FirstOrDefault(_ => _.Irn == irn);
            if (@case != null)
            {
                var casesToDelete = DbContext.Set<PolicingRequest>().Where(_ => _.CaseId == @case.Id).ToList();
                casesToDelete.ForEach(_ => DbContext.Set<PolicingRequest>().Remove(_));
            }
            DbContext.SaveChanges();
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
    }
}