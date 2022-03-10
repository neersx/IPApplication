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
using InprotechKaizen.Model.Queries;
using WipCategory = InprotechKaizen.Model.Accounting.WipCategory;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.WipAdjustments
{
    internal class DataSetup
    {
        const int DebtorBillPercentage40 = 40;
        const int DebtorBillPercentage60 = 60;

        public WipData ForWipAdjustments()
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

                var serviceChargeWipType = x.InsertWithNewAlphaNumericId(new WipType {CategoryId = "SC"});

                var sc1Narrative = new NarrativeBuilder(x.DbContext).Create("SC1-" + Fixture.AlphaNumericString(2));
                x.DbContext.SaveChanges();

                var sc2Narrative = new NarrativeBuilder(x.DbContext).Create("SC2-" + Fixture.AlphaNumericString(2));
                x.DbContext.SaveChanges();

                var serviceChargeWipTemplate1 = new WipTemplateBuilder(x.DbContext).Create("SC1", typeId: serviceChargeWipType.Id);
                var serviceChargeWipTemplate2 = new WipTemplateBuilder(x.DbContext).Create("SC2", typeId: serviceChargeWipType.Id);

                x.InsertWithNewId(new NarrativeRule {NarrativeId = sc1Narrative.NarrativeId, WipCode = serviceChargeWipTemplate1.WipCode});
                x.InsertWithNewId(new NarrativeRule {NarrativeId = sc2Narrative.NarrativeId, WipCode = serviceChargeWipTemplate2.WipCode});

                /* across the board margin of 20 bucks for PD2 */
                var marginForAll = x.InsertWithNewId(new Margin
                {
                    WipCode = serviceChargeWipTemplate2.WipCode,
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
                var marginForDebtor2Sc2 = x.InsertWithNewId(new Margin
                {
                    WipCode = serviceChargeWipTemplate2.WipCode,
                    EffectiveDate = DateTime.Today.AddDays(-1),
                    WipCategory = "SC",
                    DebtorId = debtor2.Id,
                    MarginAmount = (decimal) 50.0 /* debtor 2 enjoys a margin of 50 bucks */
                });

                /* LOCAL DEBTOR SCENARIO: 'local-multiple' will have debtor 1 at 60%, debtor 2 at 40% */
                var caseLocalMultiple = new CaseBuilder(x.DbContext).Create("local-multiple", null, user.Username, null, null, false);
                caseLocalMultiple.CaseNames.Add(new CaseName(caseLocalMultiple, debtorNameType, debtor1, 100) {BillingPercentage = DebtorBillPercentage60});
                caseLocalMultiple.CaseNames.Add(new CaseName(caseLocalMultiple, debtorNameType, debtor2, 101) {BillingPercentage = DebtorBillPercentage40});

                new OpenActionBuilder(x.DbContext).CreateInDb(caseLocalMultiple);

                /* FOREIGN DEBTOR SCENARIO: foreign debtor 1 will always have a 20% discount and a margin of $100 in foreign currency 1 'F1' */
                var foreignCurrency1 = new CurrencyBuilder(x.DbContext).Create("F1", (decimal) 1.1, (decimal) 1.1);
                var foreignDebtor1 = new NameBuilder(x.DbContext).CreateClientOrg("FOREIGN-1");
                x.Insert(new ClientDetail(foreignDebtor1.Id) {CurrencyId = foreignCurrency1.Id});
                x.Insert(new Discount {NameId = foreignDebtor1.Id, DiscountRate = (decimal) 20.0});
                var marginForForeignDebtor1Sc2 = x.InsertWithNewId(new Margin
                {
                    WipCode = serviceChargeWipTemplate2.WipCode,
                    EffectiveDate = DateTime.Today.AddDays(-1),
                    WipCategory = "SC",
                    DebtorId = foreignDebtor1.Id,
                    DebtorCurrency = foreignCurrency1.Id,
                    MarginAmount = (decimal) 100.0 /* foreign debtor 1 enjoys a margin of 100 bucks in foreign currency 1 'F1' */
                });

                /* FOREIGN DEBTOR SCENARIO: foreign debtor 1 will incur a margin of 100 bucks through pd1 */
                var foreignCurrency2 = new CurrencyBuilder(x.DbContext).Create("F2", (decimal) 1.2, (decimal) 1.2);
                var foreignDebtor2 = new NameBuilder(x.DbContext).CreateClientOrg("FOREIGN-2");
                x.Insert(new ClientDetail(foreignDebtor2.Id) {CurrencyId = foreignCurrency2.Id});

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

                new OpenActionBuilder(x.DbContext).CreateInDb(caseForeignMultiple);

                var localWip = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(homeEntity, caseLocalMultiple.Id, serviceChargeWipTemplate1.WipCode, 1000);

                var localWipWithDiscount = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(homeEntity, caseLocalMultiple.Id, serviceChargeWipTemplate1.WipCode, 2000, -200);

                var foreignWip = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(homeEntity, caseForeignMultiple.Id, serviceChargeWipTemplate2.WipCode, 1000, foreignCurrency: foreignCurrency1.Id, exchangeRate: (decimal) 1.5);

                #region for debugging

                void CreateSavedQuery(Case @case)
                {
                    var filterCase = x.Insert(new QueryFilter
                    {
                        ProcedureName = "wp_ListWorkInProgress",
                        XmlFilterCriteria = $@"<Search><Filtering><wp_ListWorkInProgress><FilterCriteria><EntityKey Operator='0'>-283575757</EntityKey><BelongsTo><ActingAs><IsWipStaff>0</IsWipStaff><AssociatedName>1</AssociatedName><AnyNameType>1</AnyNameType></ActingAs></BelongsTo><Debtor IsRenewalDebtor='0' /><CaseKey Operator='0'>{@case.Id}</CaseKey><WipStatus><IsActive>1</IsActive><IsLocked>1</IsLocked></WipStatus><RenewalWip><IsRenewal>1</IsRenewal><IsNonRenewal>1</IsNonRenewal></RenewalWip><CaseKey Operator='0'>{@case.Id}</CaseKey></FilterCriteria><AggregateFilterCriteria /></wp_ListWorkInProgress></Filtering></Search>"
                    });

                    x.Insert(new Query {ContextId = 200, Filter = filterCase, Name = $"Case {@case.Irn} ({@case.Id})", IdentityId = user.Id});
                }

                CreateSavedQuery(caseLocalMultiple);
                CreateSavedQuery(caseForeignMultiple);

                #endregion

                x.DbContext.SaveChanges();

                return new WipData
                {
                    Today = today,
                    StaffName = staffName,
                    User = user,

                    LocalCurrency = homeCurrency,
                    LocalDebtor1 = debtor1,
                    LocalDebtor2 = debtor2,
                    CaseLocalMultiple = caseLocalMultiple,
                    CaseForeignMultiple = caseForeignMultiple,
                    ForeignDebtor1 = foreignDebtor1,
                    ForeignDebtor2 = foreignDebtor2,
                    ForeignCurrency1 = foreignCurrency1,
                    ForeignCurrency2 = foreignCurrency2,

                    OtherNarrative = otherNarrative,
                    ServiceCharge1 = serviceChargeWipTemplate1,
                    ServiceCharge2 = serviceChargeWipTemplate2,
                    ServiceCharge1Narrative = sc1Narrative,
                    ServiceCharge2Narrative = sc2Narrative,
                    MarginForAll = marginForAll,
                    MarginForDebtor2Sc2 = marginForDebtor2Sc2,
                    MarginForForeignDebtor1Sc2 = marginForForeignDebtor1Sc2,

                    LocalWip = localWip.Wip,
                    LocalWipWithDiscount = localWipWithDiscount.Wip,
                    ForeignWip = foreignWip.Wip,
                    EntityId = homeEntity
                };
            });
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
        public Case CaseForeignMultiple { get; set; }
        public Narrative OtherNarrative { get; set; }
        public WipTemplate ServiceCharge1 { get; set; }
        public WipTemplate ServiceCharge2 { get; set; }
        public Name LocalDebtor1 { get; set; }
        public Name LocalDebtor2 { get; set; }
        public Name ForeignDebtor1 { get; set; }
        public Name ForeignDebtor2 { get; set; }
        public int EntityId { get; set; }
        public DateTime Today { get; set; }
        public Margin MarginForDebtor2Sc2 { get; set; }
        public Margin MarginForForeignDebtor1Sc2 { get; set; }
        public Margin MarginForAll { get; set; }
        public Narrative ServiceCharge1Narrative { get; set; }
        public Narrative ServiceCharge2Narrative { get; set; }
        public WorkInProgress LocalWip { get; set; }
        public WorkInProgress ForeignWip { get; set; }
        public WorkInProgress LocalWipWithDiscount { get; set; }
    }
}