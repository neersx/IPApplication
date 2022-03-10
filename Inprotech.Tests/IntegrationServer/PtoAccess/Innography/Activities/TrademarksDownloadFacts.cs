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
using Inprotech.IntegrationServer.PtoAccess.Innography.Model;
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
    public class TrademarksDownloadFacts
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
                    PropertyType = KnownPropertyTypes.TradeMark
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
                    PropertyType = KnownPropertyTypes.TradeMark
                }
            };

            [Fact]
            public async Task DispatchDetailsUnavailableWhenMatchConfidenceIsLow()
            {
                var ipIdResults = new[]
                {
                    new TrademarkDataResponse
                    {
                        ClientIndex = _d1.Case.CaseKey.ToString()
                    },
                    new TrademarkDataResponse
                    {
                        ClientIndex = _d2.Case.CaseKey.ToString()
                    }
                };

                var validationResult = new[]
                {
                    new TrademarkDataValidationResult
                    {
                        ClientIndex = ipIdResults[0].ClientIndex,
                        IpId = ipIdResults[0].IpId
                    },
                    new TrademarkDataValidationResult
                    {
                        ClientIndex = ipIdResults[1].ClientIndex,
                        IpId = ipIdResults[1].IpId
                    }
                };

                var fixture = new TrademarksDownloadFixture(Db)
                              .WithDataToDownload(_d1, _d2)
                              .WithEquivalentEligibleCase(_d1)
                              .WithEquivalentEligibleCase(_d2)
                              .WithIdsResult(ipIdResults)
                              .WithVerificationResult(validationResult);

                fixture.JobArgsStorage.GetAsync<DataDownload[]>(Arg.Any<long>()).ReturnsForAnyArgs(new[] {_d1,_d2});

                var r = await fixture.Subject.Process(Fixture.Long());

                fixture.InnographyDataMatchingClient.Received(1)
                       .MatchingApi(Arg.Is<TrademarkDataRequest[]>(_ => _.Length == 2))
                       .IgnoreAwaitForNSubstituteAssertion();

                var ag = (ActivityGroup)r;

                Assert.False(ag.IsParallel);
                Assert.Single(ag.Items);
                Assert.Equal("DetailsUnavailable.DiscardNofitications", ((SingleActivity)ag.Items.Single()).TypeAndMethod());
                Assert.Equal(new[]
                {
                    _d1.Case.CaseKey,
                    _d2.Case.CaseKey
                }, (int[])((SingleActivity)ag.Items.Single()).Arguments[1]);
            }

            [Fact]
            public async Task DispatchDetailsUnavailableWhenNonMatch()
            {
                var ipIdResults = new[]
                {
                    new TrademarkDataResponse
                    {
                        ClientIndex = _d1.Case.CaseKey.ToString()
                    }
                };

                var validationResults = new[]
                {
                    new TrademarkDataValidationResult
                    {
                        ClientIndex = _d2.Case.CaseKey.ToString(),
                        IpId = Fixture.String()
                    }
                };

                var fixture = new TrademarksDownloadFixture(Db)
                              .WithDataToDownload(_d1)
                              .WithEquivalentEligibleCase(_d1)
                              .WithIdsResult(ipIdResults)
                              .WithVerificationResult(validationResults);

                fixture.JobArgsStorage.GetAsync<DataDownload[]>(Arg.Any<long>()).ReturnsForAnyArgs(new[] {_d1});

                var r = await fixture.Subject.Process(Fixture.Long());

                fixture.InnographyDataMatchingClient.Received(1)
                       .MatchingApi(Arg.Is<TrademarkDataRequest[]>(_ => _.Length == 1))
                       .IgnoreAwaitForNSubstituteAssertion();

                var ag = (ActivityGroup)r;

                Assert.False(ag.IsParallel);
                Assert.Single(ag.Items);

                var detailsUnavailable = (SingleActivity)ag.Items.Single();
                Assert.Equal("DetailsUnavailable.DiscardNofitications", detailsUnavailable.TypeAndMethod());
            }

            [Fact]
            public async Task DispatchDownloadedCaseActivityForEachMediumOrHighMatchItems()
            {
                var ipIdResults = new[]
                {
                    new TrademarkDataResponse
                    {
                        ClientIndex = _d1.Case.CaseKey.ToString(),
                        IpId = Fixture.Integer().ToString()
                    },
                    new TrademarkDataResponse
                    {
                        ClientIndex = _d2.Case.CaseKey.ToString(),
                        IpId = Fixture.Integer().ToString()
                    }
                };

                var validationResult = new[]
                {
                    new TrademarkDataValidationResult
                    {
                        ClientIndex = ipIdResults[0].ClientIndex,
                        IpId = ipIdResults[0].IpId,
                        ApplicationNumber = new MatchingFieldData {StatusCode = TrademarkValidationStatusCodes.PublicDataMatchesUserData}
                    },
                    new TrademarkDataValidationResult
                    {
                        ClientIndex = ipIdResults[1].ClientIndex,
                        IpId = ipIdResults[1].IpId,
                        ApplicationNumber = new MatchingFieldData {StatusCode = TrademarkValidationStatusCodes.PublicDataNotMatchesUserData}
                    }
                };

                var fixture = new TrademarksDownloadFixture(Db)
                              .WithDataToDownload(_d1, _d2)
                              .WithEquivalentEligibleCase(_d1)
                              .WithEquivalentEligibleCase(_d2)
                              .WithIdsResult(ipIdResults)
                              .WithVerificationResult(validationResult);

                fixture.JobArgsStorage.GetAsync<DataDownload[]>(Arg.Any<long>()).ReturnsForAnyArgs(new[] {_d1,_d2});

                var r = await fixture.Subject.Process(Fixture.Long());

                fixture.InnographyDataMatchingClient.Received(1)
                       .MatchingApi(Arg.Is<TrademarkDataRequest[]>(_ => _.Length == 2))
                       .IgnoreAwaitForNSubstituteAssertion();

                fixture.DataDownloadLocationResolver.Received(2).Resolve(Arg.Any<DataDownload>());

                var ag = (ActivityGroup)r;

                Assert.Equal(2, ag.Items.Count());

                var itemgroup1 = ((ActivityGroup)ag.Items.First()).Items.ToArray();
                var itemgroup2 = ((ActivityGroup)ag.Items.Last()).Items.ToArray();
                
                var item1 = (SingleActivity)itemgroup1[0];
                var item2 = (SingleActivity)itemgroup1[1];
                var item3 = (SingleActivity)itemgroup2[0];
                var item4 = (SingleActivity)itemgroup2[1];

                Assert.Equal("IDownloadedCase.Process", item1.TypeAndMethod());
                Assert.Equal(_d1.Case.CaseKey, ((DataDownload)item1.Arguments[0]).Case.CaseKey);
                Assert.True((bool)item1.Arguments[1]);
                Assert.False(item1.ExceptionFilters.Any());

                Assert.Equal("IInnographyTrademarksImage.Download", item2.TypeAndMethod());
                Assert.Equal(4, item2.Arguments.Length);
                Assert.False(item2.ExceptionFilters.Any());

                Assert.Equal("IDownloadedCase.Process", item3.TypeAndMethod());
                Assert.Equal(_d2.Case.CaseKey, ((DataDownload)item3.Arguments[0]).Case.CaseKey);
                Assert.False((bool)item3.Arguments[1]);

                Assert.Equal("IInnographyTrademarksImage.Download", item4.TypeAndMethod());
                Assert.Equal(4, item4.Arguments.Length);
                Assert.False(item4.ExceptionFilters.Any());
            }

            [Fact]
            public async Task SendDatesAsNullOrIso8301()
            {
                var validationResults = new[]
                {
                    new TrademarkDataValidationResult
                    {
                        ClientIndex = _d1.Case.CaseKey.ToString(),
                        IpId = Fixture.String()
                    }
                };

                var fixture = new TrademarksDownloadFixture(Db)
                              .WithDataToDownload(_d1)
                              .WithEquivalentEligibleCase(_d1,
                                                          applicationDate: null,
                                                          publicationDate: Fixture.Today(),
                                                          registrationDate: Fixture.PastDate())
                              .WithIdsResult()
                              .WithVerificationResult(validationResults);

                fixture.JobArgsStorage.GetAsync<DataDownload[]>(Arg.Any<long>()).ReturnsForAnyArgs(new[] {_d1});

                await fixture.Subject.Process(Fixture.Long());

                fixture.InnographyDataMatchingClient.Received(1)
                       .MatchingApi(
                                Arg.Is<TrademarkDataRequest[]>(_ =>
                                                                   _.Single().ApplicationDate == null &&
                                                                   _.Single().PublicationDate == Fixture.Today().ToString("yyyy-MM-dd") &&
                                                                   _.Single().RegistrationDate == Fixture.PastDate().ToString("yyyy-MM-dd")))
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class TrademarksDownloadFixture : IFixture<TrademarksDownload>
        {
            readonly InMemoryDbContext _db;
            readonly EligibleCase[] _cases = new EligibleCase[0];
            TrademarkDataResponse[] _ipIdResults;
            TrademarkDataValidationResult[] _validationResults;

            public TrademarksDownloadFixture(InMemoryDbContext db)
            {
                _db = db;
                BufferedStringReader = Substitute.For<IBufferedStringReader>();

                InnographyDataMatchingClient = Substitute.For<IInnographyTradeMarksDataMatchingClient>();
                InnographyDataValidationClient = Substitute.For<IInnographyTradeMarksDataValidationClient>();
                EligibleInnographyItems = Substitute.For<IEligibleTrademarkItems>();
                JobArgsStorage = Substitute.For<IJobArgsStorage>();
                BackgroundProcessLogger = Substitute.For<IBackgroundProcessLogger<TrademarksDownload>>();
                InnographyValidationRequestMapping = Substitute.For<IInnographyTrademarksValidationRequestMapping>();
                InnographyValidationRequestMapping = Substitute.For<IInnographyTrademarksValidationRequestMapping>();
                DataDownloadLocationResolver = Substitute.For<IDataDownloadLocationResolver>();

                Subject = new TrademarksDownload(InnographyDataMatchingClient, InnographyDataValidationClient, InnographyValidationRequestMapping,
                                              EligibleInnographyItems, JobArgsStorage, BackgroundProcessLogger, DataDownloadLocationResolver);
            }
            public IInnographyTrademarksValidationRequestMapping InnographyValidationRequestMapping { get; set; }

            public IEligibleTrademarkItems EligibleInnographyItems { get; set; }

            public IJobArgsStorage JobArgsStorage { get; set; }

            public IBufferedStringReader BufferedStringReader { get; set; }

            public IInnographyTradeMarksDataMatchingClient InnographyDataMatchingClient { get; set; }

            public IInnographyTradeMarksDataValidationClient InnographyDataValidationClient { get; set; }

            public IBackgroundProcessLogger<TrademarksDownload> BackgroundProcessLogger { get; set; }

            public IDataDownloadLocationResolver DataDownloadLocationResolver { get; set; }

            public TrademarksDownload Subject { get; }

            public TrademarksDownloadFixture WithDataToDownload(params DataDownload[] dataDownloads)
            {
                _ipIdResults = dataDownloads.Select(d => new TrademarkDataResponse
                {
                    ClientIndex = d.Case.CaseKey.ToString(),
                    IpId = Fixture.String()
                }).ToArray();

                _validationResults = dataDownloads.Select(d => new TrademarkDataValidationResult
                {
                    ClientIndex = _cases.SingleOrDefault()?.CaseKey.ToString()
                }).ToArray();

                BufferedStringReader.Read(Arg.Any<string>())
                                    .Returns(JsonConvert.SerializeObject(dataDownloads));

                return this;
            }

            public TrademarksDownloadFixture WithEquivalentEligibleCase(DataDownload dataDownload, string countryCode = null, string alternateCountryCode = null, DateTime? applicationDate = null, DateTime? publicationDate = null, DateTime? registrationDate = null)
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

                EligibleInnographyItems.Retrieve(Arg.Any<int[]>())
                                       .Returns(_db.Set<EligibleInnographyItem>());

                return this;
            }

            public TrademarksDownloadFixture WithIdsResult(params TrademarkDataResponse[] results)
            {
                InnographyDataMatchingClient.MatchingApi(Arg.Any<TrademarkDataRequest[]>())
                                            .Returns(
                                                     new InnographyApiResponse<TrademarkDataResponse>
                                                     {
                                                         Result = results.Any() ? results : _ipIdResults
                                                     });
                return this;
            }

            public TrademarksDownloadFixture WithVerificationResult(params TrademarkDataValidationResult[] results)
            {
                InnographyDataValidationClient.ValidationApi(Arg.Any<TrademarkDataValidationRequest[]>())
                                              .Returns(
                                                       new InnographyApiResponse<TrademarkDataValidationResult>
                                                       {
                                                           Result = results.Any() ? results : _validationResults
                                                       });
                return this;
            }
        }
    }
}