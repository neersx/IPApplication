using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Picklists.ResponseShaping;
using Inprotech.Web.Picklists;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class RelationshipPicklistControllerFacts
    {
        public class RelationshipPicklistControllerFixture : IFixture<RelationshipPicklistController>
        {
            public RelationshipPicklistControllerFixture(InMemoryDbContext db)
            {
                var relationshipPicklistMaintenance = Substitute.For<IRelationshipPicklistMaintenance>();
                var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                Subject = new RelationshipPicklistController(db, relationshipPicklistMaintenance, preferredCultureResolver);
            }

            public RelationshipPicklistController Subject { get; }
        }

        public class RelationshipsMethod : FactBase
        {
            public dynamic Relationships()
            {
                var c1 =
                    new CaseRelationBuilder {RelationshipCode = "ASG", RelationshipDescription = "Assignment/Recordal"}
                        .Build().In(Db);

                var c2 =
                    new CaseRelationBuilder {RelationshipCode = "GBC", RelationshipDescription = "British corresponding Regn/Appln"}
                        .Build().In(Db);

                var c3 =
                    new CaseRelationBuilder {RelationshipCode = "GBD", RelationshipDescription = "British corresponding Design"}
                        .Build().In(Db);

                return new
                {
                    c1,
                    c2,
                    c3
                };
            }

            [Fact]
            public void ReturnsAllMatchingRelationshipsWhenSearchedForOrderedByDescription()
            {
                var relationships = Relationships();
                var c2 = (CaseRelation) relationships.c2;
                var c3 = (CaseRelation) relationships.c3;

                var f = new RelationshipPicklistControllerFixture(Db);

                var result =
                    ((IEnumerable<Relationship>) f.Subject.Relationships(null, "corresponding").Data).ToArray();

                Assert.Equal(2, result.Length);
                Assert.Equal(c3.Relationship, result.First().Code);
                Assert.Equal(c2.Relationship, result.Last().Code);
                Assert.Equal(c3.Description, result.First().Value);
                Assert.Equal(c2.Description, result.Last().Value);
            }

            [Fact]
            public void ReturnsAllRelationships()
            {
                Relationships();

                var f = new RelationshipPicklistControllerFixture(Db);

                var result =
                    ((IEnumerable<Relationship>) f.Subject.Relationships().Data).ToArray();

                Assert.Equal(3, result.Length);
                Assert.Equal(Db.Set<CaseRelation>().AsQueryable().OrderBy(_ => _.Relationship).First().Relationship,
                             result.First().Code);
            }

            [Fact]
            public void ReturnsExactMatchingCode()
            {
                var relationships = Relationships();
                var c1 = (CaseRelation) relationships.c1;

                var f = new RelationshipPicklistControllerFixture(Db);

                var result =
                    ((IEnumerable<Relationship>) f.Subject.Relationships(null, c1.Relationship).Data).ToArray();

                Assert.Single(result);
                Assert.Equal(c1.Relationship, result[0].Code);
            }

            [Fact]
            public void ReturnsExactMatchingDescription()
            {
                var relationships = Relationships();
                var c1 = (CaseRelation) relationships.c1;

                var f = new RelationshipPicklistControllerFixture(Db);

                var result =
                    ((IEnumerable<Relationship>) f.Subject.Relationships(null, c1.Description).Data).ToArray();

                Assert.Single(result);
                Assert.Equal(c1.Description, result[0].Value);
            }
        }

        public class RelationshipFacts
        {
            readonly Type _subject = typeof(Relationship);

            [Fact]
            public void DisplaysFollowingFields()
            {
                Assert.Equal(new[] {"Code", "Value"},
                             _subject.DisplayableFields());
            }

            [Fact]
            public void HighightedFields()
            {
                Assert.Equal(new[] {"Code", "Value"},
                             _subject.HighlightedFields());
            }

            [Fact]
            public void PicklistCodeIsDefined()
            {
                Assert.NotNull(_subject
                               .GetProperty("Code").GetCustomAttribute<PicklistCodeAttribute>());
            }

            [Fact]
            public void PicklistDescriptionIsDefined()
            {
                Assert.NotNull(_subject
                               .GetProperty("Value").GetCustomAttribute<PicklistDescriptionAttribute>());
            }

            [Fact]
            public void SortableFields()
            {
                Assert.Equal(new[] {"Code", "Value"},
                             _subject.SortableFields());
            }
        }
    }
}