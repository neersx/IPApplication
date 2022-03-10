using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using Xunit;
using Name = InprotechKaizen.Model.Names.Name;

namespace Inprotech.Tests.Web.Accounting.Work
{
    public class PrepaymentWarningFacts
    {
        public class ForCase : FactBase
        {
            [Fact]
            public async Task ChecksSiteControl()
            {
                var f = new PrepaymentWarningFactsFixture(Db);
                f.SiteControlReader.Read<bool>(SiteControls.PrepaymentWarnOver).Returns(false);
                var result = await f.Subject.ForCase(Fixture.Integer());
                Db.DidNotReceive().Set<OpenItem>();
                Db.DidNotReceive().Set<OpenItemCase>();
                Db.DidNotReceive().Set<Diary>();
                Db.DidNotReceive().Set<WorkInProgress>();
                Db.DidNotReceive().Set<Case>();
                Db.DidNotReceive().Set<CaseName>();
                Assert.Null(result);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task CalculatesCasePrepaymentsAndChecksAgainstTotalWipAndTime(bool exceeded)
            {   
                var f = new PrepaymentWarningFactsFixture(Db);
                f.Setup(exceeded);
                var result = await f.Subject.ForCase(f.OpenItemCase.Id);
                Assert.Equal(f.CaseValue, result.CasePrepayments);
                Assert.Equal(0, result.DebtorPrepayments);
                Assert.Equal(f.WipValue, result.TotalWip);
                Assert.Equal(exceeded, result.Exceeded);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task CalculatesCaseDebtorPrepayments(bool exceeded)
            {
                var f = new PrepaymentWarningFactsFixture(Db);
                f.Setup(exceeded, true);
                var result = await f.Subject.ForCase(f.OpenItemCase.Id);
                Assert.Equal(f.CaseValue, result.CasePrepayments);
                Assert.Equal(f.DebtorValue, result.DebtorPrepayments);
                Assert.Equal(f.WipValue, result.TotalWip);
                Assert.Equal(result.TotalWip, result.CasePrepayments + result.DebtorPrepayments + (exceeded ? 1 : 0));
                Assert.Equal(exceeded, result.Exceeded);
            }
        }
        
        public class ForName : FactBase
        {
            [Fact]
            public async Task ChecksSiteControl()
            {
                var f = new PrepaymentWarningFactsFixture(Db);
                f.SiteControlReader.Read<bool>(SiteControls.PrepaymentWarnOver).Returns(false);
                var result = await f.Subject.ForCase(Fixture.Integer());
                Db.DidNotReceive().Set<OpenItem>();
                Db.DidNotReceive().Set<OpenItemCase>();
                Db.DidNotReceive().Set<Diary>();
                Db.DidNotReceive().Set<WorkInProgress>();
                Assert.Null(result);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task CalculatesDebtorPrepaymentsOnly(bool exceeded)
            {
                var f = new PrepaymentWarningFactsFixture(Db);
                f.Setup(exceeded, true, true);
                var result = await f.Subject.ForName(f.DebtorName.Id);
                Db.DidNotReceive().Set<Case>();
                Db.DidNotReceive().Set<CaseName>();
                Assert.Equal(f.DebtorValue, result.DebtorPrepayments);
                Assert.Equal(f.DebtorWipValue, result.TotalWip);
                Assert.Equal(exceeded, result.Exceeded);
            }
        }
        
        class PrepaymentWarningFactsFixture : IFixture<PrepaymentWarningCheck>
        {
            readonly InMemoryDbContext _db;

            public PrepaymentWarningFactsFixture(InMemoryDbContext db)
            {
                _db = db;
                SiteControlReader = Substitute.For<ISiteControlReader>();
                SiteControlReader.Read<bool>(SiteControls.PrepaymentWarnOver).Returns(true);
                Now = Substitute.For<Func<DateTime>>();
                Subject = new PrepaymentWarningCheck(db, SiteControlReader, Now);
            }

            public void Setup(bool exceeded, bool withCaseDebtor = false, bool withDebtorOnly = false)
            {
                OpenItemCase = new CaseBuilder().BuildWithId(Fixture.Integer());
                CaseValue = 12345;
                DebtorValue = 12345;
                DebtorWipValue = DebtorValue + (exceeded ? 1 : 0);
                WipValue = CaseValue + (withCaseDebtor ? DebtorValue : 0) + (exceeded ? 1 : 0);
                var caseOpenItem = new OpenItemBuilder(_db)
                    {
                        PreTaxValue = -CaseValue,
                        LocalValue = CaseValue,
                        LocalBalance = CaseValue,
                        TypeId = ItemType.Prepayment,
                        Status = TransactionStatus.Active
                    }.BuildWithCase(OpenItemCase)
                     .In(_db);

                if (withCaseDebtor)
                {
                    var debtorNameType = new NameTypeBuilder {NameTypeCode = KnownNameTypes.Debtor}.Build().In(_db);
                    new CaseNameBuilder(_db) {NameType = debtorNameType, Name = caseOpenItem.AccountDebtorName}.BuildWithCase(OpenItemCase).In(_db);
                    new OpenItemBuilder(_db)
                    {
                        PreTaxValue = -DebtorValue,
                        LocalValue = DebtorValue,
                        LocalBalance = DebtorValue,
                        TypeId = ItemType.Prepayment,
                        Status = TransactionStatus.Active,
                        AccountDebtorName = caseOpenItem.AccountDebtorName
                    }.Build().In(_db);
                }
                new WorkInProgress {CaseId = OpenItemCase.Id, Balance = CaseValue + (withCaseDebtor ? DebtorValue : 0)}.In(_db);
                new DiaryBuilder(_db) {Case = OpenItemCase, TimeValue = exceeded ? 1 : 0}.BuildWithCase(true);

                if (!withDebtorOnly) return;
                var debtorItem = new OpenItemBuilder(_db)
                {
                    PreTaxValue = -DebtorValue,
                    LocalValue = DebtorValue,
                    LocalBalance = DebtorValue,
                    TypeId = ItemType.Prepayment,
                    Status = TransactionStatus.Active
                }.Build().In(_db);
                new WorkInProgress {AccountClientId = debtorItem.AccountDebtorId, Balance = DebtorValue}.In(_db);
                new DiaryBuilder(_db) {Debtor = debtorItem.AccountDebtorName, TimeValue = exceeded ? 1 : 0}.Build();
                DebtorName = debtorItem.AccountDebtorName;
            }

            public int CaseValue { get;set; }
            public Name DebtorName { get; set; }
            public int DebtorValue { get; set; }
            public int DebtorWipValue { get; set; }
            public int WipValue { get; set; }
            public Case OpenItemCase { get; set; }
            public ISiteControlReader SiteControlReader { get; private set; }
            public Func<DateTime> Now { get; set; }
            public PrepaymentWarningCheck Subject { get; }
        }
    }
}
