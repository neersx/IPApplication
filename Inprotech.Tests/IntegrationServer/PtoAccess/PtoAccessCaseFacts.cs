using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.CaseFiles;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Storage;
using Inprotech.IntegrationServer.PtoAccess;
using Inprotech.Tests.Fakes;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess
{
    public class PtoAccessCaseFacts
    {
        [SuppressMessage("ReSharper", "NotResolvedInText")]
        public class EnsureAvailableMethod : FactBase
        {
            [Theory]
            [MemberData(nameof(DataSourceTypesProvider.AllSources), MemberType = typeof(DataSourceTypesProvider))]
            public async Task ShouldCreateIntegrationCase(DataSourceType expectedSource, string systemCode)
            {
                var eligibleCase = new EligibleCase
                {
                    CaseKey = Fixture.Integer(),
                    ApplicationNumber = Fixture.String(),
                    RegistrationNumber = Fixture.String(),
                    PublicationNumber = Fixture.String(),
                    SystemCode = systemCode
                };

                var subject = new PtoAccessCaseFixture(Db).Subject;

                await subject.EnsureAvailable(eligibleCase);

                var created = Db.Set<Case>().Single();

                Assert.Equal(expectedSource, created.Source);
                Assert.Equal(eligibleCase.CaseKey, created.CorrelationId);
                Assert.Equal(eligibleCase.ApplicationNumber, created.ApplicationNumber);
                Assert.Equal(eligibleCase.PublicationNumber, created.PublicationNumber);
                Assert.Equal(eligibleCase.RegistrationNumber, created.RegistrationNumber);
            }

            [Theory]
            [MemberData(nameof(DataSourceTypesProvider.AllSources), MemberType = typeof(DataSourceTypesProvider))]
            public async Task ShouldNotCreateIfExists(DataSourceType source, string systemCode)
            {
                var eligibleCase = new EligibleCase
                {
                    CaseKey = Fixture.Integer(),
                    ApplicationNumber = Fixture.String(),
                    RegistrationNumber = Fixture.String(),
                    PublicationNumber = Fixture.String(),
                    CountryCode = Fixture.String(),
                    SystemCode = systemCode
                };

                var existing = new Case
                {
                    ApplicationNumber = eligibleCase.ApplicationNumber,
                    PublicationNumber = eligibleCase.PublicationNumber,
                    RegistrationNumber = eligibleCase.RegistrationNumber,
                    CorrelationId = eligibleCase.CaseKey,
                    Source = source
                }.In(Db);

                await new PtoAccessCaseFixture(Db).Subject.EnsureAvailable(eligibleCase);

                Assert.Equal(existing, Db.Set<Case>().Single());
            }

            [Theory]
            [MemberData(nameof(DataSourceTypesProvider.AllSources), MemberType = typeof(DataSourceTypesProvider))]
            public async Task ShouldPopulateCountryCodeForAllSourcesExceptPrivatePair(DataSourceType source, string systemCode)
            {
                var eligibleCase = new EligibleCase
                {
                    CaseKey = Fixture.Integer(),
                    ApplicationNumber = Fixture.String(),
                    RegistrationNumber = Fixture.String(),
                    PublicationNumber = Fixture.String(),
                    CountryCode = Fixture.String(),
                    SystemCode = systemCode
                };

                var subject = new PtoAccessCaseFixture(Db).Subject;

                await subject.EnsureAvailable(eligibleCase);

                var created = Db.Set<Case>().Single();

                Assert.Equal(source, created.Source);

                if (source != DataSourceType.UsptoPrivatePair)
                {
                    Assert.Equal(eligibleCase.CountryCode, created.Jurisdiction);
                }
                else
                {
                    Assert.Null(created.Jurisdiction);
                }
            }

            [Fact]
            public async Task ShouldThrowIfEligibleCasesSourceIsUnknown()
            {
                await Assert.ThrowsAsync<InvalidOperationException>(async () => await new PtoAccessCaseFixture(Db)
                                                                                      .Subject
                                                                                      .EnsureAvailable(new EligibleCase
                                                                                      {
                                                                                          SystemCode = Fixture.String()
                                                                                      })
                                                                   );
            }
        }

        public class DataSourceTypesProvider
        {
            public static List<object[]> AllSources
            {
                get
                {
                    return Enum.GetValues(typeof(DataSourceType))
                               .Cast<DataSourceType>()
                               .Select(_ => new object[]
                               {
                                   _, ExternalSystems.SystemCode(_)
                               })
                               .ToList();
                }
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void UpdatesTheCaseBasicCaseDetails()
            {
                var f = new PtoAccessCaseFixture(Db);
                var testCase = new Case();
                f.Subject.Update("ABC", testCase, "ABCD");

                Assert.Equal("ABCD", testCase.Version);
                Assert.Equal(Fixture.Today(), testCase.UpdatedOn);
                Assert.Equal(PtoAccessFileNames.CpaXml, testCase.FileStore.OriginalFileName);
                Assert.Equal("ABC", testCase.FileStore.Path);
                Assert.Null(testCase.CorrelationId);
                Assert.Null(testCase.ApplicationNumber);
                Assert.Null(testCase.PublicationNumber);
                Assert.Null(testCase.RegistrationNumber);
            }

            [Fact]
            public void UpdatesTheCaseFromEligibleCase()
            {
                var f = new PtoAccessCaseFixture(Db);
                var testCase = new Case();
                var eligibleCase = new EligibleCase
                {
                    CaseKey = Fixture.Integer(),
                    ApplicationNumber = "1",
                    PublicationNumber = "2",
                    RegistrationNumber = "3"
                };
                f.Subject.Update("ABC", testCase, "ABCD", eligibleCase);

                Assert.Equal("ABCD", testCase.Version);
                Assert.Equal(Fixture.Today(), testCase.UpdatedOn);
                Assert.Equal(PtoAccessFileNames.CpaXml, testCase.FileStore.OriginalFileName);
                Assert.Equal("ABC", testCase.FileStore.Path);
                Assert.Equal(eligibleCase.CaseKey, testCase.CorrelationId);
                Assert.Equal(eligibleCase.ApplicationNumber, testCase.ApplicationNumber);
                Assert.Equal(eligibleCase.PublicationNumber, testCase.PublicationNumber);
                Assert.Equal(eligibleCase.RegistrationNumber, testCase.RegistrationNumber);
            }
        }

        public class CreateOrUpdateNotificationMethod : FactBase
        {
            [Fact]
            public void CreatesNewNotification()
            {
                var f = new PtoAccessCaseFixture(Db);
                var testCase = new Case();

                f.Subject.CreateOrUpdateNotification(testCase, "MyTitle");

                var r = Db.Set<CaseNotification>().FirstOrDefault();

                Assert.NotNull(r);
                Assert.Equal(CaseNotificateType.CaseUpdated, r.Type);
                Assert.Contains("MyTitle", r.Body);
                Assert.Equal(testCase, r.Case);
                Assert.Equal(Fixture.Today(), r.CreatedOn);
                Assert.Equal(Fixture.Today(), r.UpdatedOn);
            }

            [Fact]
            public void FlagsNotificationForReview()
            {
                var f = new PtoAccessCaseFixture(Db);

                var testCase = new Case
                {
                    Id = Fixture.Integer()
                };
                var cn = new CaseNotification
                {
                    CaseId = testCase.Id,
                    Type = CaseNotificateType.CaseUpdated,
                    IsReviewed = true,
                    ReviewedBy = 555
                }.In(Db);

                f.Subject.CreateOrUpdateNotification(testCase, "MyTitle");

                Assert.False(Db.Set<CaseNotification>().Contains(cn));

                cn = Db.Set<CaseNotification>().Single();

                Assert.Equal(CaseNotificateType.CaseUpdated, cn.Type);
                Assert.False(cn.IsReviewed);
                Assert.Equal(Fixture.Today(), cn.UpdatedOn);
                Assert.Null(cn.ReviewedBy);
            }

            [Fact]
            public void UpdatesExistingNotification()
            {
                var f = new PtoAccessCaseFixture(Db);

                var testCase = new Case
                {
                    Id = Fixture.Integer()
                };
                var cn = new CaseNotification
                {
                    CaseId = testCase.Id,
                    Type = CaseNotificateType.CaseUpdated,
                    CreatedOn = Fixture.PastDate()
                }.In(Db);

                f.Subject.CreateOrUpdateNotification(testCase, "MyTitle");

                Assert.False(Db.Set<CaseNotification>().Contains(cn));

                cn = Db.Set<CaseNotification>().Single();

                Assert.Equal(CaseNotificateType.CaseUpdated, cn.Type);
                Assert.Contains("MyTitle", cn.Body);
                Assert.Equal(Fixture.Today(), cn.UpdatedOn);
            }
        }

        public class AddCaseFileMethod : FactBase
        {
            [Fact]
            public void AddsACaseFileWithAFileStore()
            {
                var f = new PtoAccessCaseFixture(Db);

                var @case = new Case
                {
                    Id = Fixture.Integer(),
                    Source = DataSourceType.UsptoTsdr,
                    CorrelationId = Fixture.Integer()
                }.In(Db);

                var eligibleCase = new EligibleCase
                {
                    CaseKey = @case.CorrelationId.GetValueOrDefault(),
                    SystemCode = "USPTO.TSDR"
                };

                new CaseFiles
                {
                    Id = Fixture.Integer(),
                    CaseId = @case.Id,
                    FileStore =
                        new FileStore {Id = Fixture.Integer(), OriginalFileName = "existing", Path = "existing.file"}.In(Db),
                    Type = (int) CaseFileType.MarkImage
                }.In(Db);

                f.Subject.AddCaseFile(eligibleCase, CaseFileType.MarkImage, @"C:\", "Image.png");

                var fileStores = Db.Set<FileStore>();
                Assert.Equal(2, fileStores.Count());
                Assert.Equal("Image.png", fileStores.Last().OriginalFileName);
                Assert.Equal(@"C:\", fileStores.Last().Path);

                var caseFiles = Db.Set<CaseFiles>();
                Assert.Equal(2, caseFiles.Count());
                Assert.Equal(fileStores.Last().Id, caseFiles.Last().FileStoreId);
                Assert.Equal(@case.Id, caseFiles.Last().CaseId);
            }

            [Fact]
            public void DeletesOldCaseFiles()
            {
                var f = new PtoAccessCaseFixture(Db);

                var @case = new Case
                {
                    Id = Fixture.Integer(),
                    Source = DataSourceType.UsptoTsdr,
                    CorrelationId = Fixture.Integer()
                }.In(Db);

                var eligibleCase = new EligibleCase
                {
                    CaseKey = @case.CorrelationId.GetValueOrDefault(),
                    SystemCode = "USPTO.TSDR"
                };

                new CaseFiles
                {
                    Id = Fixture.Integer(),
                    CaseId = @case.Id,
                    FileStore =
                        new FileStore
                        {
                            Id = Fixture.Integer(),
                            OriginalFileName = "existing",
                            Path = "existing.file"
                        }.In(Db),
                    Type = (int) CaseFileType.MarkImage
                }.In(Db);

                f.Subject.AddCaseFile(eligibleCase, CaseFileType.MarkImage, @"C:\", "Image.png", true);

                Assert.Equal(1, Db.Set<CaseFiles>().Count());
            }
        }

        public class PtoAccessCaseFixture : IFixture<PtoAccessCase>
        {
            public PtoAccessCaseFixture(InMemoryDbContext db)
            {
                Subject = new PtoAccessCase(db, Fixture.Today);
            }

            public PtoAccessCase Subject { get; }
        }
    }
}