using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration.DmsIntegration;
using Inprotech.Integration.DmsIntegration.Component;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Inprotech.Integration.DmsIntegration.Component.iManage.v10;
using Inprotech.Tests.Extensions;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Xunit;

namespace Inprotech.Tests.Integration.DmsIntegration.Component.iManage
{
    public class IManageDmsServiceFacts
    {
        public class GetCaseFolderMethod
        {
            [Fact]
            public async Task ShouldLoopsOverDatabases()
            {
                var settings = new IManageSettings
                {
                    Databases = new List<IManageSettings.SiteDatabaseSettings>
                    {
                        new IManageSettings.SiteDatabaseSettings(),
                        new IManageSettings.SiteDatabaseSettings(),
                        new IManageSettings.SiteDatabaseSettings()
                    }
                };
                var fixture = new IManageDmsServiceFixture(settings);
                var workSiteManager = Substitute.For<IWorkSiteManager>();
                workSiteManager.Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password).Returns(true);
                fixture.WorksiteFactory.GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Returns(workSiteManager);

                await fixture.Subject.GetCaseFolders("AAA123");

                fixture.Credentials.Received(3).Resolve(Arg.Any<IManageSettings.SiteDatabaseSettings>())
                       .IgnoreAwaitForNSubstituteAssertion();
                fixture.WorksiteFactory.Received(3).GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>());
                workSiteManager.Received(3).Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password)
                               .IgnoreAwaitForNSubstituteAssertion();
                workSiteManager.Received(3).SetSettings(Arg.Any<IManageSettings>());
                workSiteManager.Received(3).GetTopFolders(Arg.Any<SearchType>(), Arg.Any<string>(), Arg.Any<string>())
                               .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldNotTryToGetFoldersIfCantConnect()
            {
                var settings = new IManageSettings
                {
                    Databases = new List<IManageSettings.SiteDatabaseSettings>
                    {
                        new IManageSettings.SiteDatabaseSettings(),
                        new IManageSettings.SiteDatabaseSettings(),
                        new IManageSettings.SiteDatabaseSettings()
                    }
                };
                var fixture = new IManageDmsServiceFixture(settings);
                var workSiteManager = Substitute.For<IWorkSiteManager>();
                workSiteManager.Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password).Returns(false);
                fixture.WorksiteFactory.GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Returns(workSiteManager);

                await fixture.Subject.GetCaseFolders("AAA123");

