using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Notifications;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation.Builders;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Reporting;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Generation
{
    public interface IBillGeneration
    {
        Task<bool> OnFinalise(int userIdentityId, string culture, 
                        BillGenerationTracking trackingDetails, BillingSiteSettings siteSettings, params BillGenerationRequest[] requests);

        Task<bool> OnPrint(int userIdentityId, string culture, 
                     BillGenerationTracking trackingDetails, BillingSiteSettings siteSettings, params BillGenerationRequest[] requests);
    }

    public class BillGeneration : IBillGeneration
    {
        readonly ILogger<BillGeneration> _logger;
        readonly IIndex<BillGenerationType, IBillDefinitionBuilder> _builderFactory;
        readonly IBillPrintDetails _billPrintDetails;
        readonly IReportService _reportService;

        public BillGeneration(
            ILogger<BillGeneration> logger,
            IIndex<BillGenerationType, IBillDefinitionBuilder> builderFactory,
            IBillPrintDetails billPrintDetails,
            IReportService reportService)
        {
            _logger = logger;
            _builderFactory = builderFactory;
            _billPrintDetails = billPrintDetails;
            _reportService = reportService;
        }
        
        public async Task<bool> OnFinalise(int userIdentityId, string culture, BillGenerationTracking trackingDetails, BillingSiteSettings siteSettings, params BillGenerationRequest[] requests)
        {
            if (trackingDetails == null) throw new ArgumentNullException(nameof(trackingDetails));
            if (siteSettings == null) throw new ArgumentNullException(nameof(siteSettings));

            _logger.SetContext(trackingDetails.RequestContextId);

            if (!requests.Any())
            {
                _logger.Warning($"{nameof(OnFinalise)} is called with no bill requests.");
                return true;
            }
            
            var builder = siteSettings.BillSaveAsPdfSetting 
                switch
                {
                    BillSaveAsPdfSetting.GenerateThenSaveToDms => _builderFactory[BillGenerationType.GenerateThenSendToDms],
                    _ => null
                };

            if (builder == null)
            {
                _logger.Trace($"{nameof(OnFinalise)} is 'Bill Save as PDF' value of {siteSettings.BillSaveAsPdfSetting}, skipping generation on Finalise.");
                return true;
            }

            await builder.EnsureValidSettings();

            var definitions = (await GetBillDefinitions(userIdentityId, culture, builder, requests)).ToArray();
            
            if (await RenderBill(userIdentityId, culture, builder.GetType().Name, trackingDetails, definitions))
            {
                return true;
            }
            
            return false;
        }

        public async Task<bool> OnPrint(int userIdentityId, string culture, BillGenerationTracking trackingDetails, BillingSiteSettings siteSettings, params BillGenerationRequest[] requests)
        {
            if (trackingDetails == null) throw new ArgumentNullException(nameof(trackingDetails));
            if (siteSettings == null) throw new ArgumentNullException(nameof(siteSettings));
            
            _logger.SetContext(trackingDetails.RequestContextId);
            
            if (!requests.Any())
            {
                _logger.Warning($"{nameof(OnPrint)} is called with no bill requests.");
                return true;
            }
            
            var builder = siteSettings.BillSaveAsPdfSetting 
                    switch
                    {
                        /*
                         * Generation of the bill on finalise need confirmation from the user
                         * The front end manages the generation only after the finalisation is complete.
                         */
                        BillSaveAsPdfSetting.GenerateOnFinaliseThenAttachToCase => _builderFactory[BillGenerationType.GenerateThenAttachToCase],
                        BillSaveAsPdfSetting.GenerateOnPrintThenAttachToCase => _builderFactory[BillGenerationType.GenerateThenAttachToCase],
                        _ => _builderFactory[BillGenerationType.GenerateOnly]
                    };

            await builder.EnsureValidSettings();

            var definitions = (await GetBillDefinitions(userIdentityId, culture, builder, requests)).ToArray();
            
            if (await RenderBill(userIdentityId, culture, builder.GetType().Name, trackingDetails, definitions))
            {
                return true;
            }
            
            return false;
        }

        async Task<IEnumerable<ReportDefinition>> GetBillDefinitions(int userIdentityId, string culture, IBillDefinitionBuilder builder, params BillGenerationRequest[] requests)
        {
            var definitions = new List<ReportDefinition>();
            
            foreach (var request in requests)
            {
                var billPrintDetails = await _billPrintDetails.For(
                                                                   userIdentityId, culture, 
                                                                   request.ItemEntityId, 
                                                                   request.OpenItemNo,
                                                                   request.ShouldPrintAsOriginal);

                var details = request.ShouldNotPrintCopyTo
                    ? billPrintDetails.Where(_ => _.BillPrintType != BillPrintType.CopyToInvoice)
                    : billPrintDetails;

                var interim = (await builder.Build(request, details.ToArray())).ToArray();

                request.ResultFilePath = interim.FirstOrDefault(_ => !string.IsNullOrWhiteSpace(_.FileName))?.FileName;

                definitions.AddRange(interim);
            }

            var printTypeCount = (from d in definitions
                      let b = (BillPrintType) int.Parse(d.Parameters[KnownParameters.BillPrintType])
                      group d by b into d1
                      select new
                      {
                          d1.Key,
                          Count = d1.Count()
                      }).ToArray()
                        .Select(_ => $"#{_.Key}={_.Count}")
                        .ToArray();
            
            _logger.Trace($"{nameof(GetBillDefinitions)} #requests={requests.Length} {string.Join(", ", printTypeCount)}");
            
            return definitions;
        }
        
        async Task<bool> RenderBill(int userIdentityId, string culture, 
                                             string context, BillGenerationTracking trackingDetails, 
                                             ReportDefinition[] billDefinitions)
        {
            if (!billDefinitions.Any())
            {
                _logger.Trace($"No bill definition created. builder settings={context}, [ContentID={trackingDetails.ContentId}]");
                return true;
            }
            
            _logger.Trace($"{nameof(RenderBill)} #billdefs={billDefinitions.Length}, settings={context} [ContentID={trackingDetails.ContentId}]");

            if (!await _reportService.Render(new ReportRequest(billDefinitions)
                {
                    UserCulture = culture,
                    UserIdentityKey = userIdentityId,
                    ShouldConcatenate = true,
                    ContentId = trackingDetails.ContentId,
                    RequestContextId = trackingDetails.RequestContextId,
                    NotificationProcessType = BackgroundProcessType.BillPrint
                }))
            {
                return false;
            }
            
            _logger.Trace($"{nameof(RenderBill)} Completed. [ContentID={trackingDetails.ContentId}]");

            return true;
        }
    }
}
