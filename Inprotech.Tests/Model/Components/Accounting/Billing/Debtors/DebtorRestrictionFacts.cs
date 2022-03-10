using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model.Components.Accounting.Billing.Debtors;
using InprotechKaizen.Model.Persistence;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Debtors
{
    public class DebtorRestrictionFacts
    {
        public class DebtorRestrictionFixture : IFixture<DebtorRestriction>
        {
            public DebtorRestrictionFixture(IDbContext dbContext)
            {
                Subject = new DebtorRestriction(dbContext);
            }
            
            public DebtorRestriction Subject { get; }
        }

        public class GetDebtorRestrictionMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnNullWhenNoDebtorRestrictionStatusFound()
            {
                var n1 = new NameBuilder(Db).Build().In(Db);
                var n2 = new NameBuilder(Db).Build().In(Db);
                new ClientDetailBuilder().BuildForName(n1).In(Db);
                var f = new DebtorRestrictionFixture(Db);
                var r = await f.Subject.GetDebtorRestriction(Fixture.String(), n1.Id, n2.Id);
                Assert.Equal(2, r.Count);
                Assert.Equal(n1.Id, r.First().Key);
                Assert.Null(r.First().Value.DebtorStatus);
                Assert.Null(r.Last().Value.DebtorStatus);
            }

            [Fact]
            public async Task ShouldGetDebtorRestrictionStatus()
            {
                var n1 = new NameBuilder(Db).Build().In(Db);
                var n2 = new NameBuilder(Db).Build().In(Db);
                var debtorStatus = new DebtorStatusBuilder { Status = "Slow Payer" }.Build().In(Db);
                new ClientDetailBuilder {DebtorStatus = debtorStatus}.BuildForName(n1).In(Db);
                debtorStatus.RestrictionType = 1;
                
                var f = new DebtorRestrictionFixture(Db);
                var r = await f.Subject.GetDebtorRestriction(Fixture.String(), n1.Id, n2.Id);
                Assert.Equal(2, r.Count);
                Assert.Equal(n1.Id, r.First().Key);
                Assert.Equal(debtorStatus.Status, r.First().Value.DebtorStatus);
                Assert.Equal((short)1, r.First().Value.DebtorStatusAction);
                Assert.Null(r.Last().Value.DebtorStatus);
            }
        }

        public class HasDebtorsNotConfiguredForBillingMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnFalseIfDebtorIsConfiguredForBilling()
            {
                var n = new NameBuilder(Db).Build().In(Db);
                new ClientDetailBuilder().BuildForName(n).In(Db);

                var f = new DebtorRestrictionFixture(Db);
                var subject = f.Subject;
                var result = await subject.HasDebtorsNotConfiguredForBilling(n.Id);

                Assert.False(result);
            }

            [Fact]
            public async Task ShouldReturnTrueIfDebtorIsNotConfiguredForBilling()
            {
                var n = new NameBuilder(Db).Build().In(Db);
                
                // missing client detail for name.

                var f = new DebtorRestrictionFixture(Db);
                var subject = f.Subject;
                var result = await subject.HasDebtorsNotConfiguredForBilling(n.Id);

                Assert.True(result);
            }
        }
    }
}
