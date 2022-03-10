using Inprotech.Integration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Schedules;
using Inprotech.Tests.Fakes;
using NSubstitute;
using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using Xunit;

#pragma warning disable 612

namespace Inprotech.Tests.Integration.Schedules
{
    [SuppressMessage("ReSharper", "ObjectCreationAsStatement")]
    public class ScheduleRecoverableReaderFacts
    {
        public class GetAllMethod : FactBase
        {
            [Theory]
            [InlineData(ArtifactInclusion.Include, false)]
            [InlineData(ArtifactInclusion.Exclude, true)]
            public void ReturnsRecoverableCases(ArtifactInclusion artefactInclusion, bool isNull)
            {
                var f = new ScheduleRecoverableReaderFixture(Db);

                var data = new DummyData(Db, DataSourceType.Epo, "1234");

                var @case = new Case
                {
                    Id = 1,
                    ApplicationNumber = "A1",
                    RegistrationNumber = "R1",
                    PublicationNumber = "P1",
                    Source = DataSourceType.Epo
                }.In(Db);

                var sr = new ScheduleRecoverable(data._scheduleExecution, @case, Fixture.Monday).In(Db);

                sr.Blob = new byte[0];

                var result = f.Subject.GetAll(artefactInclusion).Single();

                Assert.Equal("A1", result.ApplicationNumber);
                Assert.Equal("R1", result.RegistrationNumber);
                Assert.Equal("P1", result.PublicationNumber);
                Assert.Equal(1, result.ArtifactId);
                Assert.Equal(ArtifactType.Case, result.ArtifactType);
                Assert.Equal(DataSourceType.Epo, result.DataSourceType);
                Assert.Equal(result.ScheduleId, data._schedule.Id);
                Assert.Equal("1234", result.CorrelationId);
                Assert.Equal(isNull, result.Artifact == null);
            }

            [Fact]
            public void IgnoreRecoverableCaseWithUpdateCaseNotification()
            {
                var f = new ScheduleRecoverableReaderFixture(Db);
                var data = new DummyData(Db, DataSourceType.UsptoPrivatePair);
                var @case = new Case
                {
                    Id = 1,
                    ApplicationNumber = "A1",
                    Source = DataSourceType.UsptoPrivatePair
                }.In(Db);

                new ScheduleRecoverable(data._scheduleExecution, @case, Fixture.Monday).In(Db);
                new CaseNotification { CaseId = 1, Type = CaseNotificateType.CaseUpdated }.In(Db);

                var result = f.Subject.GetAll().Count();
                Assert.Equal(0, result);
            }

            [Fact]
            public void IgnoreRecoverableDocumentWithStatusOtherThanFailed()
            {
                var f = new ScheduleRecoverableReaderFixture(Db);
                var data = new DummyData(Db, DataSourceType.UsptoPrivatePair);

                var document = new Document
                {
                    Id = 1,
                    ApplicationNumber = "A1",
                    Source = DataSourceType.UsptoPrivatePair,
                    Status = DocumentDownloadStatus.Pending
                }.In(Db);
                new ScheduleRecoverable(data._scheduleExecution, document, Fixture.Monday).In(Db);

                var result = f.Subject.GetAll().Count();
                Assert.Equal(0, result);
            }

            [Fact]
            public void IgnoreRecoverableIfScheduleIsDeleted()
            {
                var f = new ScheduleRecoverableReaderFixture(Db);
                var data = new DummyData(Db, DataSourceType.UsptoPrivatePair);
                data._schedule.IsDeleted = true;
                Db.SaveChanges();

                var document = new Document
                {
                    Id = 1,
                    ApplicationNumber = "A1",
                    Source = DataSourceType.UsptoPrivatePair,
                    Status = DocumentDownloadStatus.Failed
                }.In(Db);

                new ScheduleRecoverable(data._scheduleExecution, document, Fixture.Monday).In(Db);

                var result = f.Subject.GetAll().Count();
                Assert.Equal(0, result);
            }

