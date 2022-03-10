using System.Collections.Generic;
using System.Linq;
using Inprotech.IntegrationServer.PtoAccess.Innography;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Integration.DataVerification;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Innography
{
    public class MappedParentRelatedCasesResolverFacts : FactBase
    {
        ParentRelatedCase CreateCase(string relationship = null)
        {
            return new ParentRelatedCase()
            {
                CountryCode = Fixture.String(),
                CaseKey = Fixture.Integer(),
                RelatedCaseId = Fixture.Integer(),
                RelatedCaseRef = Fixture.String(),
                Number = Fixture.String(),
                Date = Fixture.Date(),
                RelationId = Fixture.Integer(),
                Relationship = relationship ?? Fixture.String(),
                EventId = Fixture.Integer()
            };
        }

        [Fact]
        public void FallsBackToCaseCountryCodeIfNoMapping()
        {
            var parentRelatedCases = new List<ParentRelatedCase>()
            {
                CreateCase(),
                CreateCase(),
                CreateCase(),
            };

            var fixture = new MappedParentRelatedCasesResolverFixture(Db, parentRelatedCases);
            var subject = fixture.Subject;

            var relatedParents = subject.Resolve(parentRelatedCases.Select(x=> x.CaseKey).ToArray()).ToList();

            Assert.Equal(3, relatedParents.Count());
            Assert.Equal(relatedParents[0].CountryCode, parentRelatedCases[0].CountryCode);
            Assert.Equal(relatedParents[1].CountryCode, parentRelatedCases[1].CountryCode);
            Assert.Equal(relatedParents[2].CountryCode, parentRelatedCases[2].CountryCode);
        }
       
        [Fact]
        public void MapsCountryCodeIfThereIsValueForIt()
        {
            var parentRelatedCases = new List<ParentRelatedCase>()
            {
                CreateCase(),
                CreateCase(),
                CreateCase(),
            };

            var mappedCode1 = Fixture.String();
            var mappedCode2= Fixture.String();
            var mappedCode3 = Fixture.String();
            var fixture = new MappedParentRelatedCasesResolverFixture(Db, parentRelatedCases);
            fixture.CountryCodeResolver.ResolveMapping().Returns(new Dictionary<string, string>
            {
                {
                    parentRelatedCases[0].CountryCode, mappedCode1
                },
                {
                    parentRelatedCases[1].CountryCode, mappedCode2
                },
                {
                    parentRelatedCases[2].CountryCode, mappedCode3
                }
            });
            var subject = fixture.Subject;

            var relatedParents = subject.Resolve(parentRelatedCases.Select(x=> x.CaseKey).ToArray()).ToList();

            Assert.Equal(3, relatedParents.Count());
            Assert.Equal(relatedParents[0].CountryCode, mappedCode1);
            Assert.Equal(relatedParents[1].CountryCode, mappedCode2);
            Assert.Equal(relatedParents[2].CountryCode, mappedCode3);
        }
         
        [Fact]
        public void MapsRelationshipCodeIfThereIsValueForIt()
        {
            
            var mappedCode1 = Fixture.String();
            var mappedCode2= Fixture.String();

            var parentRelatedCases = new List<ParentRelatedCase>()
            {
                CreateCase(mappedCode1),
                CreateCase(mappedCode1),
                CreateCase(mappedCode2),
            };

            var fixture = new MappedParentRelatedCasesResolverFixture(Db, parentRelatedCases);
            fixture.RelationshipCodeResolver.ResolveMapping(Arg.Any<string[]>()).Returns(new Dictionary<string, string>()
            {
                {
                    Relations.PctApplication, mappedCode1
                },
                {
                    Relations.EarliestPriority, mappedCode2
                }
            });

            var subject = fixture.Subject;

            var relatedParents = subject.Resolve(parentRelatedCases.Select(x=> x.CaseKey).ToArray()).ToList();

            Assert.Equal(3, relatedParents.Count());
            Assert.Equal(relatedParents[0].RelationshipId, Relations.PctApplication);
            Assert.Equal(relatedParents[1].RelationshipId, Relations.PctApplication);
            Assert.Equal(relatedParents[2].RelationshipId, Relations.EarliestPriority);
        }

        [Fact]
        public void FallsBackToRelationshipCodeIfNoMapping()
        {
            var parentRelatedCases = new List<ParentRelatedCase>()
            {
                CreateCase(),
                CreateCase(),
                CreateCase(),
            };

            var fixture = new MappedParentRelatedCasesResolverFixture(Db, parentRelatedCases);

            var subject = fixture.Subject;

            var relatedParents = subject.Resolve(parentRelatedCases.Select(x=> x.CaseKey).ToArray()).ToList();

            Assert.Equal(3, relatedParents.Count());
            Assert.Equal(relatedParents[0].Relationship, parentRelatedCases[0].Relationship);
            Assert.Equal(relatedParents[1].Relationship, parentRelatedCases[1].Relationship);
            Assert.Equal(relatedParents[2].Relationship, parentRelatedCases[2].Relationship);
        }

        public class MappedParentRelatedCasesResolverFixture
        {
            public MappedParentRelatedCasesResolver Subject
            {
                get;
            }

            public ICountryCodeResolver CountryCodeResolver
            {
                get;
            }

            public IParentRelatedCases ParentRelatedCases
            {
                get;
            }

            public IRelationshipCodeResolver RelationshipCodeResolver
            {
                get;
            }
            public MappedParentRelatedCasesResolverFixture(InMemoryDbContext db, List<ParentRelatedCase> relatedParents)
            {
                RelationshipCodeResolver = Substitute.For<IRelationshipCodeResolver>();
                RelationshipCodeResolver.ResolveMapping(Arg.Any<string[]>()).Returns(new Dictionary<string, string>());

                new[]
                {
                    new CaseRelation
                    {
                        Relationship = KnownRelations.PctParentApp,
                    },
                    new CaseRelation
                    {
                        Relationship = KnownRelations.EarliestPriority,
                    }
                }.In(db);

                var countryCodes = relatedParents.Select(x=> x.CountryCode).ToDictionary(x=> x, x=> x);
                CountryCodeResolver = Substitute.For<ICountryCodeResolver>();
                ParentRelatedCases = Substitute.For<IParentRelatedCases>();
                ParentRelatedCases.Resolve(Arg.Any<int[]>(), Arg.Any<string[]>()).Returns(relatedParents);
                CountryCodeResolver.ResolveMapping().Returns(countryCodes);
                Subject = new MappedParentRelatedCasesResolver(ParentRelatedCases, RelationshipCodeResolver, CountryCodeResolver);
            }
        }

    }
}
