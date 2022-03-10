using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Common;
using Inprotech.Web.Configuration.Core;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.SiteControl;
using NSubstitute;
using Xunit;

#pragma warning disable 618

namespace Inprotech.Tests.Web.Configuration.Core
{
    public class SiteControlsControllerFacts
    {
        public class GetViewDataMethod : FactBase
        {
            [Fact]
            public void ReturnsAllReleases()
            {
                var f = new SiteControlsControllerFixture(Db);

                var rv1 = f.AddReleaseVersion(null, "1", 1);
                var rv2 = f.AddReleaseVersion(Fixture.Today(), "2", 2);
                var result = f.Subject.GetViewData();

                var results = ((IEnumerable<dynamic>) result.releases).ToArray();

                Assert.NotNull(results.SingleOrDefault(r => r.Id == rv1.Id && r.value == rv1.VersionName));
                Assert.NotNull(results.SingleOrDefault(r => r.Id == rv2.Id && r.value == rv2.VersionName));
            }

            [Fact]
            public void ReturnsReleasesOrderedByVersionSequenceDescending()
            {
                var f = new SiteControlsControllerFixture(Db);

                f.AddReleaseVersion(null, "2", 2, 2);
                f.AddReleaseVersion(null, "1", 1, 1);
                f.AddReleaseVersion(null, "3", 3, 3);

                var result = f.Subject.GetViewData();

                var results = ((IEnumerable<dynamic>) result.releases).ToArray();

                Assert.Equal("3", results.First().value);
                Assert.Equal("1", results.Last().value);
                Assert.Equal(3, results.Length);
            }
        }

        public class SearchMethod : FactBase
        {
            [Fact]
            public void Returns50SiteControlsPerPage()
            {
                for (var i = 0; i < 55; i++) SiteControlBuilderWrapper.Generate(Db, Fixture.UniqueName(), Fixture.String());

                var options = SiteControlBuilderWrapper.CreateSearchOptions(isByName: true, text: string.Empty);
                var s = new SiteControlsControllerFixture(Db);
                var result = s.Subject.Search(options);
                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(50, results.Length);
            }

            [Fact]
            public void ReturnsAllSiteControlsFromReleaseDate()
            {
                var s = new SiteControlsControllerFixture(Db);

                var s1 = SiteControlBuilderWrapper.Generate(Db, "S1", Fixture.String());
                var s2 = SiteControlBuilderWrapper.Generate(Db, "S2", Fixture.String());
                var s3 = SiteControlBuilderWrapper.Generate(Db, "S3", Fixture.String());
                var s4 = SiteControlBuilderWrapper.Generate(Db, "S4", Fixture.String());

                var r1 = s.AddReleaseVersion(DateTime.Today.AddDays(-30), id: 1, versionName: "version 1", sequence: 1);
                var r2 = s.AddReleaseVersion(DateTime.Today.AddDays(-20), id: 2, versionName: "version 2", sequence: 2);
                var r3 = s.AddReleaseVersion(DateTime.Today.AddDays(-10), id: 3, versionName: "version 3", sequence: 3);
                var r4 = s.AddReleaseVersion(DateTime.Today, id: 4, versionName: "version 4", sequence: 4);

                s1.ReleaseVersion = r1;
                s2.ReleaseVersion = r2;
                s3.ReleaseVersion = r3;
                s4.ReleaseVersion = r4;

                var options = SiteControlBuilderWrapper.CreateSearchOptions(isByName: true, text: string.Empty, versionId: 3);

                var result = s.Subject.Search(options);
                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.NotNull(results.SingleOrDefault(r => r.Name == s3.ControlId));
                Assert.NotNull(results.SingleOrDefault(r => r.Name == s4.ControlId));
                Assert.Equal(2, results.Length);
            }

