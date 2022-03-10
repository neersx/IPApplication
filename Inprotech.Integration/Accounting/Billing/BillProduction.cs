using System;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Dependable.Dispatcher;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Jobs;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.BackgroundProcess;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.BillReview;
using InprotechKaizen.Model.Components.Accounting.Billing.Delivery;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using InprotechKaizen.Model.Components.Integration.Jobs;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.Accounting.Billing
{
    public class BillProduction : IPerformImmediateBackgroundJob
    {
        readonly IDbContext _dbContext;
        readonly ILogger<BillProduction> _logger;
        readonly IJobArgsStorage _jobArgsStorage;
        readonly IBillingSiteSettingsResolver _siteSettingsResolver;
        readonly IBillGeneration _billGeneration;
        readonly IBillDelivery _billDelivery;
        readonly IBillReview _billReview;
        readonly Func<DateTime> _clock;

        public string Type => nameof(BillProduction);

        public BillProduction(IDbContext dbContext,
                              ILogger<BillProduction> logger,
                              IJobArgsStorage jobArgsStorage,
                              IBillingSiteSettingsResolver siteSettingsResolver,
                              IBillGeneration billGeneration,
                              IBillDelivery billDelivery,
                              IBillReview billReview,
                              Func<DateTime> clock)
        {
            _dbContext = dbContext;
            _logger = logger;
            _jobArgsStorage = jobArgsStorage;
            _siteSettingsResolver = siteSettingsResolver;
            _billGeneration = billGeneration;
            _billDelivery = billDelivery;
            _billReview = billReview;
            _clock = clock;
        }

        public SingleActivity GetJob(JObject jobArguments)
        {
            var args = jobArguments.ToObject<BillProductionJobArgs>();

            var shouldSendBillForReview = args.Options.Get(AdditionalBillingOptions.SendFinalisedBillToReviewer) is true;

            var id = _jobArgsStorage.Create(args);

            return Activity.Run<BillProduction>(_ => _.Run(id, shouldSendBillForReview))
                           .ExceptionFilter<BillProduction>((exception, c) => c.LogException(exception, args));
        }

        public Task<Activity> Run(long jobArgStorageId, bool shouldSendBillForReview)
        {
            var generate = Activity.Run<BillProduction>(_ => _.Generate(jobArgStorageId));

            var deliver = Activity.Run<BillProduction>(_ => _.Deliver(jobArgStorageId));

            var sendForReview = shouldSendBillForReview
                ? Activity.Run<BillProduction>(_ => _.SendForReview(jobArgStorageId))
                : DefaultActivity.NoOperation();

            return Task.FromResult((Activity) Activity.Sequence(generate, deliver, sendForReview));
        }

        public async Task Generate(long jobArgStorageId)
        {
            var jobArgs = await _jobArgsStorage.GetAsync<BillProductionJobArgs>(jobArgStorageId);

            var siteSettings = await _siteSettingsResolver.Resolve(new BillingSiteSettingsScope { UserIdentityId = jobArgs.UserIdentityId });

            _logger.SetContext(jobArgs.TrackingDetails.RequestContextId);
            _logger.Trace($"{nameof(Generate)}:Started");

            var result = jobArgs.ProductionType switch
            {
                BillProductionType.ProductionDuringFinalisePhase =>
                    await _billGeneration.OnFinalise(jobArgs.UserIdentityId, jobArgs.Culture, jobArgs.TrackingDetails, siteSettings, jobArgs.Requests.ToArray()),

                BillProductionType.ProductionDuringPrintPhase =>
                    await _billGeneration.OnPrint(jobArgs.UserIdentityId, jobArgs.Culture, jobArgs.TrackingDetails, siteSettings, jobArgs.Requests.ToArray()),

                _ => throw new InvalidOperationException("unknown bill production type")
            };

            await _jobArgsStorage.UpdateAsync(jobArgStorageId, jobArgs);

            if (!result)
            {
                jobArgs.HasError = true;
                _logger.Trace($"{nameof(Generate)}:Failed");
                return;
            }

            _logger.Trace($"{nameof(Generate)}:Completed");
        }

        public async Task Deliver(long jobArgStorageId)
        {
            var jobArgs = await _jobArgsStorage.GetAsync<BillProductionJobArgs>(jobArgStorageId);
            if (jobArgs.HasError) return;

            var siteSettings = await _siteSettingsResolver.Resolve(new BillingSiteSettingsScope { UserIdentityId = jobArgs.UserIdentityId });

            _logger.SetContext(jobArgs.TrackingDetails.RequestContextId);
            _logger.Trace($"{nameof(Deliver)}:Started");

            switch (jobArgs.ProductionType)
            {
                case BillProductionType.ProductionDuringFinalisePhase:
                    await _billDelivery.OnFinalise(jobArgs.UserIdentityId, jobArgs.Culture, jobArgs.TrackingDetails, siteSettings, jobArgs.Requests.ToArray());
                    break;

                case BillProductionType.ProductionDuringPrintPhase:
                    await _billDelivery.OnPrint(jobArgs.UserIdentityId, jobArgs.Culture, jobArgs.TrackingDetails, siteSettings, jobArgs.Requests.ToArray());
                    break;

                default:
                    throw new InvalidOperationException("unknown bill production type");
            }
            
            var billsPrinted = 0;

            foreach (var req in jobArgs.Requests)
            {
                if (!req.ShouldMarkBillAsPrinted) continue;

                if (req.ItemTransactionId == null) continue;
                
                billsPrinted += await _dbContext.UpdateAsync(_dbContext.Set<OpenItem>()
                                                                       .Where(_ => _.ItemEntityId == req.ItemEntityId &&
                                                                                   _.ItemTransactionId == req.ItemTransactionId),
                                                             x => new OpenItem
                                                             {
                                                                 IsBillPrinted = 1
                                                             });
            }

            if (billsPrinted > 0)
            {
                _logger.Trace($"{nameof(Deliver)}Number of bills marked as printed={billsPrinted}");
            }

            _logger.Trace($"{nameof(Deliver)}:Completed");
        }

        public async Task SendForReview(long jobArgStorageId)
        {
            var jobArgs = await _jobArgsStorage.GetAsync<BillProductionJobArgs>(jobArgStorageId);
            if (jobArgs.HasError) return;

            var reviewableBills = jobArgs.Requests
                                              .Where(_ => !string.IsNullOrWhiteSpace(_.ResultFilePath))
                                              .ToArray();

            await _billReview.SendBillsForReview(jobArgs.UserIdentityId, jobArgs.Culture, reviewableBills);
        }

        public void LogException(ExceptionContext context, BillProductionJobArgs args)
        {
            var type = args.ProductionType switch
            {
                BillProductionType.ProductionDuringFinalisePhase => "generating the bill during finalisation.",
                BillProductionType.ProductionDuringPrintPhase => "printing the bill",
                _ => null
            };

            _logger.SetContext(args.TrackingDetails.RequestContextId);
            var message = $"There was an error {type}{Environment.NewLine}";

            _logger.Exception(context.Exception, message + context.Exception.Message);
            
            var bgProcess = new BackgroundProcess
            {
                IdentityId = args.UserIdentityId,
                ProcessType = BackgroundProcessType.BillPrint.ToString(),
                Status = (int)StatusType.Error,
                StatusDate = _clock(),
                StatusInfo = message + $"ref: {args.TrackingDetails.RequestContextId}"
            };

            _dbContext.Set<BackgroundProcess>().Add(bgProcess);
            _dbContext.SaveChanges();
        }
    }
}
