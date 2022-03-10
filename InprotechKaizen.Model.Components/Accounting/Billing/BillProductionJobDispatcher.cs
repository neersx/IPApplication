using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;

namespace InprotechKaizen.Model.Components.Accounting.Billing
{
    public interface IBillProductionJobDispatcher
    {
        Task Dispatch(int userIdentityId, string culture, 
                      BillGenerationTracking trackingDetails, 
                      BillProductionType billProductionType, 
                      Dictionary<string, object> options,
                      params BillGenerationRequest[] requests);
    }

    public class BillProductionJobDispatcher : IBillProductionJobDispatcher
    {
        readonly ICapabilitiesResolver _generateCapabilitiesResolver;
        readonly IIntegrationServerClient _jobsServer;
        readonly ILogger<BillProductionJobDispatcher> _logger;

        public BillProductionJobDispatcher(
            ICapabilitiesResolver generateCapabilitiesResolver,
            IIntegrationServerClient jobsServer, 
            ILogger<BillProductionJobDispatcher> logger)
        {
            _generateCapabilitiesResolver = generateCapabilitiesResolver;
            _jobsServer = jobsServer;
            _logger = logger;
        }

        public async Task Dispatch(int userIdentityId, string culture, 
                                   BillGenerationTracking trackingDetails, 
                                   BillProductionType billProductionType,
                                   Dictionary<string, object> options,
                                   params BillGenerationRequest[] requests)
        {
            if (trackingDetails == null) throw new ArgumentNullException(nameof(trackingDetails));
            if (options == null) throw new ArgumentNullException(nameof(options));
            if (requests == null) throw new ArgumentNullException(nameof(requests));

            _logger.SetContext(trackingDetails.RequestContextId);

            var generateCapabilities = await _generateCapabilitiesResolver.Resolve();
            if (!generateCapabilities.CanGenerateBills)
            {
                throw new NotSupportedException("Bill production could not be completed because the system is unable to generate the bills.");
            }
            
            await _jobsServer.Post("api/jobs/BillProduction/start",
                                   new BillProductionJobArgs
                                   {
                                       ProductionType = billProductionType,
                                       TrackingDetails = trackingDetails,
                                       UserIdentityId = userIdentityId,
                                       Culture = culture,
                                       Options = options,
                                       Requests = requests
                                   });

            _logger.Trace($"Dispatched bill production job [ContentId={trackingDetails.ContentId}]");
        }
    }

    public enum BillProductionType
    {
        ProductionDuringFinalisePhase,
        ProductionDuringPrintPhase
    }

    public class BillProductionJobArgs
    {   
        public int UserIdentityId { get; set; }

        public string Culture { get; set; }

        public BillProductionType ProductionType { get; set; }

        public BillGenerationTracking TrackingDetails { get; set; }

        public Dictionary<string, object> Options { get; set; }

        public IEnumerable<BillGenerationRequest> Requests { get; set; }

        public bool HasError { get; set; }
    }
}
