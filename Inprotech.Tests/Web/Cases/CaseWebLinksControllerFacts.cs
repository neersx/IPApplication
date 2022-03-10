using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases
{
    public class CaseWebLinksControllerFacts : FactBase
    {
        [Fact]
        public async Task GetCaseWebLinks()
        {
            var f = new CaseWebLinksControllerFixture(Db);
            var data = f.SetupData();
            var d = data.data.ToList();
            var r = (await f.Subject.GetCaseWebLinks(data.@case.Id)).ToList();
            Assert.Equal(d.Count, r.Count);
            Assert.Equal(d[0].Links.Count(), r[0].Links.Count());
            Assert.Equal(d[1].Links.Count(), r[1].Links.Count());
            Assert.Equal(d[2].Links.Count(), r[2].Links.Count());

            Assert.Null(d.Last().GroupName);
            Assert.Null(r.Last().GroupName);

            Assert.Single(r.Last().Links, _ => _.Url.Contains($"/api/case/{data.@case.Id}/weblinks/{_.CriteriaNo}/{_.DocItemId}"));
        }

        [Fact]
        public async Task GetCaseWebLinksForExternalUser()
        {
            var f = new CaseWebLinksControllerFixture(Db).WithUser(true);
            var data = f.SetupData();
            var d = data.data.ToList();
            var r = (await f.Subject.GetCaseWebLinks(data.@case.Id)).ToList();
            Assert.Equal(2, r.Count);
            Assert.Single(r[0].Links);
            Assert.Equal(2, r[1].Links.Count());

            Assert.Null(d.Last().GroupName);
            Assert.Null(r.Last().GroupName);

            Assert.Single(r.Last().Links, _ => _.Url.Contains($"/api/case/{data.@case.Id}/weblinks/{_.CriteriaNo}/{_.DocItemId}"));
        }

        [Fact]
        public async Task ReturnsNotFoundForResolveCaseWebLinksWhenNotFound()
        {
            var f = new CaseWebLinksControllerFixture(Db);
            var data = f.SetupData();
            var r = await f.Subject.ResolveLink(data.@case.Id, Fixture.Integer(), Fixture.Integer());
            Assert.Equal(HttpStatusCode.NotFound, r.StatusCode);
        }

        [Fact]
        public async Task ResolveCaseWebLinksFromDocItem()
        {
            var uri = "http://www.resolved.uri.com";
            var f = new CaseWebLinksControllerFixture(Db).WithUser().WithRunner(uri);
            var data = f.SetupData();
            var d = data.data.ToList();
            var link = d.Last().Links.First(_ => _.DocItemId.HasValue && _.Url == null);
            var r = await f.Subject.ResolveLink(data.@case.Id, link.CriteriaNo, link.DocItemId.GetValueOrDefault());

            Assert.Equal(HttpStatusCode.Redirect, r.StatusCode);
            Assert.Equal(new Uri(uri), r.Headers.Location);
        }

        [Fact]
        public async Task ResolveCaseWebLinksFromDocItemReturnMessageIfLinkIsEmpty()
        {
            var errorMessageTranslation = "The link is not valid";
            var f = new CaseWebLinksControllerFixture(Db).WithRunner(string.Empty).WithTranslation(errorMessageTranslation);
            var data = f.SetupData();
            var d = data.data.ToList();
            var link = d.Last().Links.First(_ => _.DocItemId.HasValue && _.Url == null);

            var r = await f.Subject.ResolveLink(data.@case.Id, link.CriteriaNo, link.DocItemId.GetValueOrDefault());
            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.Equal(errorMessageTranslation, await ((StringContent)r.Content).ReadAsStringAsync());
            f.StaticTranslator.Received(1).Translate("caseWebLinks.invalidDocItemUrl", Arg.Any<IEnumerable<string>>());
        }

        [Fact]
        public async Task UrlTakesPrecedenceOverDocItem()
        {
            var uri = "http://www.resolved.uri.com";
            var f = new CaseWebLinksControllerFixture(Db).WithRunner(uri);
            var data = f.SetupData();
            var d = data.data.ToList();
            var link = d.Last().Links.First(_ => _.DocItemId.HasValue && _.Url != null);
            var r = await f.Subject.ResolveLink(data.@case.Id, link.CriteriaNo, link.DocItemId.GetValueOrDefault());

            Assert.Equal(HttpStatusCode.Redirect, r.StatusCode);
            Assert.Equal(new Uri(link.Url), r.Headers.Location);
        }

        [Fact]
        public async Task InvalidUrlPointsToErrorPage()
        {
            var uri = "/abc";
            var f = new CaseWebLinksControllerFixture(Db);
            var caseKey = f.SetupData(uri);
            var r = (await f.Subject.GetCaseWebLinks(caseKey)).ToList();

            Assert.Single(r);
            Assert.Single(r[0].Links);
            Assert.Single(r.Last().Links, _ => _.Url.Contains($"/api/case/{caseKey}/weblinksopen/{_.CriteriaNo}"));
        }

        [Fact]
        public async Task InvalidLinkShowsMessage()
        {
            var errorMessageTranslation = "The link is not valid";
            var f = new CaseWebLinksControllerFixture(Db).WithTranslation(errorMessageTranslation);

            var r = f.Subject.OpenInvalidLink(Fixture.Integer(), Fixture.Integer());
            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.Equal(errorMessageTranslation, await ((StringContent)r.Content).ReadAsStringAsync());
            f.StaticTranslator.Received(1).Translate("caseWebLinks.invalidUrl", Arg.Any<IEnumerable<string>>());
        }

        class CaseWebLinksControllerFixture : IFixture<CaseWebLinksController>
        {
            public const string RequestUrl = "http://www.abc.com/apps";
            public CaseWebLinksControllerFixture(InMemoryDbContext db)
            {
                Db = db;
                SecurityContext = Substitute.For<ISecurityContext>();
                var preferredCulture = Substitute.For<IPreferredCultureResolver>();
                DocItemRunner = Substitute.For<IDocItemRunner>();
                StaticTranslator = Substitute.For<IStaticTranslator>();
                UriHelper = new UriHelper();

                preferredCulture.Resolve().Returns("en");
                WithUser();
                Subject = new CaseWebLinksController(Db, SecurityContext, preferredCulture, DocItemRunner, StaticTranslator, UriHelper)
                {
                    Request = new HttpRequestMessage(HttpMethod.Get, RequestUrl)
                };
            }

            public CaseWebLinksController Subject { get; }

            InMemoryDbContext Db { get; }
            ISecurityContext SecurityContext { get; }
            IDocItemRunner DocItemRunner { get; }

            public IStaticTranslator StaticTranslator { get; }

            IUriHelper UriHelper { get; }

            public (Case @case, IEnumerable<CaseWebLinksController.WebLinksData> data) SetupData()
            {
                var @case = new CaseBuilder().Build().In(Db);

                new CasePropertyBuilder
                {
                    Status = new StatusBuilder().Build().In(Db),
                    Case = @case
                }.Build().In(Db);

                new TableCodeBuilder() { TableCode = (int)KnownStatusCodes.Dead, Description = "Dead" }.Build().In(Db);
                new TableCodeBuilder() { TableCode = (int)KnownStatusCodes.Pending, Description = "Pending" }.Build().In(Db);
                new TableCodeBuilder() { TableCode = (int)KnownStatusCodes.Registered, Description = "Registered" }.Build().In(Db);
                var tc = new TableCodeBuilder() { Description = "Search Engines" }.Build().In(Db);
                var tc2 = new TableCodeBuilder() { Description = "IP One" }.Build().In(Db);

                var g = new CriteriaRows() { IsPublic = true, CriteriaNo = Fixture.Integer(), GroupId = tc.Id, LinkTitle = "Google", LinkDescription = "Search with Google", Url = "http://www.google.com" }.In(Db);
                var b = new CriteriaRows() { CriteriaNo = Fixture.Integer(), GroupId = tc.Id, LinkTitle = "Bing", LinkDescription = "Search with Bing", Url = "http://www.bing.com" }.In(Db);
                var i = new CriteriaRows() { CriteriaNo = Fixture.Integer(), GroupId = tc2.Id, LinkTitle = "IP One", LinkDescription = "IP Platform allows you to access different apps", Url = "http://www.ip.com" }.In(Db);
                var w = new CriteriaRows() { IsPublic = true, CriteriaNo = Fixture.Integer(), LinkTitle = "Wiki", LinkDescription = "Un grouped wiki", Url = "http://www.wiki.com" }.In(Db);
                var docItemUrl = new CriteriaRows() { IsPublic = true, CriteriaNo = Fixture.Integer(), LinkTitle = "Doc", LinkDescription = "Resolved by Doc Item", DocItemId = 123 }.In(Db);
                var urlOverDocItem = new CriteriaRows() { CriteriaNo = Fixture.Integer(), LinkTitle = "Doc", LinkDescription = "Resolved by Doc Item", DocItemId = 123, Url = "http://www.showthisurloverdocitem.com" }.In(Db);

                return (@case, new List<CaseWebLinksController.WebLinksData>()
                {
                    new CaseWebLinksController.WebLinksData()
                    {
                        GroupName = tc2.Name,
                        Links = new List<CaseWebLinksController.WebLinksData.LinkDetails>()
                        {
                            new CaseWebLinksController.WebLinksData.LinkDetails()
                            {
                                Url = i.Url, LinkTitle = i.LinkTitle, LinkDescription = i.LinkDescription, CriteriaNo = i.CriteriaNo
                            }
                        }
                    },
                    new CaseWebLinksController.WebLinksData()
                    {
                        GroupName = tc.Name,
                        Links = new List<CaseWebLinksController.WebLinksData.LinkDetails>()
                        {
                            new CaseWebLinksController.WebLinksData.LinkDetails()
                            {
                                Url = g.Url, LinkTitle = g.LinkTitle, LinkDescription = g.LinkDescription, CriteriaNo = g.CriteriaNo
                            },
                            new CaseWebLinksController.WebLinksData.LinkDetails()
                            {
                                Url = b.Url, LinkTitle = b.LinkTitle, LinkDescription = b.LinkDescription, CriteriaNo = b.CriteriaNo
                            }
                        }
                    },
                    new CaseWebLinksController.WebLinksData()
                    {
                        Links = new List<CaseWebLinksController.WebLinksData.LinkDetails>()
                        {
                            new CaseWebLinksController.WebLinksData.LinkDetails()
                            {
                                Url = w.Url, LinkTitle = w.LinkTitle, LinkDescription = w.LinkDescription, DocItemId = w.DocItemId, CriteriaNo = w.CriteriaNo
                            },
                            new CaseWebLinksController.WebLinksData.LinkDetails()
                            {
                                Url = docItemUrl.Url, LinkTitle = docItemUrl.LinkTitle, LinkDescription = docItemUrl.LinkDescription, DocItemId = docItemUrl.DocItemId, CriteriaNo = docItemUrl.CriteriaNo
                            },
                            new CaseWebLinksController.WebLinksData.LinkDetails()
                            {
                                Url = urlOverDocItem.Url, LinkTitle = urlOverDocItem.LinkTitle, LinkDescription = urlOverDocItem.LinkDescription, DocItemId = urlOverDocItem.DocItemId, CriteriaNo = urlOverDocItem.CriteriaNo
                            }
                        }
                    }
                });
            }

            public int SetupData(string url)
            {
                var @case = new CaseBuilder().Build().In(Db);

                new CasePropertyBuilder
                {
                    Status = new StatusBuilder().Build().In(Db),
                    Case = @case
                }.Build().In(Db);

                new TableCodeBuilder() { TableCode = (int)KnownStatusCodes.Dead, Description = "Dead" }.Build().In(Db);
                new TableCodeBuilder() { TableCode = (int)KnownStatusCodes.Pending, Description = "Pending" }.Build().In(Db);
                new TableCodeBuilder() { TableCode = (int)KnownStatusCodes.Registered, Description = "Registered" }.Build().In(Db);

                new CriteriaRows() { IsPublic = true, CriteriaNo = Fixture.Integer(), LinkTitle = "None", LinkDescription = "Url", Url = url }.In(Db);
                return @case.Id;
            }

            public CaseWebLinksControllerFixture WithRunner(string uri)
            {
                var dataSet = new DataSet();
                var dataTable = new DataTable();
                dataTable.Columns.Add(new DataColumn());
                dataTable.Rows.Add(uri);
                dataSet.Tables.Add(dataTable);

                DocItemRunner.Run(Arg.Any<int>(), Arg.Any<Dictionary<string, object>>()).Returns(dataSet);
                return this;
            }

            public CaseWebLinksControllerFixture WithUser(bool isExternal = false)
            {
                SecurityContext.User.Returns(new User("internal", isExternal));
                return this;
            }

            public CaseWebLinksControllerFixture WithTranslation(string translation)
            {
                StaticTranslator.Translate(Arg.Any<string>(), Arg.Any<IEnumerable<string>>()).Returns(translation);
                return this;
            }
        }
    }
}