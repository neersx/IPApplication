using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Policing
{
    public interface IBatchPolicingRequest
    {
        int? Enqueue(IEnumerable<IQueuedPolicingRequest> requests);

        bool ShouldPoliceImmediately(bool? otherPoliceImmediateConsiderations = null);
    }

    /// <summary>
    /// For contexts where policing requests are always going to the background and never popping up the policing in progress (Police Immediate) window.
    /// </summary>
    public class BatchPolicingRequest : IBatchPolicingRequest
    {
        readonly IDbContext _dbContext;
        readonly IPolicingUtility _policingUtility;
        readonly IPolicingEngine _policingEngine;

        public BatchPolicingRequest(IDbContext dbContext, IPolicingUtility policingUtility,
            IPolicingEngine policingEngine)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (policingUtility == null) throw new ArgumentNullException("policingUtility");
            if (policingEngine == null) throw new ArgumentNullException("policingEngine");
            _dbContext = dbContext;
            _policingUtility = policingUtility;
            _policingEngine = policingEngine;
        }

        public bool ShouldPoliceImmediately(bool? otherPoliceImmediateConsiderations = null)
        {
            /*
            DR-16481 - 
            Only Police Immediately requests if policing server is not running continuously to avoid deadlocks.
            */
            
            var policingIsRunningContinuously = _dbContext.Set<SiteControl>()
                .Any(sc => sc.ControlId == SiteControls.PoliceContinuously && sc.BooleanValue == true);

            if (policingIsRunningContinuously)
                return false;

            return _policingUtility.IsPoliceImmediately() || 
                otherPoliceImmediateConsiderations.GetValueOrDefault();
        }

        public int? Enqueue(IEnumerable<IQueuedPolicingRequest> requests)
        {
            var queuedPolicingRequests = requests as IQueuedPolicingRequest[] ?? requests.ToArray();
            if (!queuedPolicingRequests.Any())
                return null;

            int? policingBatchNo = null;

            if (ShouldPoliceImmediately())
                policingBatchNo = _policingEngine.CreateBatch();

            foreach (var pr in queuedPolicingRequests.Where(pr => pr != null))
            {
                pr.Enqueue(policingBatchNo, _policingEngine);
            }

            return policingBatchNo;
        }
    }
}