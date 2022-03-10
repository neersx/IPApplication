using System;
using System.Threading.Tasks;
using Dependable.Dispatcher;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Notifications;
using InprotechKaizen.Model.BackgroundProcess;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.ApplyRecordal
{
    public class ApplyRecordal
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;
        readonly ISiteControlReader _siteControlReader;
        readonly IBackgroundProcessLogger<ApplyRecordal> _logger;

        public ApplyRecordal(IDbContext dbContext, Func<DateTime> now, ISiteControlReader siteControlReader, IBackgroundProcessLogger<ApplyRecordal> logger)
        {
            _dbContext = dbContext;
            _now = now;
            _siteControlReader = siteControlReader;
            _logger = logger;
        }

        public async Task Run(ApplyRecordalArgs args)
        {
            var isPoliceImmediately = _siteControlReader.Read<bool>(SiteControls.PoliceImmediately) || _siteControlReader.Read<bool>(SiteControls.PoliceImmediateInBackground);

            var inputParameters = new Parameters
            {
                {"@pnUserIdentityId", args.RunBy},
                {"@psCulture", args.Culture},
                {"@pnRecordalCaseId", args.RecordalCase},
                {"@pdtRecordalDate", args.RecordalDate},
                {"@psRecordalStatus", args.RecordalStatus},
                {"@pbPolicingImmediate", isPoliceImmediately},
                {"@psRecordalSeqIds", args.RecordalSeqIds}
            };

            using (var command = _dbContext.CreateStoredProcedureCommand("apps_ApplyRecordals", inputParameters))
            {
                await command.ExecuteNonQueryAsync();
            }
        }

        public async Task AddBackgroundProcess(ApplyRecordalArgs args)
        {
            UpdateBackgroundStatus(args, StatusType.Completed, args.SuccessMessage);
            await _dbContext.SaveChangesAsync();
        }

        public void HandleException(ExceptionContext exception, ApplyRecordalArgs args)
        {
            _logger.Exception(exception.Exception, exception.Exception.Message);
            UpdateBackgroundStatus(args, StatusType.Error, args.ErrorMessage);
            _dbContext.SaveChanges();
        }

        void UpdateBackgroundStatus(ApplyRecordalArgs args, StatusType statusType, string info)
        {
            var bgProcess = new BackgroundProcess
            {
                IdentityId = args.RunBy,
                ProcessType = BackgroundProcessType.General.ToString(),
                ProcessSubType = BackgroundProcessSubType.ApplyRecordals.ToString(),
                Status = (int) statusType,
                StatusDate = _now(),
                StatusInfo = info
            };
            _dbContext.Set<BackgroundProcess>().Add(bgProcess);
        }
    }
}
