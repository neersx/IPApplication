using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.DbHelpers.Builders.Accounting;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Account;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using WipCategory = InprotechKaizen.Model.Accounting.WipCategory;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Billing.DebtorOnly
{
    public class DebtorOnlyBillDataSetup
    {
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

            /* LOCAL DEBTOR SCENARIO  10% discount across the board */
            var localDebtor = new NameBuilder(x.DbContext).CreateClientOrg("LOCAL-1");
            x.Insert(new ClientDetail(localDebtor.Id));
            x.Insert(new Discount {NameId = localDebtor.Id, DiscountRate = (decimal) 10.0});
            x.Insert(new Account {EntityId = homeEntity, Balance = 0, NameId = localDebtor.Id});

            /* FOREIGN DEBTOR SCENARIO: foreign debtor 1 will always have a 20% discount and a margin of $100 in foreign currency 1 'F1' */
            var foreignCurrency = new CurrencyBuilder(x.DbContext).Create("F1", (decimal) 1.1, (decimal) 1.1);
            var foreignDebtor = new NameBuilder(x.DbContext).CreateClientOrg("FOREIGN-1");
            x.Insert(new ClientDetail(foreignDebtor.Id) {CurrencyId = foreignCurrency.Id});
            x.Insert(new Discount {NameId = foreignDebtor.Id, DiscountRate = (decimal) 20.0});
            x.Insert(new Account {EntityId = homeEntity, Balance = 0, NameId = foreignDebtor.Id});

            /*
             * FOREIGN DEBTOR SCENARIO: 'foreign-multiple' will have
             * foreign debtor 1 in foreign currency 1 'F1'
             * foreign currency 1 has exchange rate 1.1
             */

            var entityCountry = (from a in x.DbContext.Set<Address>()
                                 join n in x.DbContext.Set<Name>() on a.Id equals n.PostalAddressId
                                 where n.Id == homeEntity
                                 select a.CountryId).Single();

            x.DbContext.SaveChanges();

            var debtorOnlyWipForLocalDebtor = new WipBuilder(x.DbContext)
                .BuildDebtorOnlyWithWorkHistory(homeEntity, localDebtor.Id, serviceChargeWipTemplate1.WipCode, 1000, 10);

            var debtorOnlyWipForForeignDebtor = new WipBuilder(x.DbContext)
                .BuildDebtorOnlyWithWorkHistory(homeEntity, foreignDebtor.Id, serviceChargeWipTemplate1.WipCode, 1000, 10, foreignCurrency.Id, (decimal) 1.1);

            var copiesTo = new NameBuilder(x.DbContext).CreateClientOrg("cc-org");
            var copiesToContact = new NameBuilder(x.DbContext).CreateClientIndividual("cc-contact");

            x.Insert(new AssociatedName(localDebtor, copiesTo, KnownNameRelations.CopyBillsTo, 0) { ContactId = copiesToContact.Id });
            x.Insert(new AssociatedName(foreignDebtor, copiesTo, KnownNameRelations.CopyBillsTo, 0) { ContactId = copiesToContact.Id });
            
            var discountWipType = x.DbContext.Set<WipType>().Single(_ => _.Id == "DISC");
            var discountWipTemplate = x.DbContext.Set<WipTemplate>().Single(_ => _.WipCode == "DISC");

            return new BillingData
            {
                Today = today,
                StaffName = staffName,
                StaffProfitCentre = profitCentre,
                User = user,

                LocalCurrency = homeCurrency,
                LocalDebtor = localDebtor,
                ForeignDebtor = foreignDebtor,
                ForeignCurrency = foreignCurrency,

                CopyBillsTo = copiesTo,
                CopyBillsToContact = copiesToContact,

                ServiceCharge1 = serviceChargeWipTemplate1,
                ServiceCharge2 = serviceChargeWipTemplate2,

                EntityId = homeEntity,
                EntityCountry = entityCountry,

                DebtorOnlyWipLocalDebtor = debtorOnlyWipForLocalDebtor.Wip,
                DebtorOnlyWipDiscountLocalDebtor = debtorOnlyWipForLocalDebtor.Discount,
                DebtorOnlyWipForeignDebtor = debtorOnlyWipForForeignDebtor.Wip,
                DebtorOnlyWipDiscountForeignDebtor = debtorOnlyWipForForeignDebtor.Discount,

                ServiceChargeWipTemplate = serviceChargeWipTemplate1,
                ServiceChargeWipType = serviceChargeWipTemplate1.WipType,
                ServiceChargeWipCategory = serviceChargeWipTemplate1.WipType.Category,

                /* this is simplified for test data retrieval, it should be based on effective date, country (or fallback to 'ZZZ') */
                ServiceChargeTaxRate = x.DbContext.Set<TaxRatesCountry>().Single(_ => _.TaxCode == serviceChargeWipTemplate1.TaxCode),  
                    
                DiscountWipTemplate = discountWipTemplate,
                DiscountWipType = discountWipType,

                /* this is simplified for test data retrieval, it should be based on effective date, country (or fallback to 'ZZZ') */
                DiscountTaxRate = x.DbContext.Set<TaxRatesCountry>().Single(_ => _.TaxCode == discountWipTemplate.TaxCode)
            };
        }
    }

    public class BillingData
    {
        public Name StaffName { get; set; }
        public TestUser User { get; set; }
        public Currency LocalCurrency { get; set; }
        public Currency ForeignCurrency { get; set; }
        public Name LocalDebtor { get; set; }
        public Name ForeignDebtor { get; set; }
        public int EntityId { get; set; }
        public WipTemplate ServiceCharge1 { get; set; }
        public WipTemplate ServiceCharge2 { get; set; }
        public DateTime Today { get; set; }
        public ProfitCentre StaffProfitCentre { get; set; }

        /// <summary>
        ///     This is a fallback choice of the 'source country resolution logic fn_GetSourceCountry for BillSourceCountryCode
        /// </summary>
        public string EntityCountry { get; set; }

        public WorkInProgress DebtorOnlyWipLocalDebtor { get; set; }
        public WorkInProgress DebtorOnlyWipForeignDebtor { get; set; }
        public WorkInProgress DebtorOnlyWipDiscountLocalDebtor { get; set; }
        public WorkInProgress DebtorOnlyWipDiscountForeignDebtor { get; set; }
        public Name CopyBillsTo { get; set; }
        public Name CopyBillsToContact { get; set; }
        public TaxRatesCountry ServiceChargeTaxRate { get; set; }
        public WipTemplate DiscountWipTemplate { get; set; }
        public WipType DiscountWipType { get; set; }
        public TaxRatesCountry DiscountTaxRate { get; set; }
        public WipTemplate ServiceChargeWipTemplate { get; set; }
        public WipType ServiceChargeWipType { get; set; }
        public InprotechKaizen.Model.Accounting.Work.WipCategory ServiceChargeWipCategory { get; set; }
    }
}