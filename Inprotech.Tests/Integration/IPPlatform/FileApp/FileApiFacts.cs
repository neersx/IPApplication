using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Integration.IPPlatform.FileApp.Builders;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using Inprotech.Integration.IPPlatform.FileApp.Post;
using Inprotech.Integration.IPPlatform.FileApp.Validators;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;
using FileCaseEntity = InprotechKaizen.Model.Integration.FileCase;

namespace Inprotech.Tests.Integration.IPPlatform.FileApp
{
    public class FileApiFacts
    {
        public class UpdateCountrySelectionMethod : FactBase
        {
            readonly FileSettings _settings = new FileSettings
            {
                ApiBase = "http://ipplatform.com/fapi/api/v1"
            };

            readonly IFileApiClient _apiClient = Substitute.For<IFileApiClient>();
            readonly IFileCaseBuilder _priorityCaseBuilder = Substitute.For<IFileCaseBuilder>();
            readonly IFileCaseValidator _fileCaseValidator = Substitute.For<IFileCaseValidator>();
            readonly IPostInstructionCreationTasks _postInstructionCreationTasks = Substitute.For<IPostInstructionCreationTasks>();

            readonly Link[] _successLinks =
            {
                new Link
                {
                    Href = "http://ipplatform.com/wizard/agents",
                    Rel = "wizard"
                }
            };

            IFileApi CreateSubject()
            {
                var builders = Substitute.For<IIndex<string, IFileCaseBuilder>>();
                var validators = Substitute.For<IIndex<string, IFileCaseValidator>>();
                var tasks = Substitute.For<IIndex<string, IPostInstructionCreationTasks>>();

                builders[Arg.Any<string>()].Returns(_priorityCaseBuilder);
                validators[Arg.Any<string>()].Returns(_fileCaseValidator);
                tasks.TryGetValue(Arg.Any<string>(), out _)
                     .Returns(x =>
                     {
                         x[1] = _postInstructionCreationTasks;
                         return true;
                     });

                _fileCaseValidator.TryValidate(Arg.Any<FileCase>(), out _)
                                  .Returns(x =>
                                  {
                                      x[1] = null;
                                      return true;
                                  });

                _fileCaseValidator.TryValidateCountrySelection(Arg.Any<FileCase>(), Arg.Any<IEnumerable<Country>>(), out _)
                                  .Returns(x =>
                                  {
                                      x[2] = null;
                                      return true;
                                  });

                return new FileApi(_apiClient, builders, validators, tasks, Db);
            }

