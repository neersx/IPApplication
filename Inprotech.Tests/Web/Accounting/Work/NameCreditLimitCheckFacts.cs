using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model.Accounting;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Work
{
    public class NameCreditLimitCheckFacts : FactBase
    {
        [Fact]
        public async Task ReturnsFalseWhereNoCreditLimit()
        {
            var name = new NameBuilder(Db).Build().In(Db);
            var f = new NameCreditLimitCheckFixture(Db);
            var result = await f.Subject.For(name.Id);
            Assert.False(result.Exceeded);
        }

        [Fact]
        public async Task ReturnsFalseWhereCreditLimitZero()
        {
            var name = new NameBuilder(Db).Build().In(Db);
            new ClientDetailBuilder {CreditLimit = 0}.BuildForName(name).In(Db);
            var f = new NameCreditLimitCheckFixture(Db);
            var result = await f.Subject.For(name.Id);
            Assert.False(result.Exceeded);
        }

        [Fact]
        public async Task ReturnsFalseWhereCreditLimitNotExceeded()
        {
            var name = new NameBuilder(Db).Build().In(Db);
            new ClientDetailBuilder {CreditLimit = 10}.BuildForName(name).In(Db);
            var today = Fixture.Today();
            new OpenItemBuilder(Db) {LocalBalance = 1, AccountDebtorName = name, Status = TransactionStatus.Active, ItemDate = today, ClosePostDate = today.AddDays(1)}.Build().In(Db);
            new OpenItemBuilder(Db) {LocalBalance = 1, AccountDebtorName = name, Status = TransactionStatus.Active, ItemDate = today, ClosePostDate = today.AddDays(1)}.Build().In(Db);
            new OpenItemBuilder(Db) {LocalBalance = 100, AccountDebtorName = name, ClosePostDate = Fixture.PastDate()}.Build().In(Db);
            new OpenItemBuilder(Db) {LocalBalance = 100, Status = TransactionStatus.Active, ItemDate = today, ClosePostDate = today.AddDays(1)}.Build().In(Db);
            var f = new NameCreditLimitCheckFixture(Db);
            var result = await f.Subject.For(name.Id);
            Assert.False(result.Exceeded);
            Assert.Equal(10, (decimal) result.CreditLimit);
            Assert.Equal(2, (decimal) result.ReceivableBalance);
            Assert.Equal(100, result.LimitPercentage);
        }

        [Fact]
        public async Task ReturnTrueWhereCreditLimitExceeded()
        {
            var name = new NameBuilder(Db).Build().In(Db);
            new ClientDetailBuilder {CreditLimit = 10}.BuildForName(name).In(Db);
            var today = Fixture.Today();
            
            new OpenItemBuilder(Db)
            {
                LocalBalance = 10, 
                AccountDebtorName = name, 
                Status = TransactionStatus.Active, 
                ItemDate = today, 
                ClosePostDate = today.AddDays(1)
            }.Build().In(Db);

            new OpenItemBuilder(Db)
            {
                LocalBalance = 10, 
                AccountDebtorName = name, 
                Status = TransactionStatus.Active, 
                ItemDate = today, 
                ClosePostDate = today.AddDays(1)
            }.Build().In(Db);

            var f = new NameCreditLimitCheckFixture(Db);
            var result = await f.Subject.For(name.Id);
            Assert.True(result.Exceeded);
            Assert.Equal(10, (decimal) result.CreditLimit);
            Assert.Equal(20, (decimal) result.ReceivableBalance);
            Assert.Equal(100, result.LimitPercentage);
        }

        [Theory]
        [InlineData(10, 10, true)]
        [InlineData(200, 200, false)]
        [InlineData(-10, 100, true)]
        [InlineData(null, 100, true)]
        public async Task AllAddressesIncludeParentPath(int? siteControlValue,int? percentage, bool exceeded)
        {
            var name = new NameBuilder(Db).Build().In(Db);
            new ClientDetailBuilder {CreditLimit = 10}.BuildForName(name).In(Db);
            var today = Fixture.Today();
            
            new OpenItemBuilder(Db)
            {
                LocalBalance = 10, 
                AccountDebtorName = name, 
                Status = TransactionStatus.Active, 
                ItemDate = today, 
                ClosePostDate = today.AddDays(1)
            }.Build().In(Db);

            new OpenItemBuilder(Db)
            {
                LocalBalance = 10, 
                AccountDebtorName = name, 
                Status = TransactionStatus.Active, 
                ItemDate = today, 
                ClosePostDate = today.AddDays(1)
            }.Build().In(Db);

            var f = new NameCreditLimitCheckFixture(Db);
            f.SiteControlReader.Read<int?>(Arg.Any<string>()).ReturnsForAnyArgs(siteControlValue);

            var result = await f.Subject.For(name.Id);
            Assert.Equal(exceeded, result.Exceeded);
            Assert.Equal(10, (decimal) result.CreditLimit);
            Assert.Equal(20, (decimal) result.ReceivableBalance);
            Assert.Equal(percentage, result.LimitPercentage);
        }

        [Fact]
        public async Task WarningNotReturnedIfSiteControlIsSetToZero()
        {
            var name = new NameBuilder(Db).Build().In(Db);
            new ClientDetailBuilder {CreditLimit = 10}.BuildForName(name).In(Db);

            var f = new NameCreditLimitCheckFixture(Db);
            f.SiteControlReader.Read<int?>(Arg.Any<string>()).ReturnsForAnyArgs(0);

            var result = await f.Subject.For(name.Id);
            Assert.Null(result);
        }

        public class NameCreditLimitCheckFixture : IFixture<NameCreditLimitCheck>
        {
            public NameCreditLimitCheckFixture(InMemoryDbContext db)
            {
                SiteControlReader = Substitute.For<ISiteControlReader>();
                SiteControlReader.Read<int?>(Arg.Any<string>()).ReturnsForAnyArgs(100);
                Subject = new NameCreditLimitCheck(db, Fixture.Today, SiteControlReader);
            }

            public NameCreditLimitCheck Subject { get; }

            public ISiteControlReader SiteControlReader { get; set; }
        }
    }
}