            [Fact]
            public void ReturnsCsvListOfComponents()
            {
                var s1 = SiteControlBuilderWrapper.Generate(Db, "S1", Fixture.String());
                s1.Components.Add(new Component {ComponentName = "C1", Id = 1});
                s1.Components.Add(new Component {ComponentName = "C2", Id = 2});
                SiteControlBuilderWrapper.Generate(Db, "S12", Fixture.String());
                var searchOptions = SiteControlBuilderWrapper.CreateSearchOptions(isByName: true, text: "S1");
                searchOptions.ComponentIds = new[] {1};

                var s = new SiteControlsControllerFixture(Db);
                var result = s.Subject.Search(searchOptions);
                var firstResult = ((IEnumerable<dynamic>) result.Data).ToArray().First();

                Assert.Equal("C1, C2", firstResult.Components);
            }

            [Fact]
            public void ReturnSiteControlSearchingComponents()
            {
                var s1 = SiteControlBuilderWrapper.Generate(Db, "S1", Fixture.String());
                s1.Components.Add(new Component {ComponentName = "C1", Id = 1});
                s1.Components.Add(new Component {ComponentName = "C2", Id = 2});
                s1.Components.Add(new Component {ComponentName = "C3", Id = 3});
                SiteControlBuilderWrapper.Generate(Db, "S12", Fixture.String());
                var searchOptions = SiteControlBuilderWrapper.CreateSearchOptions(isByName: true, text: "S1");
                searchOptions.ComponentIds = new[] {1};

                var s = new SiteControlsControllerFixture(Db);
                var result = s.Subject.Search(searchOptions);
                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.NotNull(results.SingleOrDefault(_ => _.Name == s1.ControlId));
                Assert.Single(results);
            }

            [Fact]
            public void ReturnSiteControlSearchingTags()
            {
                var s1 = SiteControlBuilderWrapper.Generate(Db, "S1", Fixture.String());
                s1.Tags.Add(new Tag {TagName = "T1", Id = 1});
                SiteControlBuilderWrapper.Generate(Db, "S12", Fixture.String());
                var options = SiteControlBuilderWrapper.CreateSearchOptions(isByName: true, text: "S1");
                options.TagIds = new[] {1};

                var s = new SiteControlsControllerFixture(Db);
                var result = s.Subject.Search(options);
                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.NotNull(results.SingleOrDefault(_ => _.Name == s1.ControlId));
                Assert.Single(results);
            }

            [Fact]
            public void SortsByIdAscendingByDefault()
            {
                SiteControlBuilderWrapper.Generate(Db, "S2", Fixture.String());
                SiteControlBuilderWrapper.Generate(Db, "S1", Fixture.String());
                var options = SiteControlBuilderWrapper.CreateSearchOptions(isByName: true, text: string.Empty);

                var s = new SiteControlsControllerFixture(Db);
                var result = s.Subject.Search(options);
                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal("S1", results.First().Name);
                Assert.Equal("S2", results.Last().Name);
            }

