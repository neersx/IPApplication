using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.BatchEventUpdate;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Components.Cases.Restrictions;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate
{
    public class WarnOnlyRestrictionBuilderFacts
    {
        public class Build : FactBase
        {
            public class CaseWithName
            {
                public CaseWithName(InMemoryDbContext db)
                {
                    CheckResult = new DataEntryTaskPrerequisiteCheckResult();

                    Case = new CaseBuilder().Build().In(db);

                    ClientDetail =
                        new ClientDetailBuilder {DebtorStatus = new DebtorStatusBuilder().Build().In(db)}.Build().In(db);

                    CaseName = new CaseNameBuilder(db)
                    {
                        Case = Case,
                        Name = new NameBuilder(db)
                        {
                            ClientDetail = ClientDetail
                        }.Build().In(db)
                    }.Build().In(db);
                    Case.CaseNames.Add(CaseName);
                }

                public DataEntryTaskPrerequisiteCheckResult CheckResult { get; }
                public Case Case { get; }
                public CaseName CaseName { get; }
                public ClientDetail ClientDetail { get; }

                public CaseWithName WithDebtorStatus(short restrictionType)
                {
                    CheckResult.CaseNameRestrictions = new[]
                    {
                        new CaseNameRestriction(
                                                CaseName,
                                                CaseName.Name.ClientDetail.DebtorStatus)
                    };

                    CaseName.Name.ClientDetail.DebtorStatus.RestrictionType = restrictionType;
                    return this;
                }
            }

            [Fact]
            public void GroupsRestrictionsByNameAndNameType()
            {
                var c = new CaseWithName(Db).WithDebtorStatus(KnownDebtorRestrictions.DisplayWarning);

                c.CaseName.Name.ClientDetail.DebtorStatus.Status = "b";
                c.CheckResult.CaseNamesWithCreditLimitExceeded = new[] {c.CaseName};

                var r = new WarnOnlyRestrictionsBuilder().Build(c.Case, c.CheckResult).ToArray();

                Assert.Single(r);
                Assert.Equal(c.CaseName.Name.Formatted(), r.Single().FormattedName);
                Assert.Same(c.CaseName.NameType.Name, r.Single().NameTypeDescription);
                Assert.Equal(2, r.Single().Restrictions.Count);
                Assert.Contains(r.Single().Restrictions, r1 => r1.Message == Resources.WarningCreditLimitExceeded);
                Assert.Contains(r.Single().Restrictions, r1 => r1.Message == "b");
            }

            [Fact]
            public void IgnoresBlockingRestrictions()
            {
                var c = new CaseWithName(Db).WithDebtorStatus(KnownDebtorRestrictions.DisplayError);
                var r = new WarnOnlyRestrictionsBuilder().Build(c.Case, c.CheckResult);

                Assert.False(r.Any());
            }

            [Fact]
            public void IgnoresRestrictionsRequiringApproval()
            {
                var c =
                    new CaseWithName(Db).WithDebtorStatus(KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation);
                var r = new WarnOnlyRestrictionsBuilder().Build(c.Case, c.CheckResult);

                Assert.False(r.Any());
            }

            [Fact]
            public void ReturnsCreditLimitRestrictions()
            {
                var c = new CaseWithName(Db);

                c.CheckResult.CaseNamesWithCreditLimitExceeded = new[] {c.CaseName};

                var r = new WarnOnlyRestrictionsBuilder().Build(c.Case, c.CheckResult).ToArray();

                Assert.Single(r);
                Assert.Equal(c.CaseName.Name.Formatted(), r.Single().FormattedName);
                Assert.Same(c.CaseName.NameType.Name, r.Single().NameTypeDescription);
                Assert.Same(Resources.WarningCreditLimitExceeded, r.Single().Restrictions.Single().Message);
                Assert.Equal(Severity.Warning, r.Single().Restrictions.Single().Severity);
            }

            [Fact]
            public void ReturnsDebtorStatusRestrictionsWithInformationSeverity()
            {
                var c = new CaseWithName(Db).WithDebtorStatus(KnownDebtorRestrictions.NoRestriction);

                c.CaseName.Name.ClientDetail.DebtorStatus.Status = "a";

                var r = new WarnOnlyRestrictionsBuilder().Build(c.Case, c.CheckResult).ToArray();

                Assert.Single(r);
                Assert.Equal(c.CaseName.Name.Formatted(), r.Single().FormattedName);
                Assert.Same(c.CaseName.NameType.Name, r.Single().NameTypeDescription);
                Assert.Same("a", r.Single().Restrictions.Single().Message);
                Assert.Equal(Severity.Information, r.Single().Restrictions.Single().Severity);
            }

            [Fact]
            public void ReturnsDebtorStatusRestrictionsWithWarningSeverity()
            {
                var c = new CaseWithName(Db).WithDebtorStatus(KnownDebtorRestrictions.DisplayWarning);

                c.CaseName.Name.ClientDetail.DebtorStatus.Status = "b";

                var r = new WarnOnlyRestrictionsBuilder().Build(c.Case, c.CheckResult).ToArray();

                Assert.Single(r);
                Assert.Equal(c.CaseName.Name.Formatted(), r.Single().FormattedName);
                Assert.Same(c.CaseName.NameType.Name, r.Single().NameTypeDescription);
                Assert.Same("b", r.Single().Restrictions.Single().Message);
                Assert.Equal(Severity.Warning, r.Single().Restrictions.Single().Severity);
            }
        }
    }
}