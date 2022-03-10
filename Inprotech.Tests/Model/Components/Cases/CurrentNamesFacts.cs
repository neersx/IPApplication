using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases
{
    public class CurrentNamesFacts
    {
        public class ForSpecificNameTypesMethod : FactBase
        {
            [Fact]
            public void IgnoresCaseNamesThatExpiredLongAgo()
            {
                var c = new CaseWithName(Db) {CaseName = {ExpiryDate = Fixture.PastDate()}};
                var r = new CurrentNamesFixture(Db).Subject.For(c.Case.Id);

                Assert.False(r.Any());
            }

            [Fact]
            public void IgnoresCaseNamesThatExpiresToday()
            {
                var c = new CaseWithName(Db) {CaseName = {ExpiryDate = Fixture.Today()}};
                var r = new CurrentNamesFixture(Db).Subject.For(c.Case.Id);

                Assert.False(r.Any());
            }

            [Fact]
            public void IgnoresCaseNamesThatHaveNotCommenced()
            {
                var c = new CaseWithName(Db) {CaseName = {StartingDate = Fixture.FutureDate()}};
                var r = new CurrentNamesFixture(Db).Subject.For(c.Case.Id);

                Assert.False(r.Any());
            }
            
            [Fact]
            public void ReturnsCaseNamesThatAreNotExpired()
            {
                var c = new CaseWithName(Db) {CaseName = {ExpiryDate = Fixture.FutureDate()}};
                var r = new CurrentNamesFixture(Db).Subject.For(c.Case.Id);

                Assert.True(r.Any());
            }

            [Fact]
            public void ReturnsCaseNamesThatHaveCommenced()
            {
                var c = new CaseWithName(Db) {CaseName = {StartingDate = Fixture.Today()}};
                var r = new CurrentNamesFixture(Db).Subject.For(c.Case.Id);

                Assert.True(r.Any());
            }

            [Fact]
            public void ReturnsNamesThatHaveNotBeenCeased()
            {
                var c = new CaseWithName(Db) {Name = {DateCeased = Fixture.FutureDate()}};
                var r = new CurrentNamesFixture(Db).Subject.For(c.Case.Id);

                Assert.True(r.Any());
            }
        }

        public class ForMethod : FactBase
        {
            [Fact]
            public void IgnoresCaseNamesThatExpiredLongAgo()
            {
                var c = new CaseWithName(Db) {CaseName = {ExpiryDate = Fixture.PastDate()}};
                var r = new CurrentNamesFixture(Db).Subject.For(c.Case);

                Assert.False(r.Any());
            }

            [Fact]
            public void IgnoresCaseNamesThatExpiresToday()
            {
                var c = new CaseWithName(Db) {CaseName = {ExpiryDate = Fixture.Today()}};
                var r = new CurrentNamesFixture(Db).Subject.For(c.Case);

                Assert.False(r.Any());
            }

            [Fact]
            public void IgnoresCaseNamesThatHaveNotCommenced()
            {
                var c = new CaseWithName(Db) {CaseName = {StartingDate = Fixture.FutureDate()}};
                var r = new CurrentNamesFixture(Db).Subject.For(c.Case);

                Assert.False(r.Any());
            }

            [Fact]
            public void IgnoresNamesThatHaveBeenCeasedLongAgo()
            {
                var c = new CaseWithName(Db) {Name = {DateCeased = Fixture.PastDate()}};
                var r = new CurrentNamesFixture(Db).Subject.For(c.Case);

                Assert.False(r.Any());
            }

            [Fact]
            public void IgnoresNamesThatHaveBeenCeasedToday()
            {
                var c = new CaseWithName(Db) {Name = {DateCeased = Fixture.Today()}};
                var r = new CurrentNamesFixture(Db).Subject.For(c.Case);

                Assert.False(r.Any());
            }

            [Fact]
            public void ReturnsCaseNamesThatAreNotExpired()
            {
                var c = new CaseWithName(Db) {CaseName = {ExpiryDate = Fixture.FutureDate()}};
                var r = new CurrentNamesFixture(Db).Subject.For(c.Case);

                Assert.True(r.Any());
            }

            [Fact]
            public void ReturnsCaseNamesThatHaveCommenced()
            {
                var c = new CaseWithName(Db) {CaseName = {StartingDate = Fixture.Today()}};
                var r = new CurrentNamesFixture(Db).Subject.For(c.Case);

                Assert.True(r.Any());
            }

            [Fact]
            public void ReturnsNamesThatHaveNotBeenCeased()
            {
                var c = new CaseWithName(Db) {Name = {DateCeased = Fixture.FutureDate()}};
                var r = new CurrentNamesFixture(Db).Subject.For(c.Case);

                Assert.True(r.Any());
            }
        }

        public class CaseWithName
        {
            public CaseWithName(InMemoryDbContext db)
            {
                Case = new CaseBuilder().Build().In(db);

                NameType = new NameTypeBuilder().Build().In(db);

                Name = new NameBuilder(db).Build().In(db);

                CaseName = new CaseNameBuilder(db)
                {
                    Name = Name,
                    NameType = NameType
                }.BuildWithCase(Case).In(db);
            }

            public Case Case { get; }
            public NameType NameType { get; }
            public InprotechKaizen.Model.Names.Name Name { get; }
            public CaseName CaseName { get; }
        }

        public class CurrentNamesFixture : IFixture<CurrentNames>
        {
            public CurrentNamesFixture(IDbContext db)
            {
                SystemClock = Substitute.For<Func<DateTime>>();
                SystemClock().Returns(Fixture.Today());

                Subject = new CurrentNames(SystemClock, db);
            }

            public Func<DateTime> SystemClock { get; set; }

            public CurrentNames Subject { get; set; }
        }
    }
}