using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration;
using Inprotech.Integration.Documents;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ContactActivities;
using Xunit;
using Case = InprotechKaizen.Model.Cases.Case;

namespace Inprotech.Tests.Integration.Documents
{
    public class DocumentLoaderFacts
    {
        public class GetDocumentsFromMethod : FactBase
        {
            [Theory]
            [InlineData(DataSourceType.UsptoPrivatePair)]
            [InlineData(DataSourceType.UsptoTsdr)]
            public void DoesNotConsiderDocumentsFromDifferentDataSource(DataSourceType dataSourceType)
            {
                var fixture = new DocumentLoaderFixture(Db)
                              .WithCase()
                              .And(KnownNumberTypes.Application, "1234");

                new Document
                {
                    DocumentDescription = DataSourceType.UsptoPrivatePair.ToString(),
                    Source = DataSourceType.UsptoPrivatePair,
                    Status = DocumentDownloadStatus.Downloaded,
                    ApplicationNumber = "1234"
                }.In(Db);

                new Document
                {
                    DocumentDescription = DataSourceType.UsptoTsdr.ToString(),
                    Source = DataSourceType.UsptoTsdr,
                    Status = DocumentDownloadStatus.Downloaded,
                    ApplicationNumber = "1234"
                }.In(Db);

                var caseId = Db.Set<Case>().Last().Id;
                var result = fixture.Subject.GetDocumentsFrom(dataSourceType, caseId).ToArray();

                Assert.Single((IEnumerable<object>) result);
                Assert.Equal(dataSourceType.ToString(), ((IEnumerable<dynamic>) result).First().DocumentDescription);
            }

            [Theory]
            [InlineData("12,3456/78", "12345678", KnownNumberTypes.Application)]
            [InlineData("12,3456/78", "12345678", KnownNumberTypes.Publication)]
            [InlineData("12,3456/78", "12345678", KnownNumberTypes.Registration)]
            public void FuzzyMatchAllSupportedNumberTypes(string inproNumber, string ptoNumber, string numberType)
            {
                var fixture = new DocumentLoaderFixture(Db)
                              .WithCase()
                              .And(numberType, inproNumber);

                new Document
                {
                    Source = DataSourceType.UsptoPrivatePair,
                    Status = DocumentDownloadStatus.Downloaded,
                    ApplicationNumber = numberType == KnownNumberTypes.Application ? ptoNumber : null,
                    RegistrationNumber = numberType == KnownNumberTypes.Registration ? ptoNumber : null,
                    PublicationNumber = numberType == KnownNumberTypes.Publication ? ptoNumber : null
                }.In(Db);

                var caseId = Db.Set<Case>().Last().Id;
                var result = fixture.Subject.GetDocumentsFrom(DataSourceType.UsptoPrivatePair, caseId);

                Assert.Single((IEnumerable<object>) result);
            }

            [Theory]
            [InlineData(null, "12345678", "2345678", "2345678")]
            [InlineData(null, null, "2345678", "2345678")]
            [InlineData("12345678", "12345678", null, "2345678")]
            [InlineData("12345678", null, "2345678", "2345678")]
            [InlineData("12345678", "12345678", "6789", "2345678")]
            [InlineData("12345678", "789980", "2345678", "2345678")]
            public void MatchesMultipleNumbers(string inproAppNo, string ptoAppNo, string inproRegNo, string ptoRegNo)
            {
                var fixture = new DocumentLoaderFixture(Db)
                              .WithCase()
                              .And(KnownNumberTypes.Application, inproAppNo)
                              .And(KnownNumberTypes.Registration, inproRegNo);

                new Document
                {
                    Source = DataSourceType.UsptoTsdr,
                    Status = DocumentDownloadStatus.Downloaded,
                    ApplicationNumber = ptoAppNo,
                    RegistrationNumber = ptoRegNo
                }.In(Db);

                var caseId = Db.Set<Case>().Last().Id;

                var result = fixture.Subject.GetDocumentsFrom(DataSourceType.UsptoTsdr, caseId);

                Assert.Single((IEnumerable<object>) result);
            }