            [Fact]
            public void SortsByIdDescending()
            {
                SiteControlBuilderWrapper.Generate(Db, "S2", Fixture.String());
                SiteControlBuilderWrapper.Generate(Db, "S1", Fixture.String());
                var options = SiteControlBuilderWrapper.CreateSearchOptions(isByName: true, text: string.Empty);

                var s = new SiteControlsControllerFixture(Db);
                var result = s.Subject.Search(options, new CommonQueryParameters {SortBy = "ControlId", SortDir = "desc"});
                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal("S2", results.First().Name);
                Assert.Equal("S1", results.Last().Name);
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void ReturnsSiteControlDetail()
            {
                var sc = new SiteControl().In(Db);
                sc.SiteControlDescription = Fixture.String();
                sc.Notes = Fixture.String();
                sc.DataType = "C";
                sc.StringValue = Fixture.String();
                sc.InitialValue = Fixture.String();
                var tagId = Fixture.Integer();
                var tagName = Fixture.String();
                sc.Tags = new List<Tag> {new Tag {Id = tagId, TagName = tagName}};

                var fixture = new SiteControlsControllerFixture(Db);
                var d = fixture.Subject.Get(sc.Id);

                Assert.Equal(sc.Id, d.Id);
                Assert.Equal(sc.Notes, d.Notes);
                Assert.Equal("String", d.DataType);
                Assert.Equal(sc.StringValue, d.Value);
                Assert.Equal(sc.InitialValue, d.InitialValue);
                Assert.Equal(tagId, d.Tags[0].Id);
                Assert.Equal(tagName, d.Tags[0].TagName);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void InsertsAndRemovesTags()
            {
                var sc1 = new SiteControlBuilder
                {
                    StringValue = Fixture.String(),
                    Tags = new List<Tag> {new Tag {Id = 1, TagName = "Tag1"}.In(Db)}
                }.Build().In(Db);

                var postData = new[]
                {
                    new SiteControlUpdateDetails
                    {
                        Id = sc1.Id,
                        Tags = new List<Tag> {new Tag {Id = 2, TagName = "Tag2"}.In(Db)}
                    }
                };

                var f = new SiteControlsControllerFixture(Db);
                f.Subject.Update(postData);

                Assert.Equal(1, sc1.Tags.Count);
                Assert.Empty(sc1.Tags.Where(tag => tag.Id == 1));
                Assert.Equal("Tag2", sc1.Tags.Single().TagName);
                
                f.SiteControlCache.Received()
                 .Clear(Arg.Is<string[]>(_ => _.Contains(sc1.ControlId)));
            }

            [Fact]
            public void UpdatesValueAndNotes()
            {
                var sc1 = new SiteControlBuilder
                {
                    SiteControlId = Fixture.String(),
                    Notes = Fixture.String(),
                    StringValue = Fixture.String()
                }.Build().In(Db);

                var sc2 = new SiteControlBuilder
                {
                    SiteControlId = Fixture.String(),
                    Notes = Fixture.String(),
                    IntegerValue = Fixture.Integer()
                }.Build().In(Db);

                var postData = new[]
                {
                    new SiteControlUpdateDetails
                    {
                        Id = sc1.Id,
                        Notes = "Different",
                        Value = "Not The Same",
                        Tags = new List<Tag>()
                    },
                    new SiteControlUpdateDetails
                    {
                        Id = sc2.Id,
                        Notes = "Different1",
                        Value = 2,
                        Tags = new List<Tag>()
                    }
                };

                var f = new SiteControlsControllerFixture(Db);
                f.Subject.Update(postData);

                Assert.Equal("Different", sc1.Notes);
                Assert.Equal("Not The Same", sc1.StringValue);
                Assert.Equal("Different1", sc2.Notes);
                Assert.Equal(2, sc2.IntegerValue);

                f.SiteControlCache.Received()
                 .Clear(Arg.Is<string[]>(_ => _.Contains(sc1.ControlId) && _.Contains(sc2.ControlId)));
            }
        }

        public class ControllerFacts
        {
            [Fact]
            public void PolicingQueueAdministrationControllerSecuredByPolicingAdministrationTask()
            {
                var r = TaskSecurity.Secures<SiteControlsController>(ApplicationTask.MaintainSiteControl);

                Assert.True(r);
            }
        }

        public class SiteControlsControllerFixture : IFixture<SiteControlsController>
        {
            readonly InMemoryDbContext _db;

            public SiteControlsControllerFixture(InMemoryDbContext db)
            {
                _db = db;
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                SiteControlCache = Substitute.For<ISiteControlCache>();

                Subject = new SiteControlsController(db, PreferredCultureResolver, TaskSecurityProvider, SiteControlCache);
            }

            public ISiteControlCache SiteControlCache { get; }
            public IPreferredCultureResolver PreferredCultureResolver { get; }
            public ITaskSecurityProvider TaskSecurityProvider { get; }
            public SiteControlsController Subject { get; }

            public ReleaseVersion AddReleaseVersion(DateTime? releaseDate, string versionName, int? id = null,
                                                    int? sequence = null)
            {
                return new ReleaseVersion
                {
                    Id = id ?? Fixture.Integer(),
                    ReleaseDate = releaseDate,
                    VersionName = versionName,
                    Sequence = sequence
                }.In(_db);
            }
        }
    }
}