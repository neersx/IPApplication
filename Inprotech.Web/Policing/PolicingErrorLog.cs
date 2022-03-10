using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Policing;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Policing
{
    public interface IPolicingErrorLog
    {
        IEnumerable<CodeDescription> CasesAvailableForFiltering(CommonQueryParameters parameters);

        IQueryable<PolicingErrorLogItem> Retrieve(CommonQueryParameters parameters);

        IEnumerable<PolicingErrorLogItem> SetInProgressFlag(IEnumerable<PolicingErrorLogItem> data);
    }

    public class PolicingErrorLog : IPolicingErrorLog
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ICommonQueryService _commonQueryService;
        readonly IPolicingQueue _policingQueue;
        readonly IPolicingRequestLogReader _policingRequestLogReader;

        public PolicingErrorLog(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, ICommonQueryService commonQueryService, IPolicingQueue policingQueue, IPolicingRequestLogReader policingRequestLogReader)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _commonQueryService = commonQueryService;
            _policingQueue = policingQueue;
            _policingRequestLogReader = policingRequestLogReader;
        }

        public IEnumerable<CodeDescription> CasesAvailableForFiltering(CommonQueryParameters parameters)
        {
            var mapped = parameters.RemapFilter("errorDate", "StartDateTime");
            var errors = _dbContext.Set<PolicingError>();
            var cases = _dbContext.Set<Case>();
            var filteredErrors = _commonQueryService.Filter(errors, mapped).AsQueryable();

            return (from pe in filteredErrors
                    join c in cases on pe.CaseId equals (int?) c.Id into l
                    from c in l.DefaultIfEmpty()
                    select c == null ? null : c.Irn)
                .Distinct()
                .OrderBy(_ => _)
                .Select(_ => new CodeDescription
                             {
                                 Code = _,
                                 Description = _
                             });
        }

        public IQueryable<PolicingErrorLogItem> Retrieve(CommonQueryParameters parameters)
        {
            var errors = _dbContext.Set<PolicingError>();
            var eventControls = _dbContext.Set<ValidEvent>();
            var events = _dbContext.Set<Event>();
            var cases = _dbContext.Set<Case>();
            var criteria = _dbContext.Set<Criteria>();

            var culture = _preferredCultureResolver.Resolve();

            var interim = from pe in errors
                          join ec in eventControls on new {ev = pe.EventNo, cr = pe.CriteriaNo} equals new {ev = (int?) ec.EventId, cr = (int?) ec.CriteriaId} into l1
                          from ec in l1.DefaultIfEmpty()
                          join e in events on pe.EventNo equals e.Id into l2
                          from e in l2.DefaultIfEmpty()
                          join c in cases on pe.CaseId equals c.Id into l3
                          from c in l3.DefaultIfEmpty()
                          join cr in criteria on pe.CriteriaNo equals cr.Id into cr1
                          from cr in cr1.DefaultIfEmpty()
                          orderby pe.StartDateTime descending
                          select new PolicingErrorLogItem
                                 {
                                     PolicingErrorsId = pe.PolicingErrorsId,
                                     ErrorDate = pe.StartDateTime,
                                     ErrorSeq = pe.ErrorSeqNo,
                                     CaseId = pe.CaseId,
                                     CaseRef = c != null ? c.Irn : null,
                                     Message = pe.Message,
                                     EventNumber = pe.EventNo,
                                     EventCycle = pe.CycleNo,
                                     EventCriteriaNumber = pe.CriteriaNo,
                                     EventCriteriaDescription = cr!=null ? DbFuncs.GetTranslation(cr.Description, null, cr.DescriptionTId, culture) : null,
                                     SpecificDescription = ec != null ? DbFuncs.GetTranslation(ec.Description, null, ec.DescriptionTId, culture) : null,
                                     BaseDescription = e != null ? DbFuncs.GetTranslation(e.Description, null, e.DescriptionTId, culture) : null,
                                 };

            return _commonQueryService.Filter(interim, parameters).AsQueryable();
        }

        public IEnumerable<PolicingErrorLogItem> SetInProgressFlag(IEnumerable<PolicingErrorLogItem> data)
        {
            var policingInQueueItems = _policingQueue.GetPolicingInQueueItemsInfo();
            var inProgressRequests = _policingRequestLogReader.GetInProgressRequests();

            var errorItems = (from e in data
                             join pq in policingInQueueItems on e.CaseId equals pq.CaseId into policingQueue
                             from policingQ in policingQueue.DefaultIfEmpty()
                             join pr in inProgressRequests on e.ErrorDate equals pr into policingRequest
                             from policingR in policingRequest.DefaultIfEmpty(DateTime.MinValue)
                             select new PolicingErrorInterim
                             {
                                        ErrorLog = e,
                                        InProgress = policingQ != null && policingQ.Earliest <= e.ErrorDate ? InprogressItem.Queue : policingR!= DateTime.MinValue ? InprogressItem.Request : InprogressItem.None
                             }).ToList();

            return errorItems.Select(_ => _.ApplyInProgressFlag());
        }
    }

    class PolicingErrorInterim
    {
        public PolicingErrorLogItem ErrorLog { get; set; }

        public InprogressItem InProgress { get; set; }

        public PolicingErrorLogItem ApplyInProgressFlag()
        {
            ErrorLog.ErrorForInProgressItem = InProgress;
            return ErrorLog;
        }
    }
}