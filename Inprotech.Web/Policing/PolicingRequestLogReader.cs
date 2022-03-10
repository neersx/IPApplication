using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using Inprotech.Infrastructure.Compatibility;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Policing;

namespace Inprotech.Web.Policing
{
    public interface IPolicingRequestLogReader
    {
        IQueryable<PolicingRequestLogItem> Retrieve();

        IEnumerable<CodeDescription> AllowableFilters(string field, CommonQueryParameters parameters);

        IQueryable<DateTime> GetInProgressRequests(DateTime[] startDateTime = null);

    }

    public class PolicingRequestLogReader : IPolicingRequestLogReader
    {
        static readonly Expression<Func<PolicingRequestLogItem, CodeDescription>> ByPolicingName =
            x => new CodeDescription
                 {
                     Code = x.PolicingName ?? string.Empty,
                     Description = x.PolicingName ?? string.Empty
                 };

        static readonly Expression<Func<PolicingRequestLogItem, CodeDescription>> ByStatus =
            x => new CodeDescription
                 {
                     Code = x.Status ?? string.Empty,
                     Description = x.Status ?? string.Empty
                 };

        static readonly Dictionary<string, Expression<Func<PolicingRequestLogItem, CodeDescription>>> Filterables
            = new Dictionary<string, Expression<Func<PolicingRequestLogItem, CodeDescription>>>
              {
                  {"policingName", ByPolicingName},
                  {"status", ByStatus}
              };

        readonly IDbContext _dbContext;
        readonly ICommonQueryService _commonQueryService;
        readonly IInprotechVersionChecker _inprotechVersionChecker;

        public PolicingRequestLogReader(IDbContext dbContext, ICommonQueryService commonQueryService, IInprotechVersionChecker inprotechVersionChecker)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (commonQueryService == null) throw new ArgumentNullException("commonQueryService");

            _dbContext = dbContext;
            _commonQueryService = commonQueryService;
            _inprotechVersionChecker = inprotechVersionChecker;
        }

        public IEnumerable<CodeDescription> AllowableFilters(string field, CommonQueryParameters parameters)
        {
            if (parameters == null) throw new ArgumentNullException("parameters");

            Expression<Func<PolicingRequestLogItem, CodeDescription>> filterable;
            if (!Filterables.TryGetValue(field, out filterable))
                throw new NotSupportedException("field=" + field);

            var requestLog = Retrieve();
            var prefilteredLog = _commonQueryService.Filter(requestLog, parameters).AsQueryable();

            return prefilteredLog
                .Select(filterable)
                .DistinctBy(x => x.Code)
                .OrderBy(x => x.Description);
        }

        public IQueryable<PolicingRequestLogItem> Retrieve()
        {
            var isMinimumVersion16 = _inprotechVersionChecker.CheckMinimumVersion(16);

            var policingLog = _dbContext.Set<PolicingLog>();
            var policing = _dbContext.Set<PolicingRequest>();
            
            return from pl in policingLog
                   join p in policing
                       on pl.PolicingName equals p.Name into p1
                   from p in p1.DefaultIfEmpty()
                   where pl.PolicingName != null && !pl.PolicingName.StartsWith("Invoked from Policing Server")
                   orderby pl.StartDateTime descending
                   select new PolicingRequestLogItem
                          {
                              PolicingLogId = pl.PolicingLogId,
                              PolicingName = pl.PolicingName,
                              StartDateTime = pl.StartDateTime,
                              FinishDateTime = pl.FinishDateTime,
                              FailMessage = pl.FailMessage,
                              FromDate = pl.FromDate,
                              NumberOfDays = pl.NumberOfDays,
                              Status = !string.IsNullOrEmpty(pl.FailMessage) ? "error" :
                              pl.FinishDateTime != null ? "completed" : "inProgress",
                              RequestId = p != null ? (int?)p.RequestId : null,
                              SpId = isMinimumVersion16 ? pl.SpId : null,
                              SpIdStart = isMinimumVersion16 ? pl.SpIdStart : null,
                              CanDelete = false
                          };
        }

        public IQueryable<DateTime> GetInProgressRequests(DateTime[] startDateTime = null)
        {
            var request = _dbContext.Set<PolicingRequest>();
            var requestLog = _dbContext.Set<PolicingLog>().AsQueryable();

            if (startDateTime !=null && startDateTime.Any())
            {
                requestLog = requestLog.Where(_ => startDateTime.Contains(_.StartDateTime));
            }

            return from l in requestLog
                   join r in request on l.PolicingName equals r.Name
                   where r.IsSystemGenerated == 0
                         && string.IsNullOrEmpty(l.FailMessage)
                         && l.FinishDateTime == null
                   select l.StartDateTime;
        }
    }
}