            [Fact]
            public async Task ShouldBuildInprotechParentCaseToCreateInFile()
            {
                var pctParent = Fixture.String();
                var subject = CreateSubject();

                var builtFileCase = new FileCase
                {
                    BibliographicalInformation = new Biblio
                    {
                        ApplicationNumber = Fixture.String(),
                        ApplicationDate = Fixture.String()
                    }
                };

                _apiClient.Get<FileCase>(null).ReturnsForAnyArgs((FileCase) null); // 404

                _priorityCaseBuilder.Build(pctParent).Returns(builtFileCase);

                await subject.UpdateCountrySelection(_settings, new FileCaseModel
                {
                    ParentCaseId = pctParent,
                    IpType = IpTypes.PatentPostPct
                });

                _apiClient.Received(1).Post<FileCase>(new Uri("http://ipplatform.com/fapi/api/v1/cases"), builtFileCase)
                          .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldExecutePostCreationTaskFollowingSuccessfulCreation()
            {
                var trademarkPriorityCase = Fixture.String();
                var subject = CreateSubject();

                var builtTrademarkCase = new FileCase
                {
                    IpType = IpTypes.TrademarkDirect,
                    BibliographicalInformation = new Biblio
                    {
                        ApplicationNumber = Fixture.String(),
                        ApplicationDate = Fixture.String()
                    }
                };

                _apiClient.Get<FileCase>(null).ReturnsForAnyArgs((FileCase) null); // 404

                _priorityCaseBuilder.Build(trademarkPriorityCase).Returns(builtTrademarkCase);

                var resultFileCase = new FileCase
                {
                    Links = _successLinks
                };

                _apiClient.Post<FileCase>(null, null).ReturnsForAnyArgs(resultFileCase);

                var r = await subject.UpdateCountrySelection(_settings, new FileCaseModel
                {
                    ParentCaseId = trademarkPriorityCase
                });

                _postInstructionCreationTasks.Received(1)
                                             .Perform(Arg.Any<FileSettings>(), resultFileCase)
                                             .IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(new Uri("http://ipplatform.com/wizard/agents"), r.Result.ProgressUri);
            }

            [Fact]
            public async Task ShouldFindPctParentOrPriorityCaseToUpdateCountrySelection()
            {
                var pctParentOrPriorityCase = Fixture.String();
                var subject = CreateSubject();

                _apiClient.Get<FileCase>(null)
                          .ReturnsForAnyArgs(new FileCase
                          {
                              Links = _successLinks
                          });

                await subject.UpdateCountrySelection(_settings, new FileCaseModel
                {
                    ParentCaseId = pctParentOrPriorityCase
                });

                _apiClient.Received(1)
                          .Get<FileCase>(new Uri($"http://ipplatform.com/fapi/api/v1/cases/{pctParentOrPriorityCase}"))
                          .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldIncludePreviouslySelectedCountryIfStatusNotInstructed()
            {
                var pctParentOrPriorityCase = Fixture.String();
                var subject = CreateSubject();

                _apiClient.Get<FileCase>(null).ReturnsForAnyArgs(new FileCase
                {
                    Countries = new List<Country>
                    {
                        new Country
                        {
                            Code = "AU",
                            Ref = "1234/abcd"
                        }
                    },
                    Links = _successLinks
                });

                await subject.UpdateCountrySelection(_settings, new FileCaseModel
                {
                    ParentCaseId = pctParentOrPriorityCase,
                    CountrySelections = new[]
                    {
                        new CountrySelection
                        {
                            Code = "US"
                        }
                    }
                });

                _apiClient.Received(1)
                          .Put<IEnumerable<Country>>(new Uri($"http://ipplatform.com/fapi/api/v1/cases/{pctParentOrPriorityCase}/countries"),
                                                     Arg.Is<IEnumerable<Country>>(_ => _.Any(c => c.Code == "AU" && c.Ref == "1234/abcd") && _.Any(c => c.Code == "US")))
                          .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldIncludePreviouslySelectedCountryThatIsStillNotYetInstructedIfTheCaseHasStatusInstructed()
            {
                var pctParentOrPriorityCase = Fixture.String();
                var subject = CreateSubject();

                _apiClient.Get<IEnumerable<Instruction>>(null)
                          .ReturnsForAnyArgs(
                                             new[]
                                             {
                                                 new Instruction
                                                 {
                                                     CountryCode = "AU",
                                                     Status = "SENT"
                                                 },
                                                 new Instruction
                                                 {
                                                     CountryCode = "JP",
                                                     Status = "DRAFT"
                                                 }
                                             });

                _apiClient.Get<FileCase>(null)
                          .ReturnsForAnyArgs(new FileCase
                          {
                              Status = FileStatuses.Instructed,
                              Countries = new List<Country>
                              {
                                  new Country
                                  {
                                      Code = "AU"
                                  },
                                  new Country
                                  {
                                      Code = "JP"
                                  }
                              },
                              Links = _successLinks
                          });

                await subject.UpdateCountrySelection(_settings, new FileCaseModel
                {
                    ParentCaseId = pctParentOrPriorityCase,
                    CountrySelections = new[]
                    {
                        new CountrySelection
                        {
                            Code = "US"
                        }
                    }
                });

                _apiClient.Received(1)
                          .Put<IEnumerable<Country>>(new Uri($"http://ipplatform.com/fapi/api/v1/cases/{pctParentOrPriorityCase}/countries"),
                                                     Arg.Is<IEnumerable<Country>>(_ => _.Any(c => c.Code == "US") && _.Any(c => c.Code == "JP") && _.Count() == 2))
                          .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldNotExecutePostCreationTaskIfError()
            {
                var trademarkPriorityCase = Fixture.String();
                var subject = CreateSubject();

                var builtTrademarkCase = new FileCase
                {
                    BibliographicalInformation = new Biblio
                    {
                        ApplicationNumber = Fixture.String(),
                        ApplicationDate = Fixture.String()
                    }
                };

                _apiClient.Get<FileCase>(null).ReturnsForAnyArgs((FileCase) null); // 404

                _priorityCaseBuilder.Build(trademarkPriorityCase).Returns(builtTrademarkCase);

                _apiClient.Post<FileCase>(null, null).ReturnsForAnyArgs((FileCase) null);

                var r = await subject.UpdateCountrySelection(_settings, new FileCaseModel
                {
                    ParentCaseId = trademarkPriorityCase
                });

                _postInstructionCreationTasks.DidNotReceive()
                                             .Perform(Arg.Any<FileSettings>(), Arg.Any<FileCase>())
                                             .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldNotIncludePreviouslySelectedCountryIfStatusInstructed()
            {
                var pctParentOrPriorityCase = Fixture.String();
                var subject = CreateSubject();

                _apiClient.Get<IEnumerable<Instruction>>(null)
                          .ReturnsForAnyArgs(
                                             new[]
                                             {
                                                 new Instruction
                                                 {
                                                     CountryCode = "AU",
                                                     Status = "SENT"
                                                 }
                                             });

                _apiClient.Get<FileCase>(null)
                          .ReturnsForAnyArgs(new FileCase
                          {
                              Status = FileStatuses.Instructed,
                              Countries = new List<Country>
                              {
                                  new Country
                                  {
                                      Code = "AU"
                                  }
                              },
                              Links = _successLinks
                          });

                await subject.UpdateCountrySelection(_settings, new FileCaseModel
                {
                    ParentCaseId = pctParentOrPriorityCase,
                    CountrySelections = new[]
                    {
                        new CountrySelection
                        {
                            Code = "US"
                        }
                    }
                });

                _apiClient.Received(1)
                          .Put<IEnumerable<Country>>(new Uri($"http://ipplatform.com/fapi/api/v1/cases/{pctParentOrPriorityCase}/countries"),
                                                     Arg.Is<IEnumerable<Country>>(_ => _.Any(c => c.Code == "US") && _.Count() == 1))
                          .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldRelayProgressFromFile()
            {
                var pctParentOrPriorityCase = Fixture.String();
                var subject = CreateSubject();

                var builtPctFileCase = new FileCase
                {
                    BibliographicalInformation = new Biblio
                    {
                        ApplicationNumber = Fixture.String(),
                        ApplicationDate = Fixture.String()
                    }
                };

                _apiClient.Get<FileCase>(null).ReturnsForAnyArgs((FileCase) null); // 404

                _priorityCaseBuilder.Build(pctParentOrPriorityCase).Returns(builtPctFileCase);

                _apiClient.Post<FileCase>(null, null).ReturnsForAnyArgs(new FileCase
                {
                    Links = _successLinks
                });

                var r = await subject.UpdateCountrySelection(_settings, new FileCaseModel
                {
                    ParentCaseId = pctParentOrPriorityCase
                });

                Assert.Equal(new Uri("http://ipplatform.com/wizard/agents"), r.Result.ProgressUri);
            }

            [Fact]
            public async Task ShouldReturnErrorIfCaseCouldNotBeCreated()
            {
                var pctParentOrPriorityCase = Fixture.String();
                var subject = CreateSubject();

                var builtPctFileCase = new FileCase
                {
                    BibliographicalInformation = new Biblio
                    {
                        ApplicationNumber = Fixture.String(),
                        ApplicationDate = Fixture.String()
                    }
                };

                _apiClient.Get<FileCase>(null).ReturnsForAnyArgs((FileCase) null); // 404

                _priorityCaseBuilder.Build(pctParentOrPriorityCase).Returns(builtPctFileCase);

                _apiClient.Post<FileCase>(null, null).ReturnsForAnyArgs((FileCase) null);

                var r = await subject.UpdateCountrySelection(_settings, new FileCaseModel
                {
                    ParentCaseId = pctParentOrPriorityCase
                });

                Assert.Equal(ErrorCodes.UnableToAccessFile, r.Result.ErrorCode);
            }

            [Fact]
            public async Task ShouldReturnErrorWhenCountrySelectionValidationFailedAtCreation()
            {
                var pctParentOrPriorityCase = Fixture.String();
                var subject = CreateSubject();
                var errorCode = Fixture.String();
                var builtPctFileCase = new FileCase();

                _apiClient.Get<FileCase>(null).ReturnsForAnyArgs((FileCase) null); // 404

                _priorityCaseBuilder.Build(pctParentOrPriorityCase).Returns(builtPctFileCase);

                _fileCaseValidator.TryValidateCountrySelection(Arg.Any<FileCase>(), Arg.Any<IEnumerable<Country>>(), out var ir)
                                  .Returns(x =>
                                  {
                                      x[2] = InstructResult.Error(errorCode);
                                      return false;
                                  });

                var r = await subject.UpdateCountrySelection(_settings, new FileCaseModel
                {
                    ParentCaseId = pctParentOrPriorityCase
                });

                Assert.Equal(errorCode, r.Result.ErrorCode);
            }

            [Fact]
            public async Task ShouldReturnErrorWhenCountrySelectionValidationFailedAtUpdate()
            {
                var pctParentOrPriorityCase = Fixture.String();
                var subject = CreateSubject();
                var errorCode = Fixture.String();

                _apiClient.Get<FileCase>(null)
                          .ReturnsForAnyArgs(new FileCase
                          {
                              Status = FileStatuses.Instructed,
                              Countries = new List<Country>
                              {
                                  new Country
                                  {
                                      Code = "AU"
                                  }
                              },
                              Links = _successLinks
                          });

                _fileCaseValidator.TryValidateCountrySelection(Arg.Any<FileCase>(), Arg.Any<IEnumerable<Country>>(), out var ir)
                                  .Returns(x =>
                                  {
                                      x[2] = InstructResult.Error(errorCode);
                                      return false;
                                  });

                var r = await subject.UpdateCountrySelection(_settings, new FileCaseModel
                {
                    ParentCaseId = pctParentOrPriorityCase,
                    CountrySelections = new[]
                    {
                        new CountrySelection
                        {
                            Code = "US"
                        }
                    }
                });

                Assert.Equal(errorCode, r.Result.ErrorCode);
            }

            [Fact]
            public async Task ShouldReturnErrorWhenValidationFailed()
            {
                var pctParentOrPriorityCase = Fixture.String();
                var subject = CreateSubject();
                var errorCode = Fixture.String();
                var builtPctFileCase = new FileCase();

                _apiClient.Get<FileCase>(null).ReturnsForAnyArgs((FileCase) null); // 404

                _priorityCaseBuilder.Build(pctParentOrPriorityCase).Returns(builtPctFileCase);

                _fileCaseValidator.TryValidate(Arg.Any<FileCase>(), out var ir)
                                  .Returns(x =>
                                  {
                                      x[1] = InstructResult.Error(errorCode);
                                      return false;
                                  });

                var r = await subject.UpdateCountrySelection(_settings, new FileCaseModel
                {
                    ParentCaseId = pctParentOrPriorityCase
                });

                Assert.Equal(errorCode, r.Result.ErrorCode);
            }
        }

        public class GetViewLinkMethod : FactBase
        {
            readonly FileSettings _settings = new FileSettings
            {
                ApiBase = "http://ipplatform.com/fapi/api/v1"
            };

            readonly IFileApiClient _apiClient = Substitute.For<IFileApiClient>();
            readonly IFileCaseBuilder _pctParentOrPriorityCaseBuilder = Substitute.For<IFileCaseBuilder>();
            readonly IFileCaseValidator _fileCaseValidator = Substitute.For<IFileCaseValidator>();
            readonly IPostInstructionCreationTasks _postInstructionCreationTasks = Substitute.For<IPostInstructionCreationTasks>();

            readonly Link[] _successLinks =
            {
                new Link
                {
                    Href = "http://ipplatform.com/wizard/agents",
                    Rel = "wizard"
                }
            };

            IFileApi CreateSubject()
            {
                var builders = Substitute.For<IIndex<string, IFileCaseBuilder>>();
                var validators = Substitute.For<IIndex<string, IFileCaseValidator>>();
                var tasks = Substitute.For<IIndex<string, IPostInstructionCreationTasks>>();

                builders[Arg.Any<string>()].Returns(_pctParentOrPriorityCaseBuilder);
                validators[Arg.Any<string>()].Returns(_fileCaseValidator);
                tasks.TryGetValue(Arg.Any<string>(), out _)
                     .Returns(x =>
                     {
                         x[1] = _postInstructionCreationTasks;
                         return true;
                     });

                InstructResult r;
                _fileCaseValidator.TryValidate(Arg.Any<FileCase>(), out r)
                                  .Returns(x =>
                                  {
                                      x[1] = null;
                                      return true;
                                  });

                return new FileApi(_apiClient, builders, validators, tasks, Db);
            }

            readonly Link _wizardLink = new Link
            {
                Href = "http://ipplatform.com/wizard/agents",
                Rel = "wizard"
            };

            readonly Link _progressLink = new Link
            {
                Href = "http://ipplatform.com/progress/",
                Rel = "progress"
            };

            readonly Link _childProgressLink = new Link
            {
                Href = "http://ipplatform.com/progress/AU",
                Rel = "progress"
            };

            [Fact]
            public async Task ReturnsErrorIfChildCaseNotFoundInDb()
            {
                var childCase = new FileInstructAllowedCase
                {
                    ParentCaseId = Fixture.Integer(),
                    CaseId = Fixture.Integer(),
                    CountryCode = "AU",
                    IpType = "SomeIpType"
                };

                var subject = CreateSubject();

                var result = await subject.GetViewLink(_settings, childCase);
                Assert.Equal(ErrorCodes.CaseNotInFile, result.ErrorCode);
            }

            [Fact]
            public async Task ReturnsParentProgressLink()
            {
                var parentCaseId = Fixture.Integer();

                _apiClient.Get<FileCase>(null).ReturnsForAnyArgs(new FileCase
                {
                    Links = new[] {_progressLink}
                });

                var subject = CreateSubject();

                var result = await subject.GetViewLink(_settings, parentCaseId);
                Assert.Equal(new Uri(_progressLink.Href), result.ProgressUri);
            }

            [Fact]
            public async Task ReturnsParentWizardLink()
            {
                var parentCaseId = Fixture.Integer();

                _apiClient.Get<FileCase>(null).ReturnsForAnyArgs(new FileCase
                {
                    Links = new[] {_wizardLink}
                });

                var subject = CreateSubject();

                var result = await subject.GetViewLink(_settings, parentCaseId);
                Assert.Equal(new Uri(_wizardLink.Href), result.ProgressUri);
            }

            [Fact]
            public async Task ReturnsParentWizardLinkForDraftChild()
            {
                var childCase = new FileInstructAllowedCase
                {
                    ParentCaseId = Fixture.Integer(),
                    CaseId = Fixture.Integer(),
                    CountryCode = "AU",
                    IpType = "SomeIpType"
                };

                _apiClient.Get<FileCase>(null).ReturnsForAnyArgs(new FileCase
                {
                    Links = new[] {_wizardLink}
                });

                new FileCaseEntity
                {
                    Id = 1,
                    CaseId = childCase.CaseId,
                    ParentCaseId = childCase.ParentCaseId,
                    IpType = childCase.IpType,
                    Status = FileStatuses.Draft,
                    CountryCode = childCase.CountryCode
                }.In(Db);

                var subject = CreateSubject();

                var result = await subject.GetViewLink(_settings, childCase);

                Assert.Equal(new Uri(_wizardLink.Href), result.ProgressUri);
            }

            [Fact]
            public async Task ReturnsProgressLinkForNonDraftChild()
            {
                var childCase = new FileInstructAllowedCase
                {
                    ParentCaseId = Fixture.Integer(),
                    CaseId = Fixture.Integer(),
                    CountryCode = "AU",
                    IpType = "SomeIpType"
                };

                _apiClient.Get<Instruction>(null).ReturnsForAnyArgs(new Instruction
                {
                    Links = new[] {_childProgressLink}
                });

                new FileCaseEntity
                {
                    Id = 1,
                    CaseId = childCase.CaseId,
                    ParentCaseId = childCase.ParentCaseId,
                    IpType = childCase.IpType,
                    Status = "SENT",
                    CountryCode = childCase.CountryCode
                }.In(Db);

                var subject = CreateSubject();

                var result = await subject.GetViewLink(_settings, childCase);

                Assert.Equal(new Uri(_childProgressLink.Href), result.ProgressUri);
            }

            [Fact]
            public async Task ShouldReturnUriForView()
            {
                var pctParentOrPriorityCase = Fixture.Integer();
                var subject = CreateSubject();

                _apiClient.Get<FileCase>(null).ReturnsForAnyArgs(new FileCase
                {
                    Links = _successLinks
                });

                var r = await subject.GetViewLink(_settings, pctParentOrPriorityCase);

                Assert.Equal(new Uri("http://ipplatform.com/wizard/agents"), r.ProgressUri);
            }
        }
    }
}