            [Fact]
            public void ReturnsRecoverableCaseWhenPresent()
            {
                var f = new ScheduleRecoverableReaderFixture(Db);
                var data = new DummyData(Db, DataSourceType.UsptoTsdr);

                var @case = new Case
                {
                    Id = 1,
                    ApplicationNumber = "A1",
                    Source = DataSourceType.UsptoTsdr
                }.In(Db);

                var docuemnt = new Document
                {
                    Id = 11,
                    ApplicationNumber = "DA1",
                    Source = DataSourceType.UsptoTsdr
                }.In(Db);

                new ScheduleRecoverable(data._scheduleExecution, @case, Fixture.Monday) { Document = docuemnt }.In(Db);

                var result = f.Subject.GetAll().Single();

                Assert.Equal("A1", result.ApplicationNumber);
                Assert.Equal(1, result.ArtifactId);
                Assert.Equal(ArtifactType.Case, result.ArtifactType);
            }

            [Fact]
            public void ReturnsRecoverableDocument()
            {
                var f = new ScheduleRecoverableReaderFixture(Db);
                var data = new DummyData(Db, DataSourceType.Epo);

                var document = new Document
                {
                    Id = 1,
                    ApplicationNumber = "A1",
                    RegistrationNumber = "R1",
                    PublicationNumber = "P1",
                    Source = DataSourceType.Epo,
                    Status = DocumentDownloadStatus.Failed,
                    DocumentDescription = "description",
                    FileWrapperDocumentCode = "D",
                    MailRoomDate = DateTime.Now.AddDays(-1),
                    UpdatedOn = DateTime.Now.AddDays(-1)
                }.In(Db);
                new ScheduleRecoverable(data._scheduleExecution, document, Fixture.Monday).In(Db);

                var result = f.Subject.GetAll().Single();

                Assert.Equal("A1", result.ApplicationNumber);
                Assert.Equal("R1", result.RegistrationNumber);
                Assert.Equal("P1", result.PublicationNumber);
                Assert.Equal(1, result.ArtifactId);
                Assert.Equal(ArtifactType.Document, result.ArtifactType);
                Assert.Equal(DataSourceType.Epo, result.DataSourceType);
                Assert.Equal(result.ScheduleId, data._schedule.Id);
                Assert.Equal(document.DocumentDescription, result.DocumentDescription);
                Assert.Equal(document.FileWrapperDocumentCode, result.FileWrapperDocumentCode);
                Assert.Equal(document.MailRoomDate, result.MailRoomDate);
                Assert.Equal(document.UpdatedOn, result.UpdatedOn);

            }
        }

        public class GetOrphanDocuments : FactBase
        {
            [Fact]
            public void ReturnsOrphanDocuments()
            {
                var failedItems = new[] { new FailedItem { ApplicationNumber = "A1", ArtifactType = ArtifactType.Document } };
                var f = new ScheduleRecoverableReaderFixture(Db);

                var result = f.Subject.OrphanDocuments(failedItems, OrphanDocumentsReaderMode.CountTowardsCase, out _).ToArray();

                Assert.Single(result);
                Assert.Equal("A1", result.First().ApplicationNumber);
                Assert.Equal(ArtifactType.Document, result.First().ArtifactType);
            }

            [Fact]
            public void ReturnsRelatedCasesForDocuments()
            {
                var failedItems = new[] { new FailedItem { ApplicationNumber = "A1", ArtifactType = ArtifactType.Document } };
                new Case
                {
                    Id = 1,
                    ApplicationNumber = "A1"
                }.In(Db);

                var f = new ScheduleRecoverableReaderFixture(Db);

                var result = f.Subject.OrphanDocuments(failedItems, OrphanDocumentsReaderMode.CountTowardsCase, out var relatedCases).ToArray();

                Assert.Empty(result);
                var enumerable = relatedCases as FailedItem[] ?? relatedCases.ToArray();

                Assert.Single(enumerable);
                Assert.Equal("A1", enumerable.First().ApplicationNumber);
                Assert.Equal(ArtifactType.Case, enumerable.First().ArtifactType);
            }
        }

