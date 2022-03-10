using System;
using System.Threading.Tasks;
using Dependable;
using Dependable.Dispatcher;
using Inprotech.Integration.Reports.Engine;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Components.Integration.Jobs;
using InprotechKaizen.Model.Components.Reporting;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Reports.Engine
{
    public class ReportEngineFacts
    {
        public class ExecuteMethod
        {
            [Fact]
            public async Task ShouldReturnArgsFromStorageThenReturnActivityToRenderReport()
            {
                var storageId = Fixture.Long();

                var jobArgs = new ReportGenerationRequiredMessage(new ReportRequest());

                var f = new ReportEngineFixture();

                f.JobArgsStorage.Get<ReportGenerationRequiredMessage>(storageId)
                 .Returns(jobArgs);

                var r = (SingleActivity) await f.Subject.Execute(storageId);

                Assert.Equal("ReportEngine.Render",  r.TypeAndMethod());
                Assert.Equal(jobArgs, r.Arguments[0]);
            }
        }
        
        public class RenderMethod
        {
            [Fact]
            public async Task ShouldRenderReportUsingReportService()
            {
                var args = new ReportGenerationRequiredMessage(new ReportRequest());

                var f = new ReportEngineFixture();

                await f.Subject.Render(args);

                f.ReportService.Received(1).Render(args.ReportRequestModel)
                 .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class HandleExceptionMethod
        {
            [Fact]
            public void ShouldHandleExceptionUsingReportContentManager()
            {
                var storageId = Fixture.Long();

                var jobArgs = new ReportGenerationRequiredMessage(new ReportRequest { ContentId = Fixture.Integer() });

                var exception = new Exception("bummer");

                var f = new ReportEngineFixture();

                f.JobArgsStorage.Get<ReportGenerationRequiredMessage>(storageId)
                 .Returns(jobArgs);

                f.Subject.HandleException(new ExceptionContext { Exception = exception }, storageId);

                f.ReportContentManager.Received(1).LogException(exception, jobArgs.ReportRequestModel.ContentId);
            }
        }

        public class ReportEngineFixture : IFixture<ReportEngine>
        {
            public IJobArgsStorage JobArgsStorage { get; } = Substitute.For<IJobArgsStorage>();

            public IReportContentManager ReportContentManager { get; } = Substitute.For<IReportContentManager>();

            public IReportService ReportService { get; } = Substitute.For<IReportService>();

            public ReportEngine Subject { get; }

            public ReportEngineFixture()
            {
                Subject = new ReportEngine(ReportService, JobArgsStorage, ReportContentManager);
            }
        }
        
    }
}
