using System;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Innography;
using Inprotech.Integration.Search.Export;
using Inprotech.IntegrationServer.PtoAccess.Innography;
using Inprotech.IntegrationServer.PtoAccess.Innography.Activities;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Patents;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Integration.Jobs;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Innography.Activities
{
    public class PatentsVerificationFacts
    {
        public class ProcessMethod : FactBase
        {
            readonly DataDownload _d1 = new DataDownload
            {
                Case = new EligibleCase
                {
                    ApplicationNumber = Fixture.String(),
                    PublicationNumber = Fixture.String(),
                    RegistrationNumber = Fixture.String(),
                    CaseKey = Fixture.Integer(),
                    PropertyType = KnownPropertyTypes.Patent
                }
            };

            readonly DataDownload _d2 = new DataDownload
            {
                Case = new EligibleCase
                {
                    ApplicationNumber = Fixture.String(),
                    PublicationNumber = Fixture.String(),
                    RegistrationNumber = Fixture.String(),
                    CaseKey = Fixture.Integer(),
                    PropertyType = KnownPropertyTypes.Patent
                }
            };

            [Fact]
            public async Task DataDownloadExtendedWithResultsIfMatched()
            {
                var validationResult = new ValidationResult
                {
                    ClientIndex = _d1.Case.CaseKey.ToString(),
                    InnographyId = Fixture.String()
                };

                var fixture = new PatentsVerificationFixture(Db)
                              .WithEquivalentEligibleCase(_d1)
                              .WithVerificationResult(validationResult);

                fixture.JobArgsStorage.GetAsync<DataDownload[]>(Arg.Any<long>()).ReturnsForAnyArgs(new[] {_d1,_d2});

                var r = (ActivityGroup)await fixture.Subject.Process(Fixture.Integer());

                fixture.PatentsDataValidation.Received(1)
                       .ValidationApi(Arg.Is<PatentDataValidationRequest[]>(_ => _.Length == 1))
                       .IgnoreAwaitForNSubstituteAssertion();

                Assert.False(r.IsParallel);
                Assert.Equal(1, r.Items.Count());

                var a = (SingleActivity)r.Items.Single();
                Assert.NotNull(((DataDownload)a.Arguments[0]).AdditionalDetails);
                Assert.Equal(
                             JsonConvert.SerializeObject(validationResult, Formatting.None),
                             ((DataDownload)a.Arguments[0]).AdditionalDetails);
            }

            [Fact]
            public async Task DispatchDownloadedCaseActivityForItems()
            {

                var validationResult = new[]
                {
                    new ValidationResult
                    {
                        ClientIndex = _d1.Case.CaseKey.ToString(),
                        InnographyId = Fixture.String()
                    },
                    new ValidationResult
                    {
                        ClientIndex = _d2.Case.CaseKey.ToString(),
                        InnographyId = Fixture.String()
                    }
                };

                var fixture = new PatentsVerificationFixture(Db)
                              .WithEquivalentEligibleCase(_d1)
                              .WithEquivalentEligibleCase(_d2)
                              .WithVerificationResult(validationResult);

                fixture.JobArgsStorage.GetAsync<DataDownload[]>(Arg.Any<long>()).ReturnsForAnyArgs(new[] {_d1,_d2});

                var r = await fixture.Subject.Process(Fixture.Integer());

                fixture.PatentsDataValidation.Received(1)
                       .ValidationApi(Arg.Is<PatentDataValidationRequest[]>(_ => _.Length == 2))
                       .IgnoreAwaitForNSubstituteAssertion();

                var ag = (ActivityGroup)r;

                Assert.False(ag.IsParallel);
                Assert.Equal(2, ag.Items.Count());

                var item1 = (SingleActivity)ag.Items.First();
                var item2 = (SingleActivity)ag.Items.Last();

                Assert.Equal("IDownloadedCase.Process", item1.TypeAndMethod());
                Assert.Equal(_d1.Case.CaseKey, ((DataDownload)item1.Arguments[0]).Case.CaseKey);
                Assert.False((bool)item1.Arguments[1]);

                Assert.Equal("IDownloadedCase.Process", item2.TypeAndMethod());
                Assert.Equal(_d2.Case.CaseKey, ((DataDownload)item2.Arguments[0]).Case.CaseKey);
                Assert.False((bool)item2.Arguments[1]);
            }
        }

        public class PatentsVerificationFixture
        {
            readonly InMemoryDbContext _db;

            public PatentsVerificationFixture(InMemoryDbContext db)
            {
                _db = db;
                BackgroundProcessLogger = Substitute.For<IBackgroundProcessLogger<PatentsVerification>>();
                JobArgsStorage = Substitute.For<IJobArgsStorage>();
                EligiblePatentItems = Substitute.For<IEligiblePatentItems>();
                PatentsDataValidation = Substitute.For<IInnographyPatentsDataValidationClient>();

                Subject = new PatentsVerification(EligiblePatentItems, PatentsDataValidation, JobArgsStorage, BackgroundProcessLogger);
            }

            public IBackgroundProcessLogger<PatentsVerification> BackgroundProcessLogger { get; set; }
            public IJobArgsStorage JobArgsStorage { get; set; }
            public IEligiblePatentItems EligiblePatentItems { get; set; }
            public IInnographyPatentsDataValidationClient PatentsDataValidation { get; set; }
            public PatentsVerification Subject { get; }

            public PatentsVerificationFixture WithEquivalentEligibleCase(DataDownload dataDownload, string countryCode = null, string alternateCountryCode = null, DateTime? applicationDate = null, DateTime? publicationDate = null, DateTime? registrationDate = null)
            {
                new EligibleInnographyItem
                {
                    ApplicationNumber = dataDownload.Case.ApplicationNumber,
                    RegistrationNumber = dataDownload.Case.RegistrationNumber,
                    PublicationNumber = dataDownload.Case.PublicationNumber,
                    CountryCode = countryCode,
                    CaseKey = dataDownload.Case.CaseKey,
                    ApplicationDate = applicationDate,
                    RegistrationDate = registrationDate,
                    PublicationDate = publicationDate
                }.In(_db);

                EligiblePatentItems.Retrieve(Arg.Any<int[]>())
                                       .Returns(_db.Set<EligibleInnographyItem>());

                return this;
            }

            public PatentsVerificationFixture WithVerificationResult(params ValidationResult[] results)
            {
                PatentsDataValidation.ValidationApi(Arg.Any<PatentDataValidationRequest[]>())
                                              .Returns(
                                                       new InnographyApiResponse<ValidationResult>
                                                       {
                                                           Result = results.Any() ? results : null
                                                       });
                return this;
            }
        }
    }
}