        public class GetFailedScheduleDetailsMethod : FactBase
        {
            [Fact]
            public void ReturnsCorrlationIds()
            {
                var failedItems = new[]
                {
                    new FailedItem {ApplicationNumber = "A1", ArtifactType = ArtifactType.Document, ArtifactId = 1, ScheduleId = 10, CorrelationId = "1111"},
                    new FailedItem {ApplicationNumber = "A1", ArtifactType = ArtifactType.Document, ArtifactId = 1, ScheduleId = 10, CorrelationId = "4444"},
                    new FailedItem {ApplicationNumber = "A1", ArtifactType = ArtifactType.Case, ArtifactId = 1, ScheduleId = 10, CorrelationId = "2222"},
                    new FailedItem {ApplicationNumber = "A1", ArtifactType = ArtifactType.Case, ArtifactId = 1, ScheduleId = 10, CorrelationId = "3333"}
                };

                var f = new ScheduleRecoverableReaderFixture(Db);
                new DummyData(Db, DataSourceType.Epo);
                var result = f.Subject.GetFailedScheduleDetails(failedItems).ToArray();

                Assert.NotEmpty(result);
                Assert.Contains("1111", result.First().CorrelationIds);
                Assert.Contains("2222", result.First().CorrelationIds);
                Assert.Contains("3333", result.First().CorrelationIds);
                Assert.Contains("4444", result.First().CorrelationIds);
            }

            [Fact]
            public void ReturnsFailedCount()
            {
                var failedItems = new[]
                {
                    new FailedItem {ApplicationNumber = "A1", ArtifactType = ArtifactType.Document, ArtifactId = 1, ScheduleId = 10},
                    new FailedItem {ApplicationNumber = "A1", ArtifactType = ArtifactType.Document, ArtifactId = 1, ScheduleId = 10},
                    new FailedItem {ApplicationNumber = "A1", ArtifactType = ArtifactType.Case, ArtifactId = 1, ScheduleId = 10},
                    new FailedItem {ApplicationNumber = "A1", ArtifactType = ArtifactType.Case, ArtifactId = 1, ScheduleId = 10}
                };

                var f = new ScheduleRecoverableReaderFixture(Db);
                new DummyData(Db, DataSourceType.Epo);
                var result = f.Subject.GetFailedScheduleDetails(failedItems).ToArray();

                Assert.NotEmpty(result);
                Assert.Equal(1, result.First().FailedCasesCount);
            }

            [Fact]
            public void ReturnsFailedScheduleData()
            {
                var failedItems = new[]
                {
                    new FailedItem {ApplicationNumber = "A1", ArtifactType = ArtifactType.Document, ArtifactId = 1, ScheduleId = 10, DataSourceType = DataSourceType.Epo},
                    new FailedItem {ApplicationNumber = "A1", ArtifactType = ArtifactType.Document, ArtifactId = 1, ScheduleId = 10, DataSourceType = DataSourceType.Epo},
                    new FailedItem {ApplicationNumber = "A1", ArtifactType = ArtifactType.Case, ArtifactId = 1, ScheduleId = 10, DataSourceType = DataSourceType.Epo},
                    new FailedItem {ApplicationNumber = "A1", ArtifactType = ArtifactType.Case, ArtifactId = 1, ScheduleId = 10, DataSourceType = DataSourceType.Epo}
                };

                var f = new ScheduleRecoverableReaderFixture(Db);
                new DummyData(Db, DataSourceType.Epo);
                var result = f.Subject.GetFailedScheduleDetails(failedItems).ToArray();

                Assert.NotEmpty(result);
                Assert.Single(result);
                Assert.Equal(10, result.First().ScheduleId);
                Assert.Equal("Schedule1", result.First().Name);
                Assert.Equal(DataSourceType.Epo, result.First().DataSource);
            }

            [Fact]
            public void ReturnsRecoveryStatus()
            {
                var failedItems = new[]
                {
                    new FailedItem {ApplicationNumber = "A1", ArtifactType = ArtifactType.Document, ArtifactId = 1, ScheduleId = 10, CorrelationId = "*"}
                };

                var f = new ScheduleRecoverableReaderFixture(Db);
                f.RecoveryScheduleStatusReader.Read(Arg.Any<int>()).Returns(RecoveryScheduleStatus.Idle);

                new DummyData(Db, DataSourceType.Epo);
                var result = f.Subject.GetFailedScheduleDetails(failedItems).ToArray();

                Assert.NotEmpty(result);
                Assert.Equal(RecoveryScheduleStatus.Idle, result.First().RecoveryStatus);
            }

