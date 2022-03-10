using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Accounting;
using Inprotech.Web.Accounting.Names;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.OpenItem;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Names
{
    public class NameBalancesControllerFacts
    {
        public class GetReceivables : FactBase
        {
            [Fact]
            public async Task ReturnsNullWhenReceivablesInaccessible()
            {
                var nameId = Fixture.Integer();
                var f = new NameBalancesControllerFixture(Db);
                f.SubjectSecurity.HasAccessToSubject(ApplicationSubject.ReceivableItems).Returns(false);
                var result = await f.Subject.GetReceivables(nameId);
                Assert.Null(result);
                Db.DidNotReceive().Set<OpenItem>();
            }

            [Fact]
            public async Task ReturnsZeroBalance()
            {
                var nameId = Fixture.Integer();
                var f = new NameBalancesControllerFixture(Db);
                f.SubjectSecurity.HasAccessToSubject(ApplicationSubject.ReceivableItems).Returns(true);
                var result = await f.Subject.GetReceivables(nameId);
                Assert.Equal(0, result.Data.ReceivableBalance);
            }

            [Fact]
            public async Task ReturnsReceivableBalanceForTheName()
            {
                var nameId = Fixture.Integer();
                var theDebtor = new NameBuilder(Db).Build().WithKnownId(nameId);
                var otherDebtor = new NameBuilder(Db).Build();
                var today = Fixture.Today();

                new OpenItemBuilder(Db)
                {
                    LocalBalance = 100, 
                    AccountDebtorName = theDebtor, 
                    Status = TransactionStatus.Active, 
                    ItemDate = today, 
                    ClosePostDate = today.AddDays(1)
                }.Build().In(Db);

                new OpenItemBuilder(Db)
                {
                    LocalBalance = 100, 
                    AccountDebtorName = theDebtor, 
                    Status = TransactionStatus.Active, 
                    ItemDate = today, 
                    ClosePostDate = today.AddDays(1)
                }.Build().In(Db);

                new OpenItemBuilder(Db)
                {
                    LocalBalance = 100, 
                    AccountDebtorName = theDebtor, 
                    ClosePostDate = Fixture.PastDate()
                }.Build().In(Db);

                new OpenItemBuilder(Db)
                {
                    LocalBalance = 100, 
                    AccountDebtorName = otherDebtor
                }.Build().In(Db);

                var f = new NameBalancesControllerFixture(Db);
                f.SubjectSecurity.HasAccessToSubject(ApplicationSubject.ReceivableItems).Returns(true);
                f.Now().Returns(today);
                var result = await f.Subject.GetReceivables(nameId);
                Assert.Equal(200, result.Data.ReceivableBalance);
            }
        }
        public class NameBalancesControllerFixture : IFixture<NameBalancesController>
        {
            public ISubjectSecurityProvider SubjectSecurity { get; set; }
            public NameBalancesController Subject { get; set; }
            public Func<DateTime> Now { get; set; }
            public IAccountingProvider AccountingProvider {get; set;}
            public NameBalancesControllerFixture(InMemoryDbContext dbContext)
            {
                SubjectSecurity = Substitute.For<ISubjectSecurityProvider>();
                Now = Substitute.For<Func<DateTime>>();
                AccountingProvider = Substitute.For<IAccountingProvider>();
                Subject = new NameBalancesController(dbContext, SubjectSecurity, Now, AccountingProvider);

            }
        }
    }
}
