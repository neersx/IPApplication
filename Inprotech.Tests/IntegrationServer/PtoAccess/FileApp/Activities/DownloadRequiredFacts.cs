using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using Inprotech.IntegrationServer.PtoAccess.FileApp.Activities;
using Inprotech.Tests.Extensions;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

// ReSharper disable InconsistentNaming

namespace Inprotech.Tests.IntegrationServer.PtoAccess.FileApp.Activities
{
    public class DownloadRequiredFacts
    {
        public class FromTheIPPlatformMethod
        {
            [Fact]
            public async Task ShouldDispatchMatchingNationalCases()
            {
                var dataPath = Fixture.String();
                var fileCasePath = Fixture.String();
                var caseId1 = Fixture.Integer();
                var caseId2 = Fixture.Integer();
                var parentPctCaseId = Fixture.Integer();

                var dataDownloads = new[]
                {
                    new DataDownload {Case = new EligibleCase(caseId1, "AU")},
                    new DataDownload {Case = new EligibleCase(caseId2, "US")}
                };

                var fileCases = new[]
                {
                    new FileCase
                    {
                        Id = parentPctCaseId.ToString(),
                        Countries = new List<Country>
                        {
                            new Country("AU"),
                            new Country("US")
                        }
                    }
                };

                var fixture = new DownloadRequiredFixture();

                fixture.BufferedStringReader.Read(dataPath)
                       .Returns(JsonConvert.SerializeObject(dataDownloads));

                fixture.BufferedStringReader.Read(fileCasePath)
                       .Returns(JsonConvert.SerializeObject(fileCases));

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               CaseId = caseId1,
                               CountryCode = "AU",
                               ParentCaseId = parentPctCaseId
                           },
                           new FileInstructAllowedCase
                           {
                               CaseId = caseId2,
                               CountryCode = "US",
                               ParentCaseId = parentPctCaseId
                           }
                       }.AsQueryable());

                var r = (ActivityGroup) await fixture.Subject.FromTheIPPlatform(dataPath, fileCasePath);

                Assert.Equal(2, r.Items.Count());

                Assert.Equal("DownloadedCase.Process", ((SingleActivity) r.Items.First()).TypeAndMethod());
                Assert.Equal("DownloadedCase.Process", ((SingleActivity) r.Items.Last()).TypeAndMethod());
            }

            [Fact]
            public async Task ShouldDispatchRogueIntegratedCasesForClearing()
            {
                var dataPath = Fixture.String();
                var fileCasePath = Fixture.String();
                var caseId1 = Fixture.Integer();
                var caseId2 = Fixture.Integer();
                var caseId3 = Fixture.Integer();
                var parentPctCaseId1 = Fixture.Integer();
                var parentPctCaseId2 = Fixture.Integer();

                var dataDownloads = new[]
                {
                    new DataDownload {Case = new EligibleCase(caseId1, "AU")},
                    new DataDownload {Case = new EligibleCase(caseId2, "US")},
                    new DataDownload {Case = new EligibleCase(caseId3, "BR")}
                };

                var fileCases = new[]
                {
                    new FileCase
                    {
                        Id = parentPctCaseId1.ToString(),
                        Countries = new List<Country>
                        {
                            new Country("AU")
                        }
                    },
                    new FileCase
                    {
                        Id = parentPctCaseId2.ToString(),
                        Countries = new List<Country>
                        {
                            new Country("US")
                        }
                    }
                };

                var fixture = new DownloadRequiredFixture();

                fixture.BufferedStringReader.Read(dataPath)
                       .Returns(JsonConvert.SerializeObject(dataDownloads));

                fixture.BufferedStringReader.Read(fileCasePath)
                       .Returns(JsonConvert.SerializeObject(fileCases));

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               CaseId = caseId1,
                               CountryCode = "AU",
                               ParentCaseId = parentPctCaseId1
                           },
                           new FileInstructAllowedCase
                           {
                               CaseId = caseId2,
                               CountryCode = "US",
                               ParentCaseId = parentPctCaseId1
                           },
                           new FileInstructAllowedCase
                           {
                               CaseId = caseId3,
                               CountryCode = "BR",
                               ParentCaseId = parentPctCaseId2
                           }
                       }.AsQueryable());

                var r = (ActivityGroup) await fixture.Subject.FromTheIPPlatform(dataPath, fileCasePath);

                Assert.Equal(2, r.Items.Count());

                Assert.Equal("DetailsUnavailableOrInvalid.Handle", ((SingleActivity) r.Items.First()).TypeAndMethod());
                Assert.Equal(new[] {caseId2, caseId3}, ((SingleActivity) r.Items.First()).Arguments[1]);
                Assert.Equal("DownloadedCase.Process", ((SingleActivity) r.Items.Last()).TypeAndMethod());
            }
        }

        public class DownloadRequiredFixture : IFixture<DownloadRequired>
        {
            public DownloadRequiredFixture()
            {
                BufferedStringReader = Substitute.For<IBufferedStringReader>();

                FileInstructAllowedCases = Substitute.For<IFileInstructAllowedCases>();

                FileSettingsResolver = Substitute.For<IFileSettingsResolver>();

                Subject = new DownloadRequired(BufferedStringReader, FileSettingsResolver, FileInstructAllowedCases);
            }

            public IBufferedStringReader BufferedStringReader { get; set; }

            public IFileSettingsResolver FileSettingsResolver { get; set; }

            public IFileInstructAllowedCases FileInstructAllowedCases { get; set; }

            public DownloadRequired Subject { get; }
        }
    }
}