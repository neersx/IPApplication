using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration;
using Inprotech.Integration.CaseFiles;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Storage;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public class BiblioStorageFacts
    {
        public class GetBiblio : FactBase
        {
            [Fact]
            public async Task GetBiblioInfoWithMinDateWhenRecordNotFound()
            {
                var f = new BiblioStorageFixture(Db);
                var r = await f.Subject.GetFileStoreBiblioInfo(Fixture.String());
                Assert.Null(r.fileStore);
                Assert.Equal(DateTime.MinValue, r.date);
            }

            [Fact]
            public async Task GetBiblioInfoOnlyLooksForPrivatePairRecords()
            {
                var applicationId = Fixture.String();
                var f = new BiblioStorageFixture(Db).WitheRecords(applicationId, DataSourceType.UsptoTsdr);
                var r = await f.Subject.GetFileStoreBiblioInfo(applicationId);
                Assert.Null(r.fileStore);
                Assert.Equal(DateTime.MinValue, r.date);
            }

            [Fact]
            public async Task GetBiblioInfo()
            {
                var applicationId = Fixture.String();
                var f = new BiblioStorageFixture(Db).WitheRecords(applicationId);
                var r = await f.Subject.GetFileStoreBiblioInfo(applicationId);
                Assert.NotNull(r.fileStore);
                Assert.Equal(Fixture.Today(), r.date);
            }
        }

        public class ValidateBiblio : FactBase
        {
            readonly Session _session = new Session();
            ApplicationDownload Application(string applicationId) => new ApplicationDownload() { ApplicationId = applicationId, Number = applicationId };

            [Fact]
            public async Task ThrowsIfBiblioRecordNotFoundInDb()
            {
                var applicationId = Fixture.String();
                var f = new BiblioStorageFixture(Db);
                await Assert.ThrowsAsync<Exception>(async () => await f.Subject.ValidateBiblio(_session, Application(applicationId)));
            }

            [Fact]
            public async Task ThrowsIfBiblioFileNotFoundOnPath()
            {
                var applicationId = Fixture.String();
                var f = new BiblioStorageFixture(Db).WitheRecords(applicationId);
                f.FileSystem.Exists(Arg.Any<string>()).Returns(false);
                await Assert.ThrowsAsync<Exception>(async () => await f.Subject.ValidateBiblio(_session, Application(applicationId)));
            }

            [Fact]
            public async Task ValidatesBiblio()
            {
                var applicationId = Fixture.String();
                var f = new BiblioStorageFixture(Db).WitheRecords(applicationId);
                f.FileSystem.Exists(Arg.Any<string>()).Returns(true);

                await f.Subject.ValidateBiblio(_session, Application(applicationId));
                f.FileSystem.Received(1).Exists(Arg.Any<string>());

            }
        }

        public class ReadBiblio : FactBase
        {
            ApplicationDownload Application(string applicationId) => new ApplicationDownload() { ApplicationId = applicationId, Number = applicationId };

            [Fact]
            public async Task ReadsBiblio()
            {
                var applicationId = Fixture.String();
                var f = new BiblioStorageFixture(Db).WitheRecords(applicationId)
                                                    .WithBiblioFile(applicationId);

                await f.Subject.Read(Application(applicationId));
                f.BufferedStringReader.Received(1).Read(Arg.Any<string>()).IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class StoreBiblio : FactBase
        {
            ApplicationDownload Application(string applicationId) => new ApplicationDownload() { ApplicationId = applicationId, Number = applicationId };

            [Fact]
            public async Task AddsCaseIfNotAlreadyAvailable()
            {
                var applicationId = Fixture.String();
                var f = new BiblioStorageFixture(Db);
                await f.Subject.StoreBiblio(Application(applicationId), Fixture.Today());

                f.CorrelationIdUpdator.Received(1).UpdateIfRequired(Arg.Any<Case>());
                var @case = Db.Set<Case>().Single(_ => _.ApplicationNumber == applicationId && _.Source == DataSourceType.UsptoPrivatePair);
                var caseFile = Db.Set<CaseFiles>().Single(_ => _.CaseId == @case.Id && _.Type == (int)CaseFileType.Biblio);
                Assert.NotNull(caseFile.FileStore);
                Assert.Equal(Fixture.Today(), caseFile.UpdatedOn);
                Assert.Equal($"biblio_{applicationId}", caseFile.FileStore.OriginalFileName);
            }

            [Fact]
            public async Task UpdatesCaseWithNewerBiblio()
            {
                var applicationId = Fixture.String();
                var f = new BiblioStorageFixture(Db).WitheRecords(applicationId);
                await f.Subject.StoreBiblio(Application(applicationId), Fixture.FutureDate());

                f.CorrelationIdUpdator.Received(1).UpdateIfRequired(Arg.Any<Case>());
                var @case = Db.Set<Case>().Single(_ => _.ApplicationNumber == applicationId && _.Source == DataSourceType.UsptoPrivatePair);
                var caseFile = Db.Set<CaseFiles>().Single(_ => _.CaseId == @case.Id && _.Type == (int)CaseFileType.Biblio);
                Assert.NotNull(caseFile.FileStore);
                Assert.Equal(Fixture.FutureDate(), caseFile.UpdatedOn);
                Assert.Equal($"biblio_{applicationId}", caseFile.FileStore.OriginalFileName);
            }

            [Fact]
            public async Task DoesNotUpdateIfNewerBiblioAlreadyStored()
            {
                var applicationId = Fixture.String();
                var f = new BiblioStorageFixture(Db).WitheRecords(applicationId);
                await f.Subject.StoreBiblio(Application(applicationId), Fixture.PastDate());

                f.CorrelationIdUpdator.Received(1).UpdateIfRequired(Arg.Any<Case>());
                var @case = Db.Set<Case>().Single(_ => _.ApplicationNumber == applicationId && _.Source == DataSourceType.UsptoPrivatePair);
                var caseFile = Db.Set<CaseFiles>().Single(_ => _.CaseId == @case.Id && _.Type == (int)CaseFileType.Biblio);
                Assert.NotNull(caseFile.FileStore);
                Assert.Equal(Fixture.Today(), caseFile.UpdatedOn);
                Assert.Equal($"biblio_{applicationId}", caseFile.FileStore.OriginalFileName);
            }
        }

        class BiblioStorageFixture : IFixture<BiblioStorage>
        {
            public BiblioStorageFixture(InMemoryDbContext db)
            {
                Db = db;
                ArtifactsLocationResolver = Substitute.For<IArtifactsLocationResolver>();
                FileSystem = Substitute.For<IFileSystem>();
                CorrelationIdUpdator = Substitute.For<ICorrelationIdUpdator>();
                BufferedStringReader = Substitute.For<IBufferedStringReader>();
                Subject = new BiblioStorage(Db, ArtifactsLocationResolver, FileSystem, CorrelationIdUpdator, BufferedStringReader, Fixture.Today);
            }

            InMemoryDbContext Db { get; }
            IArtifactsLocationResolver ArtifactsLocationResolver { get; }
            public IFileSystem FileSystem { get; }
            public ICorrelationIdUpdator CorrelationIdUpdator { get; }
            public IBufferedStringReader BufferedStringReader { get; }
            public BiblioStorage Subject { get; }

            public BiblioStorageFixture WitheRecords(string applicationId, DataSourceType source = DataSourceType.UsptoPrivatePair, DateTime? updatedOn = null)
            {
                var @case = new Case() { ApplicationNumber = applicationId, Source = source }.In(Db);
                new CaseFiles()
                {
                    CaseId = @case.Id,
                    Type = (int)CaseFileType.Biblio,
                    UpdatedOn = updatedOn ?? Fixture.Today(),
                    FileStore = new FileStore()
                    {
                        OriginalFileName = $"biblio_{applicationId}",
                        Path = Fixture.String()
                    }.In(Db)
                }.In(Db);
                return this;
            }

            public BiblioStorageFixture WithBiblioFile(string applicationId)
            {
                BufferedStringReader.Read(Arg.Any<string>()).Returns(JsonConvert.SerializeObject(new BiblioFile()
                {
                    Summary = new BiblioSummary() { AppId = applicationId }
                }));
                return this;
            }
        }
    }
}
