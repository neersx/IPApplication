using System.IO;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Integration;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Schedules;
using Inprotech.Tests.Extensions;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.PtoAccess
{
    public class CurrentFailureSnapshotFacts
    {
        readonly ICompressionHelper _compressionHelper = Substitute.For<ICompressionHelper>();
        readonly IFailureSummaryProvider _failureSummaryProvider = Substitute.For<IFailureSummaryProvider>();
        readonly IFileSystem _fileSystem = Substitute.For<IFileSystem>();

        IDiagnosticsArtefacts CreateSubject(params FailedItemsSummary[] summaries)
        {
            _failureSummaryProvider.RecoverableItemsByDataSource(Arg.Any<DataSourceType[]>(), Arg.Any<ArtifactInclusion>())
                                   .Returns(summaries);

            return new CurrentFailureSnapshot(_failureSummaryProvider, _fileSystem, _compressionHelper);
        }

        [Fact]
        public async Task AssociatedFailedArtefactsArePulledIntoArchive()
        {
            var failedSummary = new FailedItemsSummary
            {
                Cases = new[]
                {
                    new FailedItem
                    {
                        ApplicationNumber = Fixture.String(),
                        ArtifactId = Fixture.Integer(),
                        ArtifactType = ArtifactType.Case,
                        CorrelationId = Fixture.String(),
                        CorrelationIds = Fixture.String(),
                        DataSourceType = DataSourceType.Epo,
                        Id = Fixture.Integer(),
                        PublicationNumber = Fixture.String(),
                        RegistrationNumber = Fixture.String(),
                        ScheduleId = Fixture.Integer(),
                        Artifact = new byte[0]
                    },
                    new FailedItem
                    {
                        ApplicationNumber = Fixture.String(),
                        ArtifactId = Fixture.Integer(),
                        ArtifactType = ArtifactType.Case,
                        CorrelationId = Fixture.String(),
                        CorrelationIds = Fixture.String(),
                        DataSourceType = DataSourceType.Epo,
                        Id = Fixture.Integer(),
                        PublicationNumber = Fixture.String(),
                        RegistrationNumber = Fixture.String(),
                        ScheduleId = Fixture.Integer(),
                        Artifact = new byte[0]
                    }
                },
                DataSource = Fixture.String(),
                FailedCount = Fixture.Integer(),
                Schedules = new[]
                {
                    new FailedSchedule
                    {
                        FailedCasesCount = Fixture.Integer(),
                        CorrelationIds = Fixture.String(),
                        DataSource = DataSourceType.Epo,
                        Name = Fixture.String(),
                        RecoveryStatus = RecoveryScheduleStatus.Pending,
                        ScheduleId = Fixture.Integer()
                    }
                }
            };

            var subject = CreateSubject(failedSummary);

            var path = Fixture.String();

            await subject.Prepare(path);

            _fileSystem.WriteAllText(Path.Combine(path, "CurrentFailureSnapshot.json"), JsonConvert.SerializeObject(failedSummary, Formatting.Indented));

            _compressionHelper.Received(2).AddToArchive(Arg.Any<string>(), Arg.Any<MemoryStream>(), Arg.Any<string>())
                              .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public void NamedCorrectly()
        {
            Assert.Equal("CurrentFailureSnapshot.json", CreateSubject().Name);
        }

        [Fact]
        public async Task SavesToRightLocation()
        {
            var failedSummary = new FailedItemsSummary
            {
                Cases = new[]
                {
                    new FailedItem
                    {
                        ApplicationNumber = Fixture.String(),
                        ArtifactId = Fixture.Integer(),
                        ArtifactType = ArtifactType.Case,
                        CorrelationId = Fixture.String(),
                        CorrelationIds = Fixture.String(),
                        DataSourceType = DataSourceType.Epo,
                        Id = Fixture.Integer(),
                        PublicationNumber = Fixture.String(),
                        RegistrationNumber = Fixture.String(),
                        ScheduleId = Fixture.Integer()
                    }
                },
                DataSource = Fixture.String(),
                FailedCount = Fixture.Integer(),
                Schedules = new[]
                {
                    new FailedSchedule
                    {
                        FailedCasesCount = Fixture.Integer(),
                        CorrelationIds = Fixture.String(),
                        DataSource = DataSourceType.Epo,
                        Name = Fixture.String(),
                        RecoveryStatus = RecoveryScheduleStatus.Pending,
                        ScheduleId = Fixture.Integer()
                    }
                }
            };

            var subject = CreateSubject(failedSummary);

            var path = Fixture.String();

            await subject.Prepare(path);

            _fileSystem.WriteAllText(Path.Combine(path, "CurrentFailureSnapshot.json"), JsonConvert.SerializeObject(failedSummary, Formatting.Indented));
        }
    }
}