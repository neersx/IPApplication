using System;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using NSubstitute;
using Xunit;
using Case = InprotechKaizen.Model.Cases.Case;
using CaseName = InprotechKaizen.Model.Cases.CaseName;
using ComparisonModels = InprotechKaizen.Model.Components.Cases.Comparison.Models;
using NameBuilder = Inprotech.Tests.Web.Builders.Model.Names.NameBuilder;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Comparers
{
    public class NamesComparerFacts
    {
        public class CompareMethod : FactBase
        {
            readonly NameComparisonScenarioBuilder _scenarioBuilder = new NameComparisonScenarioBuilder();

            [Theory]
            [InlineData("Tony", "STARK")]
            [InlineData("TONY", "stark")]
            public void MatchesFormattedName(string firstName, string lastName)
            {
                _scenarioBuilder.Name = new ComparisonModels.Name
                {
                    FirstName = firstName,
                    LastName = lastName,
                    NameTypeCode = "A"
                };

                var f = new NamesComparerFixture(Db)
                        .WithCaseName("A", "ABC", "Stark", "Tony")
                        .Configure();

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(f.Case, new[] {_scenarioBuilder.Build()}, cr);

                var comparisonCaseName = cr.CaseNames.Single();
                var inproCaseName = f.Case.CaseNames.Single();

                Assert.Equal("ABC", comparisonCaseName.NameType);
                Assert.Equal("Stark, Tony", comparisonCaseName.Name.OurValue);
                Assert.Equal(false, comparisonCaseName.Name.Different);
                Assert.Equal(false, comparisonCaseName.Name.Updateable);
                Assert.Equal(inproCaseName.NameId, comparisonCaseName.NameId);
                Assert.Equal(inproCaseName.NameTypeId, comparisonCaseName.NameTypeId);
                Assert.Equal(inproCaseName.Sequence, comparisonCaseName.Sequence);
            }

            [Theory]
            [InlineData("Charpentier, Pierre Emmanuel", "Pierre Emmanuel Charpentier", "")]
            public void MatchesFreeFormattedName(string freeFormattedName, string persistedName, string persistedFirstName)
            {
                _scenarioBuilder.Name = new ComparisonModels.Name
                {
                    FreeFormatName = freeFormattedName,
                    NameTypeCode = "A"
                };

                var f = new NamesComparerFixture(Db)
                        .WithCaseName("A", "ABC", persistedName, persistedFirstName)
                        .Configure();

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(f.Case, new[] {_scenarioBuilder.Build()}, cr);

                var comparisonCaseName = cr.CaseNames.Single();
                var inproCaseName = f.Case.CaseNames.Single();

                var formattedResult = string.IsNullOrWhiteSpace(persistedFirstName)
                    ? persistedName
                    : persistedName + ", " + persistedFirstName;

                Assert.Equal("ABC", comparisonCaseName.NameType);
                Assert.Equal(formattedResult, comparisonCaseName.Name.OurValue);
                Assert.Equal(freeFormattedName, comparisonCaseName.Name.TheirValue);
                Assert.Equal(false, comparisonCaseName.Name.Different);
                Assert.Equal(false, comparisonCaseName.Name.Updateable);
                Assert.Equal(inproCaseName.NameId, comparisonCaseName.NameId);
                Assert.Equal(inproCaseName.NameTypeId, comparisonCaseName.NameTypeId);
                Assert.Equal(inproCaseName.Sequence, comparisonCaseName.Sequence);
            }

            [Theory]
            [InlineData("O")]
            [InlineData("J")]
            public void IdentifiesAddressDifferencesInSingleNames(string nameType)
            {
                _scenarioBuilder.Name = new ComparisonModels.Name
                {
                    FreeFormatName = "Tony Stark",
                    Street = "4 York",
                    CountryCode = "AU",
                    StateName = "NSW",
                    NameTypeCode = nameType
                };

                var address = string.Format("4 Yorkers{0}NSW{0}AU", Environment.NewLine);

                var f = new NamesComparerFixture(Db)
                        .WithCaseName(nameType, nameType, "Stark", "Tony", address)
                        .WithCountry("AU", "Australia")
                        .Configure();

                f.Case.CaseNames.Single().NameType.MaximumAllowed = 1;

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(f.Case, new[] {_scenarioBuilder.Build()}, cr);

                var comparisonCaseName = cr.CaseNames.Single();
                var inproCaseName = f.Case.CaseNames.Single();

                Assert.Equal(nameType, comparisonCaseName.NameType);
                Assert.Equal(false, comparisonCaseName.Name.Different);
                Assert.Equal(true, comparisonCaseName.Address.Different);
                Assert.Equal(false, comparisonCaseName.Name.Updateable);
                Assert.Equal(inproCaseName.NameId, comparisonCaseName.NameId);
                Assert.Equal(inproCaseName.NameTypeId, comparisonCaseName.NameTypeId);
                Assert.Equal(inproCaseName.Sequence, comparisonCaseName.Sequence);
            }

            [Theory]
            [InlineData("O")]
            [InlineData("J")]
            public void MatchesAddress(string nameType)
            {
                _scenarioBuilder.Name = new ComparisonModels.Name
                {
                    FreeFormatName = "Tony Stark",
                    Street = "4 York",
                    CountryCode = "AU",
                    StateName = "NSW",
                    NameTypeCode = nameType
                };

                var address = string.Format("4 York{0}NSW{0}Australia", Environment.NewLine);

                var f = new NamesComparerFixture(Db)
                        .WithCaseName(nameType, nameType, "Stark", "Tony", address)
                        .WithCountry("AU", "Australia")
                        .Configure();

                f.Case.CaseNames.Single().NameType.MaximumAllowed = 1;

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(f.Case, new[] {_scenarioBuilder.Build()}, cr);

                var comparisonCaseName = cr.CaseNames.Single();
                var inproCaseName = f.Case.CaseNames.Single();

                Assert.Equal(nameType, comparisonCaseName.NameType);
                Assert.Equal(false, comparisonCaseName.Name.Different);
                Assert.Equal(false, comparisonCaseName.Address.Different);
                Assert.Equal(false, comparisonCaseName.Name.Updateable);
                Assert.Equal(inproCaseName.NameId, comparisonCaseName.NameId);
                Assert.Equal(inproCaseName.NameTypeId, comparisonCaseName.NameTypeId);
                Assert.Equal(inproCaseName.Sequence, comparisonCaseName.Sequence);
            }

            [Theory]
            [InlineData("I")]
            [InlineData("EMP")]
            public void IgnoreAddressDifferencesForOtherNames(string nameType)
            {
                _scenarioBuilder.Name = new ComparisonModels.Name
                {
                    FreeFormatName = "Tony Stark",
                    NameTypeCode = nameType
                };

                var address = string.Format("4 York{0}NSW{0}Australia", Environment.NewLine);

                var f = new NamesComparerFixture(Db)
                        .WithCaseName(nameType, nameType, "Stark", "Tony", address)
                        .WithCountry("AU", "Australia")
                        .Configure();

                f.Case.CaseNames.Single().NameType.MaximumAllowed = 1;

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(f.Case, new[] {_scenarioBuilder.Build()}, cr);

                var comparisonCaseName = cr.CaseNames.Single();
                var inproCaseName = f.Case.CaseNames.Single();

                Assert.Equal(nameType, comparisonCaseName.NameType);
                Assert.Equal(false, comparisonCaseName.Name.Different);
                Assert.Equal(false, comparisonCaseName.Address.Different);
                Assert.Equal(false, comparisonCaseName.Name.Updateable);
                Assert.Equal(inproCaseName.NameId, comparisonCaseName.NameId);
                Assert.Equal(inproCaseName.NameTypeId, comparisonCaseName.NameTypeId);
                Assert.Equal(inproCaseName.Sequence, comparisonCaseName.Sequence);
            }

            [Theory]
            [InlineData("12345", "12345", false)]
            [InlineData("12345", "99999", true)]
            public void IncludesReferenceDifference(string caseNameref, string fileNameRef, bool isDifferent)
            {
                _scenarioBuilder.Name = new ComparisonModels.Name
                {
                    FreeFormatName = "Tony Stark",
                    NameTypeCode = "A",
                    NameReference = fileNameRef
                };

                var f = new NamesComparerFixture(Db)
                        .WithCaseName("A", "ABC", "Mokbel", "Tony", null, caseNameref)
                        .Configure();

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(f.Case, new[] {_scenarioBuilder.Build()}, cr);

                var comparisonCaseName = cr.CaseNames.Single();

                Assert.Equal(caseNameref, comparisonCaseName.Reference.OurValue);
                Assert.Equal(fileNameRef, comparisonCaseName.Reference.TheirValue);
                Assert.Equal(isDifferent, comparisonCaseName.Reference.Different);
                Assert.False(comparisonCaseName.Reference.Updateable != null && comparisonCaseName.Reference.Updateable.Value);
            }

            [Fact]
            public void IdentifiesDifferencesInSingleNames()
            {
                _scenarioBuilder.Name = new ComparisonModels.Name
                {
                    FreeFormatName = "Tony Stark",
                    NameTypeCode = "A"
                };

                var f = new NamesComparerFixture(Db)
                        .WithCaseName("A", "ABC", "Mokbel", "Tony")
                        .Configure();

                f.Case.CaseNames.Single().NameType.MaximumAllowed = 1;

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(f.Case, new[] {_scenarioBuilder.Build()}, cr);

                var comparisonCaseName = cr.CaseNames.Single();
                var inproCaseName = f.Case.CaseNames.Single();

                Assert.Equal("ABC", comparisonCaseName.NameType);
                Assert.Equal("Mokbel, Tony", comparisonCaseName.Name.OurValue);
                Assert.Equal("Tony Stark", comparisonCaseName.Name.TheirValue);
                Assert.Equal(true, comparisonCaseName.Name.Different);
                Assert.Equal(false, comparisonCaseName.Name.Updateable);
                Assert.Equal(inproCaseName.NameId, comparisonCaseName.NameId);
                Assert.Equal(inproCaseName.NameTypeId, comparisonCaseName.NameTypeId);
                Assert.Equal(inproCaseName.Sequence, comparisonCaseName.Sequence);
            }

            [Fact]
            public void IncludesReferenceDifferenceAndMarksUpdatable()
            {
                _scenarioBuilder.Name = new ComparisonModels.Name
                {
                    FreeFormatName = "Tony Stark",
                    NameTypeCode = "A",
                    NameReference = "12345"
                };

                var f = new NamesComparerFixture(Db)
                        .WithCaseName("A", "ABC", "Stark", "Tony", null, "ABCDE")
                        .Configure();

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(f.Case, new[] {_scenarioBuilder.Build()}, cr);

                var comparisonCaseName = cr.CaseNames.Single();

                Assert.Equal("ABCDE", comparisonCaseName.Reference.OurValue);
                Assert.Equal("12345", comparisonCaseName.Reference.TheirValue);
                Assert.True(comparisonCaseName.Reference.Different != null && comparisonCaseName.Reference.Different.Value);
                Assert.True(comparisonCaseName.Reference.Updateable != null && comparisonCaseName.Reference.Updateable.Value);
            }

            [Fact]
            public void PreparesCaseNameResult()
            {
                var cr = new ComparisonResult(Fixture.String());

                new NamesComparerFixture(Db)
                    .Subject
                    .Compare(new CaseBuilder().Build(), Enumerable.Empty<ComparisonScenario<ComparisonModels.Name>>(),
                             cr);

                Assert.Empty(cr.CaseNames);
                Assert.NotNull(cr.CaseNames);
            }

            [Fact]
            public void ReturnsMatchedOnesFirst()
            {
                var f = new NamesComparerFixture(Db)
                        .WithCaseName("A", null, "Mokbel", "Tony")
                        .Configure();

                f.Case.CaseNames.Single().NameType.MaximumAllowed = 2;

                var cr = new ComparisonResult(Fixture.String());

                f.Subject
                 .Compare(f.Case, new[]
                 {
                     new NameComparisonScenarioBuilder
                     {
                         Name = new ComparisonModels.Name
                         {
                             LastName = "Mokbel",
                             FirstName = "Tony",
                             NameTypeCode = "A"
                         }
                     }.Build(),
                     new NameComparisonScenarioBuilder
                     {
                         Name = new ComparisonModels.Name
                         {
                             LastName = "Trinh",
                             FirstName = "Tony",
                             NameTypeCode = "A"
                         }
                     }.Build()
                 }, cr);

                var unmatched = cr.CaseNames.First();
                var matched = cr.CaseNames.Last();
                var inproCaseName = f.Case.CaseNames.Single();

                Assert.Equal("Mokbel, Tony", matched.Name.TheirValue);
                Assert.Equal("Trinh, Tony", unmatched.Name.TheirValue);
                Assert.Equal(2, cr.CaseNames.Count());

                Assert.Equal(inproCaseName.NameId, matched.NameId);
                Assert.Equal(inproCaseName.NameTypeId, matched.NameTypeId);
                Assert.Equal(inproCaseName.Sequence, matched.Sequence);
            }

            [Fact]
            public void ReturnsUnmatchedWhenMultipleNamesAllowed()
            {
                _scenarioBuilder.Name = new ComparisonModels.Name
                {
                    FreeFormatName = "Tony Stark",
                    NameTypeCode = "A"
                };

                var f = new NamesComparerFixture(Db)
                        .WithCaseName("A", null, "Mokbel", "Tony")
                        .Configure();

                f.Case.CaseNames.Single().NameType.MaximumAllowed = 2;

                var cr = new ComparisonResult(Fixture.String());

                f.Subject
                 .Compare(f.Case, new[] {_scenarioBuilder.Build()}, cr);

                var unmatched = cr.CaseNames.First();
                var matched = cr.CaseNames.Last();
                var inproCaseName = f.Case.CaseNames.Single();

                Assert.Equal("Tony Stark", unmatched.Name.TheirValue);
                Assert.Null(unmatched.Name.OurValue);
                Assert.Equal(true, unmatched.Name.Different);
                Assert.Null(unmatched.NameId);
                Assert.Null(unmatched.NameTypeId);
                Assert.Null(unmatched.Sequence);

                Assert.Equal("Mokbel, Tony", matched.Name.OurValue);
                Assert.Null(matched.Name.TheirValue);
                Assert.Equal(true, matched.Name.Different);
                Assert.Equal(inproCaseName.NameId, matched.NameId);
                Assert.Equal(inproCaseName.NameTypeId, matched.NameTypeId);
                Assert.Equal(inproCaseName.Sequence, matched.Sequence);
            }
        }

        public class NamesComparerFixture : IFixture<NamesComparer>
        {
            readonly InMemoryDbContext _db;

            Case _case;

            public NamesComparerFixture(InMemoryDbContext db)
            {
                _db = db;
                CurrentNames = Substitute.For<ICurrentNames>();

                CaseNameAddressResolver = Substitute.For<ICaseNameAddressResolver>();

                var cultureResolver = Substitute.For<IPreferredCultureResolver>();

                Subject = new NamesComparer(db, CurrentNames, CaseNameAddressResolver,
                                            cultureResolver);
            }

            public ICurrentNames CurrentNames { get; set; }

            public ICaseNameAddressResolver CaseNameAddressResolver { get; set; }

            public Case Case => _case ?? (_case = new CaseBuilder().Build().In(_db));

            public NamesComparer Subject { get; set; }

            public NamesComparerFixture WithCaseName(string nameTypeCode, string nameTypeDescription, string name, string firstName, string address = null, string reference = null)
            {
                var nameType = _db.Set<NameType>()
                                  .SingleOrDefault(_ => _.NameTypeCode == nameTypeCode)
                               ?? new NameTypeBuilder
                                   {
                                       NameTypeCode = nameTypeCode,
                                       Name = nameTypeDescription ?? nameTypeCode
                                   }.Build()
                                    .In(_db);

                var caseName = new CaseNameBuilder(_db)
                    {
                        Case = Case,
                        Name = new NameBuilder(_db)
                            {
                                LastName = name,
                                FirstName = firstName
                            }.Build()
                             .In(_db),
                        NameType = nameType,
                        Reference = reference,
                        Sequence = 0
                    }.Build()
                     .In(_db);

                Case.CaseNames.Add(caseName);

                if (!string.IsNullOrWhiteSpace(address))
                {
                    CaseNameAddressResolver.Resolve(
                                                    Arg.Any<CaseName>())
                                           .Returns(new CaseNameAddress
                                           {
                                               FormattedAddress = address
                                           });
                }

                return this;
            }

            public NamesComparerFixture WithCountry(string countryCode, string countryName)
            {
                new CountryBuilder
                    {
                        Id = countryCode,
                        Name = countryName
                    }
                    .Build()
                    .In(_db);

                return this;
            }

            public NamesComparerFixture Configure()
            {
                CurrentNames.For(Case).Returns(Case.CaseNames);
                return this;
            }
        }
    }
}