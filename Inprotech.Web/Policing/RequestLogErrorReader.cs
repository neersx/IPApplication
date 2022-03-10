using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Policing;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Policing
{
    public interface IRequestLogErrorReader
    {
        Dictionary<DateTime, RequestLogError> Read(DateTime[] startDateTimes, int top);

        IQueryable<PolicingRequestLogErrorItem> For(int policingLogId);
    }

    public class RequestLogErrorReader : IRequestLogErrorReader
    {
        readonly IDbContext _dbContext;
        private readonly IPreferredCultureResolver _preferredCultureResolver;

        public RequestLogErrorReader(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");

            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _dbContext.Log = s => Debug.WriteLine(s);
        }

        public Dictionary<DateTime, RequestLogError> Read(DateTime[] startDateTimes, int top)
        {
            if (!startDateTimes.Any())
            {
                return new Dictionary<DateTime, RequestLogError>();
            }

            var errors = Errors(startDateTimes);

            return TopItemsInError(errors, top)
                .ToDictionary(_ => _.StartDateTime, _ => _);
        }

        public IQueryable<PolicingRequestLogErrorItem> For(int policingLogid)
        {
            var startDateTime = _dbContext.Set<PolicingLog>()
                                          .Where(_ => _.PolicingLogId == policingLogid)
                                          .Select(_ => _.StartDateTime)
                                          .Single();

            return Errors(new[] { startDateTime });
        }

        IQueryable<PolicingRequestLogErrorItem> Errors(DateTime[] startDateTimes)
        {
            var culture = _preferredCultureResolver.Resolve();

            var policingErrors = _dbContext.Set<PolicingError>();
            var cases = _dbContext.Set<Case>();
            var eventControls = _dbContext.Set<ValidEvent>();
            var events = _dbContext.Set<Event>();
            var criteria = _dbContext.Set<Criteria>();

            return from pe in policingErrors
                   join c in cases on pe.CaseId equals c.Id into c1
                   from c in c1.DefaultIfEmpty()
                   join ec in eventControls on new {cr = pe.CriteriaNo, ev = pe.EventNo} equals new {cr = (int?) ec.CriteriaId, ev = (int?) ec.EventId} into l1
                   from ec in l1.DefaultIfEmpty()
                   join e in events on pe.EventNo equals e.Id into l2
                   from e in l2.DefaultIfEmpty()
                   where startDateTimes.Contains(pe.StartDateTime)
                   join cr in criteria on pe.CriteriaNo equals cr.Id into cr1
                   from cr in cr1.DefaultIfEmpty()
                   select new PolicingRequestLogErrorItem
                          {
                              StartDateTime = pe.StartDateTime,
                              Irn = c != null ? c.Irn : null,
                              SpecificDescription = ec != null ? DbFuncs.GetTranslation(ec.Description, null, ec.DescriptionTId, culture) : null,
                              BaseDescription = e != null ? DbFuncs.GetTranslation(e.Description, null, e.DescriptionTId, culture) : null,
                              CriteriaDescription = cr != null ? DbFuncs.GetTranslation(cr.Description, null, cr.DescriptionTId, culture) : null,
                              CycleNo = pe.CycleNo,
                              Message = pe.Message,
                              CriteriaNo = pe.CriteriaNo,
                              EventNo = pe.EventNo
                          };
        }

        IEnumerable<RequestLogError> TopItemsInError(IQueryable<PolicingRequestLogErrorItem> errors, int count)
        {
            return
                from e in errors
                group e by e.StartDateTime
                into logErrors
                select new RequestLogError
                       {
                           StartDateTime = logErrors.Key,
                           ErrorItems = (from le in logErrors
                                         orderby le.StartDateTime descending
                                         select le).Take(count),
                           TotalErrorItemsCount = logErrors.Count()
                       };
        }
    }

    public static class RequestLogErrorExtension
    {
        public static RequestLogError For(this Dictionary<DateTime, RequestLogError> data, DateTime startDateTime)
        {
            RequestLogError error;
            if (data.TryGetValue(startDateTime, out error))
                return error;

            return null;
        }
    }
}