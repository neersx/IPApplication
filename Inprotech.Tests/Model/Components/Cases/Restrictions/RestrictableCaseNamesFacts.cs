using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.Restrictions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Restrictions
{
    public class RestrictableCaseNamesFacts
    {
        public class CaseWithName
        {
            public CaseWithName(InMemoryDbContext db)
            {
                Case = new CaseBuilder().Build().In(db);

                NameType = new NameTypeBuilder().Build().In(db);
                NameType.IsNameRestricted = 1;

                Name = new NameBuilder(db).Build().In(db);
                Name.ClientDetail = new ClientDetailBuilder().BuildForName(Name).In(db);

                CaseName = new CaseNameBuilder(db)
                {
                    Name = Name,
                    NameType = NameType
                }.Build().In(db);

                Case.CaseNames.Add(CaseName);
            }

            public Case Case { get; }
            public NameType NameType { get; }
            public InprotechKaizen.Model.Names.Name Name { get; }
            public CaseName CaseName { get; }
        }

        public class ForMethod : FactBase
        {
            [Fact]
            public void IgnoresNamesNotMarkedToBeConsideredForRestriction()
            {
                var c = new CaseWithName(Db) {NameType = {IsNameRestricted = 0}};
                var r = new RestrictableCaseNamesFixture().Subject.For(c.Case);

                Assert.False(r.Any());
            }

            [Fact]
            public void IgnoresNamesWithNoClientDetails()
            {
                var c = new CaseWithName(Db) {Name = {ClientDetail = null}};
                var r = new RestrictableCaseNamesFixture().Subject.For(c.Case);

                Assert.False(r.Any());
            }

            [Fact]
            public void ReturnsRestrictedNames()
            {
                var c = new CaseWithName(Db) {NameType = {IsNameRestricted = 1}};
                var r = new RestrictableCaseNamesFixture().Subject.For(c.Case);

                Assert.True(r.Any());
            }
        }

        public class RestrictableCaseNamesFixture : IFixture<RestrictableCaseNames>
        {
            public RestrictableCaseNamesFixture()
            {
                CurrentNames = Substitute.For<ICurrentNames>();
                CurrentNames.For(Arg.Any<Case>())
                            .Returns(x => ((Case) x[0]).CaseNames);

                Subject = new RestrictableCaseNames(CurrentNames);
            }

            public ICurrentNames CurrentNames { get; }

            public RestrictableCaseNames Subject { get; }
        }
    }
}