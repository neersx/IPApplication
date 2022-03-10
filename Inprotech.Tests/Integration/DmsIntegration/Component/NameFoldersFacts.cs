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
    public class NameFoldersFacts
    {
        public class NameFoldersFixture : IFixture<NameFolders>
        {
            public NameFoldersFixture()
            {
                DmsService = Substitute.For<IDmsService>();
                DmsSettingsProvider = Substitute.For<IDmsSettingsProvider>();
                NameFolderCriteriaResolver = Substitute.For<INameFolderCriteriaResolver>();

                var configuredDms = Substitute.For<IConfiguredDms>();
                configuredDms.GetService().Returns(DmsService);

                Subject = new NameFolders(configuredDms, DmsSettingsProvider, NameFolderCriteriaResolver);
            }

            public IDmsService DmsService { get; set; }
            public IDmsSettingsProvider DmsSettingsProvider { get; set; }
            public INameFolderCriteriaResolver NameFolderCriteriaResolver { get; set; }

            public NameFolders Subject { get; }

            public NameFoldersFixture WithSearchCriteria(DmsSearchCriteria criteria = null)
            {
                NameFolderCriteriaResolver.Resolve(Arg.Any<int>())
                                          .Returns(x =>
                                          {
                                              if (criteria != null) return criteria;

                                              var defaulted = new DmsSearchCriteria();
                                              defaulted.NameEntity.NameCode = "1234";
                                              defaulted.NameEntity.NameType = "I";
                                              defaulted.NameEntity.NameKey = (int)x[0];

                                              return defaulted;
                                          });

                return this;
            }

            public NameFoldersFixture WithSearchCriteria(DmsSearchCriteria criteria, IManageSettings settings)
            {
                NameFolderCriteriaResolver.Resolve(Arg.Any<int>(), settings)
                                          .Returns(x =>
                                          {
                                              if (criteria != null) return criteria;

                                              var defaulted = new DmsSearchCriteria();
                                              defaulted.NameEntity.NameCode = "1234";
                                              defaulted.NameEntity.NameType = "I";
                                              defaulted.NameEntity.NameKey = (int) x[0];

                                              return defaulted;
                                          });

                return this;
            }

            public NameFoldersFixture WithNameTypes(params string[] nameTypesOrCommaSeparatedNameTypes)
            {
                var dmsSettings = Substitute.For<DmsSettings>();
                dmsSettings.NameTypesRequired.Returns(nameTypesOrCommaSeparatedNameTypes);

                DmsSettingsProvider.Provide().Returns(dmsSettings);

                return this;
            }

            public NameFoldersFixture WithNameFoldersFor(string searchStr, string nameType, IEnumerable<DmsFolder> folders = null)
            {
                DmsService.GetNameFolders(searchStr, nameType).Returns(folders);

                return this;
            }

            public NameFoldersFixture WithNameFoldersFor(string searchStr, string nameType, IEnumerable<DmsFolder> folders, IManageTestSettings settings)
            {
                DmsService.GetNameFolders(searchStr, nameType, settings).Returns(folders);

                return this;
            }

            public NameFoldersFixture WithSubFoldersFor(string searchStr, IEnumerable<DmsFolder> folders = null)
            {
                DmsService.GetSubFolders(searchStr,  FolderType.Folder, true).Returns(folders);

                return this;
            }
        }

        public class FetchTopFoldersMethod
        {
            [Fact]
            public async Task ShouldNotPerformSearchIfNameTypesIsResolvedToEmpty()
            {
                var f = new NameFoldersFixture()
                        .WithNameTypes()
                        .WithSearchCriteria(new DmsSearchCriteria());

                var r = (await f.Subject.FetchTopFolders(1)).ToArray();

                Assert.Empty(r);

                f.DmsService.DidNotReceiveWithAnyArgs().GetNameFolders(null, null)
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldReturnFoldersForEachConfiguredNames()
            {
                var folderForInstructor = new DmsFolder();
                var folderForDebtor = new DmsFolder();
                var folderForOwner = new DmsFolder();

                var searchCriteria = new DmsSearchCriteria();
                searchCriteria.NameEntity.NameCode = "1234";

                var f = new NameFoldersFixture()
                        .WithSearchCriteria(searchCriteria)
                        .WithNameTypes("I", "D", "O")
                        .WithNameFoldersFor("1234", "I", new[] { folderForInstructor })
                        .WithNameFoldersFor("1234", "D", new[] { folderForDebtor })
                        .WithNameFoldersFor("1234", "O", new[] { folderForOwner });

                var r = (await f.Subject.FetchTopFolders(1)).ToArray();

                f.DmsService.Received(1).GetNameFolders("1234", "I").IgnoreAwaitForNSubstituteAssertion();
                f.DmsService.Received(1).GetNameFolders("1234", "D").IgnoreAwaitForNSubstituteAssertion();
                f.DmsService.Received(1).GetNameFolders("1234", "O").IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(r, new[] { folderForInstructor, folderForDebtor, folderForOwner });
            }

            [Fact]
            public async Task ShouldPassTestSettingsToDmsFolders()
            {
                var folderForInstructor = new DmsFolder();
                var folderForDebtor = new DmsFolder();

                var settings = new IManageTestSettings
                {
                    Settings = new IManageSettings 
                    { 
                        NameTypes = new List<IManageSettings.NameTypeSettings>
                        {
                            new IManageSettings.NameTypeSettings {NameType = "I"},
                            new IManageSettings.NameTypeSettings {NameType = "D"}
                        }
                    }
                };

                var searchCriteria = new DmsSearchCriteria {NameEntity = {NameCode = "1234"}};

                var f = new NameFoldersFixture()
                        .WithSearchCriteria(searchCriteria, settings.Settings)
                        .WithNameFoldersFor("1234", "I", new[] {folderForInstructor}, settings)
                        .WithNameFoldersFor("1234", "D", new[] {folderForDebtor}, settings);

                var r = (await f.Subject.FetchTopFolders(1, settings)).ToArray();

                f.DmsService.Received(1).GetNameFolders("1234", "I", settings).IgnoreAwaitForNSubstituteAssertion();
                f.DmsService.Received(1).GetNameFolders("1234", "D", settings).IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(r, new[] {folderForInstructor, folderForDebtor});
            }
        }

        public class FetchSubFoldersMethod
        {
            [Fact]
            public async Task ShouldReturnSubFolders()
            {
                var subFolder1 = new DmsFolder();
                var subFolder2 = new DmsFolder();

                var f = new NameFoldersFixture()
                    .WithSubFoldersFor("any", new[] { subFolder1, subFolder2 });

                var r = (await f.Subject.FetchSubFolders("any", FolderType.Folder, true)).ToArray();

                Assert.Contains(subFolder1, r);
                Assert.Contains(subFolder2, r);
            }

            [Fact]
            public async Task ShouldThrowIfSearchStringOrPathIsNotProvided()
            {
                var f = new NameFoldersFixture();

                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.FetchSubFolders(null,  FolderType.Folder, true));
            }
        }
    }
}