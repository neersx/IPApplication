using Inprotech.Integration.DmsIntegration;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Inprotech.Integration.DmsIntegration.Component.iManage.v10;
using Inprotech.Integration.DmsIntegration.Component.iManage.v10.v1;
using Inprotech.Tests.Extensions;
using Newtonsoft.Json;
using NSubstitute;
using System;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using Xunit;

namespace Inprotech.Tests.Integration.DmsIntegration.Component.iManage.v10.v1
{
    public class WorkSiteManagerFacts
    {
        public class Connect
        {
            [Fact]
            public async Task ShouldPassForceToLogin()
            {
                var db = Fixture.String();

                var settings = new IManageSettings
                {
                    Databases = new[]
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Server = "https://work.imanage.com",
                            Database = db,
                            CustomerId = 1,
                            LoginType = IManageSettings.LoginTypes.UsernamePassword
                        }
                    },
                    Case =
                    {
                        SearchField = IManageSettings.SearchFields.CustomField2,
                        SubType = "work"
                    }
                };

                var f = new WorkSiteManagerFixture();
                var subject = f.Subject;

                subject.SetSettings(settings);
                var userName = Fixture.String();
                var passWord = Fixture.String();
                await subject.Connect(settings.Databases.Single(), userName, passWord, true);
                await f.WorkServerClient.Received(1).Login(new Uri(settings.Databases.First().ServerUrl(), "api/v1/session/login"), userName, passWord, true);
            }
        }

        public class GetFoldersMethod
        {
            [Fact]
            public async Task ShouldFilterCaseSubClass()
            {
                var db = Fixture.String();

                var settings = new IManageSettings
                {
                    Databases = new[]
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Server = "https://work.imanage.com",
                            Database = db,
                            IntegrationType = IManageSettings.IntegrationTypes.iManageWorkApiV1,
                            CustomerId = 1
                        }
                    },
                    Case =
                    {
                        SearchField = IManageSettings.SearchFields.CustomField2,
                        SubType = "work",
                        SubClass = "test_sub_class"
                    }
                };

                var f = new WorkSiteManagerFixture();

                f.WorkServerClient.Send(HttpMethod.Get, $"GetFoldersByDataBase:{db}", Arg.Any<Uri>())
                 .Returns(new Response<string>
                 {
                     StatusCode = HttpStatusCode.OK,
                     Data = null
                 });

                var subject = f.Subject;

                subject.SetSettings(settings);

                await subject.Connect(settings.Databases.Single(), Fixture.String(), Fixture.String());

                await subject.GetTopFolders(SearchType.ByCaseReference, "caseRef1234", string.Empty);

                var dbSetting = settings.Databases.Single();
                var expectedUri = dbSetting.ServerUrl() +
                                  $"api/v1/workspaces/search?scope={dbSetting.Database}&custom2=caseRef1234&subclass=test_sub_class";

                f.WorkServerClient
                 .Received()
                 .Send(HttpMethod.Get, Arg.Any<string>(), new Uri(expectedUri))
                 .IgnoreAwaitForNSubstituteAssertion();
                f.DmsEventEmitter.Received(1).Emit(Arg.Is<DocumentManagementEvent>(n => n.Key == KnownDocumentManagementEvents.CaseWorkspaceCustomField2 && n.Value == "caseRef1234"));
                f.DmsEventEmitter.Received(1).Emit(Arg.Is<DocumentManagementEvent>(n => n.Key == KnownDocumentManagementEvents.CaseSubClass && n.Value == "test_sub_class"));
            }

            [Fact]
            public async Task ShouldCallForMultipleDatabases()
            {
                var db1 = Fixture.String();
                var db2 = Fixture.String();
                var db = $"{db1},{db2}";
                var settings = new IManageSettings
                {
                    Databases = new[]
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Server = "https://work.imanage.com",
                            Database = db,
                            IntegrationType = IManageSettings.IntegrationTypes.iManageWorkApiV1,
                            CustomerId = 1
                        }
                    },
                    Case =
                    {
                        SearchField = IManageSettings.SearchFields.CustomField2,
                        SubType = "work"
                    }
                };

                var f = new WorkSiteManagerFixture();
                f.WorkServerClient.Send(HttpMethod.Get, Arg.Any<string>(), Arg.Any<Uri>())
                 .Returns(new Response<string>());

                var subject = f.Subject;

                subject.SetSettings(settings);
                await subject.Connect(settings.Databases.Single(), Fixture.String(), Fixture.String());

                await subject.GetTopFolders(SearchType.ByCaseReference, "caseRef1234", string.Empty);
                f.WorkServerClient.Received(2).Send(HttpMethod.Get, Arg.Any<string>(), Arg.Any<Uri>());
            }

            [Fact]
            public async Task ShouldFilterCaseWorkspaceBySubtype()
            {
                var db1 = Fixture.String();
                var db2 = Fixture.String();
                var db = $"{db1},{db2}";
                var settings = new IManageSettings
                {
                    Databases = new[]
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Server = "https://work.imanage.com",
                            Database = db,
                            IntegrationType = IManageSettings.IntegrationTypes.iManageWorkApiV1,
                            CustomerId = 1
                        }
                    },
                    Case =
                    {
                        SearchField = IManageSettings.SearchFields.CustomField2,
                        SubType = "work"
                    }
                };

                var f = new WorkSiteManagerFixture();
                var response1 = new Response<string>
                {
                    StatusCode = HttpStatusCode.OK,
                    Data = JsonConvert.SerializeObject(new
                    {
                        data = new[]
                        {
                            new FolderResult
                            {
                                Database = db1,
                                WsType = "workspace",
                                Id = $"{db1}!1234",
                                SubType = "work"
                            },
                            new FolderResult
                            {
                                Database = db1,
                                WsType = "workspace",
                                Id = $"{db1}!4567",
                                SubType = "other"
                            }
                        }
                    })
                };
                var response2 = new Response<string>
                {
                    StatusCode = HttpStatusCode.OK,
                    Data = JsonConvert.SerializeObject(new
                    {
                        data = new[]
                        {
                            new FolderResult
                            {
                                Database = db2,
                                WsType = "workspace",
                                Id = $"{db2}!1234",
                                SubType = "work"
                            },
                            new FolderResult
                            {
                                Database = db2,
                                WsType = "workspace",
                                Id = $"{db2}!4567",
                                SubType = "other"
                            }
                        }
                    })
                };
                f.WorkServerClient.Send(HttpMethod.Get, $"GetFoldersByDataBase:{db1}", Arg.Any<Uri>())
                 .Returns(response1);
                f.WorkServerClient.Send(HttpMethod.Get, $"GetFoldersByDataBase:{db2}", Arg.Any<Uri>())
                 .Returns(response2);

                var subject = f.Subject;

                subject.SetSettings(settings);
                await subject.Connect(settings.Databases.Single(), Fixture.String(), Fixture.String());

                var r = (await subject.GetTopFolders(SearchType.ByCaseReference, "caseRef1234", string.Empty)).ToArray();
                f.WorkServerClient.Received(2).Send(HttpMethod.Get, Arg.Any<string>(), Arg.Any<Uri>());
                Assert.Equal(2, r.Length);

                Assert.Equal(db1, r.First().Database);
                Assert.Equal($"{db1}!1234", r.First().ContainerId);
                Assert.Equal(FolderType.Workspace, r.First().FolderType);

                Assert.Equal(db2, r.Last().Database);
                Assert.Equal($"{db2}!1234", r.Last().ContainerId);
                Assert.Equal(FolderType.Workspace, r.Last().FolderType);
            }

            [Fact]
            public async Task ShouldFilterNameSubClass()
            {
                var db1 = Fixture.String();
                var db2 = Fixture.String();
                var db = $"{db1},{db2}";

                var settings = new IManageSettings
                {
                    Databases = new[]
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Server = "https://work.imanage.com",
                            Database = db,
                            IntegrationType = IManageSettings.IntegrationTypes.iManageWorkApiV1,
                            CustomerId = 1
                        }
                    },
                    NameTypes = new[]
                    {
                        new IManageSettings.NameTypeSettings
                        {
                            NameType = "I",
                            SubClass = "a_sub_class"
                        }
                    }
                };

                var f = new WorkSiteManagerFixture();

                f.WorkServerClient.Send(HttpMethod.Get, $"GetFoldersByDataBase:{db1}", Arg.Any<Uri>())
                 .Returns(new Response<string>
                 {
                     StatusCode = HttpStatusCode.OK,
                     Data = null

                 });
                f.WorkServerClient.Send(HttpMethod.Get, $"GetFoldersByDataBase:{db2}", Arg.Any<Uri>())
                 .Returns(new Response<string>
                 {
                     StatusCode = HttpStatusCode.OK,
                     Data = null
                 });

                var subject = f.Subject;

                subject.SetSettings(settings);

                await subject.Connect(settings.Databases.Single(), Fixture.String(), Fixture.String());

                (await subject.GetTopFolders(SearchType.ByNameCode, "namecode1234", "I")).ToArray();

                var dbSetting = settings.Databases.Single();
                var expectedUri1 = dbSetting.ServerUrl() +
                                   $"api/v1/workspaces/search?scope={db1}&custom1=namecode1234&subclass=a_sub_class";

                f.WorkServerClient
                 .Received()
                 .Send(HttpMethod.Get, Arg.Any<string>(), new Uri(expectedUri1))
                 .IgnoreAwaitForNSubstituteAssertion();
                var expectedUri2 = dbSetting.ServerUrl() +
                                   $"api/v1/workspaces/search?scope={db2}&custom1=namecode1234&subclass=a_sub_class";

                f.WorkServerClient
                 .Received()
                 .Send(HttpMethod.Get, Arg.Any<string>(), new Uri(expectedUri2))
                 .IgnoreAwaitForNSubstituteAssertion();
                f.DmsEventEmitter.Received(1).Emit(Arg.Is<DocumentManagementEvent>(n => n.Key == KnownDocumentManagementEvents.NameWorkspaceCustomField1 && n.Value == "namecode1234"));
                f.DmsEventEmitter.Received(1).Emit(Arg.Is<DocumentManagementEvent>(n => n.Key == KnownDocumentManagementEvents.NameSubClass && n.Value == "a_sub_class"));
            }

            [Fact]
            public async Task ShouldFilterNameWorkspaceBySubtype()
            {
                var db = Fixture.String();

                var settings = new IManageSettings
                {
                    Databases = new[]
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Server = "https://work.imanage.com",
                            Database = db,
                            IntegrationType = IManageSettings.IntegrationTypes.iManageWorkApiV1,
                            CustomerId = 1
                        }
                    },
                    NameTypes = new[]
                    {
                        new IManageSettings.NameTypeSettings
                        {
                            NameType = "I",
                            SubClass = "a_sub_class"
                        }
                    }
                };

                var f = new WorkSiteManagerFixture();

                f.WorkServerClient.Send(HttpMethod.Get, $"GetFoldersByDataBase:{db}", Arg.Any<Uri>())
                 .Returns(new Response<string>
                 {
                     StatusCode = HttpStatusCode.OK,
                     Data = JsonConvert.SerializeObject(new
                     {
                         data = new[]
                         {
                             new FolderResult
                             {
                                 Database = db,
                                 WsType = "workspace",
                                 Id = $"{db}!1234",
                                 SubType = "work"
                             },
                             new FolderResult
                             {
                                 Database = db,
                                 WsType = "workspace",
                                 Id = $"{db}!3456",
                                 SubType = "not_applicable_sub_type"
                             }
                         }
                     })
                 });

                var subject = f.Subject;

                subject.SetSettings(settings);
                await subject.Connect(settings.Databases.Single(), Fixture.String(), Fixture.String());

                var r = (await subject.GetTopFolders(SearchType.ByNameCode, "namecode1234", "I")).ToArray();

                Assert.Single(r);

                Assert.Equal(db, r.Single().Database);
                Assert.Equal($"{db}!1234", r.Single().ContainerId);
                Assert.Equal(FolderType.Workspace, r.Single().FolderType);
            }

            [Fact]
            public async Task ShouldIgnoreNoneFolderChildrenWhenPopulatingFolderSubTree()
            {
                var db = Fixture.String();
                var expectedFoldersChildrenUri = $"https://work.imanage.com/api/v1/workspaces/{db}!1234/children?scope={db}";
                var settings = new IManageSettings
                {
                    Databases = new[]
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Server = "https://work.imanage.com",
                            Database = db,
                            IntegrationType = IManageSettings.IntegrationTypes.iManageWorkApiV1,
                            CustomerId = 1
                        }
                    }
                };

                var f = new WorkSiteManagerFixture();
                f.WorkServerClient.Send(HttpMethod.Get, "GetSubFolders", Arg.Is<Uri>(_ => _ != new Uri(expectedFoldersChildrenUri)))
                 .Returns(new Response<string>
                 {
                     StatusCode = HttpStatusCode.OK,
                     Data = JsonConvert.SerializeObject(new
                     {
                         data = new[]
                         {
                             new FolderResult
                             {
                                 Database = db,
                                 FolderType = "search",
                                 Id = $"{db}!2349",
                                 HasDocuments = false,
                                 HasSubFolders = false
                             }
                         }
                     })
                 });

                f.WorkServerClient.Send(HttpMethod.Get, "GetSubFolders", new Uri(expectedFoldersChildrenUri))
                 .Returns(new Response<string>
                 {
                     StatusCode = HttpStatusCode.OK,
                     Data = JsonConvert.SerializeObject(new
                     {
                         data = new[]
                         {
                             new FolderResult
                             {
                                 Database = db,
                                 WsType = "document", /* no folder_type */
                                 Id = $"{db}!2345.1",
                                 HasDocuments = true,
                                 HasSubFolders = true
                             },
                             new FolderResult
                             {
                                 Database = db,
                                 WsType = "email", /* no folder_type */
                                 Id = $"{db}!2346.2",
                                 HasDocuments = false
                             },
                             new FolderResult
                             {
                                 Database = db,
                                 FolderType = "regular",
                                 Id = $"{db}!2347",
                                 HasDocuments = false,
                                 HasSubFolders = true
                             }
                         }
                     })
                 });

                var subject = f.Subject;

                subject.SetSettings(settings);
                await subject.Connect(settings.Databases.Single(), Fixture.String(), Fixture.String());

                var r = (await subject.GetSubFolders($"{db}!1234", FolderType.NotSet, true)).ToList();

                Assert.Single(r);

                Assert.Equal($"{db}!2347", r.Single().ContainerId);
                Assert.Equal(FolderType.Folder, r.Single().FolderType);

                Assert.Equal(1, r[0].ChildFolders.Count);
                Assert.Equal($"{db}!2349", r[0].ChildFolders[0].ContainerId);

                f.WorkServerClient.Received(2).Send(HttpMethod.Get, "GetSubFolders", Arg.Any<Uri>())
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldPopulateFolderSubTree()
            {
                var db = Fixture.String();
                var expectedFoldersChildrenUri = $"https://work.imanage.com/api/v1/workspaces/{db}!2344/children?scope={db}";

                var settings = new IManageSettings
                {
                    Databases = new[]
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Server = "https://work.imanage.com",
                            Database = db,
                            IntegrationType = IManageSettings.IntegrationTypes.iManageWorkApiV1,
                            CustomerId = 1
                        }
                    }
                };

                var f = new WorkSiteManagerFixture();

                f.WorkServerClient.Send(HttpMethod.Get, "GetSubFolders", Arg.Is<Uri>(_ => _ != new Uri(expectedFoldersChildrenUri)))
                 .Returns(new Response<string>
                 {
                     StatusCode = HttpStatusCode.OK,
                     Data = JsonConvert.SerializeObject(new
                     {
                         data = new FolderResult[0]
                     })
                 });

                f.WorkServerClient.Send(HttpMethod.Get, "GetSubFolders", new Uri(expectedFoldersChildrenUri))
                 .Returns(new Response<string>
                 {
                     StatusCode = HttpStatusCode.OK,
                     Data = JsonConvert.SerializeObject(new
                     {
                         data = new[]
                         {
                             new FolderResult
                             {
                                 Database = db,
                                 FolderType = "regular",
                                 Id = $"{db}!2345",
                                 HasDocuments = true
                             },
                             new FolderResult
                             {
                                 Database = db,
                                 FolderType = "search",
                                 Id = $"{db}!2346",
                                 HasDocuments = false
                             },
                             new FolderResult
                             {
                                 Database = db,
                                 FolderType = "regular",
                                 Email = "some@email.com",
                                 Id = $"{db}!2347",
                                 HasDocuments = false
                             }
                         }
                     })
                 });
                var subject = f.Subject;

                subject.SetSettings(settings);
                await subject.Connect(settings.Databases.Single(), Fixture.String(), Fixture.String());

                var r = (await subject.GetSubFolders($"{db}!2344", FolderType.NotSet, true)).ToList();

                Assert.Equal(3, r.Count);

                Assert.Equal($"{db}!2345", r[0].ContainerId);
                Assert.Equal(FolderType.Folder, r[0].FolderType);

                Assert.Equal($"{db}!2346", r[1].ContainerId);
                Assert.Equal(FolderType.SearchFolder, r[1].FolderType);

                Assert.Equal($"{db}!2347", r[2].ContainerId);
                Assert.Equal(FolderType.EmailFolder, r[2].FolderType);

                f.WorkServerClient.Received(1).Send(HttpMethod.Get, "GetSubFolders", Arg.Any<Uri>())
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldReturnNameWorkspaceWhenSubclassProvided()
            {
                var db = Fixture.String();

                var settings = new IManageSettings
                {
                    Databases = new[]
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Server = "https://work.imanage.com",
                            Database = db,
                            IntegrationType = IManageSettings.IntegrationTypes.iManageWorkApiV1,
                            CustomerId = 1
                        }
                    },
                    NameTypes = new[]
                    {
                        new IManageSettings.NameTypeSettings
                        {
                            NameType = "I",
                            SubClass = "a_sub_class"
                        }
                    }
                };

                var f = new WorkSiteManagerFixture();

                f.WorkServerClient.Send(HttpMethod.Get, $"GetFoldersByDataBase:{db}", Arg.Any<Uri>())
                 .Returns(new Response<string>
                 {
                     StatusCode = HttpStatusCode.OK,
                     Data = JsonConvert.SerializeObject(new
                     {
                         data = new[]
                         {
                             new FolderResult
                             {
                                 Database = db,
                                 WsType = "workspace",
                                 Id = $"{db}!1234",
                                 SubType = "work"
                             }
                         }
                     })
                 });

                var subject = f.Subject;

                subject.SetSettings(settings);
                await subject.Connect(settings.Databases.Single(), Fixture.String(), Fixture.String());

                var r = (await subject.GetTopFolders(SearchType.ByNameCode, "namecode1234", "I")).Single();

                Assert.Equal(db, r.Database);
                Assert.Equal($"{db}!1234", r.ContainerId);
                Assert.Equal(FolderType.Workspace, r.FolderType);

                f.WorkServerClient.Received(1)
                 .Send(HttpMethod.Get, Arg.Any<string>(), new Uri($"https://work.imanage.com/api/v1/workspaces/search?scope={db}&custom1=namecode1234&subclass=a_sub_class"))
                 .IgnoreAwaitForNSubstituteAssertion();
                f.DmsEventEmitter.Received(1).Emit(Arg.Is<DocumentManagementEvent>(n => n.Key == KnownDocumentManagementEvents.NameWorkspaceCustomField1 && n.Value == "namecode1234"));
                f.DmsEventEmitter.Received(1).Emit(Arg.Is<DocumentManagementEvent>(n => n.Key == KnownDocumentManagementEvents.NameSubClass && n.Value == "a_sub_class"));
                f.DmsEventEmitter.Received(1).Emit(Arg.Is<DocumentManagementEvent>(n => n.Key == KnownDocumentManagementEvents.NameWorkspace && n.Value == r.Name));
            }

            [Fact]
            public async Task ShouldSearchUsingCustom1AndCustom2ForCaseRef()
            {
                var db = Fixture.String();

                var settings = new IManageSettings
                {
                    Databases = new[]
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Server = "https://work.imanage.com",
                            Database = db,
                            IntegrationType = IManageSettings.IntegrationTypes.iManageWorkApiV1,
                            CustomerId = 1
                        }
                    },
                    Case =
                    {
                        SearchField = IManageSettings.SearchFields.CustomField1And2,
                        SubType = "work"
                    }
                };

                var f = new WorkSiteManagerFixture();

                f.WorkServerClient.Send(HttpMethod.Get, $"GetFoldersByDataBase:{db}", Arg.Any<Uri>())
                 .Returns(new Response<string>
                 {
                     StatusCode = HttpStatusCode.OK,
                     Data = JsonConvert.SerializeObject(new
                     {
                         data = new[]
                         {
                             new FolderResult
                             {
                                 Database = db,
                                 WsType = "workspace",
                                 Id = $"{db}!1234",
                                 SubType = "work"
                             }
                         }
                     })
                 });

                var subject = f.Subject;

                subject.SetSettings(settings);
                await subject.Connect(settings.Databases.Single(), Fixture.String(), Fixture.String());

                var r = (await subject.GetTopFolders(SearchType.ByCaseReference, "namecode1234.caseRef1234", string.Empty)).Single();

                Assert.Equal(db, r.Database);
                Assert.Equal($"{db}!1234", r.ContainerId);
                Assert.Equal(FolderType.Workspace, r.FolderType);

                f.WorkServerClient.Received(1)
                 .Send(HttpMethod.Get, Arg.Any<string>(),
                       new Uri($"https://work.imanage.com/api/v1/workspaces/search?scope={db}&custom1=namecode1234&custom2=caseRef1234"))
                 .IgnoreAwaitForNSubstituteAssertion();
                f.DmsEventEmitter.Received(1).Emit(Arg.Is<DocumentManagementEvent>(n => n.Key == KnownDocumentManagementEvents.CaseWorkspaceCustomField1 && n.Value == "namecode1234"));
                f.DmsEventEmitter.Received(1).Emit(Arg.Is<DocumentManagementEvent>(n => n.Key == KnownDocumentManagementEvents.CaseWorkspaceCustomField2 && n.Value == "caseRef1234"));
            }

            [Fact]
            public async Task ShouldSearchUsingCustom1ForCaseRef()
            {
                var db = Fixture.String();

                var settings = new IManageSettings
                {
                    Databases = new[]
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Server = "https://work.imanage.com",
                            Database = db,
                            IntegrationType = IManageSettings.IntegrationTypes.iManageWorkApiV1,
                            CustomerId = 1
                        }
                    },
                    Case =
                    {
                        SearchField = IManageSettings.SearchFields.CustomField1,
                        SubType = "work"
                    }
                };

                var f = new WorkSiteManagerFixture();

                f.WorkServerClient.Send(HttpMethod.Get, $"GetFoldersByDataBase:{db}", Arg.Any<Uri>())
                 .Returns(new Response<string>
                 {
                     StatusCode = HttpStatusCode.OK,
                     Data = JsonConvert.SerializeObject(new
                     {
                         data = new[]
                         {
                             new FolderResult
                             {
                                 Database = db,
                                 WsType = "workspace",
                                 Id = $"{db}!1234",
                                 SubType = "work"
                             }
                         }
                     })
                 });

                var subject = f.Subject;

                subject.SetSettings(settings);
                await subject.Connect(settings.Databases.Single(), Fixture.String(), Fixture.String());

                var r = (await subject.GetTopFolders(SearchType.ByCaseReference, "caseRef1234", string.Empty)).Single();

                Assert.Equal(db, r.Database);
                Assert.Equal($"{db}!1234", r.ContainerId);
                Assert.Equal(FolderType.Workspace, r.FolderType);

                f.WorkServerClient.Received(1)
                 .Send(HttpMethod.Get, Arg.Any<string>(),
                       new Uri($"https://work.imanage.com/api/v1/workspaces/search?scope={db}&custom1=caseRef1234"))
                 .IgnoreAwaitForNSubstituteAssertion();
                f.DmsEventEmitter.Received(1).Emit(Arg.Is<DocumentManagementEvent>(n => n.Key == KnownDocumentManagementEvents.CaseWorkspaceCustomField1 && n.Value == "caseRef1234"));
                f.DmsEventEmitter.Received(1).Emit(Arg.Is<DocumentManagementEvent>(n => n.Key == KnownDocumentManagementEvents.CaseWorkspace && n.Value == r.Name));
            }

            [Fact]
            public async Task ShouldSearchUsingCustom2ForCaseRef()
            {
                var db = Fixture.String();

                var settings = new IManageSettings
                {
                    Databases = new[]
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Server = "https://work.imanage.com",
                            Database = db,
                            IntegrationType = IManageSettings.IntegrationTypes.iManageWorkApiV1,
                            CustomerId = 1
                        }
                    },
                    Case =
                    {
                        SearchField = IManageSettings.SearchFields.CustomField2,
                        SubType = "work"
                    }
                };

                var f = new WorkSiteManagerFixture();

                f.WorkServerClient.Send(HttpMethod.Get, $"GetFoldersByDataBase:{db}", Arg.Any<Uri>())
                 .Returns(new Response<string>
                 {
                     StatusCode = HttpStatusCode.OK,
                     Data = JsonConvert.SerializeObject(new
                     {
                         data = new[]
                         {
                             new FolderResult
                             {
                                 Database = db,
                                 WsType = "workspace",
                                 Id = $"{db}!1234",
                                 SubType = "work"
                             }
                         }
                     })
                 });

                var subject = f.Subject;

                subject.SetSettings(settings);
                await subject.Connect(settings.Databases.Single(), Fixture.String(), Fixture.String());

                var r = (await subject.GetTopFolders(SearchType.ByCaseReference, "caseRef1234", string.Empty)).Single();

                Assert.Equal(db, r.Database);
                Assert.Equal($"{db}!1234", r.ContainerId);
                Assert.Equal(FolderType.Workspace, r.FolderType);

                f.WorkServerClient.Received(1)
                 .Send(HttpMethod.Get, Arg.Any<string>(),
                       new Uri($"https://work.imanage.com/api/v1/workspaces/search?scope={db}&custom2=caseRef1234"))
                 .IgnoreAwaitForNSubstituteAssertion();

                f.DmsEventEmitter.Received(1).Emit(Arg.Is<DocumentManagementEvent>(n => n.Key == KnownDocumentManagementEvents.CaseWorkspaceCustomField2 && n.Value == "caseRef1234"));
            }

            [Fact]
            public async Task ShouldSearchUsingCustom3ForCaseRef()
            {
                var db = Fixture.String();

                var settings = new IManageSettings
                {
                    Databases = new[]
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Server = "https://work.imanage.com",
                            Database = db,
                            IntegrationType = IManageSettings.IntegrationTypes.iManageWorkApiV1,
                            CustomerId = 1
                        }
                    },
                    Case =
                    {
                        SearchField = IManageSettings.SearchFields.CustomField3,
                        SubType = "work"
                    }
                };

                var f = new WorkSiteManagerFixture();

                f.WorkServerClient.Send(HttpMethod.Get, $"GetFoldersByDataBase:{db}", Arg.Any<Uri>())
                 .Returns(new Response<string>
                 {
                     StatusCode = HttpStatusCode.OK,
                     Data = JsonConvert.SerializeObject(new
                     {
                         data = new[]
                         {
                             new FolderResult
                             {
                                 Database = db,
                                 WsType = "workspace",
                                 Id = $"{db}!1234",
                                 SubType = "work"
                             }
                         }
                     })
                 });

                var subject = f.Subject;

                subject.SetSettings(settings);
                await subject.Connect(settings.Databases.Single(), Fixture.String(), Fixture.String());

                var r = (await subject.GetTopFolders(SearchType.ByCaseReference, "caseRef1234", string.Empty)).Single();

                Assert.Equal(db, r.Database);
                Assert.Equal($"{db}!1234", r.ContainerId);
                Assert.Equal(FolderType.Workspace, r.FolderType);

                f.WorkServerClient.Received(1)
                 .Send(HttpMethod.Get, Arg.Any<string>(),
                       new Uri($"https://work.imanage.com/api/v1/workspaces/search?scope={db}&custom3=caseRef1234"))
                 .IgnoreAwaitForNSubstituteAssertion();
                f.DmsEventEmitter.Received(1).Emit(Arg.Is<DocumentManagementEvent>(n => n.Key == KnownDocumentManagementEvents.CaseWorkspaceCustomField3 && n.Value == "caseRef1234"));

            }
        }

        public class GetDocumentsMethod
        {
            [Fact]
            public async Task ShouldGetAllDocumentsFromRequestedFolder()
            {
                var database = Fixture.String();
                var folderId = Fixture.String();
                var documentId1 = Fixture.Integer();
                var comments1 = Fixture.String();
                var version1 = Fixture.Short();
                var documentId2 = Fixture.Integer();
                var comments2 = Fixture.String();
                var version2 = Fixture.Short();

                var settings = new IManageSettings
                {
                    Databases = new[]
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Server = "https://work.imanage.com",
                            Database = database,
                            IntegrationType = IManageSettings.IntegrationTypes.iManageWorkApiV1,
                            CustomerId = 1
                        }
                    }
                };

                var f = new WorkSiteManagerFixture();

                f.WorkServerClient.Send(HttpMethod.Get, "GetDocuments", Arg.Any<Uri>())
                 .Returns(new Response<string>
                 {
                     StatusCode = HttpStatusCode.OK,
                     Data = JsonConvert.SerializeObject(new
                     {
                         data = new[]
                         {
                             new DocumentResult
                             {
                                 DocumentNumber = documentId1,
                                 Database = database,
                                 Version = version1,
                                 WsType = "email",
                                 Comments = comments1
                             },
                             new DocumentResult
                             {
                                 DocumentNumber = documentId2,
                                 Database = database,
                                 Version = version2,
                                 WsType = "document",
                                 Comments = comments2
                             }
                         },
                         total_count = 2
                     })
                 });

                var subject = f.Subject;

                subject.SetSettings(settings);
                await subject.Connect(settings.Databases.Single(), Fixture.String(), Fixture.String());

                var r = (await subject.GetDocuments($"{database}!{folderId}", FolderType.NotSet)).DmsDocuments;

                Assert.Equal(version1, r.First().Version);
                Assert.Equal(database, r.First().Database);
                Assert.Equal(documentId1, r.First().Id);
                Assert.Equal(comments1, r.First().Comment);

                Assert.Equal(version2, r.Last().Version);
                Assert.Equal(database, r.Last().Database);
                Assert.Equal(documentId2, r.Last().Id);
                Assert.Equal(comments2, r.Last().Comment);

                f.WorkServerClient
                 .Received(1)
                 .Send(HttpMethod.Get, "GetDocuments", new Uri($"https://work.imanage.com/api/v1/folders/{database}!{folderId}/documents?scope={database}"))
                 .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class RelatedDocumentsMethod
        {
            [Fact]
            public async Task ShouldNotGetRelatedDocuments()
            {
                var database = Fixture.String();
                var folderId = Fixture.String();

                var relatedDocument1 = Fixture.Integer();
                var relatedDocumentVersion = Fixture.Short();

                var settings = new IManageSettings
                {
                    Databases = new[]
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Server = "https://work.imanage.com",
                            Database = database,
                            IntegrationType = IManageSettings.IntegrationTypes.iManageWorkApiV1,
                            CustomerId = 1
                        }
                    }
                };

                var f = new WorkSiteManagerFixture();

                f.WorkServerClient.Send(HttpMethod.Get, "GetDocumentById", Arg.Any<Uri>())
                 .Returns(new Response<string>
                 {
                     StatusCode = HttpStatusCode.OK,
                     Data = JsonConvert.SerializeObject(new
                     {
                         data = new DocumentResult
                         {
                             DocumentNumber = relatedDocument1,
                             Version = relatedDocumentVersion,
                             Database = database,
                             WsType = "document",
                             IsRelated = true
                         }
                     })
                 });

                var subject = f.Subject;

                subject.SetSettings(settings);
                await subject.Connect(settings.Databases.Single(), Fixture.String(), Fixture.String());

                var r = await f.Subject.GetRelatedDocuments(folderId);

                Assert.Empty(r);
            }
        }

        public class ConnectMethod
        {
            [Fact]
            public async Task ShouldConnectToWorkServer()
            {
                var uId = Fixture.String();
                var pwd = Fixture.String();
                var database = Fixture.String();
                var settings = new IManageSettings
                {
                    Databases = new[]
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Server = "https://work.imanage.com",
                            Database = database
                        }
                    }
                };
                var f = new WorkSiteManagerFixture();

                await f.Subject.Connect(settings.Databases.Single(), uId, pwd);

                f.WorkServerClient.Received(1).Connect(f.DmsEventEmitter, settings.Databases.Single(), uId, pwd, null)
                 .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class DisconnectMethod
        {
            [Fact]
            public async Task ShouldDisconnectFromWorkServer()
            {
                var database = Fixture.String();
                var settings = new IManageSettings
                {
                    Databases = new[]
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            Server = "https://work.imanage.com",
                            IntegrationType = IManageSettings.IntegrationTypes.iManageWorkApiV1,
                            Database = database
                        }
                    }
                };

                var f = new WorkSiteManagerFixture();

                var subject = f.Subject;

                subject.SetSettings(settings);

                await f.Subject.Connect(settings.Databases.Single(), Fixture.String(), Fixture.String());

                await f.Subject.Disconnect();

                f.WorkServerClient.Received(1).Disconnect(settings.Databases.Single())
                 .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class WorkSiteManagerFixture : IFixture<WorkSiteManager>
        {
            public WorkSiteManagerFixture()
            {
                DmsEventEmitter = Substitute.For<IDmsEventEmitter>();
                WorkServerClient = Substitute.For<IWorkServerClient>();
                Subject = new WorkSiteManager(WorkServerClient, DmsEventEmitter);
            }

            public IDmsEventEmitter DmsEventEmitter { get; }
            public IWorkServerClient WorkServerClient { get; }
            
            public WorkSiteManager Subject { get; set; }
        }
    }

    public class FolderResult
    {
        [JsonProperty("database")]
        public string Database { get; set; }

        [JsonProperty("name")]
        public string Name { get; set; }

        [JsonProperty("id")]
        public string Id { get; set; }

        [JsonProperty("wstype")]
        public string WsType { get; set; }

        [JsonProperty("folder_type")]
        public string FolderType { get; set; }

        [JsonProperty("subtype")]
        public string SubType { get; set; }

        [JsonProperty("email")]
        public string Email { get; set; }

        [JsonProperty("has_subfolders")]
        public bool HasSubFolders { get; set; }

        [JsonProperty("has_documents")]
        public bool HasDocuments { get; set; }

        [JsonProperty("sub_class")]
        public string SubClass { get; set; }
    }

    public class DocumentResult
    {
        [JsonProperty("database")]
        public string Database { get; set; }

        [JsonProperty("document_number")]
        public int DocumentNumber { get; set; }

        [JsonProperty("version")]
        public int Version { get; set; }

        [JsonProperty("size")]
        public int Size { get; } = Fixture.Integer();

        [JsonProperty("name")]
        public string Name { get; set; }

        [JsonProperty("id")]
        public string Id => $"{Database}!{DocumentNumber}.{Version}";

        [JsonProperty("wstype")]
        public string WsType { get; set; }

        [JsonProperty("is_related")]
        public bool IsRelated { get; set; }

        [JsonProperty("comment")]
        public string Comments { get; set; }

        [JsonProperty("iwl")]
        public string Iwl => $"iwl:dms=work.imanage.com&&lib={Database}&&num={DocumentNumber}&&ver={Version}";
    }
}