                fixture.Credentials.Received(3).Resolve(Arg.Any<IManageSettings.SiteDatabaseSettings>())
                       .IgnoreAwaitForNSubstituteAssertion();
                fixture.WorksiteFactory.Received(3).GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>());
                workSiteManager.Received(3).Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password)
                               .IgnoreAwaitForNSubstituteAssertion();
                workSiteManager.DidNotReceive().GetTopFolders(Arg.Any<SearchType>(), Arg.Any<string>(), Arg.Any<string>())
                               .IgnoreAwaitForNSubstituteAssertion();
                workSiteManager.DidNotReceive().SetSettings(Arg.Any<IManageSettings>());
            }

            [Fact]
            public async Task ShouldTryToGetCredentialsFromSettings()
            {
                var settings = new IManageSettings
                {
                    Databases = new List<IManageSettings.SiteDatabaseSettings>
                    {
                        new IManageSettings.SiteDatabaseSettings(),
                        new IManageSettings.SiteDatabaseSettings()
                    }
                };
                var testSettings = new IManageTestSettings
                {
                    UserName = Fixture.String(),
                    Password = Fixture.String(),
                    Settings = settings
                };
                var fixture = new IManageDmsServiceFixture(settings);
                var workSiteManager = Substitute.For<IWorkSiteManager>();
                workSiteManager.Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), testSettings.UserName, testSettings.Password).Returns(true);
                fixture.WorksiteFactory.GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Returns(workSiteManager);

                await fixture.Subject.GetCaseFolders("AAA123", testSettings);

                fixture.Credentials.Received(2).Resolve(Arg.Any<IManageSettings.SiteDatabaseSettings>())
                       .IgnoreAwaitForNSubstituteAssertion();
                fixture.WorksiteFactory.Received(2).GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>());
                workSiteManager.Received(2).Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), testSettings.UserName, testSettings.Password)
                               .IgnoreAwaitForNSubstituteAssertion();
                workSiteManager.Received(2).SetSettings(Arg.Any<IManageSettings>());
                workSiteManager.Received(2).GetTopFolders(Arg.Any<SearchType>(), Arg.Any<string>(), Arg.Any<string>())
                               .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldReTryOnCachedTokenExpiredException()
            {
                var settings = new IManageSettings
                {
                    Databases = new List<IManageSettings.SiteDatabaseSettings>
                    {
                        new IManageSettings.SiteDatabaseSettings(),
                        new IManageSettings.SiteDatabaseSettings(),
                        new IManageSettings.SiteDatabaseSettings()
                    }
                };
                var fixture = new IManageDmsServiceFixture(settings);
                var workSiteManager = Substitute.For<IWorkSiteManager>();
                workSiteManager.Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password, Arg.Any<bool>()).Returns(true);
                fixture.WorksiteFactory.GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Returns(workSiteManager);
                workSiteManager.GetTopFolders(SearchType.ByCaseReference, Arg.Any<string>(), Arg.Any<string>())
                               .Returns(x => throw new CachedTokenExpiredException(), x => new DmsFolder[1] { new DmsFolder() });

                await fixture.Subject.GetCaseFolders("AAA123");

                fixture.Credentials.Received(3).Resolve(Arg.Any<IManageSettings.SiteDatabaseSettings>()).IgnoreAwaitForNSubstituteAssertion();
                fixture.WorksiteFactory.Received(3).GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>());
                workSiteManager.Received(3).Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password, false).IgnoreAwaitForNSubstituteAssertion();
                workSiteManager.Received(1).Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password, true).IgnoreAwaitForNSubstituteAssertion();
                workSiteManager.Received(4).SetSettings(Arg.Any<IManageSettings>());
                workSiteManager.Received(4).GetTopFolders(Arg.Any<SearchType>(), Arg.Any<string>(), Arg.Any<string>()).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldReturnEmptyAndLogIfNoSearchString()
            {
                var fixture = new IManageDmsServiceFixture();

                var result = await fixture.Subject.GetCaseFolders(string.Empty);

                fixture.Logger.Received(1).Warning(KnownErrors.CaseSearchFieldEmpty);
                Assert.Empty(result);
            }
            
            [Fact]
            public async Task ShouldTryReconnectIfOAuthAndHasCachedTokenException()
            {
                var settings = new IManageSettings
                {
                    Databases = new List<IManageSettings.SiteDatabaseSettings>
                    {
                        new IManageSettings.SiteDatabaseSettings()
                        {
                            LoginType = IManageSettings.LoginTypes.OAuth
                        }
                    }
                };
                var fixture = new IManageDmsServiceFixture(settings);
                var workSiteManager = Substitute.For<IWorkSiteManager>();
                workSiteManager.Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password).Throws<CachedTokenExpiredException>();
                fixture.WorksiteFactory.GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Returns(workSiteManager);

                var result = await fixture.Subject.GetCaseFolders(Fixture.String());

                fixture.AccessTokenManager.Received(1).RefreshAccessToken(Arg.Any<string>(), settings.Databases.First());
            }

            [Theory]
            [InlineData(IManageSettings.LoginTypes.TrustedLogin)]
            public async Task ShouldNotTryReconnectIfOAuthAndHasCachedTokenException(string loginType)
            {
                var settings = new IManageSettings
                {
                    Databases = new List<IManageSettings.SiteDatabaseSettings>
                    {
                        new IManageSettings.SiteDatabaseSettings()
                        {
                            LoginType = loginType
                        }
                    }
                };
                var fixture = new IManageDmsServiceFixture(settings);
                var workSiteManager = Substitute.For<IWorkSiteManager>();
                workSiteManager.Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password).Throws<CachedTokenExpiredException>();
                fixture.WorksiteFactory.GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Returns(workSiteManager);

                var result = await fixture.Subject.GetCaseFolders(Fixture.String());

                fixture.AccessTokenManager.DidNotReceive().RefreshAccessToken(Arg.Any<string>(), settings.Databases.First());
            }
        }

        public class GetNameFoldersMethod
        {
            [Fact]
            public async Task ShouldLoopsOverDatabases()
            {
                var settings = new IManageSettings
                {
                    Databases = new List<IManageSettings.SiteDatabaseSettings>
                    {
                        new IManageSettings.SiteDatabaseSettings(),
                        new IManageSettings.SiteDatabaseSettings(),
                        new IManageSettings.SiteDatabaseSettings()
                    }
                };
                var fixture = new IManageDmsServiceFixture(settings);
                var workSiteManager = Substitute.For<IWorkSiteManager>();
                workSiteManager.Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password).Returns(true);
                fixture.WorksiteFactory.GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Returns(workSiteManager);

                await fixture.Subject.GetNameFolders("AAA123", Fixture.String());

                fixture.Credentials.Received(3).Resolve(Arg.Any<IManageSettings.SiteDatabaseSettings>())
                       .IgnoreAwaitForNSubstituteAssertion();
                fixture.WorksiteFactory.Received(3).GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>());
                workSiteManager.Received(3).Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password)
                               .IgnoreAwaitForNSubstituteAssertion();
                workSiteManager.Received(3).SetSettings(Arg.Any<IManageSettings>());
                workSiteManager.Received(3).GetTopFolders(Arg.Any<SearchType>(), Arg.Any<string>(), Arg.Any<string>())
                               .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldNotTryToGetFoldersIfCantConnect()
            {
                var settings = new IManageSettings
                {
                    Databases = new List<IManageSettings.SiteDatabaseSettings>
                    {
                        new IManageSettings.SiteDatabaseSettings(),
                        new IManageSettings.SiteDatabaseSettings(),
                        new IManageSettings.SiteDatabaseSettings()
                    }
                };
                var fixture = new IManageDmsServiceFixture(settings);
                var workSiteManager = Substitute.For<IWorkSiteManager>();
                workSiteManager.Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password).Returns(false);
                fixture.WorksiteFactory.GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Returns(workSiteManager);

                await fixture.Subject.GetNameFolders("AAA123", Fixture.String());

                fixture.Credentials.Received(3).Resolve(Arg.Any<IManageSettings.SiteDatabaseSettings>())
                       .IgnoreAwaitForNSubstituteAssertion();
                fixture.WorksiteFactory.Received(3).GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>());
                workSiteManager.Received(3).Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password)
                               .IgnoreAwaitForNSubstituteAssertion();
                workSiteManager.DidNotReceive().GetTopFolders(Arg.Any<SearchType>(), Arg.Any<string>(), Arg.Any<string>())
                               .IgnoreAwaitForNSubstituteAssertion();
                workSiteManager.DidNotReceive().SetSettings(Arg.Any<IManageSettings>());
            }

            [Fact]
            public async Task ShouldReturnEmptyAndLogIfNoSearchString()
            {
                var fixture = new IManageDmsServiceFixture();

                var result = await fixture.Subject.GetNameFolders(string.Empty, Fixture.String());

                fixture.Logger.Received(1).Warning(KnownErrors.NameSearchFieldEmpty);
                Assert.Empty(result);
            }
        }

        public class GetSubFoldersMethod
        {
            [Fact]
            public async Task ShouldFetchIfPathProvided()
            {
                var databaseName = Fixture.String();
                var containerId = Fixture.String();
                var settings = new IManageSettings
                {
                    Databases = new List<IManageSettings.SiteDatabaseSettings>
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Database = databaseName,
                            SiteDbId = databaseName
                        }
                    }
                };
                var fixture = new IManageDmsServiceFixture(settings);
                var workSiteManager = Substitute.For<IWorkSiteManager>();
                workSiteManager.Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password).Returns(true);
                fixture.WorksiteFactory.GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Returns(workSiteManager);
                workSiteManager.GetSubFolders(containerId, FolderType.NotSet, true).Returns(new[] { new DmsFolder() });
                var folders = await fixture.Subject.GetSubFolders($"{databaseName}-{containerId}", FolderType.NotSet, true);

                Assert.Equal(1, folders.Count());
            }

            [Fact]
            public async Task ShouldReTryOnCachedTokenExpiredException()
            {
                var databaseName = Fixture.String();
                var containerId = Fixture.String();
                var settings = new IManageSettings
                {
                    Databases = new List<IManageSettings.SiteDatabaseSettings>
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Database = databaseName,
                            SiteDbId = databaseName
                        }
                    }
                };
                var fixture = new IManageDmsServiceFixture(settings);
                var worksiteManager = Substitute.For<IWorkSiteManager>();
                worksiteManager.Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password, Arg.Any<bool>()).Returns(true);
                fixture.WorksiteFactory.GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Returns(worksiteManager);
                worksiteManager.GetSubFolders(containerId, FolderType.NotSet, true).Returns(x => throw new CachedTokenExpiredException(), x => new DmsFolder[1] { new DmsFolder() });
                var folders = await fixture.Subject.GetSubFolders($"{databaseName}-{containerId}", FolderType.NotSet, true);

                Assert.Equal(1, folders.Count());
                worksiteManager.Received(1).Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password).IgnoreAwaitForNSubstituteAssertion();
                worksiteManager.Received(1).Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password, true).IgnoreAwaitForNSubstituteAssertion();
                worksiteManager.Received(2).GetSubFolders(containerId, FolderType.NotSet, true).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldThrowExceptionIfNoPathProvided()
            {
                var fixture = new IManageDmsServiceFixture();
                await Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.GetSubFolders(string.Empty, FolderType.NotSet, true); });
            }
        }

        public class GetRelatedDocumentsMethod
        {
            [Fact]
            public async Task ShouldLoopsOverDatabases()
            {
                var databaseName = Fixture.String();
                var settings = new IManageSettings
                {
                    Databases = new List<IManageSettings.SiteDatabaseSettings>
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Database = databaseName,
                            SiteDbId = databaseName
                        }
                    }
                };
                var fixture = new IManageDmsServiceFixture(settings);
                var workSiteManager = Substitute.For<IWorkSiteManager>();
                workSiteManager.Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password).Returns(true);
                fixture.WorksiteFactory.GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Returns(workSiteManager);
                workSiteManager.GetDocumentById(Arg.Any<string>()).Returns(new DmsDocument());

                await fixture.Subject.GetDocumentDetails(Fixture.String(databaseName + "-"));

                fixture.Credentials.Received(1).Resolve(Arg.Any<IManageSettings.SiteDatabaseSettings>())
                       .IgnoreAwaitForNSubstituteAssertion();
                fixture.WorksiteFactory.Received(1).GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>());
                workSiteManager.Received(1).Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password)
                               .IgnoreAwaitForNSubstituteAssertion();
                workSiteManager.Received(1).GetRelatedDocuments(Arg.Any<string>())
                               .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldNotTryToGetFoldersIfCantConnect()
            {
                var databaseName = Fixture.String();
                var settings = new IManageSettings
                {
                    Databases = new List<IManageSettings.SiteDatabaseSettings>
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Database = databaseName,
                            SiteDbId = databaseName
                        }
                    }
                };
                var fixture = new IManageDmsServiceFixture(settings);
                var workSiteManager = Substitute.For<IWorkSiteManager>();
                workSiteManager.Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password).Returns(false);
                fixture.WorksiteFactory.GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Returns(workSiteManager);

                await fixture.Subject.GetDocumentDetails(Fixture.String(databaseName + "-"));

                fixture.Credentials.Received(1).Resolve(Arg.Any<IManageSettings.SiteDatabaseSettings>())
                       .IgnoreAwaitForNSubstituteAssertion();
                fixture.WorksiteFactory.Received(1).GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>());
                workSiteManager.Received(1).Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password)
                               .IgnoreAwaitForNSubstituteAssertion();
                workSiteManager.DidNotReceive().GetRelatedDocuments(Arg.Any<string>())
                               .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldReTryOnCachedTokenExpiredException()
            {
                var databaseName = Fixture.String();
                var settings = new IManageSettings
                {
                    Databases = new List<IManageSettings.SiteDatabaseSettings>
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Database = databaseName,
                            SiteDbId = databaseName
                        }
                    }
                };
                var fixture = new IManageDmsServiceFixture(settings);
                var workSiteManager = Substitute.For<IWorkSiteManager>();
                workSiteManager.Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password, Arg.Any<bool>()).Returns(true);
                fixture.WorksiteFactory.GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Returns(workSiteManager);
                workSiteManager.GetDocumentById(Arg.Any<string>()).Returns(x => throw new CachedTokenExpiredException(), x => new DmsDocument());

                var result = await fixture.Subject.GetDocumentDetails(Fixture.String(databaseName + "-"));

                Assert.NotNull(result);
                fixture.Credentials.Received(1).Resolve(Arg.Any<IManageSettings.SiteDatabaseSettings>()).IgnoreAwaitForNSubstituteAssertion();
                fixture.WorksiteFactory.Received(1).GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>());
                workSiteManager.Received(1).Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password).IgnoreAwaitForNSubstituteAssertion();
                workSiteManager.Received(1).Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password, true).IgnoreAwaitForNSubstituteAssertion();
                workSiteManager.Received(2).GetDocumentById(Arg.Any<string>()).IgnoreAwaitForNSubstituteAssertion();
                workSiteManager.Received(1).GetRelatedDocuments(Arg.Any<string>()).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldThrowExceptionIfNoPathProvided()
            {
                var fixture = new IManageDmsServiceFixture();

                Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.GetDocumentDetails(string.Empty); }).IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class GetDocumentsMethod
        {
            [Fact]
            public async Task ShouldLoopsOverDatabases()
            {
                var databaseName = Fixture.String();
                var settings = new IManageSettings
                {
                    Databases = new List<IManageSettings.SiteDatabaseSettings>
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Database = databaseName,
                            SiteDbId = databaseName
                        }
                    }
                };
                var fixture = new IManageDmsServiceFixture(settings);
                var workSiteManager = Substitute.For<IWorkSiteManager>();
                workSiteManager.Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password).Returns(true);
                fixture.WorksiteFactory.GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Returns(workSiteManager);

                await fixture.Subject.GetDocuments(Fixture.String(databaseName + "-"), FolderType.NotSet);

                fixture.Credentials.Received(1).Resolve(Arg.Any<IManageSettings.SiteDatabaseSettings>())
                       .IgnoreAwaitForNSubstituteAssertion();
                fixture.WorksiteFactory.Received(1).GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>());
                workSiteManager.Received(1).Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password)
                               .IgnoreAwaitForNSubstituteAssertion();
                workSiteManager.Received(1).GetDocuments(Arg.Any<string>(), Arg.Any<FolderType>())
                               .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldNotTryToGetFoldersIfCantConnect()
            {
                var databaseName = Fixture.String();
                var settings = new IManageSettings
                {
                    Databases = new List<IManageSettings.SiteDatabaseSettings>
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Database = databaseName,
                            SiteDbId = databaseName
                        }
                    }
                };
                var fixture = new IManageDmsServiceFixture(settings);
                var workSiteManager = Substitute.For<IWorkSiteManager>();
                workSiteManager.Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password).Returns(false);
                fixture.WorksiteFactory.GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Returns(workSiteManager);

                await fixture.Subject.GetDocuments(Fixture.String(databaseName + "-"), FolderType.NotSet);

                fixture.Credentials.Received(1).Resolve(Arg.Any<IManageSettings.SiteDatabaseSettings>())
                       .IgnoreAwaitForNSubstituteAssertion();
                fixture.WorksiteFactory.Received(1).GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>());
                workSiteManager.Received(1).Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password)
                               .IgnoreAwaitForNSubstituteAssertion();
                workSiteManager.DidNotReceive().GetDocuments(Arg.Any<string>(), Arg.Any<FolderType>())
                               .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldReTryOnCachedTokenExpiredException()
            {
                var databaseName = Fixture.String();
                var documents = new DmsDocumentCollection { DmsDocuments = new List<DmsDocument> { new DmsDocument() }, TotalCount = 1 };
                var settings = new IManageSettings
                {
                    Databases = new List<IManageSettings.SiteDatabaseSettings>
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Database = databaseName,
                            SiteDbId = databaseName
                        }
                    }
                };
                var fixture = new IManageDmsServiceFixture(settings);
                var workSiteManager = Substitute.For<IWorkSiteManager>();
                workSiteManager.Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password, Arg.Any<bool>()).Returns(true);
                workSiteManager.GetDocuments(Arg.Any<string>(), Arg.Any<FolderType>()).Returns(x => throw new CachedTokenExpiredException(), x => documents);

                fixture.WorksiteFactory.GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Returns(workSiteManager);

                var result = await fixture.Subject.GetDocuments(Fixture.String(databaseName + "-"), FolderType.NotSet);

                Assert.Equal(1, result.TotalCount);
                await fixture.Credentials.Received(1).Resolve(Arg.Any<IManageSettings.SiteDatabaseSettings>());
                fixture.WorksiteFactory.Received(1).GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>());
                await workSiteManager.Received(1).Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password);
                await workSiteManager.Received(1).Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password, true);
                await workSiteManager.Received(2).GetDocuments(Arg.Any<string>(), Arg.Any<FolderType>());
            }

            [Fact]
            public async Task ShouldThrowExceptionIfNoPathProvided()
            {
                var fixture = new IManageDmsServiceFixture();

                await Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.GetDocuments(string.Empty, FolderType.NotSet); });
            }
        }

        public class DownloadMethod
        {
            [Theory]
            [InlineData("ACROBAT", "application/pdf")]
            [InlineData("EXCEL", "application/vnd.ms-excel")]
            [InlineData("MIME", "application/vnd.ms-outlook")]
            [InlineData("PPT", "application/vnd.ms-powerpoint")]
            [InlineData("WORD", "application/msword")]
            [InlineData("Test", "application/octet-stream")]
            [InlineData("AnotherFailed", "application/octet-stream")]
            public async Task ShouldReturnDocumentWithCorrectContentTypeIfConnectSucceeds(string applicationName, string expectedContentType)
            {
                var databaseName = Fixture.String();
                var settings = new IManageSettings
                {
                    Databases = new List<IManageSettings.SiteDatabaseSettings>
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Database = databaseName,
                            SiteDbId = databaseName
                        }
                    }
                };
                var fixture = new IManageDmsServiceFixture(settings);
                var workSiteManager = Substitute.For<IWorkSiteManager>();
                workSiteManager.Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password).Returns(true);

                var document = new DownloadDocumentResponse
                {
                    ApplicationName = applicationName
                };
                workSiteManager.DownloadDocument(Arg.Any<string>()).Returns(document);
                fixture.WorksiteFactory.GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Returns(workSiteManager);

                var result = await fixture.Subject.Download(Fixture.String(databaseName + "-"));

                Assert.Equal(result, document);
                Assert.Equal(result.ContentType, expectedContentType);
                fixture.Logger.DidNotReceive().Exception(Arg.Any<Exception>());
            }

            [Fact]
            public async Task ShouldCatchExceptionLogAndReturnNullIfExceptionOnSubComponent()
            {
                var fixture = new IManageDmsServiceFixture();

                var workSiteManager = Substitute.For<IWorkSiteManager>();
                workSiteManager.Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password).Throws(new Exception());
                fixture.WorksiteFactory.GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Returns(workSiteManager);

                var result = await fixture.Subject.Download(Fixture.String("test-"));

                Assert.Null(result);
                fixture.Logger.Received(1).Exception(Arg.Any<Exception>());
            }

            [Fact]
            public async Task ShouldReturnNullWithoutLoggingExceptionIfConnectFails()
            {
                var databaseName = Fixture.String();
                var settings = new IManageSettings
                {
                    Databases = new List<IManageSettings.SiteDatabaseSettings>
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Database = databaseName,
                            SiteDbId = databaseName
                        }
                    }
                };
                var fixture = new IManageDmsServiceFixture(settings);
                var workSiteManager = Substitute.For<IWorkSiteManager>();
                workSiteManager.Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), fixture.ResolvedCredentials.UserName, fixture.ResolvedCredentials.Password).Returns(false);
                fixture.WorksiteFactory.GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Returns(workSiteManager);

                var result = await fixture.Subject.Download(Fixture.String(databaseName + "-"));

                Assert.Null(result);
                fixture.Logger.DidNotReceive().Exception(Arg.Any<Exception>());
            }

            [Fact]
            public async Task ShouldThrowExceptionIfNoPathProvided()
            {
                var fixture = new IManageDmsServiceFixture();

                await Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.Download(string.Empty); });
            }
        }

        public class IManageDmsServiceFixture : IFixture<IManageDmsService>
        {
            public IManageDmsServiceFixture(IManageSettings settings = null)
            {
                Logger = Substitute.For<ILogger<IManageDmsService>>();
                WorksiteFactory = Substitute.For<IWorkSiteManagerFactory>();
                Credentials = Substitute.For<ICredentialsResolver>();
                EventEmitter = Substitute.For<IDmsEventEmitter>();
                ResolvedCredentials = new DmsCredential
                {
                    Password = Fixture.String(),
                    UserName = Fixture.String()
                };

                Credentials.Resolve(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Returns(ResolvedCredentials);
                SettingsProvider = Substitute.For<IDmsSettingsProvider>();
                SettingsProvider.Provide().Returns(settings ?? new IManageSettings());
                WorkServerClient = Substitute.For<IWorkServerClient>();
                AccessTokenManager = Substitute.For<IAccessTokenManager>();
                Subject = new IManageDmsService(Logger, WorksiteFactory, Credentials, SettingsProvider, EventEmitter, WorkServerClient, AccessTokenManager);
            }
            public IWorkServerClient WorkServerClient { get; set; }
            public IDmsEventEmitter EventEmitter { get; set; }
            public IAccessTokenManager AccessTokenManager { get; }
            public DmsCredential ResolvedCredentials { get; set; }
            public IDmsSettingsProvider SettingsProvider { get; set; }

            public ICredentialsResolver Credentials { get; set; }

            public IWorkSiteManagerFactory WorksiteFactory { get; set; }

            public ILogger<IManageDmsService> Logger { get; set; }
            public IManageDmsService Subject { get; }
        }
    }
}