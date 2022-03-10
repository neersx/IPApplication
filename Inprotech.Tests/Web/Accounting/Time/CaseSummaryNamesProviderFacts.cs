using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Accounting.Time;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class CaseSummaryNamesProviderFacts : FactBase
    {
        public class GetNamesMethod : FactBase
        {
            [Fact]
            public async Task ReturnsRequiredFormattedNames()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var name1 = new NameBuilder(Db) { NameCode = Fixture.String() }.Build().In(Db);
                var name2 = new NameBuilder(Db) { NameCode = string.Empty }.Build().In(Db);
                var name3 = new NameBuilder(Db) { NameCode = string.Empty }.Build().In(Db);
                var name4 = new NameBuilder(Db) { NameCode = string.Empty }.Build().In(Db);

                var fixture = new CaseSummaryNamesProviderFixture(Db)
                              .WithNameType(KnownNameTypes.Instructor, out var nt1).WithCaseName(@case, nt1, name1)
                              .WithNameType(KnownNameTypes.Debtor, out var nt2).WithCaseName(@case, nt2, name1)
                              .WithCaseName(@case, nt2, name2)
                              .WithNameType(KnownNameTypes.Owner, out var nt3).WithCaseName(@case, nt3, name3)
                              .WithNameType(KnownNameTypes.StaffMember, out var nt4).WithCaseName(@case, nt4, name4)
                              .WithNameType(KnownNameTypes.Signatory, out var nt5).WithCaseName(@case, nt5, name4)
                              .WithNameType("XYZ", out var nt6).WithCaseName(@case, nt6, name4);

                nt1.ShowNameCode = 1m;
                nt2.ShowNameCode = 2m;
                nt3.ShowNameCode = null;
                nt4.ShowNameCode = null;
                nt5.ShowNameCode = null;

                var r = (await fixture.Subject
                                      .GetNames(@case.Id)).ToArray();

                var name1Formatted = name1.Formatted(fallbackNameStyle: NameStyles.FirstNameThenFamilyName);
                var name2Formatted = name2.Formatted(fallbackNameStyle: NameStyles.FirstNameThenFamilyName);
                var name3Formatted = name3.Formatted(fallbackNameStyle: NameStyles.FirstNameThenFamilyName);
                var name4Formatted = name4.Formatted(fallbackNameStyle: NameStyles.FirstNameThenFamilyName);

                Assert.Equal(6, r.Length);

                Assert.Equal(name1Formatted, r.Single(_ => _.TypeId == nt1.NameTypeCode).Name);
                Assert.Equal($"{{{name1.NameCode}}} {name1.Formatted(fallbackNameStyle: NameStyles.FirstNameThenFamilyName)}", r.Single(_ => _.TypeId == nt1.NameTypeCode).NameAndCode);

                Assert.Equal(name1Formatted, r.Single(_ => _.TypeId == nt2.NameTypeCode && _.Id == name1.Id).Name);
                Assert.Equal($"{name1.Formatted(fallbackNameStyle: NameStyles.FirstNameThenFamilyName)} {{{name1.NameCode}}}", r.Single(_ => _.TypeId == nt2.NameTypeCode && _.Id == name1.Id).NameAndCode);

                Assert.Equal(name2Formatted, r.Single(_ => _.TypeId == nt2.NameTypeCode && _.Id == name2.Id).Name);
                Assert.Equal(name2Formatted, r.Single(_ => _.TypeId == nt2.NameTypeCode && _.Id == name2.Id).NameAndCode);

                Assert.Equal(name3Formatted, r.Single(_ => _.TypeId == nt3.NameTypeCode).Name);
                Assert.Equal(name3Formatted, r.Single(_ => _.TypeId == nt3.NameTypeCode).NameAndCode);

                Assert.Equal(name4Formatted, r.Single(_ => _.TypeId == nt4.NameTypeCode).Name);
                Assert.Equal(name4Formatted, r.Single(_ => _.TypeId == nt4.NameTypeCode).NameAndCode);

                Assert.Equal(name4Formatted, r.Single(_ => _.TypeId == nt5.NameTypeCode).Name);
                Assert.Equal(name4Formatted, r.Single(_ => _.TypeId == nt5.NameTypeCode).NameAndCode);

                await fixture.NameAuthorization.Received(1).AccessibleNames(Arg.Any<int []>());
            }

            [Fact]
            public async Task ReturnsReferenceField()
            {
                var reference = Fixture.String();
                var @case = new CaseBuilder().Build().In(Db);
                var name = new NameBuilder(Db) { NameCode = Fixture.String() }.Build().In(Db);
                var fixture = new CaseSummaryNamesProviderFixture(Db)
                              .WithNameType(KnownNameTypes.Instructor, out var nt1).WithCaseName(@case, nt1, name, reference);
                var r = (await fixture.Subject
                                      .GetNames(@case.Id)).ToArray();

                Assert.Equal(reference, r.First().Reference);
            }

            [Theory]
            [InlineData(60, 40, true)]
            [InlineData(100, 0, false)]
            public async Task DisplayBillPercentageOnlyWhereRelevant(decimal percentage1, decimal percentage2, bool expected)
            {
                var reference = Fixture.String();
                var @case = new CaseBuilder().Build().In(Db);
                var debtor1 = new NameBuilder(Db) { NameCode = Fixture.String() }.Build().In(Db);
                var debtor2 = new NameBuilder(Db) { NameCode = Fixture.String() }.Build().In(Db);
                var fixture = new CaseSummaryNamesProviderFixture(Db)
                              .WithNameType(KnownNameTypes.Debtor, out var nt1)
                              .WithCaseName(@case, nt1, debtor1, reference, percentage1)
                              .WithCaseName(@case, nt1, debtor2, reference, percentage2);
                var r = (await fixture.Subject
                                      .GetNames(@case.Id)).ToArray();
                Assert.True(r.All(_ => _.BillingPercentage.HasValue));
                Assert.Equal(expected, r.All(_ => _.ShowBillPercentage));
            }

            [Fact]
            public async Task ChecksAuthorisedNames()
            {
                var reference = Fixture.String();
                var @case = new CaseBuilder().Build().In(Db);
                var name1 = new NameBuilder(Db) { NameCode = Fixture.String() }.Build().In(Db);
                var name2 = new NameBuilder(Db) { NameCode = Fixture.String() }.Build().In(Db);
                var fixture = new CaseSummaryNamesProviderFixture(Db)
                              .WithNameType(KnownNameTypes.Instructor, out var nt1).WithCaseName(@case, nt1, name1, reference)
                              .WithNameType(KnownNameTypes.Debtor, out var nt2).WithCaseName(@case, nt2, name2, reference);
                fixture.NameAuthorization.AccessibleNames(Arg.Any<int[]>()).Returns(x => new []{name2.Id});
                var r = (await fixture.Subject.GetNames(@case.Id)).ToArray();
                Assert.Equal(reference, r.First().Reference);
                await fixture.NameAuthorization.Received(1).AccessibleNames(Arg.Is<int []>(x => x.Contains(name1.Id)));
                Assert.False(r.Single(_ => _.Id == name1.Id).CanView);
                Assert.True(r.Single(_ => _.Id == name2.Id).CanView);
            }
        }

        public class CaseSummaryNamesProviderFixture : IFixture<CaseSummaryNamesProvider>
        {
            readonly InMemoryDbContext _db;

            public CaseSummaryNamesProviderFixture(InMemoryDbContext db)
            {
                _db = db;

                var cultureResolver = Substitute.For<IPreferredCultureResolver>();
                cultureResolver.Resolve().Returns("en");
                NameAuthorization = Substitute.For<INameAuthorization>();

                Subject = new CaseSummaryNamesProvider(db, cultureResolver, NameAuthorization);
            }

            public INameAuthorization NameAuthorization { get; set; }
            public CaseSummaryNamesProvider Subject { get; }
            public CaseSummaryNamesProviderFixture WithNameType(string nameTypeCode, out NameType nt)
            {
                nt = new NameTypeBuilder
                     {
                         NameTypeCode = nameTypeCode,
                         PriorityOrder = (short)_db.Set<NameType>().Count()
                     }
                     .Build()
                     .In(_db);

                return this;
            }

            public CaseSummaryNamesProviderFixture WithCaseName(Case @case, NameType nameType, Name name = null, string reference = null, decimal? billPercentage = null)
            {
                new CaseNameBuilder(_db)
                {
                    Name = name ?? new NameBuilder(_db).Build().In(_db),
                    NameType = nameType,
                    Reference = reference,
                    BillPercentage = billPercentage
                }.BuildWithCase(@case).In(_db);

                return this;
            }
        }
    }
}
