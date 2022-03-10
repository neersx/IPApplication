using System;
using System.Collections.Generic;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Settings;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.DMSIntegration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.DMSIntegration
{
    public class SendToDmsControllerFacts
    {
        public class SendDocumentsFromSourceMethod : FactBase
        {
            [Fact]
            public void ShouldStartJob()
            {
                var fixture = new SendToDmsControllerFixture(Db);
                fixture.Subject.SendDocumentsFromSource(DataSourceType.UsptoPrivatePair);

                fixture.ConfigureJob.Received(1).StartJob(DataSourceHelper.PrivatePairJobType);
            }

            [Fact]
            public void ShouldThrowExceptionForInvalidDataSource()
            {
                var e = Record.Exception(() =>
                {
                    var fixture = new SendToDmsControllerFixture(Db);
                    fixture.Subject.SendDocumentsFromSource((DataSourceType) 999);
                });

                Assert.IsType<InvalidOperationException>(e);
            }

            [Fact]
            public void ShouldThrowExceptionIfIntegrationIsNotEnabledForDataSource()
            {
                var e = Record.Exception(() =>
                {
                    var fixture = new SendToDmsControllerFixture(Db).WithDmsIntegrationDisabled();
                    fixture.Subject.SendDocumentsFromSource(DataSourceType.UsptoPrivatePair);
                });

                Assert.IsType<ArgumentException>(e);
            }
        }

        public class SendDocumentsFromSourceForCaseMethod : FactBase
        {
            [Fact]
            public void ShouldNotChangeStatusForDocumentsThatShouldNotBeSent()
            {
                var doc = new Document
                {
                    Status = DocumentDownloadStatus.SentToDms
                }.In(Db);

                new SendToDmsControllerFixture(Db).WithCaseDocuments(new List<Document> {doc}).Subject.SendDocumentsFromSourceForCase(DataSourceType.UsptoPrivatePair, 1);

                Assert.Equal(DocumentDownloadStatus.SentToDms, doc.Status);
            }

            [Fact]
            public void ShouldNotSendDocumentsThatHaveBeenImported()
            {
                var reference = new Guid();
                var doc = new Document
                {
                    Status = DocumentDownloadStatus.Downloaded,
                    Reference = reference
                }.In(Db);

                new SendToDmsControllerFixture(Db).WithCaseDocuments(new List<Document> {doc}).WithImportedReference(reference).Subject.SendDocumentsFromSourceForCase(DataSourceType.UsptoPrivatePair, 1);

                Assert.Equal(DocumentDownloadStatus.Downloaded, doc.Status);
            }

            [Fact]
            public void ShouldSetStatusToSendToDmsForDownloadedAndFailedDocuments()
            {
                var doc1 = new Document
                {
                    Status = DocumentDownloadStatus.Downloaded
                }.In(Db);

                var doc2 = new Document
                {
                    Status = DocumentDownloadStatus.FailedToSendToDms
                }.In(Db);

                new SendToDmsControllerFixture(Db).WithCaseDocuments(new List<Document> {doc1, doc2}).Subject.SendDocumentsFromSourceForCase(DataSourceType.UsptoPrivatePair, 1);

                Assert.Equal(DocumentDownloadStatus.SendToDms, doc1.Status);
                Assert.Equal(DocumentDownloadStatus.SendToDms, doc2.Status);
            }

            [Fact]
            public void ShouldThrowExceptionIfCaseIdIsNull()
            {
                var e = Record.Exception(() =>
                {
                    var fixture = new SendToDmsControllerFixture(Db);
                    fixture.Subject.SendDocumentsFromSourceForCase(DataSourceType.UsptoPrivatePair, null);
                });

                Assert.IsType<ArgumentNullException>(e);
            }

            [Fact]
            public void ShouldThrowExceptionIfIntegrationIsNotEnabledForDataSource()
            {
                var e = Record.Exception(() =>
                {
                    var fixture = new SendToDmsControllerFixture(Db).WithDmsIntegrationDisabled();
                    fixture.Subject.SendDocumentsFromSourceForCase(DataSourceType.UsptoPrivatePair, 1);
                });

                Assert.IsType<ArgumentException>(e);
            }
        }

        [Fact]
        public void RequiresConfigureDmsIntegrationTask()
        {
            var r = TaskSecurity.Secures<SendToDmsController>(ApplicationTask.ConfigureDmsIntegration);

            Assert.True(r);
        }

        [Fact]
        public void RequiresSaveImportedCaseDataTask()
        {
            var r = TaskSecurity.Secures<SendToDmsController>(ApplicationTask.SaveImportedCaseData);

            Assert.True(r);
        }

        [Fact]
        public void RequiresViewCaseDataComparisonTask()
        {
            var r = TaskSecurity.Secures<SendToDmsController>(ApplicationTask.ViewCaseDataComparison);

            Assert.True(r);
        }
    }

    public class SendToDmsControllerFixture : IFixture<SendToDmsController>
    {
        public SendToDmsControllerFixture(InMemoryDbContext db)
        {
            ConfigureJob = Substitute.For<IConfigureJob>();
            DmsIntegrationSettings = Substitute.For<IDmsIntegrationSettings>();

            DmsIntegrationSettings.IsEnabledFor(new DataSourceType())
                                  .ReturnsForAnyArgs(true);

            DocumentLoader = Substitute.For<IDocumentLoader>();

            Subject = new SendToDmsController(DmsIntegrationSettings, ConfigureJob, db, DocumentLoader);
        }

        public IDocumentLoader DocumentLoader { get; set; }

        public IDmsIntegrationSettings DmsIntegrationSettings { get; set; }

        public IConfigureJob ConfigureJob { get; set; }

        public SendToDmsController Subject { get; set; }

        public SendToDmsControllerFixture WithDmsIntegrationDisabled()
        {
            DmsIntegrationSettings.IsEnabledFor(new DataSourceType())
                                  .ReturnsForAnyArgs(false);

            return this;
        }

        public SendToDmsControllerFixture WithJobStatus(JobStatus status)
        {
            ConfigureJob.GetJobStatus(string.Empty).ReturnsForAnyArgs(status);

            return this;
        }

        public SendToDmsControllerFixture WithCaseDocuments(IEnumerable<Document> documents)
        {
            DocumentLoader.GetDocumentsFrom(new DataSourceType(), null).ReturnsForAnyArgs(documents);

            return this;
        }

        public SendToDmsControllerFixture WithImportedReference(Guid? referenceGuid)
        {
            DocumentLoader.GetImportedRefs(null).ReturnsForAnyArgs(new[] {referenceGuid});

            return this;
        }
    }
}