using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Policing.Monitoring;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Policing;

namespace Inprotech.Web.Policing
{
    public interface IPolicingQueue
    {
        IEnumerable<PolicingQueueItem> Retrieve(string byStatus);

        IEnumerable<CodeDescription> AllowableFilters(string byStatus, string field, CommonQueryParameters parameters);

        IQueryable<PolicingItemInQueue> GetPolicingInQueueItemsInfo(int[] caseIds = null);
    }

    public class PolicingQueue : IPolicingQueue
    {
        static readonly string[] KnownStatuses
            = { PolicingQueueKnownStatus.All, PolicingQueueKnownStatus.Progressing, PolicingQueueKnownStatus.RequiresAttention, PolicingQueueKnownStatus.OnHold };

        static readonly Expression<Func<PolicingQueueView, CodeDescription>> ByCaseRef =
            x => new CodeDescription
            {
                Code = x.CaseReference ?? string.Empty, /* CaseRef is unique */
                Description = x.CaseReference ?? string.Empty
            };

        static readonly Expression<Func<PolicingQueueView, CodeDescription>> ByUser =
            x => new CodeDescription
            {
                Code = x.UserKey ?? string.Empty,
                Description = x.User ?? string.Empty
            };

        static readonly Expression<Func<PolicingQueueView, CodeDescription>> ByStatus =
            x => new CodeDescription
            {
                Code = x.Status ?? string.Empty,
                Description = x.Status ?? string.Empty
            };

        static readonly Expression<Func<PolicingQueueView, CodeDescription>> ByRequestType =
            x => new CodeDescription
            {
                Code = x.TypeOfRequest ?? string.Empty,
                Description = x.TypeOfRequest ?? string.Empty
            };

        static readonly Dictionary<string, Expression<Func<PolicingQueueView, CodeDescription>>> Filterables
            = new Dictionary<string, Expression<Func<PolicingQueueView, CodeDescription>>>
              {
                  {"caseReference", ByCaseRef},
                  {"user", ByUser},
                  {"status", ByStatus},
                  {"typeOfRequest", ByRequestType}
              };

        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ICommonQueryService _commonQueryService;

        public PolicingQueue(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, ICommonQueryService commonQueryService)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (preferredCultureResolver == null) throw new ArgumentNullException("preferredCultureResolver");
            if (commonQueryService == null) throw new ArgumentNullException("commonQueryService");

            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _commonQueryService = commonQueryService;
        }

        public IEnumerable<CodeDescription> AllowableFilters(string byStatus, string field, CommonQueryParameters parameters)
        {
            if (parameters == null) throw new ArgumentNullException("parameters");

            if (!KnownStatuses.Contains(byStatus))
                throw new NotSupportedException("Unable to filter queue by the status:" + byStatus);

            Expression<Func<PolicingQueueView, CodeDescription>> filterable;
            if (!Filterables.TryGetValue(field, out filterable))
                throw new NotSupportedException("field=" + field);

            var mappedStatueses = PolicingQueueKnownStatus.MappedStatus(byStatus);

            var queue = _dbContext.Set<PolicingQueueView>();
            var prefilteredQueue = _commonQueryService.Filter(queue, parameters).AsQueryable();

            return prefilteredQueue
                             .Where(_ => byStatus == "all" || mappedStatueses.Contains(_.Status))
                .Select(filterable)
                .DistinctBy(x => x.Code)
                .OrderBy(x => x.Description);
        }

        public IEnumerable<PolicingQueueItem> Retrieve(string byStatus)
        {
            if (!KnownStatuses.Contains(byStatus))
                throw new NotSupportedException("Unable to filter queue by the status:" + byStatus);

            var culture = _preferredCultureResolver.Resolve();
            var policingQueue = _dbContext.Set<PolicingQueueView>();
            var mappedStatueses = PolicingQueueKnownStatus.MappedStatus(byStatus);

            return from p in policingQueue
                   where byStatus == "all" || mappedStatueses.Contains(p.Status)
                   orderby p.Requested
                   select new PolicingQueueItem
                          {
                              Requested = p.Requested,
                              RequestId = p.RequestId,
                              Status = p.Status,
                              User = p.User,
                              UserKey = p.UserKey,
                              CaseId = p.CaseId,
                              CaseReference = p.CaseReference,
                              EventId = p.EventId,
                              SpecificEventDescription = p.EventControlDescription != null ? DbFuncs.GetTranslation(p.EventControlDescription, null, p.EventControlDescriptionTId, culture) : null,
                              DefaultEventDescription = p.EventDescription != null ? DbFuncs.GetTranslation(p.EventDescription, null, p.EventDescriptionTId, culture) : null,
                              SpecificActionName = p.ValidActionName != null ? DbFuncs.GetTranslation(p.ValidActionName, null, p.ValidActionNameTId, culture) : null,
                              DefaultActionName = p.ActionName != null ? DbFuncs.GetTranslation(p.ActionName, null, p.ActionNameTId, culture) : null,
                              CriteriaId = p.CriteriaId,
                              CriteriaDescription = p.CriteriaDescription != null ? DbFuncs.GetTranslation(p.CriteriaDescription, null, p.CriteriaDescriptionTId, culture) : null,
                              TypeOfRequest = p.TypeOfRequest,
                              IdleFor = p.IdleFor,
                              PropertyName = p.PropertyName != null ? DbFuncs.GetTranslation(p.PropertyName, null, p.PropertyNameTId, culture) : null,
                              Jurisdiction = p.Jurisdiction != null ? DbFuncs.GetTranslation(p.Jurisdiction, null, p.JurisdictionTId, culture) : null,
                              NextScheduled = p.ScheduledDateTime,
                              PolicingName = p.PolicingName,
                              Cycle = p.Cycle,
                              HasEventControl = !string.IsNullOrEmpty(p.EventControlDescription)
                          };
        }

        public IQueryable<PolicingItemInQueue> GetPolicingInQueueItemsInfo(int[] caseIds = null)
        {
            var policing = _dbContext.Set<PolicingRequest>().Where(_=> _.CaseId != null);

            if (caseIds!=null && caseIds.Any())
            {
                policing = policing.Where(p => caseIds.Contains(p.CaseId.Value));
            }

            return from p in policing
                    group p by p.CaseId
                    into policingCases
                    select new PolicingItemInQueue
                           {
                               CaseId = policingCases.Key.Value,
                               Earliest = policingCases.Min(_ => _.DateEntered)
                           };
        }
    }
}