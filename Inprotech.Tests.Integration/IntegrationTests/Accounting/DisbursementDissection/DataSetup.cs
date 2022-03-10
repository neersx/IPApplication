using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.DbHelpers.Builders.Accounting;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Names;
using WipCategory = InprotechKaizen.Model.Accounting.WipCategory;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.DisbursementDissection
{
    internal class DataSetup
    {
        const int DebtorBillPercentage40 = 40;
        const int DebtorBillPercentage60 = 60;

        public WipData ForDisbursementDissection()
        {
            AccountingDbHelper.SetupPeriod();

            return DbSetup.Do(x =>
            {
                var today = DateTime.Now.Date;
                var staffName = new NameBuilder(x.DbContext).CreateStaff();
                var userSetup = new Users(x.DbContext)
                    {
                        Name = staffName
                    }.WithPermission(ApplicationTask.AdjustWip)
                     .WithPermission(ApplicationTask.RecordWip, Allow.Create);

                var user = userSetup.Create();

                var paidDisbursementWipType = x.InsertWithNewAlphaNumericId(new WipType {CategoryId = WipCategory.Disbursements});

                var pd1Narrative = new NarrativeBuilder(x.DbContext).Create("PD1-" + Fixture.AlphaNumericString(2));
                x.DbContext.SaveChanges();

                var pd2Narrative = new NarrativeBuilder(x.DbContext).Create("PD2-" + Fixture.AlphaNumericString(2));
                x.DbContext.SaveChanges();

                var disbursementWipTemplate1 = new WipTemplateBuilder(x.DbContext).Create("PD1", typeId: paidDisbursementWipType.Id);
                var disbursementWipTemplate2 = new WipTemplateBuilder(x.DbContext).Create("PD2", typeId: paidDisbursementWipType.Id);

                x.InsertWithNewId(new NarrativeRule {NarrativeId = pd1Narrative.NarrativeId, WipCode = disbursementWipTemplate1.WipCode});
                x.InsertWithNewId(new NarrativeRule {NarrativeId = pd2Narrative.NarrativeId, WipCode = disbursementWipTemplate2.WipCode});

                /* across the board margin of 20 bucks for PD2 */
                var marginForAll = x.InsertWithNewId(new Margin
                {
                    WipCode = disbursementWipTemplate2.WipCode,
                    EffectiveDate = DateTime.Today.AddDays(-1),
                    WipCategory = WipCategory.Disbursements,
                    MarginAmount = (decimal) 20.0
                });

                var otherNarrative = new NarrativeBuilder(x.DbContext).Create("other");

                var homeEntity = x.DbContext.Set<SiteControl>()
                                  .Single(_ => _.ControlId == SiteControls.HomeNameNo)
                                  .IntegerValue.GetValueOrDefault();

                var homeCurrency = new CurrencyBuilder(x.DbContext).Create();
                var localCurrency = x.DbContext.Set<SiteControl>()
                                     .Single(_ => _.ControlId == SiteControls.CURRENCY);
                localCurrency.StringValue = homeCurrency.Id;

                var debtorNameType = x.DbContext.Set<NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.Debtor);

                /* LOCAL DEBTOR SCENARIO: local debtor 1 will always have a 10% discount */
                var debtor1 = new NameBuilder(x.DbContext).CreateClientOrg("LOCAL-1");
                x.Insert(new ClientDetail(debtor1.Id));
                x.Insert(new Discount {NameId = debtor1.Id, DiscountRate = (decimal) 10.0});

                /* LOCAL DEBTOR SCENARIO: local debtor 2 will incur a margin of 50 with PD2*/
                var debtor2 = new NameBuilder(x.DbContext).CreateClientOrg("LOCAL-2");
                x.Insert(new ClientDetail(debtor2.Id));
                var marginForDebtor2Pd2 = x.InsertWithNewId(new Margin
                {
                    WipCode = disbursementWipTemplate2.WipCode,
                    EffectiveDate = DateTime.Today.AddDays(-1),
                    WipCategory = WipCategory.Disbursements,
                    DebtorId = debtor2.Id,
                    MarginAmount = (decimal) 50.0 /* debtor 2 enjoys a margin of 50 bucks */
                });

                /* LOCAL DEBTOR SCENARIO: 'local-single' will have only 1 debtor, Debtor 1 */
                var caseLocalSingle = new CaseBuilder(x.DbContext).Create("local-single", true, withDebtor: false);
                caseLocalSingle.CaseNames.Add(new CaseName(caseLocalSingle, debtorNameType, debtor1, 100) {BillingPercentage = 100});

                /* LOCAL DEBTOR SCENARIO: 'local-multiple' will have debtor 1 at 60%, debtor 2 at 40% */
                var caseLocalMultiple = new CaseBuilder(x.DbContext).Create("local-multiple", null, user.Username, null, null, false);
                caseLocalMultiple.CaseNames.Add(new CaseName(caseLocalMultiple, debtorNameType, debtor1, 100) {BillingPercentage = DebtorBillPercentage60});
                caseLocalMultiple.CaseNames.Add(new CaseName(caseLocalMultiple, debtorNameType, debtor2, 101) {BillingPercentage = DebtorBillPercentage40});

                new OpenActionBuilder(x.DbContext).CreateInDb(caseLocalSingle);
                new OpenActionBuilder(x.DbContext).CreateInDb(caseLocalMultiple);

                /* FOREIGN DEBTOR SCENARIO: foreign debtor 1 will always have a 20% discount and a margin of $100 in foreign currency 1 'F1' */
                var foreignCurrency1 = new CurrencyBuilder(x.DbContext).Create("F1", (decimal) 1.1);
                var foreignDebtor1 = new NameBuilder(x.DbContext).CreateClientOrg("FOREIGN-1");
                x.Insert(new ClientDetail(foreignDebtor1.Id) {CurrencyId = foreignCurrency1.Id});
                x.Insert(new Discount {NameId = foreignDebtor1.Id, DiscountRate = (decimal) 20.0});
                var marginForForeignDebtor1Pd2 = x.InsertWithNewId(new Margin
                {
                    WipCode = disbursementWipTemplate2.WipCode,
                    EffectiveDate = DateTime.Today.AddDays(-1),
                    WipCategory = WipCategory.Disbursements,
                    DebtorId = foreignDebtor1.Id,
                    DebtorCurrency = foreignCurrency1.Id,
                    MarginAmount = (decimal) 100.0 /* foreign debtor 1 enjoys a margin of 100 bucks in foreign currency 1 'F1' */
                });

                /* FOREIGN DEBTOR SCENARIO: foreign debtor 1 will incur a margin of 100 bucks through pd1 */
                var foreignCurrency2 = new CurrencyBuilder(x.DbContext).Create("F2", (decimal) 1.2);
                var foreignDebtor2 = new NameBuilder(x.DbContext).CreateClientOrg("FOREIGN-2");
                x.Insert(new ClientDetail(foreignDebtor2.Id) {CurrencyId = foreignCurrency2.Id});

                /* FOREIGN DEBTOR SCENARIO: 'foreign-single' will have foreign debtor 1 in foreign currency 1 'F1' 
                */
                var caseForeignSingle = new CaseBuilder(x.DbContext).Create("foreign-single", null, user.Username, null, null, false);
                caseForeignSingle.CaseNames.Add(new CaseName(caseForeignSingle, debtorNameType, foreignDebtor1, 100) {BillingPercentage = 100});

                /*
                 * FOREIGN DEBTOR SCENARIO: 'foreign-multiple' will have
                 * foreign debtor 2 as main debtor, at 60% in foreign currency 2 'F2';
                 * foreign debtor 1 in 40% in foreign currency 1 'F1'
                 * foreign currency 1 has exchange rate 1.1
                 * foreign currency 2 has exchange rate 1.2
                 */
                var caseForeignMultiple = new CaseBuilder(x.DbContext).Create("foreign-multiple", true, withDebtor: false);
                caseForeignMultiple.CaseNames.Add(new CaseName(caseForeignMultiple, debtorNameType, foreignDebtor2, 100) {BillingPercentage = DebtorBillPercentage60});
                caseForeignMultiple.CaseNames.Add(new CaseName(caseForeignMultiple, debtorNameType, foreignDebtor1, 101) {BillingPercentage = DebtorBillPercentage40});

                new OpenActionBuilder(x.DbContext).CreateInDb(caseForeignSingle);
                new OpenActionBuilder(x.DbContext).CreateInDb(caseForeignMultiple);
                
                x.DbContext.SaveChanges();

                return new WipData
                {
                    Today = today,
                    StaffName = staffName,
                    User = user,

                    LocalCurrency = homeCurrency,
                    LocalDebtor1 = debtor1,
                    LocalDebtor2 = debtor2,
                    CaseLocalSingle = caseLocalSingle,
                    CaseLocalMultiple = caseLocalMultiple,
                    
                    CaseForeignSingle = caseForeignSingle,
                    CaseForeignMultiple = caseForeignMultiple,
                    ForeignDebtor1 = foreignDebtor1,
                    ForeignDebtor2 = foreignDebtor2,
                    ForeignCurrency1 = foreignCurrency1,
                    ForeignCurrency2 = foreignCurrency2,

                    OtherNarrative = otherNarrative,
                    PaidDisbursement1 = disbursementWipTemplate1,
                    PaidDisbursement2 = disbursementWipTemplate2,
                    PaidDisbursement1Narrative = pd1Narrative,
                    PaidDisbursement2Narrative = pd2Narrative,
                    MarginForAll = marginForAll,
                    MarginForDebtor2Pd2 = marginForDebtor2Pd2,
                    MarginForForeignDebtor1Pd2 = marginForForeignDebtor1Pd2,
                    EntityId = homeEntity
                };
            });
        }

        public DataSetup WithSplitWipMultiDebtorEnabled()
        {
            DbSetup.Do(x =>
            {
                var splitMultiDebtorWip = x.DbContext.Set<SiteControl>()
                                           .Single(_ => _.ControlId == SiteControls.WIPSplitMultiDebtor);
                splitMultiDebtorWip.BooleanValue = true;
                x.DbContext.SaveChanges();
            });

            return this;
        }
    }

    internal class WipData
    {
        public Name StaffName { get; set; }
        public TestUser User { get; set; }
        public Currency LocalCurrency { get; set; }
        public Currency ForeignCurrency1 { get; set; }
        public Currency ForeignCurrency2 { get; set; }
        public Case CaseLocalMultiple { get; set; }
        public Case CaseForeignSingle { get; set; }
        public Case CaseForeignMultiple { get; set; }
        public Case CaseLocalSingle { get; set; }
        public Narrative OtherNarrative { get; set; }
        public WipTemplate PaidDisbursement1 { get; set; }
        public WipTemplate PaidDisbursement2 { get; set; }
        public Name LocalDebtor1 { get; set; }
        public Name LocalDebtor2 { get; set; }
        public Name ForeignDebtor1 { get; set; }
        public Name ForeignDebtor2 { get; set; }
        public int EntityId { get; set; }
        public DateTime Today { get; set; }
        public Margin MarginForDebtor2Pd2 { get; set; }
        public Margin MarginForForeignDebtor1Pd2 { get; set; }
        public Margin MarginForAll { get; set; }
        public Narrative PaidDisbursement1Narrative { get; set; }
        public Narrative PaidDisbursement2Narrative { get; set; }
    }
}