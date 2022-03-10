using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Restrictions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Restrictions
{
    public class CaseCreditLimitCheckerFacts
    {
        public class NamesExceededCreditLimit : FactBase
        {
            public class CaseWithName
            {
                readonly InMemoryDbContext _db;

                public CaseWithName(InMemoryDbContext db, string type)
                {
                    _db = db;

                    Case = new CaseBuilder().Build().In(_db);

                    ExistingName = new NameBuilder(db).Build().In(_db);

                    var instructorNameType = new NameTypeBuilder {NameTypeCode = type}.Build().In(_db);

                    Name = new CaseNameBuilder(_db)
                    {
                        Name = ExistingName,
                        Case = Case,
                        NameType = instructorNameType
                    }.Build().In(_db);

                    Case.CaseNames.Add(Name);

                    ExistingName.ClientDetail = new ClientDetailBuilder().BuildForName(ExistingName).In(_db);
                    ExistingName.ClientDetail.CreditLimit = 1;
                }

                public Case Case { get; }
                public CaseName Name { get; }
                public InprotechKaizen.Model.Names.Name ExistingName { get; }

                public CaseWithName WithAnOpenItem()
                {
                    new OpenItemBuilder(_db)
                    {
                        AccountDebtorName = ExistingName,
                        LocalBalance = 100
                    }.Build().In(_db);

                    return this;
                }
            }

            [Fact]
            public void IgnoresCaseNamesWhichAreNotInstructorsOrDebtors()
            {
                var c = new CaseWithName(Db, KnownNameTypes.Owner).WithAnOpenItem();

                var f = new CaseCreditLimitCheckerFixture(Db);
                f.RestrictableCaseNames.For(c.Case).Returns(new[] {c.Name});

                var result = f.Subject.NamesExceededCreditLimit(c.Case);

                Assert.False(result.Any());
            }

            [Fact]
            public void IgnoresCaseNamesWithoutAnyOpenItems()
            {
                var c = new CaseWithName(Db, KnownNameTypes.Instructor);

                var f = new CaseCreditLimitCheckerFixture(Db);
                f.RestrictableCaseNames.For(c.Case).Returns(new[] {c.Name});

                var result = f.Subject.NamesExceededCreditLimit(c.Case);

                Assert.DoesNotContain(c.Name, result);
            }

            [Fact]
            public void IgnoresNamesWithoutCreditLimits()
            {
                var c = new CaseWithName(Db, KnownNameTypes.Instructor).WithAnOpenItem();
                c.Name.Name.ClientDetail.CreditLimit = null;

                var f = new CaseCreditLimitCheckerFixture(Db);
                f.RestrictableCaseNames.For(c.Case).Returns(new[] {c.Name});

                var result = f.Subject.NamesExceededCreditLimit(c.Case);

                Assert.False(result.Any());
            }

            [Fact]
            public void ReturnsDebtorThatExceededCreditLimit()
            {
                var c = new CaseWithName(Db, KnownNameTypes.Debtor).WithAnOpenItem();

                var f = new CaseCreditLimitCheckerFixture(Db);
                f.RestrictableCaseNames.For(c.Case).Returns(new[] {c.Name});

                var result = f.Subject.NamesExceededCreditLimit(c.Case).ToArray();

                Assert.True(result.Any());
            }

            [Fact]
            public void ReturnsInstructorThatExceededCreditLimit()
            {
                var c = new CaseWithName(Db, KnownNameTypes.Instructor).WithAnOpenItem();

                var f = new CaseCreditLimitCheckerFixture(Db);
                f.RestrictableCaseNames.For(c.Case).Returns(new[] {c.Name});

                var result = f.Subject.NamesExceededCreditLimit(c.Case);

                Assert.Contains(c.Name, result);
            }
        }
    }

    public class CaseCreditLimitCheckerFixture : IFixture<ICaseCreditLimitChecker>
    {
        public CaseCreditLimitCheckerFixture(InMemoryDbContext db)
        {
            RestrictableCaseNames = Substitute.For<IRestrictableCaseNames>();

            Subject = new CaseCreditLimitChecker(db, RestrictableCaseNames);
        }

        public IRestrictableCaseNames RestrictableCaseNames { get; set; }

        public ICaseCreditLimitChecker Subject { get; }
    }
}