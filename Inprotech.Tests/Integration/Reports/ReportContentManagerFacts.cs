using System;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Integration.Reports;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.BackgroundProcess;
using InprotechKaizen.Model.Components.ContentManagement.Export;
using InprotechKaizen.Model.Search.Export;
using NSubstitute;
using Xunit;
using StatusType = Inprotech.Infrastructure.Notifications.StatusType;

namespace Inprotech.Tests.Integration.Reports
{
    public class ReportContentManagerFacts : FactBase
    {
        readonly IExportExecutionTimeLimit _exportExecutionTimeLimit = Substitute.For<IExportExecutionTimeLimit>();
        readonly IBackgroundProcessLogger<ReportContentManager> _log = Substitute.For<IBackgroundProcessLogger<ReportContentManager>>();
        readonly Func<DateTime> _now = Substitute.For<Func<DateTime>>();
        readonly IFileSystem _fileSystem = Substitute.For<IFileSystem>();
        
        ReportContentManager GetSubject()
        {
            return new ReportContentManager(Db, _now, _log, _exportExecutionTimeLimit, _fileSystem);
        }

        [Fact]
        public void HandleException()
        {
            var content = new ReportContentResult
            {
                Status = (int) StatusType.Started,
                ConnectionId = new Guid().ToString(),
                IdentityId = 45,
                Started = _now().ToUniversalTime(),
                FileName = "billingWorksheet.pdf"
            }.In(Db);

            var subject = GetSubject();

            subject.LogException(new Exception("Some error has occured"), content.Id, 
                                       "bummer", BackgroundProcessType.StandardReportRequest);

            Assert.Equal((int) StatusType.Error, content.Status);

            var backgroundProcess = Db.Set<BackgroundProcess>().Single();

            Assert.Equal(content.BackgroundProcess, backgroundProcess);
            Assert.Equal((int) StatusType.Error,  backgroundProcess.Status);
            Assert.Equal("bummer", backgroundProcess.StatusInfo);
            Assert.Equal(nameof(BackgroundProcessType.StandardReportRequest), backgroundProcess.ProcessType);
        }

        [Fact]
        public async Task SaveReport()
        {
            var content = new ReportContentResult
            {
                Status = (int) StatusType.Started,
                ConnectionId = new Guid().ToString(),
                IdentityId = 45,
                Started = _now().ToUniversalTime(),
                FileName = "billingWorksheet.pdf"
            }.In(Db);

            await GetSubject().Save(content.Id, Encoding.ASCII.GetBytes("billingWorksheet.pdf"), "application/pdf", "billingWorksheet.pdf");

            Assert.NotNull(content.Finished);
            Assert.Equal("billingWorksheet.pdf", content.FileName );
            Assert.Equal("application/pdf", content.ContentType);
            Assert.Equal((int) StatusType.Completed, content.Status);
        }
        
        [Fact]
        public async Task TryAssociatingWithBackgroundProcessWhenTimeHasElapsed()
        {
            var content = new ReportContentResult
            {
                Status = (int) StatusType.Completed,
                ConnectionId = new Guid().ToString(),
                IdentityId = 45,
                Started = _now().ToUniversalTime(),
                FileName = "billingWorksheet.pdf",
                Finished = _now().ToUniversalTime().AddMinutes(15),
                Content = Encoding.ASCII.GetBytes("billingWorksheet.pdf"),
                ContentType = "application/pdf"
            }.In(Db);

            _exportExecutionTimeLimit.IsLapsed(Arg.Any<DateTime?>(), Arg.Any<DateTime>(), Arg.Any<string>(), Arg.Any<int>())
                                     .Returns(true);

            await GetSubject().TryPutInBackground(content.IdentityId, content.Id, BackgroundProcessType.StandardReportRequest);

            Assert.NotNull(content.ProcessId);
            Assert.Null(content.ConnectionId);
            
            var backgroundProcess = Db.Set<BackgroundProcess>().Single(_ => _.Id == content.ProcessId);
            Assert.Equal((int) StatusType.Completed,  backgroundProcess.Status);
            Assert.Equal(nameof(BackgroundProcessType.StandardReportRequest), backgroundProcess.ProcessType);
        }

        [Fact]
        public async Task TryAssociatingWithBackgroundProcessWhenTimeHasNotElapsed()
        {
            var content = new ReportContentResult
            {
                Status = (int) StatusType.Completed,
                ConnectionId = new Guid().ToString(),
                IdentityId = 45,
                Started = _now().ToUniversalTime(),
                FileName = "billingWorksheet.pdf",
                Finished = _now().ToUniversalTime().AddMinutes(15),
                Content = Encoding.ASCII.GetBytes("billingWorksheet.pdf"),
                ContentType = "application/pdf"
            }.In(Db);

            _exportExecutionTimeLimit.IsLapsed(Arg.Any<DateTime?>(), Arg.Any<DateTime>(), Arg.Any<string>(), Arg.Any<int>())
                                     .Returns(false);

            await GetSubject().TryPutInBackground(content.IdentityId, content.Id, BackgroundProcessType.StandardReportRequest);

            Assert.Null(content.ProcessId);
            Assert.NotNull(content.ConnectionId);
        }
    }
}