            [Fact]
            public void SkipsSettingCorrelationIdsIfNotSet()
            {
                var failedItems = new[]
                {
                    new FailedItem {ApplicationNumber = "A1", ArtifactType = ArtifactType.Document, ArtifactId = 1, ScheduleId = 10, CorrelationId = "*"},
                    new FailedItem {ApplicationNumber = "A1", ArtifactType = ArtifactType.Document, ArtifactId = 1, ScheduleId = 10, CorrelationId = "*"},
                    new FailedItem {ApplicationNumber = "A1", ArtifactType = ArtifactType.Case, ArtifactId = 1, ScheduleId = 10, CorrelationId = "*"},
                    new FailedItem {ApplicationNumber = "A1", ArtifactType = ArtifactType.Case, ArtifactId = 1, ScheduleId = 10, CorrelationId = "*"}
                };

                var f = new ScheduleRecoverableReaderFixture(Db);
                new DummyData(Db, DataSourceType.Epo);
                var result = f.Subject.GetFailedScheduleDetails(failedItems).ToArray();

                f.RecoveryScheduleStatusReader.Received(1).Read(10);
                Assert.NotEmpty(result);
                Assert.Empty(result.First().CorrelationIds);
            }
        }

        public class GetAllForMethod : FactBase
        {
            [Fact]
            public void ReturnsOrphanDocument()
            {
                var f = new ScheduleRecoverableReaderFixture(Db);
                var dataEpo = new DummyData(Db, DataSourceType.Epo);

                var @case = new Case
                {
                    Id = 1,
                    ApplicationNumber = "A1",
                    Source = DataSourceType.Epo
                }.In(Db);

                var document = new Document
                {
                    Id = 2,
                    ApplicationNumber = "A2",
                    Source = DataSourceType.Epo,
                    Status = DocumentDownloadStatus.Failed
                }.In(Db);

                new ScheduleRecoverable(dataEpo._scheduleExecution, @case, Fixture.Monday).In(Db);
                new ScheduleRecoverable(dataEpo._scheduleExecution, document, Fixture.Monday).In(Db);

                var result = f.Subject.GetAllFor(new[] { DataSourceType.Epo }).ToArray();

                Assert.NotEmpty(result);
                Assert.Equal(2, result.Length);
                Assert.Equal(1, result.Count(_ => _.ArtifactType == ArtifactType.Case));
                Assert.Equal(1, result.Count(_ => _.ArtifactType == ArtifactType.Document));
            }

            [Fact]
            public void ReturnsRecoverableItemsForGivenDataSources()
            {
                var f = new ScheduleRecoverableReaderFixture(Db);
                var dataEpo = new DummyData(Db, DataSourceType.Epo);
                var dataTsdr = new DummyData(Db, DataSourceType.UsptoTsdr, null, 11);
                var dataPrivatePair = new DummyData(Db, DataSourceType.UsptoPrivatePair, "1234", 12);

                var case1 = new Case
                {
                    Id = 1,
                    ApplicationNumber = "A1",
                    Source = DataSourceType.Epo
                }.In(Db);

                var case2 = new Case
                {
                    Id = 2,
                    ApplicationNumber = "A2",
                    Source = DataSourceType.UsptoTsdr
                }.In(Db);

                var case3 = new Case
                {
                    Id = 3,
                    ApplicationNumber = "A3",
                    Source = DataSourceType.UsptoPrivatePair
                }.In(Db);

                new ScheduleRecoverable(dataEpo._scheduleExecution, case1, Fixture.Monday).In(Db);
                new ScheduleRecoverable(dataTsdr._scheduleExecution, case2, Fixture.Monday).In(Db);
                new ScheduleRecoverable(dataPrivatePair._scheduleExecution, case3, Fixture.Monday).In(Db);

                var result = f.Subject.GetAllFor(new[] { DataSourceType.Epo, DataSourceType.UsptoPrivatePair }).ToArray();

                Assert.NotEmpty(result);
                Assert.Equal(2, result.Length);
                Assert.Equal(1, result.Count(_ => _.DataSourceType == DataSourceType.UsptoPrivatePair));
                Assert.Equal("1234", result.Single(_ => _.DataSourceType == DataSourceType.UsptoPrivatePair).CorrelationId);
                Assert.Equal(1, result.Count(_ => _.DataSourceType == DataSourceType.Epo));
            }

