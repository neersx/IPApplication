using System;
using System.Threading.Tasks;
using Dependable;
using Dependable.Dispatcher;
using InprotechKaizen.Model.Components.Integration.Jobs;
using InprotechKaizen.Model.Components.Reporting;

namespace Inprotech.Integration.Reports.Engine
{

    public class ReportEngine
    {
        readonly IJobArgsStorage _jobArgsStorage;
        readonly IReportContentManager _reportContentManager;
        readonly IReportService _reportService;

        public ReportEngine(IReportService reportService, IJobArgsStorage jobArgsStorage, IReportContentManager reportContentManager)
        {
            _reportService = reportService;
            _jobArgsStorage = jobArgsStorage;
            _reportContentManager = reportContentManager;
        }

        public Task<Activity> Execute(long storageId)
        {
            var args = _jobArgsStorage.Get<ReportGenerationRequiredMessage>(storageId);
            
            return Task.FromResult((Activity)Activity.Run<ReportEngine>(_ => _.Render(args)));
        }
        
        public async Task Render(ReportGenerationRequiredMessage args)
        {
            if (args == null) throw new ArgumentNullException(nameof(args));

            await _reportService.Render(args.ReportRequestModel);
        }

        public void HandleException(ExceptionContext context, long storageId)
        {
            var args = _jobArgsStorage.Get<ReportGenerationRequiredMessage>(storageId);

            _reportContentManager.LogException(context.Exception, args.ReportRequestModel.ContentId);
        }
    }
}