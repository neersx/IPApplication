using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class LedgerAccountPicklistControllerFacts : FactBase
    {
        [Fact]
        public async Task ReturnLedgerAccounts()
        {
            var f = new LedgerAccountPicklistControllerFixture(Db);
            f.WithLedgerTypeTableCode(Fixture.Integer(), Fixture.String(), Db)
             .WithLedgerAccount(1, Db)
             .WithLedgerAccount(1, Db)
             .WithLedgerAccountAndParentAccount(1, Db);

            var r = (await f.Subject.Search(null, string.Empty)).Data.ToArray();
            Assert.Equal(3,r.Length);
        }

        [Fact]
        public async Task ReturnSearchedLedgerAccounts()
        {
            var f = new LedgerAccountPicklistControllerFixture(Db);
            f.WithLedgerTypeTableCode(Fixture.Integer(), Fixture.String(), Db)
             .WithLedgerAccount(1, Db, "ABC")
             .WithLedgerAccount(1, Db, "ABCD")
             .WithLedgerAccountAndParentAccount(1, Db);

            var r = (await f.Subject.Search(null, "ab")).Data.ToArray();
            Assert.Equal(2,r.Length);
        }

        [Fact]
        public async Task ReturnRecordWithNoParentsSet()
        {
            var f = new LedgerAccountPicklistControllerFixture(Db);
            f.WithLedgerTypeTableCode(Fixture.Integer(), Fixture.String(), Db)
             .WithLedgerAccount(1, Db)
             .WithLedgerAccount(1, Db);

            var r = (await f.Subject.Search(null, string.Empty)).Data.ToArray();
            Assert.Equal("Movement",r.First().BudgetMovement);
        }

        [Fact]
        public async Task ReturnNoRecordWithIsActive0()
        {
            var f = new LedgerAccountPicklistControllerFixture(Db);
            f.WithLedgerTypeTableCode(Fixture.Integer(), Fixture.String(), Db)
             .WithLedgerAccount(0, Db)
             .WithLedgerAccount(0, Db);

            var r = (await f.Subject.Search(null, string.Empty)).Data.ToArray();
            Assert.Equal(0,r.Length);
        }
    }

    public class LedgerAccountPicklistControllerFixture : IFixture<LedgerAccountPicklistController>
    {
        public LedgerAccountPicklistControllerFixture(InMemoryDbContext db)
        {
            Subject = new LedgerAccountPicklistController(db);
        }

        public LedgerAccountPicklistController Subject { get; }
        public InMemoryDbContext DbContext { get; set; }
        int _ledgerTypeId;
        public LedgerAccountPicklistControllerFixture WithLedgerTypeTableCode(int id, string name, InMemoryDbContext db)
        {
            var ledgerTableCode = new TableCode(id, (short)TableTypes.LedgerAccountType, name).In(db);
            _ledgerTypeId = ledgerTableCode.Id;
            return this;
        }

        public LedgerAccountPicklistControllerFixture WithLedgerAccount(int isActive, InMemoryDbContext db, string accountCode = null)
        {
            var code = accountCode ?? Fixture.String();
            new LedgerAccount {AccountCode = code, Description = Fixture.String(), AccountType = _ledgerTypeId, BudgetMovement = 1, DisburseToWip = 0, IsActive = isActive}.In(db);
            return this;
        }

        public LedgerAccountPicklistControllerFixture WithLedgerAccountAndParentAccount(int isActive, InMemoryDbContext db, string accountCode = null)
        {
            var code = accountCode ?? Fixture.String();
            var account = new LedgerAccount {AccountCode = code, Description = Fixture.String(), AccountType = (short)TableTypes.LedgerAccountType, BudgetMovement = 1, DisburseToWip = 0, IsActive = isActive}.In(db);

            new LedgerAccount {AccountCode = Fixture.String(), Description = Fixture.String(), AccountType = _ledgerTypeId, BudgetMovement = 1, ParentAccountId = account.Id, IsActive = isActive}.In(db);
            return this;
        }
    }
}