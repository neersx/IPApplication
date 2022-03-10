using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Components.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.IPPlatform.FileApp
{
    public class FileIntegrationFacts
    {
        public class InstructAllowedForMethod : FactBase
        {
            [Fact]
            public async Task ReturnsDetailsForDirectCase()
            {
                var fixture = new FileIntegrationFixture(Db);

                var parent = Fixture.Integer();
                var child = Fixture.Integer();

                fixture.FileAgents
                       .FilesInJuridictions()
                       .Returns(new[] {"AU"}.AsQueryable());

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               ParentCaseId = parent,
                               CaseId = child,
                               Filed = true,
                               CountryCode = "AU"
                           }
                       }.AsDbAsyncEnumerble());

                var r = await fixture.Subject.InstructAllowedFor(child, new FileSettings());

                Assert.True(r.CanView);
                Assert.True(r.CanInstruct);
                Assert.Equal("AU", r.CountryCode);
                Assert.Equal(parent, r.ParentCaseId);
            }

            [Fact]
            public async Task ReturnsDetailsForParentCase()
            {
                var fixture = new FileIntegrationFixture(Db);

                var parent = Fixture.Integer();
                var child1 = Fixture.Integer();
                var child2 = Fixture.Integer();

                fixture.FileAgents
                       .FilesInJuridictions()
                       .Returns(new[] {"AU", "CA"}.AsQueryable());

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               ParentCaseId = parent,
                               CaseId = child1,
                               Filed = false,
                               CountryCode = "AU"
                           },
                           new FileInstructAllowedCase
                           {
                               ParentCaseId = parent,
                               CaseId = child2,
                               Filed = true,
                               CountryCode = "CA"
                           }
                       }.AsDbAsyncEnumerble());

                var r = await fixture.Subject.InstructAllowedFor(parent, new FileSettings());

                Assert.True(r.CanView);
                Assert.False(r.CanInstruct);
                Assert.Equal(parent, r.ParentCaseId);
                Assert.Null(r.CountryCode);
            }

            [Fact]
            public async Task ReturnsErrorIfSettingsNotSent()
            {
                var fixture = new FileIntegrationFixture(Db);

                await Assert.ThrowsAsync<ArgumentNullException>(async () => await fixture.Subject.InstructAllowedFor(1, null));
            }

            [Fact]
            public async Task ReturnsNotAllowedIfCaseNotFound()
            {
                var fixture = new FileIntegrationFixture(Db);

                var parent = Fixture.Integer();

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new FileInstructAllowedCase[] { }
                                    .AsDbAsyncEnumerble());

                var r = await fixture.Subject.InstructAllowedFor(parent, new FileSettings());

                Assert.False(r.CanView);
                Assert.False(r.CanInstruct);
                Assert.Null(r.ParentCaseId);
                Assert.Null(r.CountryCode);
            }

            [Fact]
            public async Task ReturnsNotAllowedIfMoreThanOneDirectCase()
            {
                var fixture = new FileIntegrationFixture(Db);

                var parent = Fixture.Integer();
                var child = Fixture.Integer();

                fixture.FileAgents
                       .FilesInJuridictions()
                       .Returns(new[] {"AU", "CA"}.AsQueryable());

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               ParentCaseId = parent,
                               CaseId = child,
                               Filed = false,
                               CountryCode = "AU"
                           },
                           new FileInstructAllowedCase
                           {
                               ParentCaseId = parent,
                               CaseId = child,
                               Filed = true,
                               CountryCode = "CA"
                           }
                       }.AsDbAsyncEnumerble());

                var r = await fixture.Subject.InstructAllowedFor(child, new FileSettings());

                Assert.False(r.CanView);
                Assert.False(r.CanInstruct);
                Assert.Null(r.CountryCode);
                Assert.Null(r.ParentCaseId);
            }

            [Fact]
            public async Task ReturnsNotAllowedIfNoChildCasesFiled()
            {
                var fixture = new FileIntegrationFixture(Db);

                var parent = Fixture.Integer();
                var child1 = Fixture.Integer();
                var child2 = Fixture.Integer();

                fixture.FileAgents
                       .FilesInJuridictions()
                       .Returns(new[] {"AU", "CA"}.AsQueryable());

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               ParentCaseId = parent,
                               CaseId = child1,
                               Filed = false,
                               CountryCode = "AU"
                           },
                           new FileInstructAllowedCase
                           {
                               ParentCaseId = parent,
                               CaseId = child2,
                               Filed = false,
                               CountryCode = "CA"
                           }
                       }.AsDbAsyncEnumerble());

                var r = await fixture.Subject.InstructAllowedFor(parent, new FileSettings());

                Assert.False(r.CanView);
                Assert.False(r.CanInstruct);
                Assert.Equal(parent, r.ParentCaseId);
                Assert.Null(r.CountryCode);
            }
        }

        public class FiledChildCasesMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnFiledCases()
            {
                var fixture = new FileIntegrationFixture(Db);

                var pctParent = Fixture.Integer();
                var allowed1 = Fixture.Integer();
                var allowed2 = Fixture.Integer();
                var allowed3 = Fixture.Integer();

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(
                                new[]
                                {
                                    new FileInstructAllowedCase
                                    {
                                        ParentCaseId = pctParent,
                                        CaseId = allowed1,
                                        Filed = true
                                    },
                                    new FileInstructAllowedCase
                                    {
                                        ParentCaseId = pctParent,
                                        CaseId = allowed2,
                                        Filed = true
                                    },
                                    new FileInstructAllowedCase
                                    {
                                        ParentCaseId = pctParent,
                                        CaseId = allowed3,
                                        Filed = true
                                    }
                                }.AsDbAsyncEnumerble());

                var r = await fixture.Subject.FiledChildCases(pctParent, new FileSettings());

                Assert.Equal(new[] {allowed1, allowed2, allowed3}, r.FiledCaseIds);
                Assert.Equal(pctParent, r.ParentCaseId);
            }

            [Fact]
            public async Task ShouldReturnNoCasesIdNoFiledCases()
            {
                var fixture = new FileIntegrationFixture(Db);

                var pctParent = Fixture.Integer();
                var allowed1 = Fixture.Integer();

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(
                                new[]
                                {
                                    new FileInstructAllowedCase
                                    {
                                        ParentCaseId = pctParent,
                                        CaseId = allowed1,
                                        Filed = false
                                    }
                                }.AsDbAsyncEnumerble());

                var r = await fixture.Subject.FiledChildCases(pctParent, new FileSettings());

                Assert.Empty(r.FiledCaseIds);
                Assert.Equal(pctParent, r.ParentCaseId);
            }
        }

        public class InstructAllowedChildCasesMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnAllowedCases()
            {
                var fixture = new FileIntegrationFixture(Db);

                var pctParent = Fixture.Integer();
                var allowed1 = Fixture.Integer();
                var allowed2 = Fixture.Integer();
                var allowed3 = Fixture.Integer();

                fixture.FileAgents
                       .FilesInJuridictions()
                       .Returns(new[] {"US", "BR", "AU"}.AsQueryable());

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(
                                new[]
                                {
                                    new FileInstructAllowedCase
                                    {
                                        ParentCaseId = pctParent,
                                        CaseId = allowed1,
                                        Filed = false,
                                        CountryCode = "US"
                                    },
                                    new FileInstructAllowedCase
                                    {
                                        ParentCaseId = pctParent,
                                        CaseId = allowed2,
                                        Filed = false,
                                        CountryCode = "AU"
                                    },
                                    new FileInstructAllowedCase
                                    {
                                        ParentCaseId = pctParent,
                                        CaseId = allowed3,
                                        Filed = false,
                                        CountryCode = "BR"
                                    }
                                }.AsDbAsyncEnumerble());

                var r = await fixture.Subject.InstructAllowedChildCases(pctParent, new FileSettings());

                Assert.True(r.IsEnabled);
                Assert.Equal(new[] {allowed1, allowed2, allowed3}, r.CaseIds);
                Assert.Equal(pctParent, r.ParentCaseId);
            }

            [Fact]
            public async Task ShouldReturnNotEnabledWhenCaseRequestedIsNotAllowed()
            {
                var fixture = new FileIntegrationFixture(Db);

                fixture.FileAgents
                       .FilesInJuridictions()
                       .Returns(new[] {"US"}.AsQueryable());

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(
                                new[]
                                {
                                    new FileInstructAllowedCase
                                    {
                                        Filed = false,
                                        CountryCode = "US"
                                    }
                                }.AsDbAsyncEnumerble());

                var r = await fixture.Subject.InstructAllowedChildCases(Fixture.Integer(), new FileSettings());

                Assert.False(r.IsEnabled);
            }

            [Fact]
            public async Task ShouldReturnNotEnabledWhenNoFileAgentCanFileInThatJurisdiction()
            {
                var fixture = new FileIntegrationFixture(Db);

                var pctParent = Fixture.Integer();
                var allowed1 = Fixture.Integer();
                var allowed2 = Fixture.Integer();
                var disallowed1 = Fixture.Integer();

                fixture.FileAgents
                       .FilesInJuridictions()
                       .Returns(new[] {"US", "AU"}.AsQueryable());

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(
                                new[]
                                {
                                    new FileInstructAllowedCase
                                    {
                                        ParentCaseId = pctParent,
                                        CaseId = allowed1,
                                        Filed = false,
                                        CountryCode = "US"
                                    },
                                    new FileInstructAllowedCase
                                    {
                                        ParentCaseId = pctParent,
                                        CaseId = allowed2,
                                        Filed = false,
                                        CountryCode = "AU"
                                    },
                                    new FileInstructAllowedCase
                                    {
                                        ParentCaseId = pctParent,
                                        CaseId = disallowed1,
                                        Filed = false,
                                        CountryCode = "BR"
                                    }
                                }.AsDbAsyncEnumerble());

                var r = await fixture.Subject.InstructAllowedChildCases(pctParent, new FileSettings());

                Assert.True(r.IsEnabled);
                Assert.Equal(new[] {allowed1, allowed2}, r.CaseIds);
                Assert.Equal(pctParent, r.ParentCaseId);
            }

            [Fact]
            public async Task ShouldReturnNotEnabledWhenThereAreNothingToBeFiled()
            {
                var fixture = new FileIntegrationFixture(Db);

                fixture.FileAgents
                       .FilesInJuridictions()
                       .Returns(new[] {"US", "BR", "AU"}.AsQueryable());

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(
                                new[]
                                {
                                    new FileInstructAllowedCase
                                    {
                                        Filed = true,
                                        CountryCode = "US"
                                    },
                                    new FileInstructAllowedCase
                                    {
                                        Filed = true,
                                        CountryCode = "BR"
                                    },
                                    new FileInstructAllowedCase
                                    {
                                        Filed = true,
                                        CountryCode = "AU"
                                    }
                                }.AsDbAsyncEnumerble());

                var r = await fixture.Subject.InstructAllowedChildCases(Fixture.Integer(), new FileSettings());

                Assert.False(r.IsEnabled);
            }
        }

        public class InstructFilingMethod : FactBase
        {
            [Theory]
            [InlineData(IpTypes.DirectPatent)]
            [InlineData(IpTypes.TrademarkDirect)]
            public async Task ShouldCaseWithEarliestPriority(string ipType)
            {
                var fixture = new FileIntegrationFixture(Db);

                var earliestParentCaseId = Fixture.Integer();

                var caseId = new CaseBuilder().Build().In(Db).Id;

                fixture.FileSettingsResolver.Resolve()
                       .Returns(new FileSettings
                       {
                           IsEnabled = true
                       });

                fixture.FileAgents.TryGetAgentId(Arg.Any<int>(), out _)
                       .Returns(x =>
                       {
                           x[1] = Fixture.String();
                           return true;
                       });

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               CaseId = caseId,
                               IpType = ipType,
                               EarliestPriority = Fixture.Today(),
                               ParentCaseId = Fixture.Integer()
                           },
                           new FileInstructAllowedCase
                           {
                               CaseId = caseId,
                               IpType = ipType,
                               EarliestPriority = Fixture.FutureDate(),
                               ParentCaseId = Fixture.Integer()
                           },
                           new FileInstructAllowedCase
                           {
                               CaseId = caseId,
                               IpType = ipType,
                               EarliestPriority = Fixture.PastDate(),
                               ParentCaseId = earliestParentCaseId
                           }
                       }.AsDbAsyncEnumerble());

                fixture.FileApi.UpdateCountrySelection(Arg.Any<FileSettings>(),
                                                       Arg.Is<FileCaseModel>(_ => _.ParentCaseId == earliestParentCaseId.ToString()))
                       .Returns((new InstructResult(), new FileCase()));

                var r = await fixture.Subject.InstructFiling(caseId);

                Assert.Null(r.ErrorCode);
            }

            [Fact]
            public async Task ShouldReturnCaseAlreadyFiledIfThatIsTheCase()
            {
                var fixture = new FileIntegrationFixture(Db);

                var caseId = new CaseBuilder().Build().In(Db).Id;

                fixture.FileSettingsResolver.Resolve()
                       .Returns(new FileSettings
                       {
                           IsEnabled = true
                       });

                fixture.FileAgents.TryGetAgentId(Arg.Any<int>(), out _)
                       .Returns(x =>
                       {
                           x[1] = Fixture.String();
                           return true;
                       });

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               CaseId = caseId,
                               IpType = IpTypes.PatentPostPct,
                               Filed = true
                           }
                       }.AsDbAsyncEnumerble());

                var r = await fixture.Subject.InstructFiling(caseId);

                Assert.Equal(ErrorCodes.CaseAlreadyFiled, r.ErrorCode);
            }

            [Fact]
            public async Task ShouldReturnErrorCodeFromFileWithoutUpdatingStatus()
            {
                var pctParent = Fixture.Integer();
                var errorResult = new InstructResult
                {
                    ErrorCode = Fixture.String()
                };

                var fixture = new FileIntegrationFixture(Db);
                var caseId = new CaseBuilder().Build().In(Db).Id;

                fixture.FileSettingsResolver.Resolve()
                       .Returns(new FileSettings
                       {
                           IsEnabled = true
                       });

                fixture.FileAgents.TryGetAgentId(Arg.Any<int>(), out _)
                       .Returns(x =>
                       {
                           x[1] = Fixture.String();
                           return true;
                       });

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               ParentCaseId = pctParent,
                               CaseId = caseId,
                               IpType = IpTypes.PatentPostPct,
                               Filed = false
                           }
                       }.AsDbAsyncEnumerble());

                fixture.FileApi.UpdateCountrySelection(Arg.Any<FileSettings>(), Arg.Any<FileCaseModel>())
                       .Returns((errorResult, new FileCase()));

                var r = await fixture.Subject.InstructFiling(caseId);

                Assert.Equal(errorResult.ErrorCode, r.ErrorCode);

                fixture.FileIntegrationStatus
                       .DidNotReceiveWithAnyArgs()
                       .Update(null, null, null)
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldReturnErrorWhenNoSuitableFileAgentForTheJurisdiction()
            {
                var fixture = new FileIntegrationFixture(Db);

                var caseId = new CaseBuilder().Build().In(Db).Id;

                fixture.FileSettingsResolver.Resolve()
                       .Returns(new FileSettings
                       {
                           IsEnabled = true
                       });

                fixture.FileAgents.TryGetAgentId(Arg.Any<int>(), out _)
                       .Returns(x =>
                       {
                           x[1] = Fixture.String();
                           return false;
                       });

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               CaseId = caseId,
                               IpType = IpTypes.PatentPostPct,
                               CountryCode = "US",
                               Filed = false
                           }
                       }.AsDbAsyncEnumerble());

                var r = await fixture.Subject.InstructFiling(caseId);

                Assert.Equal(ErrorCodes.IneligibleFileAgent, r.ErrorCode);
            }

            [Fact]
            public async Task ShouldReturnInvalidCaseIfCaseNotValidTobeFiled()
            {
                var fixture = new FileIntegrationFixture(Db);

                fixture.FileSettingsResolver.Resolve()
                       .Returns(new FileSettings
                       {
                           IsEnabled = true
                       });

                fixture.FileAgents.TryGetAgentId(Arg.Any<int>(), out _)
                       .Returns(x =>
                       {
                           x[1] = Fixture.String();
                           return true;
                       });

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               CaseId = 1 // requested case not in this collection.
                           }
                       }.AsDbAsyncEnumerble());

                var r = await fixture.Subject.InstructFiling(2);

                Assert.Equal(ErrorCodes.InvalidCaseForFiling, r.ErrorCode);
            }

            [Fact]
            public async Task ShouldReturnUnmetRequirementsErrorIfNotEnabled()
            {
                var fixture = new FileIntegrationFixture(Db);

                fixture.FileSettingsResolver.Resolve().Returns(new FileSettings
                {
                    IsEnabled = false
                });

                var r = await fixture.Subject.InstructFiling(Fixture.Integer());

                Assert.Equal(ErrorCodes.RequirementsUnmet, r.ErrorCode);
            }

            [Fact]
            public async Task ShouldUpdateCountrySelection()
            {
                var pctParent = Fixture.Integer();
                var agentId = Fixture.String();
                var country = Fixture.String();
                var fixture = new FileIntegrationFixture(Db);
                var caseId = new CaseBuilder().Build().In(Db).Id;

                fixture.FileSettingsResolver.Resolve()
                       .Returns(new FileSettings
                       {
                           IsEnabled = true
                       });

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               ParentCaseId = pctParent,
                               CaseId = caseId,
                               CountryCode = country,
                               IpType = IpTypes.PatentPostPct,
                               Filed = false
                           }
                       }.AsDbAsyncEnumerble());

                fixture.FileAgents
                       .TryGetAgentId(caseId, out _)
                       .Returns(x =>
                       {
                           x[1] = agentId;
                           return true;
                       });

                fixture.FileApi.UpdateCountrySelection(Arg.Any<FileSettings>(), Arg.Any<FileCaseModel>())
                       .Returns((new InstructResult(), new FileCase()));

                await fixture.Subject.InstructFiling(caseId);

                fixture.FileApi
                       .Received(1)
                       .UpdateCountrySelection(Arg.Any<FileSettings>(),
                                               Arg.Is<FileCaseModel>(
                                                                     _ => _.ParentCaseId == pctParent.ToString()
                                                                          && _.CountrySelections.Any(c => c.CaseId == caseId &&
                                                                                                          c.Code == country &&
                                                                                                          c.Agent == agentId))
                                              ).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldUpdateIntegrationStatus()
            {
                var pctParent = Fixture.Integer();
                var successResult = new InstructResult();
                var updatedFileCase = new FileCase();

                var fixture = new FileIntegrationFixture(Db);
                var caseId = new CaseBuilder().Build().In(Db).Id;

                fixture.FileSettingsResolver.Resolve()
                       .Returns(new FileSettings
                       {
                           IsEnabled = true
                       });

                fixture.FileAgents.TryGetAgentId(Arg.Any<int>(), out _)
                       .Returns(x =>
                       {
                           x[1] = Fixture.String();
                           return true;
                       });

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               ParentCaseId = pctParent,
                               IpType = IpTypes.PatentPostPct,
                               CaseId = caseId,
                               Filed = false
                           }
                       }.AsDbAsyncEnumerble());

                fixture.FileApi.UpdateCountrySelection(Arg.Any<FileSettings>(), Arg.Any<FileCaseModel>())
                       .Returns((successResult, updatedFileCase));

                var r = await fixture.Subject.InstructFiling(caseId);

                Assert.Equal(successResult, r);

                fixture.FileIntegrationStatus
                       .Received(1)
                       .Update(Arg.Any<FileSettings>(), Arg.Any<FileCaseModel>(), updatedFileCase)
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class InstructFilingsMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnCaseAlreadyFiledIfThatIsTheCase()
            {
                var pctParent = Fixture.Integer();
                var countryCodeCsv = Fixture.String();
                var fixture = new FileIntegrationFixture(Db);

                var caseId = new CaseBuilder().Build().In(Db).Id;
                fixture.FileSettingsResolver.Resolve().Returns(new FileSettings
                {
                    IsEnabled = true
                });

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               ParentCaseId = pctParent,
                               CaseId = caseId,
                               CountryCode = countryCodeCsv,
                               Filed = true
                           }
                       }.AsDbAsyncEnumerble());

                var r = await fixture.Subject.InstructFilings(pctParent, countryCodeCsv);

                Assert.Equal(ErrorCodes.CaseAlreadyFiled, r.ErrorCode);
            }

            [Fact]
            public async Task ShouldReturnErrorCodeFromFileWithoutUpdatingStatus()
            {
                var countryCodeCsv = Fixture.String();
                var pctParent = Fixture.Integer();
                var errorResult = new InstructResult
                {
                    ErrorCode = Fixture.String()
                };

                var fixture = new FileIntegrationFixture(Db);
                var caseId = new CaseBuilder().Build().In(Db).Id;

                fixture.FileSettingsResolver.Resolve()
                       .Returns(new FileSettings
                       {
                           IsEnabled = true
                       });

                fixture.FileAgents.TryGetAgentId(Arg.Any<int>(), out _)
                       .Returns(x =>
                       {
                           x[1] = Fixture.String();
                           return true;
                       });

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               ParentCaseId = pctParent,
                               CaseId = caseId,
                               CountryCode = countryCodeCsv,
                               Filed = false
                           }
                       }.AsDbAsyncEnumerble());

                fixture.FileApi.UpdateCountrySelection(Arg.Any<FileSettings>(), Arg.Any<FileCaseModel>())
                       .Returns((errorResult, new FileCase()));

                var r = await fixture.Subject.InstructFilings(pctParent, countryCodeCsv);

                Assert.Equal(errorResult.ErrorCode, r.ErrorCode);

                fixture.FileIntegrationStatus
                       .DidNotReceiveWithAnyArgs()
                       .Update(null, null, null)
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldReturnErrorWhenNoSuitableFileAgentsAvailable()
            {
                var pctParent = Fixture.Integer();
                var country1 = Fixture.String();
                var country2 = Fixture.String();
                var caseId1 = new CaseBuilder().Build().In(Db).Id;
                var caseId2 = new CaseBuilder().Build().In(Db).Id;

                var countryCodeCsv = string.Join(",", country1, country2);
                var fixture = new FileIntegrationFixture(Db);

                fixture.FileSettingsResolver.Resolve()
                       .Returns(new FileSettings
                       {
                           IsEnabled = true
                       });

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               ParentCaseId = pctParent,
                               CaseId = caseId1,
                               CountryCode = country1
                           },
                           new FileInstructAllowedCase
                           {
                               ParentCaseId = pctParent,
                               CaseId = caseId2,
                               CountryCode = country2
                           }
                       }.AsDbAsyncEnumerble());

                fixture.FileApi.UpdateCountrySelection(Arg.Any<FileSettings>(), Arg.Any<FileCaseModel>())
                       .Returns((new InstructResult(), new FileCase()));

                fixture.FileAgents.TryGetAgentId(Arg.Any<int>(), out _)
                       .Returns(x =>
                       {
                           x[1] = Fixture.String();
                           return false;
                       });

                var r = await fixture.Subject.InstructFilings(pctParent, countryCodeCsv);

                Assert.Equal(ErrorCodes.IneligibleFileAgent, r.ErrorCode);
            }

            [Fact]
            public async Task ShouldReturnInvalidCaseIfCaseNotValidTobeFiled()
            {
                var fixture = new FileIntegrationFixture(Db);
                var pctParent = Fixture.Integer();
                var invalidCountryCode1 = Fixture.String();
                var invalidCountryCode2 = Fixture.String();
                var countryCodeCsv = string.Join(",", invalidCountryCode1, invalidCountryCode2);

                fixture.FileSettingsResolver.Resolve().Returns(new FileSettings
                {
                    IsEnabled = true
                });

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new FileInstructAllowedCase[0].AsDbAsyncEnumerble());

                var r = await fixture.Subject.InstructFilings(pctParent, countryCodeCsv);

                Assert.Equal(ErrorCodes.InvalidCaseForFiling, r.ErrorCode);
            }

            [Fact]
            public async Task ShouldReturnUnmetRequirementsErrorIfNotEnabled()
            {
                var fixture = new FileIntegrationFixture(Db);

                fixture.FileSettingsResolver.Resolve().Returns(new FileSettings
                {
                    IsEnabled = false
                });

                var r = await fixture.Subject.InstructFilings(Fixture.Integer(), Fixture.String());

                Assert.Equal(ErrorCodes.RequirementsUnmet, r.ErrorCode);
            }

            [Fact]
            public async Task ShouldUpdateCountrySelectionForeachCountry()
            {
                var pctParent = Fixture.Integer();
                var country1 = Fixture.String();
                var country2 = Fixture.String();
                var caseId1 = new CaseBuilder().Build().In(Db).Id;
                var caseId2 = new CaseBuilder().Build().In(Db).Id;

                var countryCodeCsv = string.Join(",", country1, country2);
                var fixture = new FileIntegrationFixture(Db);

                fixture.FileSettingsResolver.Resolve().Returns(new FileSettings
                {
                    IsEnabled = true
                });

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               ParentCaseId = pctParent,
                               CaseId = caseId1,
                               CountryCode = country1
                           },
                           new FileInstructAllowedCase
                           {
                               ParentCaseId = pctParent,
                               CaseId = caseId2,
                               CountryCode = country2
                           }
                       }.AsDbAsyncEnumerble());

                fixture.FileApi.UpdateCountrySelection(Arg.Any<FileSettings>(), Arg.Any<FileCaseModel>())
                       .Returns((new InstructResult(), new FileCase()));

                fixture.FileAgents.TryGetAgentId(Arg.Any<int>(), out _)
                       .Returns(x =>
                       {
                           x[1] = Fixture.String();
                           return true;
                       });

                await fixture.Subject.InstructFilings(pctParent, countryCodeCsv);

                fixture.FileApi
                       .Received(1)
                       .UpdateCountrySelection(Arg.Any<FileSettings>(), Arg.Any<FileCaseModel>()).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldUpdateCountrySelectionForJurisdictionsWithKnownFileAgent()
            {
                var pctParent = Fixture.Integer();
                var country1 = Fixture.String();
                var country2 = Fixture.String();
                var caseId1 = new CaseBuilder().Build().In(Db).Id;
                var caseId2 = new CaseBuilder().Build().In(Db).Id;

                var countryCodeCsv = string.Join(",", country1, country2);
                var fixture = new FileIntegrationFixture(Db);

                fixture.FileSettingsResolver.Resolve()
                       .Returns(new FileSettings
                       {
                           IsEnabled = true
                       });

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               ParentCaseId = pctParent,
                               CaseId = caseId1,
                               CountryCode = country1
                           },
                           new FileInstructAllowedCase
                           {
                               ParentCaseId = pctParent,
                               CaseId = caseId2,
                               CountryCode = country2
                           }
                       }.AsDbAsyncEnumerble());

                fixture.FileApi.UpdateCountrySelection(Arg.Any<FileSettings>(), Arg.Any<FileCaseModel>())
                       .Returns((new InstructResult(), new FileCase()));

                fixture.FileAgents.TryGetAgentId(caseId1, out _)
                       .Returns(x =>
                       {
                           x[1] = Fixture.String();
                           return true;
                       });

                fixture.FileAgents.TryGetAgentId(caseId2, out _)
                       .Returns(x =>
                       {
                           x[1] = Fixture.String();
                           return false;
                       });

                await fixture.Subject.InstructFilings(pctParent, countryCodeCsv);

                fixture.FileApi
                       .Received(1)
                       .UpdateCountrySelection(Arg.Any<FileSettings>(),
                                               Arg.Is<FileCaseModel>(
                                                                     _ => _.ParentCaseId == pctParent.ToString()
                                                                          && _.CountrySelections.Any(c => c.CaseId == caseId1 &&
                                                                                                          c.Code == country1))
                                              ).IgnoreAwaitForNSubstituteAssertion();

                fixture.FileApi
                       .DidNotReceive()
                       .UpdateCountrySelection(Arg.Any<FileSettings>(),
                                               Arg.Is<FileCaseModel>(
                                                                     _ => _.ParentCaseId == pctParent.ToString()
                                                                          && _.CountrySelections.Any(c => c.CaseId == caseId2 &&
                                                                                                          c.Code == country2))
                                              ).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldUpdateIntegrationStatus()
            {
                var caseId = new CaseBuilder().Build().In(Db).Id;
                var pctParent = Fixture.Integer();
                var countryCodeCsv = Fixture.String();
                var successResult = new InstructResult();
                var updatedFileCase = new FileCase();

                var fixture = new FileIntegrationFixture(Db);

                fixture.FileSettingsResolver.Resolve()
                       .Returns(new FileSettings
                       {
                           IsEnabled = true
                       });

                fixture.FileAgents.TryGetAgentId(Arg.Any<int>(), out _)
                       .Returns(x =>
                       {
                           x[1] = Fixture.String();
                           return true;
                       });

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               ParentCaseId = pctParent,
                               CaseId = caseId,
                               CountryCode = countryCodeCsv
                           }
                       }.AsDbAsyncEnumerble());

                fixture.FileApi.UpdateCountrySelection(Arg.Any<FileSettings>(), Arg.Any<FileCaseModel>())
                       .Returns((successResult, updatedFileCase));

                var r = await fixture.Subject.InstructFilings(pctParent, countryCodeCsv);

                Assert.Null(r.ErrorCode);

                fixture.FileIntegrationStatus
                       .Received(1)
                       .Update(Arg.Any<FileSettings>(), Arg.Any<FileCaseModel>(), updatedFileCase)
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class ViewFilingMethod : FactBase
        {
            [Fact]
            public async Task ShouldCallFileApiToGetViewLinkForChildCase()
            {
                var pctCaseId = Fixture.Integer();
                var parentCaseId = pctCaseId + 1;

                var fixture = new FileIntegrationFixture(Db);
                const string viewUrl = "http://www.SomeUrl.com";

                fixture.FileApi.GetViewLink(Arg.Any<FileSettings>(), Arg.Any<FileInstructAllowedCase>())
                       .Returns(InstructResult.Progress(viewUrl));

                fixture.FileAgents
                       .FilesInJuridictions()
                       .Returns(new[] {"AU"}.AsQueryable());

                fixture.FileSettingsResolver.Resolve()
                       .Returns(new FileSettings
                       {
                           IsEnabled = true
                       });

                var directCase = new FileInstructAllowedCase
                {
                    CaseId = pctCaseId,
                    ParentCaseId = parentCaseId,
                    CountryCode = "AU"
                };

                fixture.FileInstructAllowedCases
                       .Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[] {directCase}.AsDbAsyncEnumerble());

                var r = await fixture.Subject.ViewFiling(pctCaseId);

                fixture.FileApi.Received(1).GetViewLink(Arg.Any<FileSettings>(), directCase).IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(new Uri(viewUrl).ToString(), r.ProgressUri.ToString());
            }

            [Fact]
            public async Task ShouldCallFileApiToGetViewLinkForChildCaseFirst()
            {
                var pctCaseId = Fixture.Integer();
                var parentCaseId = pctCaseId + 1;

                var fixture = new FileIntegrationFixture(Db);
                const string viewUrl = "http://www.SomeUrl.com";

                fixture.FileApi.GetViewLink(Arg.Any<FileSettings>(), Arg.Any<FileInstructAllowedCase>())
                       .Returns(InstructResult.Progress(viewUrl));

                fixture.FileAgents
                       .FilesInJuridictions()
                       .Returns(new[] {"AU"}.AsQueryable());

                fixture.FileSettingsResolver.Resolve()
                       .Returns(new FileSettings
                       {
                           IsEnabled = true
                       });

                var directCase = new FileInstructAllowedCase
                {
                    CaseId = pctCaseId,
                    ParentCaseId = parentCaseId,
                    CountryCode = "AU"
                };

                var parentCase = new FileInstructAllowedCase
                {
                    ParentCaseId = pctCaseId
                };

                fixture.FileInstructAllowedCases
                       .Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[] {parentCase, directCase}.AsDbAsyncEnumerble());

                var r = await fixture.Subject.ViewFiling(pctCaseId);

                fixture.FileApi.Received(1).GetViewLink(Arg.Any<FileSettings>(), directCase).IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(new Uri(viewUrl).ToString(), r.ProgressUri.ToString());
            }

            [Fact]
            public async Task ShouldCallFileApiToGetViewLinkForFiledChildCase()
            {
                var pctCaseId = Fixture.Integer();
                var parentCaseId = pctCaseId + 1;

                var fixture = new FileIntegrationFixture(Db);
                const string viewUrl = "http://www.SomeUrl.com";

                fixture.FileApi.GetViewLink(Arg.Any<FileSettings>(), Arg.Any<FileInstructAllowedCase>())
                       .Returns(InstructResult.Progress(viewUrl));

                fixture.FileAgents
                       .FilesInJuridictions()
                       .Returns(new[] {"AU", "US"}.AsQueryable());

                fixture.FileSettingsResolver.Resolve().Returns(new FileSettings
                {
                    IsEnabled = true
                });

                var directCaseNotYetFiled = new FileInstructAllowedCase
                {
                    CaseId = pctCaseId,
                    ParentCaseId = parentCaseId,
                    CountryCode = "AU"
                };

                var directCaseAlreadyFiled = new FileInstructAllowedCase
                {
                    CaseId = pctCaseId,
                    ParentCaseId = parentCaseId,
                    CountryCode = "US",
                    Filed = true
                };

                fixture.FileInstructAllowedCases
                       .Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[] {directCaseNotYetFiled, directCaseAlreadyFiled}.AsDbAsyncEnumerble());

                var r = await fixture.Subject.ViewFiling(pctCaseId);

                fixture.FileApi.Received(1).GetViewLink(Arg.Any<FileSettings>(), directCaseAlreadyFiled).IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(new Uri(viewUrl).ToString(), r.ProgressUri.ToString());
            }

            [Fact]
            public async Task ShouldCallFileApiToGetViewLinkForParentCase()
            {
                var pctCaseId = Fixture.Integer();
                var fixture = new FileIntegrationFixture(Db);
                var viewUrl = "http://www.SomeUrl.com";

                fixture.FileApi.GetViewLink(Arg.Any<FileSettings>(), Arg.Any<int>())
                       .Returns(InstructResult.Progress(viewUrl));

                fixture.FileAgents
                       .FilesInJuridictions()
                       .Returns(new[] {"US"}.AsQueryable());

                fixture.FileSettingsResolver.Resolve()
                       .Returns(new FileSettings
                       {
                           IsEnabled = true
                       });

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               ParentCaseId = pctCaseId,
                               CountryCode = "US"
                           }
                       }.AsDbAsyncEnumerble());

                var r = await fixture.Subject.ViewFiling(pctCaseId);

                fixture.FileApi.Received(1).GetViewLink(Arg.Any<FileSettings>(), pctCaseId).IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(new Uri(viewUrl).ToString(), r.ProgressUri.ToString());
            }

            [Fact]
            public async Task ShouldReturnInvalidCaseIfCaseNotValid()
            {
                var fixture = new FileIntegrationFixture(Db);

                fixture.FileSettingsResolver.Resolve()
                       .Returns(new FileSettings
                       {
                           IsEnabled = true
                       });

                fixture.FileAgents
                       .FilesInJuridictions()
                       .Returns(new[] {"US"}.AsQueryable());

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               CaseId = 1, // requested case not in this collection.
                               CountryCode = "US"
                           }
                       }.AsDbAsyncEnumerble());

                var r = await fixture.Subject.ViewFiling(2);

                Assert.Equal(ErrorCodes.CaseNotInFile, r.ErrorCode);
            }

            [Fact]
            public async Task ShouldReturnUnmetRequirementsErrorIfNotEnabled()
            {
                var fixture = new FileIntegrationFixture(Db);

                fixture.FileSettingsResolver.Resolve().Returns(new FileSettings
                {
                    IsEnabled = false
                });

                var r = await fixture.Subject.ViewFiling(Fixture.Integer());

                Assert.Equal(ErrorCodes.RequirementsUnmet, r.ErrorCode);
            }
        }

        public class FileIntegrationFixture : IFixture<FileIntegration>
        {
            public FileIntegrationFixture(InMemoryDbContext db)
            {
                MultipleClassApplicationCountries = Substitute.For<IMultipleClassApplicationCountries>();

                FileIntegrationStatus = Substitute.For<IFileIntegrationStatus>();

                FileAgents = Substitute.For<IFileAgents>();

                FileInstructAllowedCases = Substitute.For<IFileInstructAllowedCases>();

                FileSettingsResolver = Substitute.For<IFileSettingsResolver>();

                FileApi = Substitute.For<IFileApi>();

                Subject = new FileIntegration(FileSettingsResolver, FileInstructAllowedCases, MultipleClassApplicationCountries, FileApi, FileAgents, FileIntegrationStatus, db);
            }

            public IMultipleClassApplicationCountries MultipleClassApplicationCountries { get; set; }

            public IFileInstructAllowedCases FileInstructAllowedCases { get; set; }

            public IFileAgents FileAgents { get; set; }

            public IFileApi FileApi { get; set; }

            public IFileIntegrationStatus FileIntegrationStatus { get; set; }

            public IFileSettingsResolver FileSettingsResolver { get; set; }

            public FileIntegration Subject { get; }
        }
    }
}