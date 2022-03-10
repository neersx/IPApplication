using System;
using System.Threading.Tasks;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Innography;
using Inprotech.IntegrationServer.PtoAccess;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.IntegrationServer.PtoAccess.Diagnostics;
using Inprotech.IntegrationServer.PtoAccess.Innography.Activities;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Patents;
using Inprotech.Tests.Extensions;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Innography.Activities
{
    public class DownloadedCaseFacts
    {
        public class ProcessMethod
        {
            readonly DataDownload _dataDownload = new DataDownload
            {
                Case = new EligibleCase
                {
                    CaseKey = Fixture.Integer()
                }
            };

            [Theory]
            [InlineData("high")]
            [InlineData("medium")]
            public async Task IndicateCaseProcessed(string confidence)
            {
                _dataDownload.AdditionalDetails =
                    JsonConvert.SerializeObject(new IpIdResult
                    {
                        ClientIndex = _dataDownload.Case.CaseKey.ToString(),
                        Confidence = confidence,
                        Message = "Matched",
                        IpId = Fixture.String(),
                        PublicData = new PatentData()
                    });

                var f = new DownloadedCaseFixture();

                await f.Subject.Process(_dataDownload);

                f.RuntimeEvents.Received(1)
                 .CaseProcessed(_dataDownload)
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ConvertDetailsToCpaXml()
            {
                _dataDownload.AdditionalDetails =
                    JsonConvert.SerializeObject(new IpIdResult
                    {
                        ClientIndex = _dataDownload.Case.CaseKey.ToString(),
                        Confidence = "medium",
                        Message = "Matched",
                        IpId = Fixture.String(),
                        PublicData = new PatentData()
                    });

                var f = new DownloadedCaseFixture();

                await f.Subject.Process(_dataDownload);

                f.DetailsAvailable.Received(1)
                 .ConvertToCpaXml(_dataDownload)
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task EnsuresDataDownloadCaseIsAvailable()
            {
                var f = new DownloadedCaseFixture();

                await f.Subject.Process(_dataDownload);

                f.PtoAccessCase.Received(1)
                 .EnsureAvailable(_dataDownload.Case)
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task LinkIdWithHighConfidenceMatch()
            {
                var innographyId = Fixture.String();

                var f = new DownloadedCaseFixture();

                _dataDownload.AdditionalDetails =
                    JsonConvert.SerializeObject(new ValidationResult
                    {
                        ClientIndex = _dataDownload.Case.CaseKey.ToString(),
                        InnographyId = innographyId,
                        ApplicationDate = new MatchingFieldData()
                        {
                            Input = "1989-11-14",
                            Message = String.Empty,
                            PublicData = "1989-11-14",
                            StatusCode = "01"
                        },
                        ApplicationNumber = new MatchingFieldData()
                        {
                            Input = "AU19900065827",
                            Message = String.Empty,
                            PublicData = "AU19900065827",
                            StatusCode = "01"
                        }
                    });

                await f.Subject.Process(_dataDownload, true);

                f.InnographyIdUpdater.Received(1)
                 .Update(_dataDownload.Case.CaseKey, innographyId)
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task LinkIdWithLowConfidenceMatch()
            {
                var innographyId = Fixture.String();

                var f = new DownloadedCaseFixture();

                _dataDownload.AdditionalDetails =
                    JsonConvert.SerializeObject(new ValidationResult
                    {
                        ClientIndex = _dataDownload.Case.CaseKey.ToString(),
                        InnographyId = innographyId
                    });

                await f.Subject.Process(_dataDownload);

                f.InnographyIdUpdater.Received(0)
                 .Update(_dataDownload.Case.CaseKey, innographyId)
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task NotifiesIfChanged()
            {
                _dataDownload.AdditionalDetails =
                    JsonConvert.SerializeObject(new IpIdResult
                    {
                        ClientIndex = _dataDownload.Case.CaseKey.ToString(),
                        Confidence = "medium",
                        Message = "Matched",
                        IpId = Fixture.String(),
                        PublicData = new PatentData()
                    });

                var f = new DownloadedCaseFixture();

                await f.Subject.Process(_dataDownload);

                f.NewCaseDetailsNotification.Received(1)
                 .NotifyIfChanged(_dataDownload)
                 .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class DownloadedCaseFixture : IFixture<DownloadedCase>
        {
            public DownloadedCaseFixture()
            {
                InnographyIdUpdater = Substitute.For<IInnographyIdUpdater>();

                PtoAccessCase = Substitute.For<IPtoAccessCase>();

                DetailsAvailable = Substitute.For<IDetailsAvailable>();

                NewCaseDetailsNotification = Substitute.For<INewCaseDetailsNotification>();

                RuntimeEvents = Substitute.For<IRuntimeEvents>();

                Subject = new DownloadedCase(PtoAccessCase, InnographyIdUpdater, DetailsAvailable, NewCaseDetailsNotification, RuntimeEvents);
            }

            public IDetailsAvailable DetailsAvailable { get; set; }

            public INewCaseDetailsNotification NewCaseDetailsNotification { get; set; }

            public IRuntimeEvents RuntimeEvents { get; set; }

            public IInnographyIdUpdater InnographyIdUpdater { get; set; }

            public IPtoAccessCase PtoAccessCase { get; set; }

            public DownloadedCase Subject { get; }
        }
    }
}