            [Fact]
            public void ReturnsDocumentsMatchingApplicationNumbers()
            {
                var fixture = new DocumentLoaderFixture(Db)
                              .WithCase()
                              .And(KnownNumberTypes.Application, "1234");

                new Document
                {
                    Source = DataSourceType.UsptoPrivatePair,
                    Status = DocumentDownloadStatus.Downloaded,
                    ApplicationNumber = "1234"
                }.In(Db);

                var caseId = Db.Set<Case>().Last().Id;

                var result = fixture.Subject.GetDocumentsFrom(DataSourceType.UsptoPrivatePair, caseId);

                Assert.Single((IEnumerable<object>) result);
            }

            [Fact]
            public void ReturnsEmptyDocumentsList()
            {
                var fixture = new DocumentLoaderFixture(Db)
                              .WithCase()
                              .And("O", "1234");

                new Document().In(Db);

                var result = fixture.Subject.GetDocumentsFrom(DataSourceType.UsptoPrivatePair, 1);

                Assert.Empty(result);
            }
        }

        public class CountDocumentsFromSourceMethod : FactBase
        {
            [Fact]
            public void ShouldCountDocumentsWithDownloadedStatusForDataSource()
            {
                new Document
                {
                    Source = DataSourceType.UsptoTsdr,
                    Status = DocumentDownloadStatus.Downloaded
                }.In(Db);

                new Document
                {
                    Source = DataSourceType.UsptoPrivatePair,
                    Status = DocumentDownloadStatus.Downloaded
                }.In(Db);

                var fixture = new DocumentLoaderFixture(Db);

                var result = fixture.Subject.CountDocumentsFromSource(DataSourceType.UsptoTsdr);

                Assert.Equal(1, result);
            }

            [Fact]
            public void ShouldNotCountDocumentsWithNonDownloadedStatusForDataSource()
            {
                new Document
                {
                    Source = DataSourceType.UsptoTsdr,
                    Status = DocumentDownloadStatus.Pending
                }.In(Db);

                var fixture = new DocumentLoaderFixture(Db);

                var result = fixture.Subject.CountDocumentsFromSource(DataSourceType.UsptoTsdr);

                Assert.Equal(0, result);
            }
        }

        public class GetImportedRefsMethod : FactBase
        {
            [Fact]
            public void DoesNotReturnNullReferences()
            {
                var fixture = new DocumentLoaderFixture(Db).WithCase().And(null);

                var caseId = Db.Set<Case>().Last().Id;

                var result = fixture.Subject.GetImportedRefs(caseId);

                Assert.Empty(result);
            }

            [Fact]
            public void ReturnsImportedReferences()
            {
                var attachmentReference = Guid.NewGuid();

                var fixture = new DocumentLoaderFixture(Db).WithCase().And(attachmentReference);

                var caseId = Db.Set<Case>().Last().Id;

                var result = fixture.Subject.GetImportedRefs(caseId).ToArray();

                Assert.Single(result);
                Assert.Equal(attachmentReference, result.First());
            }
        }

        public class DocumentLoaderFixture : IFixture<IDocumentLoader>
        {
            readonly InMemoryDbContext _db;

            public DocumentLoaderFixture(InMemoryDbContext db)
            {
                _db = db;
                Subject = new DocumentLoader(db, db);
            }

            public IDocumentLoader Subject { get; }

            public DocumentLoaderFixture WithCase()
            {
                new Case(
                         "1",
                         new Country("1", "us").In(_db),
                         new CaseType("1", "t").In(_db),
                         new PropertyType("1", "p").In(_db)).In(_db);

                return this;
            }

            public DocumentLoaderFixture And(Guid? referenceGuid)
            {
                var @case = _db.Set<Case>().Last();

                var activity = new Activity().In(_db);
                var attachment = new ActivityAttachment {Reference = referenceGuid}.In(_db);
                activity.Attachments.Add(attachment);
                @case.Activities.Add(activity);
                @case.In(_db);

                return this;
            }

            public DocumentLoaderFixture And(string numberType, string number)
            {
                if (string.IsNullOrWhiteSpace(number))
                {
                    return this;
                }

                var @case = _db.Set<Case>().Last();

                new OfficialNumber(new NumberType(numberType, "numberType - " + numberType, null), @case, number)
                {
                    IsCurrent = 1
                }.In(_db);

                return this;
            }
        }
    }
}