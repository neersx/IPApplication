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
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Trademarks;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Integration.Jobs;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Innography.Activities
{
    public class TrademarksVerificationFacts
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
                var validationResult = new TrademarkDataValidationResult
                {
                    ClientIndex = _d1.Case.CaseKey.ToString()
                };

                var fixture = new TrademarksVerificationFixture(Db)
                              .WithEquivalentEligibleCase(_d1)
                              .WithVerificationResult(validationResult);

                fixture.JobArgsStorage.GetAsync<DataDownload[]>(Arg.Any<long>()).ReturnsForAnyArgs(new[] {_d1,_d2});

                var r = (ActivityGroup)await fixture.Subject.Process(Fixture.Integer());

                fixture.TrademarksDataValidation.Received(1)
                       .ValidationApi(Arg.Is<TrademarkDataValidationRequest[]>(_ => _.Length == 1))
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
                    new TrademarkDataValidationResult
                    {
                        ClientIndex = _d1.Case.CaseKey.ToString()
                    },
                    new TrademarkDataValidationResult
                    {
                        ClientIndex = _d2.Case.CaseKey.ToString()
                    }
                };

                var fixture = new TrademarksVerificationFixture(Db)
                              .WithEquivalentEligibleCase(_d1)
                              .WithEquivalentEligibleCase(_d2)
                              .WithVerificationResult(validationResult);

                fixture.JobArgsStorage.GetAsync<DataDownload[]>(Arg.Any<long>()).ReturnsForAnyArgs(new[] {_d1,_d2});

                var r = await fixture.Subject.Process(Fixture.Integer());

                fixture.TrademarksDataValidation.Received(1)
                       .ValidationApi(Arg.Is<TrademarkDataValidationRequest[]>(_ => _.Length == 2))
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

        public class TrademarksVerificationFixture
        {
            readonly InMemoryDbContext _db;

            public TrademarksVerificationFixture(InMemoryDbContext db)
            {
                _db = db;
                BackgroundProcessLogger = Substitute.For<IBackgroundProcessLogger<TrademarksVerification>>();
                JobArgsStorage = Substitute.For<IJobArgsStorage>();
                EligibleTrademarkItems = Substitute.For<IEligibleTrademarkItems>();
                TrademarksDataValidation = Substitute.For<IInnographyTradeMarksDataValidationClient>();

                Subject = new TrademarksVerification(EligibleTrademarkItems, TrademarksDataValidation, JobArgsStorage, BackgroundProcessLogger);
            }

            public IBackgroundProcessLogger<TrademarksVerification> BackgroundProcessLogger { get; set; }
            public IJobArgsStorage JobArgsStorage { get; set; }
            public IEligibleTrademarkItems EligibleTrademarkItems { get; set; }
            public IInnographyTradeMarksDataValidationClient TrademarksDataValidation { get; set; }
            public TrademarksVerification Subject { get; }

            public TrademarksVerificationFixture WithEquivalentEligibleCase(DataDownload dataDownload, string countryCode = null, string alternateCountryCode = null, DateTime? applicationDate = null, DateTime? publicationDate = null, DateTime? registrationDate = null)
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

                EligibleTrademarkItems.Retrieve(Arg.Any<int[]>())
                                       .Returns(_db.Set<EligibleInnographyItem>());

                return this;
            }

            public TrademarksVerificationFixture WithVerificationResult(params TrademarkDataValidationResult[] results)
            {
                TrademarksDataValidation.ValidationApi(Arg.Any<TrademarkDataValidationRequest[]>())
                                              .Returns(
                                                       new InnographyApiResponse<TrademarkDataValidationResult>
                                                       {
                                                           Result = results.Any() ? results : null
                                                       });
                return this;
            }
        }
    }
}