using System;
using System.Linq;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Contracts;
using InprotechKaizen.Model.Components.Accounting.Billing.Delivery.Type;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Delivery
{
    public interface IBillDelivery
    {
        Task OnFinalise(int userIdentityId, string culture, BillGenerationTracking trackingDetails, BillingSiteSettings siteSettings, params BillGenerationRequest[] requests);
        Task OnPrint(int userIdentityId, string culture, BillGenerationTracking trackingDetails, BillingSiteSettings siteSettings, params BillGenerationRequest[] requests);
    }

    public class BillDelivery : IBillDelivery
    {
        readonly ILogger<BillDelivery> _logger;
        readonly IIndex<BillGenerationType, IBillDeliveryService> _deliveryFactory;

        public BillDelivery(ILogger<BillDelivery> logger,
                            IIndex<BillGenerationType, IBillDeliveryService> deliveryFactory)
        {
            _logger = logger;
            _deliveryFactory = deliveryFactory;
        }

        public async Task OnFinalise(int userIdentityId, string culture, BillGenerationTracking trackingDetails, BillingSiteSettings siteSettings, params BillGenerationRequest[] requests)
        {
            if (trackingDetails == null) throw new ArgumentNullException(nameof(trackingDetails));
            if (siteSettings == null) throw new ArgumentNullException(nameof(siteSettings));

            _logger.SetContext(trackingDetails.RequestContextId);

            if (!requests.Any())
            {
                _logger.Warning($"{nameof(OnFinalise)} is called with no bill requests.");
                return;
            }
            
            var deliveryService = siteSettings.BillSaveAsPdfSetting 
                switch
                {
                    BillSaveAsPdfSetting.GenerateThenSaveToDms => _deliveryFactory[BillGenerationType.GenerateThenSendToDms],
                    _ => null
                };

            if (deliveryService == null)
            {
                _logger.Trace($"{nameof(OnFinalise)} is 'Bill Save as PDF' value of {siteSettings.BillSaveAsPdfSetting}, skipping delivery on Finalise.");
                return;
            }
            
            await deliveryService.EnsureValidSettings();

            await deliveryService.Deliver(userIdentityId, culture, trackingDetails.RequestContextId, requests);
        }

        public async Task OnPrint(int userIdentityId, string culture, BillGenerationTracking trackingDetails, BillingSiteSettings siteSettings, params BillGenerationRequest[] requests)
        {
            if (trackingDetails == null) throw new ArgumentNullException(nameof(trackingDetails));
            if (siteSettings == null) throw new ArgumentNullException(nameof(siteSettings));

            _logger.SetContext(trackingDetails.RequestContextId);

            if (!requests.Any())
            {
                _logger.Warning($"{nameof(OnPrint)} is called with no bill requests.");
                return;
            }
            
            var deliveryService = siteSettings.BillSaveAsPdfSetting 
                    switch
                    {
                        BillSaveAsPdfSetting.GenerateOnFinaliseThenAttachToCase => _deliveryFactory[BillGenerationType.GenerateThenAttachToCase],
                        BillSaveAsPdfSetting.GenerateOnPrintThenAttachToCase => _deliveryFactory[BillGenerationType.GenerateThenAttachToCase],
                        _ => null
                    };

            if (deliveryService == null)
                return;

            await deliveryService.EnsureValidSettings();

            await deliveryService.Deliver(userIdentityId, culture, trackingDetails.RequestContextId, requests);
        }
    }
}
