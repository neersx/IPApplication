using System;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Accounting;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting
{
    public class AccountingProviderFacts
    {
        public class GetAgeingBrackets : FactBase
        {
            [Fact]
            public async Task ReturnsAgeingBracketsFromPeriods()
            {
                new Period {Id = 10, StartDate = Fixture.PastDate().AddDays(-90), EndDate = Fixture.PastDate().AddDays(-60)}.In(Db);
                new Period {Id = 11, StartDate = Fixture.PastDate().AddDays(-60), EndDate = Fixture.PastDate().AddDays(-30)}.In(Db);
                new Period {Id = 12, StartDate = Fixture.PastDate().AddDays(-30), EndDate = Fixture.PastDate()}.In(Db);
                new Period {Id = 20, StartDate = Fixture.PastDate(), EndDate = Fixture.FutureDate()}.In(Db);
                var f = new AccountingProviderFixture(Db);
                var result = await f.Subject.GetAgeingBrackets();
                Assert.Equal(63, result.Current);
                Assert.Equal(93, result.Previous);
                Assert.Equal(123, result.Last);
                Assert.Equal(2000, result.BaseDate.GetValueOrDefault().Year);
                Assert.Equal(2, result.BaseDate.GetValueOrDefault().Month);
                Assert.Equal(1, result.BaseDate.GetValueOrDefault().Day);
            }

            [Fact]
            public async Task ReturnsDefaultAgeingBrackets()
            {
                var f = new AccountingProviderFixture(Db);
                var result = await f.Subject.GetAgeingBrackets();
                Assert.Equal(30, result.Current);
                Assert.Equal(60, result.Previous);
                Assert.Equal(90, result.Last);
                Assert.Null(result.BaseDate);
            }

            [Fact]
            public async Task ReturnsDefaultBracketsBasedOnExistingPeriods()
            {
                new Period {Id = 100, StartDate = Fixture.PastDate().AddDays(-90), EndDate = Fixture.PastDate()}.In(Db);
                new Period {Id = 200, StartDate = Fixture.PastDate(), EndDate = Fixture.PastDate().AddDays(90)}.In(Db);
                var f = new AccountingProviderFixture(Db);
                var result = await f.Subject.GetAgeingBrackets();
                Assert.Equal(91, result.Current);
                Assert.Equal(181, result.Previous);
                Assert.Equal(271, result.Last);
                Assert.Equal(2000, result.BaseDate.GetValueOrDefault().Year);
                Assert.Equal(2, result.BaseDate.GetValueOrDefault().Month);
                Assert.Equal(29, result.BaseDate.GetValueOrDefault().Day);
            }
        }

        public class GetAgedWipTotals : FactBase
        {
            void CreatePeriods()
            {
                new Period {Id = 10, StartDate = Fixture.PastDate().AddDays(-90), EndDate = Fixture.PastDate().AddDays(-60)}.In(Db);
                new Period {Id = 11, StartDate = Fixture.PastDate().AddDays(-60), EndDate = Fixture.PastDate().AddDays(-30)}.In(Db);
                new Period {Id = 12, StartDate = Fixture.PastDate().AddDays(-30), EndDate = Fixture.PastDate()}.In(Db);
                new Period {Id = 20, StartDate = Fixture.PastDate(), EndDate = Fixture.FutureDate()}.In(Db);
            }

            [Fact]
            public async Task ReturnsEmptyArrayWhenNoMatches()
            {
                CreatePeriods();
                var caseKey = Fixture.Integer();
                var baseDate = Fixture.FutureDate();
                var f = new AccountingProviderFixture(Db);
                var result = await f.Subject.GetAgedWipTotals(caseKey, baseDate, 30, 60, 90);
                Assert.Equal(0, result.Length);
            }

            [Fact]
            public async Task ReturnsForCaseOnlyGroupedByEntity()
            {
                CreatePeriods();
                var caseKey = Fixture.Integer();
                var baseDate = Fixture.FutureDate();
                var entity1 = new NameBuilder(Db).Build().In(Db);
                var entity2 = new NameBuilder(Db).Build().In(Db);
                new WorkInProgress {CaseId = caseKey, EntityId = entity1.Id, Status = TransactionStatus.Active, TransactionDate = Fixture.Today(), Balance = 100}.In(Db);
                new WorkInProgress {CaseId = caseKey, EntityId = entity1.Id, Status = TransactionStatus.Active, TransactionDate = Fixture.Today(), Balance = 100}.In(Db);
                new WorkInProgress {CaseId = caseKey, EntityId = entity1.Id, Status = TransactionStatus.Draft, TransactionDate = Fixture.Today(), Balance = 100}.In(Db);
                new WorkInProgress {CaseId = caseKey, EntityId = entity2.Id, Status = TransactionStatus.Active, TransactionDate = Fixture.Today(), Balance = 100}.In(Db);
                new WorkInProgress {CaseId = caseKey, EntityId = entity2.Id, Status = TransactionStatus.Active, TransactionDate = Fixture.Today(), Balance = 100}.In(Db);
                new WorkInProgress {CaseId = caseKey + 1, Status = TransactionStatus.Active, TransactionDate = Fixture.Today(), Balance = 100}.In(Db);
                var f = new AccountingProviderFixture(Db);
                var result = await f.Subject.GetAgedWipTotals(caseKey, baseDate, 63, 93, 123);
                Assert.Equal(2, result.Length);
                Assert.Equal(200, result[0].Total);
                Assert.Equal(200, result[1].Total);
            }
        }

        public class GetAgedReceivableBalances : FactBase
        {
            void CreatePeriods()
            {
                new Period {Id = 10, StartDate = Fixture.PastDate().AddDays(-90), EndDate = Fixture.PastDate().AddDays(-60)}.In(Db);
                new Period {Id = 11, StartDate = Fixture.PastDate().AddDays(-60), EndDate = Fixture.PastDate().AddDays(-30)}.In(Db);
                new Period {Id = 12, StartDate = Fixture.PastDate().AddDays(-30), EndDate = Fixture.PastDate()}.In(Db);
                new Period {Id = 20, StartDate = Fixture.PastDate(), EndDate = Fixture.FutureDate()}.In(Db);
            }

            [Fact]
            public async Task ReturnsEmptyArrayWhenNoMatches()
            {
                CreatePeriods();
                var nameId = Fixture.Integer();
                var baseDate = Fixture.FutureDate();
                var f = new AccountingProviderFixture(Db);
                var result = await f.Subject.GetAgedReceivableTotals(nameId, baseDate, 30, 60, 90);
                Assert.Equal(0, result.Length);
            }

            [Fact]
            public async Task ReturnsForNameOnlyGroupedByEntity()
            {
                CreatePeriods();
                var nameId = Fixture.Integer();
                var theDebtor = new NameBuilder(Db).Build().WithKnownId(nameId);
                var baseDate = Fixture.FutureDate();
                var entity1 = new NameBuilder(Db).Build().In(Db);
                var entity2 = new NameBuilder(Db).Build().In(Db);
                var today = Fixture.Today();
                
                new OpenItemBuilder(Db)
                {
                    LocalBalance = 100, 
                    AccountDebtorName = theDebtor, 
                    Status = TransactionStatus.Active, 
                    ItemDate = today, 
                    ClosePostDate = today.AddDays(1), 
                    EntityId = entity1.Id
                }.Build().In(Db);

                new OpenItemBuilder(Db)
                {
                    LocalBalance = 100, 
                    AccountDebtorName = theDebtor, 
                    Status = TransactionStatus.Active, 
                    ItemDate = today, 
                    ClosePostDate = today.AddDays(1), 
                    EntityId = entity1.Id
                }.Build().In(Db);

                new OpenItemBuilder(Db)
                {
                    LocalBalance = 100, 
                    AccountDebtorName = theDebtor, 
                    Status = TransactionStatus.Draft, 
                    ItemDate = today, 
                    ClosePostDate = today.AddDays(1), 
                    EntityId = entity1.Id
                }.Build().In(Db);

                new OpenItemBuilder(Db)
                {
                    LocalBalance = 100, 
                    AccountDebtorName = theDebtor, 
                    Status = TransactionStatus.Active, 
                    ItemDate = today, 
                    ClosePostDate = today.AddDays(1), 
                    EntityId = entity2.Id
                }.Build().In(Db);

                new OpenItemBuilder(Db)
                {
                    LocalBalance = 100, 
                    AccountDebtorName = theDebtor, 
                    Status = TransactionStatus.Active, 
                    ItemDate = today, 
                    ClosePostDate = today.AddDays(1), 
                    EntityId = entity2.Id
                }.Build().In(Db);

                new OpenItem {AccountDebtorId = nameId + 1, Status = TransactionStatus.Active, ItemDate = today, LocalBalance = 100}.In(Db);
                var f = new AccountingProviderFixture(Db);
                var result = await f.Subject.GetAgedReceivableTotals(nameId, baseDate, 63, 93, 123);
                Assert.Equal(2, result.Length);
                Assert.Equal(200, result[0].Total);
                Assert.Equal(200, result[1].Total);
            }
        }

        public class UnbilledWipFor : FactBase
        {
            [Fact]
            public async Task ReturnsWipForTheCase()
            {
                var caseId = Fixture.Integer();
                new CaseBuilder().BuildWithId(caseId);
                var case2 = new CaseBuilder().BuildWithId(Fixture.Integer());

                new WorkInProgress {CaseId = caseId, Balance = 10, Status = TransactionStatus.Draft}.In(Db);
                new WorkInProgress {CaseId = caseId, Balance = 10, Status = TransactionStatus.Active}.In(Db);
                new WorkInProgress {CaseId = case2.Id, Balance = 10, Status = TransactionStatus.Draft}.In(Db);
                new WorkInProgress {CaseId = case2.Id, Balance = 10, Status = TransactionStatus.Active}.In(Db);
                new WorkInProgress {CaseId = caseId, Balance = 20, Status = TransactionStatus.Active}.In(Db);

                var f = new AccountingProviderFixture(Db);
                var result = await f.Subject.UnbilledWipFor(caseId);
                Assert.Equal(30, result);

                result = await f.Subject.UnbilledWipFor(case2.Id);
                Assert.Equal(10, result);
            }
        }

        public class GetLastInvoiceDate : FactBase
        {
            [Fact]
            public async Task ReturnsCorrectDate()
            {
                var d = new DateTime(2010, 10, 10);
                
                new OpenItem(10, 10, 10, new Name())
                {
                    ItemDate = d, 
                    Status = TransactionStatus.Active, 
                    AssociatedOpenItemNo = null, 
                    TypeId = ItemType.DebitNote
                }.In(Db);

                new WorkHistory {RefTransactionId = 10, CaseId = 10}.In(Db);

                var f = new AccountingProviderFixture(Db);
                var result = await f.Subject.GetLastInvoiceDate(10);
                Assert.Equal(d, result);
            }

            [Fact]
            public async Task ChecksConditionsOnOpenItem()
            {
                var d = new DateTime(2010, 10, 10);

                new OpenItem(10, 10, 10, new Name())
                {
                    ItemDate = d, 
                    Status = TransactionStatus.Draft, 
                    AssociatedOpenItemNo = null, 
                    TypeId = ItemType.DebitNote
                }.In(Db);

                new OpenItem(10, 11, 10, new Name())
                {
                    ItemDate = d, 
                    Status = TransactionStatus.Active, 
                    AssociatedOpenItemNo = "1", 
                    TypeId = ItemType.DebitNote
                }.In(Db);

                new OpenItem(10, 12, 10, new Name())
                {
                    ItemDate = d, 
                    Status = TransactionStatus.Draft, 
                    AssociatedOpenItemNo = null, 
                    TypeId = ItemType.Prepayment
                }.In(Db);

                new WorkHistory {RefTransactionId = 10, CaseId = 10}.In(Db);
                new WorkHistory {RefTransactionId = 11, CaseId = 10}.In(Db);
                new WorkHistory {RefTransactionId = 12, CaseId = 10}.In(Db);

                var f = new AccountingProviderFixture(Db);
                var result = await f.Subject.GetLastInvoiceDate(10);
                Assert.Null(result);
            }

            [Fact]
            public async Task ChecksConditionOnWorkHistory()
            {
                var d = new DateTime(2010, 10, 10);
                
                new OpenItem(10, 10, 10, new Name())
                {
                    ItemDate = d, 
                    Status = TransactionStatus.Active, 
                    AssociatedOpenItemNo = null, 
                    TypeId = ItemType.DebitNote
                }.In(Db);

                new WorkHistory {RefTransactionId = 10, CaseId = 11}.In(Db);

                var f = new AccountingProviderFixture(Db);
                var result = await f.Subject.GetLastInvoiceDate(10);
                Assert.Null(result);
            }

            [Fact]
            public async Task PicksTopDateWhenMultipleFound()
            {
                var d1 = new DateTime(2010, 10, 10);
                var d2 = new DateTime(2010, 11, 10);
                
                new OpenItem(10, 10, 10, new Name())
                {
                    ItemDate = d1, 
                    Status = TransactionStatus.Active, 
                    AssociatedOpenItemNo = null, 
                    TypeId = ItemType.DebitNote
                }.In(Db);

                new OpenItem(10, 11, 10, new Name())
                {
                    ItemDate = d2, 
                    Status = TransactionStatus.Active, 
                    AssociatedOpenItemNo = null, 
                    TypeId = ItemType.DebitNote
                }.In(Db);

                new OpenItem(10, 12, 10, new Name())
                {
                    ItemDate = d2, 
                    Status = TransactionStatus.Active, 
                    AssociatedOpenItemNo = null, 
                    TypeId = ItemType.DebitNote
                }.In(Db);

                new WorkHistory {RefTransactionId = 10, CaseId = 10}.In(Db);
                new WorkHistory {RefTransactionId = 11, CaseId = 10}.In(Db);
                new WorkHistory {RefTransactionId = 12, CaseId = 10}.In(Db);

                var f = new AccountingProviderFixture(Db);
                var result = await f.Subject.GetLastInvoiceDate(10);
                Assert.Equal(d2, result);
            }
        }

        public class AccountingProviderFixture : IFixture<AccountingProvider>
        {
            public AccountingProviderFixture(InMemoryDbContext db)
            {
                Now = Substitute.For<Func<DateTime>>();
                Now().Returns(Fixture.Today());
                Subject = new AccountingProvider(db, Now);
            }

            public Func<DateTime> Now { get; set; }
            public AccountingProvider Subject { get; set; }
        }
    }
}