            [Fact]
            public void ReturnsRecoverableForGivenIds()
            {
                var f = new ScheduleRecoverableReaderFixture(Db);
                var dataTsdr = new DummyData(Db, DataSourceType.UsptoTsdr, null, 11);
                var dataPrivatePair = new DummyData(Db, DataSourceType.UsptoPrivatePair, "1234", 12);

                var case1 = new Case
                {
                    Id = 1001,
                    ApplicationNumber = "A1001",
                    Source = DataSourceType.UsptoTsdr
                }.In(Db);

                var case2 = new Case
                {
                    Id = 1002,
                    ApplicationNumber = "A1002",
                    Source = DataSourceType.UsptoPrivatePair
                }.In(Db);

                new ScheduleRecoverable(dataTsdr._scheduleExecution, case1, Fixture.Monday).In(Db);
                var r1 = new ScheduleRecoverable(dataPrivatePair._scheduleExecution, case2, Fixture.Monday).In(Db);
                new ScheduleRecoverable(dataPrivatePair._scheduleExecution, case2, Fixture.Monday).In(Db);

                var result = f.Subject.GetRecoverable(DataSourceType.UsptoPrivatePair, new List<long>() { r1.Id }).ToArray();

                Assert.NotEmpty(result);
                Assert.Single(result);
                Assert.Single(result.Where(_ => _.DataSourceType == DataSourceType.UsptoPrivatePair));
                Assert.Equal(r1.Id, result.Single(_ => _.DataSourceType == DataSourceType.UsptoPrivatePair).Id);
            }

            [Fact]
            public void ReturnsRelatedCasesForDocuments()
            {
                var f = new ScheduleRecoverableReaderFixture(Db);
                var dataEpo = new DummyData(Db, DataSourceType.Epo);

                var @case = new Case
                {
                    Id = 1,
                    ApplicationNumber = "A1",
                    Source = DataSourceType.Epo
                }.In(Db);

                new Case
                {
                    Id = 2,
                    ApplicationNumber = "A2",
                    Source = DataSourceType.Epo
                }.In(Db);

                var document = new Document
                {
                    Id = 2,
                    ApplicationNumber = "A2",
                    Source = DataSourceType.Epo,
                    Status = DocumentDownloadStatus.Failed
                }.In(Db);

                new ScheduleRecoverable(dataEpo._scheduleExecution, @case, Fixture.Monday).In(Db);
                new ScheduleRecoverable(dataEpo._scheduleExecution, document, Fixture.Monday).In(Db);

                var result = f.Subject.GetAllFor(new[] { DataSourceType.Epo }).ToArray();

                Assert.NotEmpty(result);
                Assert.Equal(2, result.Length);
                Assert.True(result.All(_ => _.ArtifactType == ArtifactType.Case));
            }
        }
    }

    public class DummyData
    {
        public Schedule _schedule;
        public ScheduleExecution _scheduleExecution;

        public DummyData(InMemoryDbContext db, DataSourceType source, string correlationId = null, int scheduleId = 10)
        {
            _schedule = new Schedule
            {
                Id = scheduleId,
                DataSourceType = source,
                Name = "Schedule1"
            }.In(db);

            _scheduleExecution = new ScheduleExecution(Guid.NewGuid(), _schedule, Fixture.Monday, correlationId).In(db);
        }
    }

    public class ScheduleRecoverableReaderFixture : IFixture<IScheduleRecoverableReader>
    {
        public ScheduleRecoverableReaderFixture(InMemoryDbContext db)
        {
            RecoveryScheduleStatusReader = Substitute.For<IRecoveryScheduleStatusReader>();
            RecoveryScheduleStatusReader.Read(Arg.Any<int>()).Returns(RecoveryScheduleStatus.Running);
            Subject = new ScheduleRecoverableReader(db, RecoveryScheduleStatusReader);
        }

        public IRecoveryScheduleStatusReader RecoveryScheduleStatusReader { get; set; }
        public IScheduleRecoverableReader Subject { get; }
    }
}