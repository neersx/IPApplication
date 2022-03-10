using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Components.Cases.Comparison.Updaters;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.AutomaticDocketing
{
    public interface IApplyUpdates
    {
        IEnumerable<Event> From(Event[] events, int caseId);
    }

    public class ApplyUpdates : IApplyUpdates
    {
        readonly IDbContext _dbContext;
        readonly ISiteConfiguration _siteConfiguration;
        readonly ITransactionRecordal _transactionRecordal;
        readonly IPolicingEngine _policingEngine;
        readonly IEventUpdater _eventUpdater;
        readonly ICaseComparisonEvent _comparisonEvent;
        readonly IBatchPolicingRequest _batchPolicingRequest;
        readonly IComponentResolver _componentResolver;

        public ApplyUpdates(IDbContext dbContext, ISiteConfiguration siteConfiguration, ITransactionRecordal transactionRecordal, IPolicingEngine policingEngine, IEventUpdater eventUpdater, ICaseComparisonEvent comparisonEvent, IBatchPolicingRequest batchPolicingRequest, IComponentResolver componentResolver)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (siteConfiguration == null) throw new ArgumentNullException("siteConfiguration");
            if (transactionRecordal == null) throw new ArgumentNullException("transactionRecordal");
            if (policingEngine == null) throw new ArgumentNullException("policingEngine");
            if (eventUpdater == null) throw new ArgumentNullException("eventUpdater");
            if (comparisonEvent == null) throw new ArgumentNullException("comparisonEvent");
            if (batchPolicingRequest == null) throw new ArgumentNullException("batchPolicingRequest");
            if (componentResolver == null) throw new ArgumentNullException("componentResolver");

            _dbContext = dbContext;
            _siteConfiguration = siteConfiguration;
            _transactionRecordal = transactionRecordal;
            _policingEngine = policingEngine;
            _eventUpdater = eventUpdater;
            _comparisonEvent = comparisonEvent;
            _batchPolicingRequest = batchPolicingRequest;
            _componentResolver = componentResolver;
        }

        public IEnumerable<Event> From(Event[] events, int caseId)
        {
            if (events == null) throw new ArgumentNullException("events");
            if (!events.Any()) return events;

            var @case = _dbContext.Set<InprotechKaizen.Model.Cases.Case>()
                .Include(c => c.OpenActions)
                .Include(c => c.OpenActions.Select(_ => _.Criteria))
                .Include(c => c.CaseEvents)
                .Single(c => c.Id == caseId);

            var eventUpdateOrder = events.OrderBy(_ => _.Sequence);
            var updated = new List<Event>();

            using (var tcs = _dbContext.BeginTransaction())
            {
                var reasonNo = _siteConfiguration.TransactionReason
                    ? _siteConfiguration.ReasonIpOfficeVerification
                    : (int?)null;
                
                _transactionRecordal.RecordTransactionFor(@case, CaseTransactionMessageIdentifier.AmendedCase, reasonNo, _componentResolver.Resolve(KnownComponents.CaseComparison));

                var policingRequests = new List<PoliceCaseEvent>();

                foreach (var req in _eventUpdater.AddOrUpdateEvents(@case, eventUpdateOrder))
                {
                    var ce = req.CaseEvent;

                    var e = eventUpdateOrder.Except(updated).First(_ => _.EventNo == ce.EventId);
                    e.Cycle = ce.Cycle;
                    updated.Add(e);

                    policingRequests.Add(req);
                }
                    
                policingRequests.Add(_comparisonEvent.Apply(@case));

                var policingBatchNo = _batchPolicingRequest.Enqueue(policingRequests);

                _dbContext.SaveChanges();

                if (policingBatchNo.HasValue)
                    _policingEngine.PoliceAsync(policingBatchNo.Value);

                tcs.Complete();
            }

            return updated;
        }
    }
}