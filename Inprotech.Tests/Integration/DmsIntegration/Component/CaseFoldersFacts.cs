using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.DmsIntegration.Component;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.DmsIntegration.Component
{
    public class CaseFoldersFacts
    {
        public class CaseFoldersFixture : IFixture<CaseFolders>
        {
            public CaseFoldersFixture()
            {
                DmsService = Substitute.For<IDmsService>();
                CaseFolderCriteriaResolver = Substitute.For<ICaseFolderCriteriaResolver>();

                var configuredDms = Substitute.For<IConfiguredDms>();
                configuredDms.GetService().Returns(DmsService);

                Subject = new CaseFolders(configuredDms, CaseFolderCriteriaResolver);
            }

            public IDmsService DmsService { get; set; }

            public ICaseFolderCriteriaResolver CaseFolderCriteriaResolver { get; set; }

            public CaseFolders Subject { get; }

            public CaseFoldersFixture WithSearchCriteria(DmsSearchCriteria criteria = null)
            {
                CaseFolderCriteriaResolver.Resolve(Arg.Any<int>())
                                          .Returns(x => criteria ?? new DmsSearchCriteria
                                          {
                                              CaseReference = "caseref",
                                              CaseKey = (int)x[0]
                                          });

                return this;
            }
            public CaseFoldersFixture WithSearchCriteria(DmsSearchCriteria criteria, IManageSettings settings)
            {
                CaseFolderCriteriaResolver.Resolve(Arg.Any<int>(), settings)
                                          .Returns(x => criteria ?? new DmsSearchCriteria
                                          {
                                              CaseReference = "caseref",
                                              CaseKey = (int)x[0]
                                          });

                return this;
            }

            public CaseFoldersFixture WithCaseFoldersFor(string searchStr, IEnumerable<DmsFolder> folders = null)
            {
                DmsService.GetCaseFolders(searchStr).Returns(folders);

                return this;
            }

            public CaseFoldersFixture WithNameFoldersFor(string searchStr, string nameType, IEnumerable<DmsFolder> folders = null)
            {
                DmsService.GetNameFolders(searchStr, nameType).Returns(folders);

                return this;
            }

            public CaseFoldersFixture WithCaseFoldersFor(string searchStr, IEnumerable<DmsFolder> folders, IManageTestSettings settings)
            {
                DmsService.GetCaseFolders(searchStr, settings).Returns(folders);

                return this;
            }

            public CaseFoldersFixture WithNameFoldersFor(string searchStr, string nameType, IEnumerable<DmsFolder> folders, IManageTestSettings settings)
            {
                DmsService.GetNameFolders(searchStr, nameType, settings).Returns(folders);

                return this;
            }

            public CaseFoldersFixture WithSubFoldersFor(string searchStr, IEnumerable<DmsFolder> folders = null)
            {
                DmsService.GetSubFolders(searchStr, FolderType.NotSet, true).Returns(folders);

                return this;
            }
        }

        public class FetchTopFoldersMethod
        {
            [Fact]
            public async Task ShouldNotPerformSearchIfSearchStringIsResolvedToEmpty()
            {
                var f = new CaseFoldersFixture()
                    .WithSearchCriteria(new DmsSearchCriteria());

                var r = (await f.Subject.FetchTopFolders(1)).ToArray();

                Assert.Empty(r);

                f.DmsService.DidNotReceiveWithAnyArgs().GetCaseFolders(null)
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldReturnFoldersForEachConfiguredNames()
            {
                var folderForInstructor = new DmsFolder() { ContainerId = "1" };
                var folderForDebtor = new DmsFolder() { ContainerId = "2" };
                var folderForCase = new DmsFolder() { ContainerId = "3" };

                var f = new CaseFoldersFixture()
                        .WithSearchCriteria(new DmsSearchCriteria
                        {
                            CaseReference = "caseref",
                            CaseNameEntities = new[]
                            {
                                new DmsNameEntity
                                {
                                    NameType = "I",
                                    NameCode = "instructor_name_code"
                                },
                                new DmsNameEntity
                                {
                                    NameType = "D",
                                    NameCode = "debtor_name_code"
                                }
                            }
                        })
                        .WithCaseFoldersFor("caseref", new[] { folderForCase })
                        .WithNameFoldersFor("instructor_name_code", "I", new[] { folderForInstructor })
                        .WithNameFoldersFor("debtor_name_code", "D", new[] { folderForDebtor });

                var r = (await f.Subject.FetchTopFolders(1)).ToArray();

                f.DmsService.Received(1).GetCaseFolders(Arg.Any<string>()).IgnoreAwaitForNSubstituteAssertion();

                f.DmsService.Received(2).GetNameFolders(Arg.Any<string>(), Arg.Any<string>()).IgnoreAwaitForNSubstituteAssertion();

                Assert.Contains(folderForCase, r);
                Assert.Contains(folderForInstructor, r);
                Assert.Contains(folderForDebtor, r);
                Assert.Equal(3, r.Length);
            }

            [Fact]
            public async Task ShouldPassTestSettingsToDmsFolders()
            {
                var folderForInstructor = new DmsFolder { ContainerId = "1" };
                var folderForCase = new DmsFolder { ContainerId = "2" };

                var settings = new IManageTestSettings
                {
                    Settings = new IManageSettings()
                };

                var f = new CaseFoldersFixture()
                        .WithSearchCriteria(new DmsSearchCriteria
                        {
                            CaseReference = "caseref",
                            CaseNameEntities = new[]
                            {
                                new DmsNameEntity
                                {
                                    NameType = "I",
                                    NameCode = "instructor_name_code"
                                }
                            }
                        }, settings.Settings)
                        .WithCaseFoldersFor("caseref", new[] { folderForCase }, settings)
                        .WithNameFoldersFor("instructor_name_code", "I", new[] { folderForInstructor }, settings);

                var r = (await f.Subject.FetchTopFolders(1, settings)).ToArray();

                f.DmsService.Received(1).GetCaseFolders(Arg.Any<string>(), settings).IgnoreAwaitForNSubstituteAssertion();

                f.DmsService.Received(1).GetNameFolders(Arg.Any<string>(), Arg.Any<string>(), settings).IgnoreAwaitForNSubstituteAssertion();

                Assert.Contains(folderForCase, r);
                Assert.Contains(folderForInstructor, r);
                Assert.Equal(2, r.Length);
            }
        }

        public class FetchSubFoldersMethod
        {
            [Fact]
            public async Task ShouldReturnSubFolders()
            {
                var subFolder1 = new DmsFolder();
                var subFolder2 = new DmsFolder();

                var f = new CaseFoldersFixture()
                    .WithSubFoldersFor("any", new[] { subFolder1, subFolder2 });

                var r = (await f.Subject.FetchSubFolders("any", FolderType.NotSet, true)).ToArray();

                Assert.Contains(subFolder1, r);
                Assert.Contains(subFolder2, r);
            }

            [Fact]
            public async Task ShouldThrowIfSearchStringOrPathIsNotProvided()
            {
                var f = new CaseFoldersFixture();

                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.FetchSubFolders(null, FolderType.NotSet, true));
            }
        }
    }
}