using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web;
using InprotechKaizen.Model.Components.ContentManagement.Export;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Search.Export;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.ContentManagement.Export
{
    public class ExportContentStatusReaderFacts : FactBase
    {
        readonly IExportExecutionTimeLimit _exportExecutionTimeLimit = Substitute.For<IExportExecutionTimeLimit>();

        ExportContentStatusReader SearchExportContentStatusReaderFixture()
        {
            SetupData();
            return new ExportContentStatusReader(Db, Fixture.Today, _exportExecutionTimeLimit);
        }
        
        void SetupData()
        {
            new SettingDefinition
            {
                SettingId = KnownSettingIds.SearchReportGenerationTimeout,
                Name = "Search Reports generation timeout",
                Description = "Specify the time duration (in seconds) from initial request, for which to push the generation of exported Search Report to the background. Default value is 15. Maximum valid value is 90."
            }.In(Db);
            new SettingValues
            {
                SettingId = 34,
                IntegerValue = 15
            }.In(Db);
        }

        [Fact]
        public void ReadManyContentWithErrorStatus()
        {
            var connectionId = Fixture.String();
            new ReportContentResult {Content = new byte[2], FileName = Fixture.String(), ConnectionId = connectionId, Status = (int) StatusType.Error}.In(Db).WithKnownId(Fixture.Integer());

            var connectionIds = Db.Set<ReportContentResult>().Select(_ => _.ConnectionId);
            var content = SearchExportContentStatusReaderFixture().ReadMany(connectionIds).ToList();

            Assert.Equal(1, content[0].ContentList.Count);
            Assert.Equal(ContentStatus.ExecutionFailed, content[0].ContentList[0].Status);
        }

        [Fact]
        public void ReadManyContentWithCompletedStatus()
        {
            var connectionId = Fixture.String();
            new ReportContentResult {Content = new byte[2], FileName = Fixture.String(), ConnectionId = connectionId, Finished = DateTime.Today.AddSeconds(5).ToUniversalTime(), Status = (int) StatusType.Completed }.In(Db).WithKnownId(Fixture.Integer());
            _exportExecutionTimeLimit.IsLapsed(Arg.Any<DateTime?>(), Arg.Any<DateTime?>(),Arg.Any<string>(), Arg.Any<int>()).Returns(false);
            var connectionIds = Db.Set<ReportContentResult>().Select(_ => _.ConnectionId);
            var content = SearchExportContentStatusReaderFixture().ReadMany(connectionIds).ToList();

            Assert.Equal(1, content[0].ContentList.Count);
            Assert.Equal(ContentStatus.ReadyToDownload, content[0].ContentList[0].Status);
        }

        [Fact]
        public void ReadManyContentWithStartedStatus()
        {
            var connectionId = Fixture.String();
            new ReportContentResult {Content = new byte[2], FileName = Fixture.String(), ConnectionId = connectionId, Status = (int) StatusType.Started}.In(Db).WithKnownId(Fixture.Integer());
            _exportExecutionTimeLimit.IsLapsed(Arg.Any<DateTime?>(), Arg.Any<DateTime?>(),Arg.Any<string>(), Arg.Any<int>()).Returns(true);
            var connectionIds = Db.Set<ReportContentResult>().Select(_ => _.ConnectionId);
            var content = SearchExportContentStatusReaderFixture().ReadMany(connectionIds).ToList();

            Assert.Equal(1, content[0].ContentList.Count);
            Assert.Equal(ContentStatus.ProcessedInBackground, content[0].ContentList[0].Status);
        }

        [Fact]
        public void ReadManyContents()
        {
            new ReportContentResult {Content = new byte[2], FileName = Fixture.String(), ConnectionId = Fixture.String(), Status = (int) StatusType.Error}.In(Db).WithKnownId(Fixture.Integer());
            new ReportContentResult {Content = new byte[2], FileName = Fixture.String(), ConnectionId = Fixture.String(), Status = (int) StatusType.Started}.In(Db).WithKnownId(Fixture.Integer());
            _exportExecutionTimeLimit.IsLapsed(Arg.Any<DateTime?>(), Arg.Any<DateTime?>(), Arg.Any<string>(), Arg.Any<int>()).Returns(true);
            var connectionIds = Db.Set<ReportContentResult>().Select(_ => _.ConnectionId);
            var content = SearchExportContentStatusReaderFixture().ReadMany(connectionIds).ToList();

            Assert.Equal(2, content.Count);
        }
    }
}
