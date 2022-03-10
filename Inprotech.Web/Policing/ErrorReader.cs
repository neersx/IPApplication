using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Policing;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Policing
{
    public interface IErrorReader
    {
        Dictionary<int, QueueError> Read(int[] caseIds, int top);

        IQueryable<PolicingErrorItem> For(int caseId);
    }

    public class ErrorReader : IErrorReader
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        private readonly IPolicingQueue _policingQueue;

        public ErrorReader(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, IPolicingQueue policingQueue)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (preferredCultureResolver == null) throw new ArgumentNullException("preferredCultureResolver");

            _dbContext = dbContext;
            _dbContext.Log = s => Debug.WriteLine(s);
            _preferredCultureResolver = preferredCultureResolver;
            _policingQueue = policingQueue;
        }

        public Dictionary<int, QueueError> Read(int[] caseIds, int top)
        {
            if (!caseIds.Any())
            {
                return new Dictionary<int, QueueError>();
            }

            var culture = _preferredCultureResolver.Resolve();
            var errors = Errors(caseIds, culture);

            return TopItemsInError(errors, top)
                .ToDictionary(_ => _.CaseId, _ => _);
        }

        public IQueryable<PolicingErrorItem> For(int caseId)
        {
            var culture = _preferredCultureResolver.Resolve();
            return Errors(new[] {caseId}, culture);
        }

        IQueryable<PolicingErrorItem> Errors(int[] caseIds, string culture)
        {
            var policingErrors = _dbContext.Set<PolicingError>();
            var eventControl = _dbContext.Set<ValidEvent>();
            var events = _dbContext.Set<Event>();
            var criteria = _dbContext.Set<Criteria>();

            var stillInQueue = _policingQueue.GetPolicingInQueueItemsInfo(caseIds);

            return from pe in policingErrors
                   join since in stillInQueue on pe.CaseId equals since.CaseId into s1
                   from since in s1.DefaultIfEmpty()
                   join c in criteria on pe.CriteriaNo equals c.Id into c1
                   from c in c1.DefaultIfEmpty()
                   join ec in eventControl on new {ev = pe.EventNo, cr = pe.CriteriaNo}
                   equals new {ev = (int?) ec.EventId, cr = (int?) ec.CriteriaId} into l1
                   from ec in l1.DefaultIfEmpty()
                   join e in events on pe.EventNo equals e.Id into l2
                   from e in l2.DefaultIfEmpty()
                   where since != null && pe.CaseId == since.CaseId && pe.LastModified >= since.Earliest
                   orderby pe.LastModified descending, pe.ErrorSeqNo descending
                   select new PolicingErrorItem
                          {
                              CaseId = pe.CaseId.Value,
                              SpecificDescription = ec != null ? DbFuncs.GetTranslation(ec.Description, null, ec.DescriptionTId, culture) : null,
                              BaseDescription = e != null ? DbFuncs.GetTranslation(e.Description, null, e.DescriptionTId, culture) : null,
                              CriteriaDescription = c != null ? DbFuncs.GetTranslation(c.Description, null, c.DescriptionTId, culture) : null,
                              ErrorDate = pe.LastModified.Value,
                              EventCriteriaNumber = pe.CriteriaNo,
                              EventNumber = pe.EventNo,
                              EventCycle = pe.CycleNo,
                              Message = pe.Message
                          };
        }

        IEnumerable<QueueError> TopItemsInError(IQueryable<PolicingErrorItem> errors, int count)
        {
            return
                from e in errors
                group e by e.CaseId
                into caseErrors
                select new QueueError
                       {
                           CaseId = caseErrors.Key,
                           ErrorItems = (from ce in caseErrors
                                         orderby ce.ErrorDate descending
                                         select ce).Take(count),
                           TotalErrorItemsCount = caseErrors.Count()
                       };
        }
    }

    public class PolicingErrorEvent
    {
        public int EventId { get; set; }

        public int? CriteriaId { get; set; }

        public string EventDescription { get; set; }
    }

    public class PolicingItemInQueue
    {
        public int CaseId { get; set; }
        public DateTime Earliest { get; set; }
    }

    public static class PolicingErrorItemExtension
    {
        public static string EventControlDescription(this PolicingErrorItem item,
                                                     IEnumerable<PolicingErrorEvent> eventControls)
        {
            if (item.EventCriteriaNumber == null || item.EventNumber == null) return null;

            var ec = eventControls
                .FirstOrDefault(
                                _ =>
                                    _.EventId == item.EventNumber &&
                                    _.CriteriaId == item.EventCriteriaNumber);

            return ec != null ? ec.EventDescription : null;
        }

        public static string EventDescription(this PolicingErrorItem item, IEnumerable<PolicingErrorEvent> events)
        {
            if (item.EventNumber != null)
            {
                var @event = events.FirstOrDefault(_ => _.EventId == item.EventNumber);
                if (@event != null)
                {
                    return @event.EventDescription;
                }
            }
            return null;
        }
    }

    public static class QueueErrorExtension
    {
        public static QueueError For(this Dictionary<int, QueueError> data, int? caseId)
        {
            QueueError error;
            if (caseId.HasValue && data.TryGetValue(caseId.Value, out error))
                return error;

            return null;
        }
    }
}