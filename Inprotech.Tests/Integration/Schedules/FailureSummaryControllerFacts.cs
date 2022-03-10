using System.Collections.Generic;
using Inprotech.Integration;
using Inprotech.Integration.DataSources;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Schedules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules
{
    public class FailureSummaryControllerFacts
    {
        public class GetMethod
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ReturnDiagnosticLogsAvailability(bool existingScheduleDataAvailable)
            {
                var f = new FailureSummaryControllerFixture();

                f.DiagnosticLogsProvider.DataAvailable.Returns(existingScheduleDataAvailable);

                Assert.Equal(existingScheduleDataAvailable, f.Subject.Get().AllowDiagnostics);
            }

            [Fact]
            public void ReturnsFailureSummaryOfAvailableDataSourceForTheUser()
            {
                var f = new FailureSummaryControllerFixture();

                var dataSources = new[] {DataSourceType.Epo, DataSourceType.UsptoPrivatePair};
                var failureSummary = new FailedItemsSummary[0];

                f.AvailableDataSources.List().Returns(dataSources);
                f.FailureSummaryProvider
                 .RecoverableItemsByDataSource(dataSources, ArtifactInclusion.Exclude)
                 .Returns(failureSummary);

                Assert.Equal(failureSummary, f.Subject.Get().FailureSummary);

                f.AvailableDataSources.Received(1).List();
            }
        }

        public class RetryAllMethod
        {
            [Fact]
            public void GivesCallToRecoverableScheduleReader()
            {
                var f = new FailureSummaryControllerFixture()
                        .WithDataSourceAccess()
                        .WithScheduleRecoverableData(new[] {new FailedItem {ScheduleId = 1}});

                f.Subject.RetryAll(DataSourceType.Epo.ToString());

                f.FailureSummaryProvider.Received(1).AllFailedItems(Arg.Any<DataSourceType[]>(), Arg.Any<ArtifactInclusion>());
            }

            [Fact]
            public void GivesCallToRecoverSchedule()
            {
                var f = new FailureSummaryControllerFixture()
                        .WithDataSourceAccess()
                        .WithScheduleRecoverableData(new[] {new FailedItem {ScheduleId = 1}, new FailedItem {ScheduleId = 2}});

                f.Subject.RetryAll(DataSourceType.Epo.ToString());
                f.FailureSummaryProvider.Received(1).AllFailedItems(Arg.Any<DataSourceType[]>(), Arg.Any<ArtifactInclusion>());

                f.RecoverableSchedule.Received(1).Recover(1);
                f.RecoverableSchedule.Received(1).Recover(2);
            }
        }
    }

    public class FailureSummaryControllerFixture : IFixture<FailureSummaryController>
    {
        public FailureSummaryControllerFixture()
        {
            FailureSummaryProvider = Substitute.For<IFailureSummaryProvider>();
            AvailableDataSources = Substitute.For<IAvailableDataSources>();
            RecoverableSchedule = Substitute.For<IRecoverableSchedule>();
            DiagnosticLogsProvider = Substitute.For<IDiagnosticLogsProvider>();

            Subject = new FailureSummaryController(
                                                   DiagnosticLogsProvider, FailureSummaryProvider,
                                                   AvailableDataSources, RecoverableSchedule);
        }

        public IFailureSummaryProvider FailureSummaryProvider { get; }

        public IAvailableDataSources AvailableDataSources { get; }

        public IRecoverableSchedule RecoverableSchedule { get; }

        public IDiagnosticLogsProvider DiagnosticLogsProvider { get; set; }

        public FailureSummaryController Subject { get; }

        public FailureSummaryControllerFixture WithDataSourceAccess(IEnumerable<DataSourceType> dataSource = null)
        {
            if (dataSource == null)
            {
                dataSource = new[] {DataSourceType.Epo, DataSourceType.UsptoPrivatePair};
            }

            AvailableDataSources.List().Returns(dataSource);
            return this;
        }

        public FailureSummaryControllerFixture WithScheduleRecoverableData(IEnumerable<FailedItem> failedItems)
        {
            FailureSummaryProvider.AllFailedItems(Arg.Any<DataSourceType[]>(), Arg.Any<ArtifactInclusion>()).Returns(failedItems);
            return this;
        }
    }
}