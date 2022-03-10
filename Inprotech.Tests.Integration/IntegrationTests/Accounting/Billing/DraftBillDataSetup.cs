using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.DbHelpers.Builders.Accounting;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Account;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;
using WipCategory = InprotechKaizen.Model.Accounting.WipCategory;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Billing
{
    public class DraftBillDataSetup
    {
        const int DebtorBillPercentage40 = 40;
        const int DebtorBillPercentage60 = 60;

        public BillingData Setup(IDbContext dbContext = null)
        {
            AccountingDbHelper.SetupPeriod();

            var x = new DbSetup(dbContext);

            var today = DateTime.Now.Date;
            var staffName = new NameBuilder(x.DbContext).CreateStaff();

            var user = new Users(x.DbContext)
                       {
                           Name = staffName
                       }
                       .WithPermission(ApplicationTask.MaintainDebitNote, Allow.Create | Allow.Modify | Allow.Delete)
                       .WithPermission(ApplicationTask.MaintainCreditNote, Allow.Create | Allow.Modify | Allow.Delete)
                       .WithPermission(ApplicationTask.RecordWip, Allow.Create)
                       .WithPermission(ApplicationWebPart.BillSearch)
                       .Create();

            var serviceCharge = x.InsertWithNewAlphaNumericId(new WipType {CategoryId = WipCategory.ServiceCharge});

            var serviceChargeWipTemplate1 = new WipTemplateBuilder(x.DbContext).Create("SC1", typeId: serviceCharge.Id, taxCode: "0" /* 0 = Exempt*/);
            var serviceChargeWipTemplate2 = new WipTemplateBuilder(x.DbContext).Create("SC2", typeId: serviceCharge.Id, taxCode: "T1" /* Standard */);

            var homeEntity = x.DbContext.Set<SiteControl>()
                              .Single(_ => _.ControlId == SiteControls.HomeNameNo)
                              .IntegerValue.GetValueOrDefault();

            var profitCentre = x.InsertWithNewAlphaNumericId(new ProfitCentre
            {
                Name = "e2e-profitcentre",
                EntityId = homeEntity
            });

            var employeeDetails = x.DbContext.Set<Employee>().Single(_ => _.Id == staffName.Id);
            employeeDetails.ProfitCentre = profitCentre.Id;

            var homeCurrency = new CurrencyBuilder(x.DbContext).Create();
            var localCurrency = x.DbContext.Set<SiteControl>()
                                 .Single(_ => _.ControlId == SiteControls.CURRENCY);
            localCurrency.StringValue = homeCurrency.Id;

            var debtorNameType = x.DbContext.Set<NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.Debtor);

            var localCountry = x.InsertWithNewAlphaNumericId(new Country
            {
                Name = "local country",
                Type = "0"
            });

            var foreignCountry = x.InsertWithNewAlphaNumericId(new Country
            {
                Name = "foreign country",
                Type = "0"
            });

            /* LOCAL DEBTOR SCENARIO  10% discount across the board */
            var debtor1 = new NameBuilder(x.DbContext).CreateClientOrg("LOCAL-1");
            x.Insert(new ClientDetail(debtor1.Id) { LocalClientFlag = 1 });
            x.Insert(new Discount {NameId = debtor1.Id, DiscountRate = (decimal) 10.0});
            x.Insert(new Account {EntityId = homeEntity, Balance = 0, NameId = debtor1.Id});

            /* LOCAL DEBTOR SCENARIO */
            var debtor2 = new NameBuilder(x.DbContext).CreateClientOrg("LOCAL-2");
            x.Insert(new ClientDetail(debtor2.Id) { LocalClientFlag = 1 });
            x.Insert(new Account {EntityId = homeEntity, Balance = 0, NameId = debtor2.Id});

            var caseLocalSingle = new CaseBuilder(x.DbContext).Create("local-single", true, user.Username, localCountry, null, false);
            caseLocalSingle.CaseNames.Add(new CaseName(caseLocalSingle, debtorNameType, debtor2, 101) {BillingPercentage = 100});

            var caseLocalSingleLatestOpenAction = new OpenActionBuilder(x.DbContext).CreateInDb(caseLocalSingle, DateTime.Today);

            /* LOCAL DEBTOR SCENARIO: 'local-multiple' will have debtor 1 at 60%, debtor 2 at 40% */
            var caseLocalMultiple = new CaseBuilder(x.DbContext).Create("local-multiple", null, user.Username, foreignCountry, null, false);
            caseLocalMultiple.CaseNames.Add(new CaseName(caseLocalMultiple, debtorNameType, debtor1, 100) {BillingPercentage = DebtorBillPercentage60});
            caseLocalMultiple.CaseNames.Add(new CaseName(caseLocalMultiple, debtorNameType, debtor2, 101) {BillingPercentage = DebtorBillPercentage40});

            var caseLocalMultipleLatestOpenAction = new OpenActionBuilder(x.DbContext).CreateInDb(caseLocalMultiple, DateTime.Today);

            /* FOREIGN DEBTOR SCENARIO: foreign debtor 1 will always have a 20% discount and a margin of $100 in foreign currency 1 'F1' */
            var foreignCurrency1 = new CurrencyBuilder(x.DbContext).Create("F1", (decimal) 1.1, (decimal) 1.1);
            var foreignDebtor1 = new NameBuilder(x.DbContext).CreateClientOrg("FOREIGN-1");
            x.Insert(new ClientDetail(foreignDebtor1.Id) {CurrencyId = foreignCurrency1.Id});
            x.Insert(new Discount {NameId = foreignDebtor1.Id, DiscountRate = (decimal) 20.0});
            x.Insert(new Account {EntityId = homeEntity, Balance = 0, NameId = foreignDebtor1.Id});

            /* FOREIGN DEBTOR SCENARIO: foreign debtor 1 will incur a margin of 100 bucks through pd1 */
            var foreignDebtor2 = new NameBuilder(x.DbContext).CreateClientOrg("FOREIGN-2");
            x.Insert(new ClientDetail(foreignDebtor2.Id) {CurrencyId = foreignCurrency1.Id});
            x.Insert(new Account {EntityId = homeEntity, Balance = 0, NameId = foreignDebtor2.Id});

            var caseForeignSingle = new CaseBuilder(x.DbContext).Create("foreign-single", null, user.Username, localCountry, null, false);
            caseForeignSingle.CaseNames.Add(new CaseName(caseForeignSingle, debtorNameType, foreignDebtor1, 101) {BillingPercentage = 100});
            var caseForeignSingleLatestOpenAction = new OpenActionBuilder(x.DbContext).CreateInDb(caseForeignSingle, DateTime.Today);

            /*
             * FOREIGN DEBTOR SCENARIO: 'foreign-multiple' will have
             * foreign debtor 2 as main debtor, at 60% in foreign currency 2 'F2';
             * foreign debtor 1 in 40% in foreign currency 1 'F1'
             * foreign currency 1 has exchange rate 1.1
             */
            var caseForeignMultiple = new CaseBuilder(x.DbContext).Create("foreign-multiple", country: foreignCountry, propertyCase: true, withDebtor: false);
            caseForeignMultiple.CaseNames.Add(new CaseName(caseForeignMultiple, debtorNameType, foreignDebtor2, 100) {BillingPercentage = DebtorBillPercentage60});
            caseForeignMultiple.CaseNames.Add(new CaseName(caseForeignMultiple, debtorNameType, foreignDebtor1, 101) {BillingPercentage = DebtorBillPercentage40});

            var caseForeignMultipleLatestOpenAction = new OpenActionBuilder(x.DbContext).CreateInDb(caseForeignMultiple, DateTime.Today);

            var entityCountry = (from a in x.DbContext.Set<Address>()
                                 join n in x.DbContext.Set<Name>() on a.Id equals n.PostalAddressId
                                 where n.Id == homeEntity
                                 select a.CountryId).Single();

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

            return new BillingData
            {
                Today = today,
                StaffName = staffName,
                StaffProfitCentre = profitCentre,
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
                ForeignCurrency = foreignCurrency1,

                ServiceCharge1 = serviceChargeWipTemplate1,
                ServiceCharge2 = serviceChargeWipTemplate2,

                EntityId = homeEntity,
                EntityCountry = entityCountry,

                LatestOpenActionByCase = new Dictionary<int, string>
                {
                    {caseLocalSingle.Id, caseLocalSingleLatestOpenAction.ActionId},
                    {caseLocalMultiple.Id, caseLocalMultipleLatestOpenAction.ActionId},
                    {caseForeignSingle.Id, caseForeignSingleLatestOpenAction.ActionId},
                    {caseForeignMultiple.Id, caseForeignMultipleLatestOpenAction.ActionId}
                }
            };
        }
    }

    public class BillingData
    {
        public Name StaffName { get; set; }
        public TestUser User { get; set; }
        public Currency LocalCurrency { get; set; }
        public Currency ForeignCurrency { get; set; }
        public Case CaseLocalSingle { get; set; }
        public Case CaseLocalMultiple { get; set; }
        public Case CaseForeignSingle { get; set; }
        public Case CaseForeignMultiple { get; set; }
        public Name LocalDebtor1 { get; set; }
        public Name LocalDebtor2 { get; set; }
        public Name ForeignDebtor1 { get; set; }
        public Name ForeignDebtor2 { get; set; }
        public int EntityId { get; set; }
        public WipTemplate ServiceCharge1 { get; set; }
        public WipTemplate ServiceCharge2 { get; set; }
        public DateTime Today { get; set; }
        public ProfitCentre StaffProfitCentre { get; set; }

        public Dictionary<int, string> LatestOpenActionByCase { get; set; }

        /// <summary>
        ///     This is a fallback choice of the 'source country resolution logic fn_GetSourceCountry for BillSourceCountryCode
        /// </summary>
        public string EntityCountry { get; set; }
    }
}