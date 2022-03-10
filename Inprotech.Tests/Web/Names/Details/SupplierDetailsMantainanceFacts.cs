using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Processing;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Names.Details;
using Inprotech.Web.Names.Maintenance.Models;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting.Creditor;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Names.Extensions;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Names.Payment;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;
using Currency = InprotechKaizen.Model.Cases.Currency;
using Name = InprotechKaizen.Model.Names.Name;

namespace Inprotech.Tests.Web.Names.Details
{
    public class SupplierDetailsMaintenanceFacts
    {
        public class SupplierDetailsMaintenanceFixture : IFixture<SupplierDetailsMaintenance>
        {
            public SupplierDetailsMaintenanceFixture(InMemoryDbContext db)
            {
                DbContext = db;
                FakeData = new Data(db);
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                SiteConfiguration = Substitute.For<ISiteConfiguration>();
                NameAddressFormatter = Substitute.For<IFormattedNameAddressTelecom>();
                SecurityContext = Substitute.For<ISecurityContext>();
                SecurityContext.User.Returns(InternalWebApiUser());
                AsyncCommandScheduler = Substitute.For<IAsyncCommandScheduler>();
                Subject = new SupplierDetailsMaintenance(DbContext, PreferredCultureResolver, NameAddressFormatter, SecurityContext, AsyncCommandScheduler);
            }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public ISiteConfiguration SiteConfiguration { get; set; }
            public ISecurityContext SecurityContext { get; set; }
            public InMemoryDbContext DbContext { get; set; }
            public SupplierDetailsMaintenance Subject { get; }
            public static IFormattedNameAddressTelecom NameAddressFormatter { get; set; }
            public IAsyncCommandScheduler AsyncCommandScheduler { get; }

            User InternalWebApiUser()
            {
                return UserBuilder.AsInternalUser(DbContext, "internal").Build().In(DbContext);
            }

            public Data FakeData { get; }

            public static Country DefaultCountry = new Country
            {
                Name = "Australia",
                Id = "AU"
            };
            public SupplierDetailsMaintenanceFixture WithDefaultCountry()
            {
                SiteConfiguration.HomeCountry().Returns(DefaultCountry);
                return this;
            }

            public class Data
            {
                readonly InMemoryDbContext _db;

                public Data(InMemoryDbContext db)
                {
                    _db = db;
                }

                public Data WithCreditorData(int nameId, string defaultTaxCode)
                {
                    new Creditor { NameId = nameId, SupplierType = Fixture.Integer(), PurchaseDescription = Fixture.String(), DefaultTaxCode = defaultTaxCode, ChequePayee = Fixture.String() }.In(_db);
                    return this;
                }

                public Data WithCreditor(Creditor creditor)
                {
                    creditor.In(_db);
                    return this;
                }

                public Data WithDefaultName(int nameId)
                {
                    var address = new Address
                    {
                        City = "Sydney",
                        Street1 = "York Street",
                        PostCode = "2000",
                        Country = DefaultCountry
                    }.In(_db);

                    var mainContactName = new NameBuilder(_db).Build().In(_db);

                    var name = new Name(nameId) { MainContact = mainContactName, PostalAddressId = address.Id }.In(_db);
                    const AddressType addressType = AddressType.Postal;
                    var addressTypeTableCode = new TableCode((int)addressType, (short)TableTypes.AddressType, addressType.ToString()).In(_db);
                    var postalAddress = new NameAddress(name, address, addressTypeTableCode) { AddressType = (int)addressType }.In(_db);
                    name.Addresses.Add(postalAddress);

                    var addresses = new Dictionary<int, AddressFormatted>();
                    foreach (var nameAddress in name.Addresses)
                    {
                        addresses.Add(nameAddress.AddressId, new AddressFormatted { Id = nameAddress.AddressId, Address = nameAddress.Address.Formatted() });
                    }
                    NameAddressFormatter.GetAddressesFormatted(Arg.Any<int[]>()).Returns(addresses);

                    var names = new Dictionary<int, NameFormatted>
                    {
                        {name.Id, new NameFormatted {NameId = name.Id, Name = name.Formatted()}},
                        {mainContactName.Id, new NameFormatted {NameId = mainContactName.Id, Name = mainContactName.Formatted()}}
                    };
                    NameAddressFormatter.GetFormatted(Arg.Any<int[]>()).Returns(names);
                    return this;
                }

                public Data WithAssociatedName(int nameId)
                {
                    var name = new Name { NameCode = Fixture.String(), LastName = Fixture.String() }.In(_db);
                    var contact = new Name { NameCode = Fixture.String(), LastName = Fixture.String() }.In(_db);
                    var relatedName = new Name(nameId).In(_db);
                    new AssociatedName(relatedName, name, KnownRelations.Pay, Int16.MinValue) { ContactId = contact.Id }.In(_db);

                    var names = new Dictionary<int, NameFormatted>
                    {
                        {name.Id, new NameFormatted {NameId = name.Id, Name = name.Formatted()}},
                        {contact.Id, new NameFormatted {NameId = contact.Id, Name = contact.Formatted()}},
                        {relatedName.Id, new NameFormatted {NameId = relatedName.Id, Name = relatedName.Formatted()}}
                    };
                    NameAddressFormatter.GetFormatted(Arg.Any<int[]>()).Returns(names);
                    return this;
                }

                public Data WithCurrency(string currencyId)
                {
                    new Currency(currencyId) { Description = Fixture.String(), DescriptionTId = Fixture.Integer() }.In(_db);
                    return this;
                }

                public int WithExchangeRate()
                {
                    var exchangeRateSchedule = new ExchangeRateSchedule { Description = Fixture.String(), DescriptionTId = Fixture.Integer() }.In(_db);
                    return exchangeRateSchedule.Id;
                }

                public Data WithProfitCenter(string id)
                {
                    new ProfitCentre(id, Fixture.String()).In(_db);
                    return this;
                }

                public Data WithLedgerAccount(int id)
                {
                    new LedgerAccount(id) { Description = Fixture.String(), AccountCode = Fixture.String() }.In(_db);
                    return this;
                }

                public Data WithWipDisbursement(string wipCode)
                {
                    new WipTemplate() { WipCode = wipCode, Description = Fixture.String() }.In(_db);
                    return this;
                }

                public Data WithCrRestrictions(int id)
                {
                    new CrRestriction(id) { ActionFlag = Fixture.Integer() }.In(_db);
                    return this;
                }
            }
        }

        public class GetNameViewRequiredData : FactBase
        {
            const int NameId = 1234;
            [Fact]
            public async Task ReturnsSupplierDetailsFromCreditor()
            {
                var defaultTaxCode = Fixture.String();

                var f = new SupplierDetailsMaintenanceFixture(Db).WithDefaultCountry();
                f.FakeData
                 .WithDefaultName(NameId)
                 .WithCreditorData(NameId, defaultTaxCode);

                var r = await f.Subject.GetSupplierDetails(NameId);
                Assert.NotNull(r.SupplierType);
                Assert.NotNull(r.PurchaseDescription);
                Assert.Equal(defaultTaxCode, r.DefaultTaxCode);
                Assert.NotNull(r.WithPayee);
                Assert.Null(r.PaymentMethod);

                Assert.Null(r.SendToAttentionName);
                Assert.Null(r.SendToAddress);
                Assert.Null(r.LedgerAcc.Code);
                Assert.Null(r.SendToName);
            }

            [Fact]
            public async Task ShouldReturnsSupplierAttention()
            {
                var defaultTaxCode = Fixture.String();

                var f = new SupplierDetailsMaintenanceFixture(Db).WithDefaultCountry();
                f.FakeData
                 .WithAssociatedName(NameId)
                 .WithCreditorData(NameId, defaultTaxCode);

                var r = await f.Subject.GetSupplierDetails(NameId);
                Assert.NotNull(r.SendToAttentionName);
            }

            [Fact]
            public async Task ShouldReturnsSupplierPaymentNameData()
            {
                const int nameId = 1234;
                var defaultTaxCode = Fixture.String();

                var f = new SupplierDetailsMaintenanceFixture(Db).WithDefaultCountry();
                f.FakeData
                 .WithCreditorData(nameId, defaultTaxCode)
                 .WithAssociatedName(nameId);

                var r = await f.Subject.GetSupplierDetails(nameId);

                Assert.NotNull(r.SendToName);
            }

            [Fact]
            public async Task ShouldReturnsSupplierCurrencyAndExchangeRate()
            {
                const int nameId = 1234;
                var purchaseCurrency = Fixture.String();

                var f = new SupplierDetailsMaintenanceFixture(Db).WithDefaultCountry();
                var exchangeScheduleId = f.FakeData.WithExchangeRate();
                f.FakeData
                 .WithDefaultName(nameId)
                 .WithCreditor(new Creditor {NameId = nameId, PurchaseCurrency = purchaseCurrency, ExchangeScheduleId = exchangeScheduleId})
                 .WithCurrency(purchaseCurrency);

                var r = await f.Subject.GetSupplierDetails(nameId);

                Assert.NotNull(r.PurchaseCurrency.Description);
                Assert.NotNull(r.ExchangeRate.Description);

                Assert.Equal("0", r.SupplierType);
                Assert.Null(r.PurchaseDescription);
            }

            [Fact]
            public async Task ShouldReturnsProfitCenterAndLedgerAccount()
            {
                const int nameId = 1234;
                var profitCentreId = Fixture.String();
                var ledgerAcc = Fixture.Integer();

                var f = new SupplierDetailsMaintenanceFixture(Db).WithDefaultCountry();
                f.FakeData
                 .WithDefaultName(nameId)
                 .WithCreditor(new Creditor { NameId = nameId, ProfitCentre = profitCentreId, ExpenseAccount = ledgerAcc })
                 .WithProfitCenter(profitCentreId)
                 .WithLedgerAccount(ledgerAcc);

                var r = await f.Subject.GetSupplierDetails(nameId);

                Assert.NotNull(r.ProfitCentre.Code);
                Assert.NotNull(r.ProfitCentre.Description);
                Assert.NotNull(r.LedgerAcc.Code);
                Assert.NotNull(r.LedgerAcc.Description);

                Assert.Null(r.PurchaseCurrency.Description);
                Assert.Null(r.ExchangeRate.Description);
            }

            [Fact]
            public async Task ShouldReturnsSupplierWipDisbursementAndRestriction()
            {
                const int nameId = 1234;
                var disbursementWipCode = Fixture.String();
                var restrictionId = Fixture.Integer();

                var f = new SupplierDetailsMaintenanceFixture(Db).WithDefaultCountry();
                f.FakeData
                 .WithDefaultName(nameId)
                 .WithCreditor(new Creditor { NameId = nameId, DisbursementWipCode = disbursementWipCode, RestrictionId = restrictionId })
                 .WithWipDisbursement(disbursementWipCode)
                 .WithCrRestrictions(restrictionId);

                var r = await f.Subject.GetSupplierDetails(nameId);

                Assert.NotNull(r.WipDisbursement);
                Assert.NotNull(r.RestrictionKey);
                Assert.Null(r.ExchangeRate.Description);
            }
        }
        public class SaveNameViewRequiredData : FactBase
        {
            const int NameId = 1234;

            [Fact]
            public async Task ShouldSaveCreditorRequiredData()
            {
                var purchaseCurrency = Fixture.String();
                var exchangeScheduleId = Fixture.Integer();
                var creditor = new Creditor { NameId = NameId, PurchaseCurrency = purchaseCurrency, ExchangeScheduleId = exchangeScheduleId };

                var f = new SupplierDetailsMaintenanceFixture(Db).WithDefaultCountry();
                f.FakeData
                 .WithDefaultName(NameId)
                 .WithCreditor(creditor);

                var input = new SupplierDetailsSaveModel
                {
                    SupplierType = "1"
                };
                f.Subject.SaveSupplierDetails(NameId, input);
                var updatedCreditor = Db.Set<Creditor>().Single(_ => _.NameId == NameId && _.SupplierType == Convert.ToInt32(input.SupplierType));
                Assert.NotNull(updatedCreditor);
                Assert.NotNull(updatedCreditor.SupplierType);
                Assert.Null(updatedCreditor.PurchaseCurrency);
                Assert.Null(updatedCreditor.ExchangeScheduleId);
            }

            [Fact]
            public async Task ShouldSaveCreditorData()
            {
                var creditor = new Creditor { NameId = NameId };

                var f = new SupplierDetailsMaintenanceFixture(Db).WithDefaultCountry();
                f.FakeData
                 .WithDefaultName(NameId)
                 .WithCreditor(creditor);

                var input = new SupplierDetailsSaveModel
                {
                    SupplierType = "1",
                    PurchaseDescription = Fixture.String(),
                    ExchangeRate = new CodeDescPair { Id = "1", Code = "ex1", Description = "exchange" },
                    DefaultTaxCode = Fixture.String(),
                    TaxTreatmentCode = Fixture.Integer().ToString(),
                    PaymentTermNo = Fixture.Integer().ToString(),
                    ProfitCentre = new CodeDescPair { Code = "pc", Description = "desc" },
                    PurchaseCurrency = new CodeDescPair { Code = "aaa", Description = "desc" },
                    LedgerAcc = new CodeDescPair { Id = "111" },
                    WipDisbursement = new CodeDescPair { Key = "abc" },
                    SendToAttentionName = null,
                    SendToName = new Inprotech.Web.Picklists.Name { Key = NameId },
                    SendToAddress = null,
                    Instruction = Fixture.String(),
                    WithPayee = Fixture.String(),
                    PaymentMethod = Fixture.Integer().ToString(),
                    IntoBankAccountCode = null,
                    RestrictionKey = Fixture.Integer().ToString(),
                    ReasonCode = Fixture.String(),
                    SupplierName = new Inprotech.Web.Picklists.Name { Key = NameId },
                    SupplierNameAddress = null,
                    SupplierMainContact = null,
                    OldSendToAttentionName = null,
                    OldSendToName = new Inprotech.Web.Picklists.Name { Key = NameId },
                    OldSendToAddress = null
                };
                f.Subject.SaveSupplierDetails(NameId, input);
                var c = f.DbContext.Set<Creditor>().First(_ => _.NameId == NameId);
                Assert.Equal(input.PurchaseDescription, c.PurchaseDescription);
                Assert.Equal(input.DefaultTaxCode, c.DefaultTaxCode);
                Assert.Equal(input.TaxTreatmentCode, c.TaxTreatment.ToString());
                Assert.Equal(input.PaymentTermNo, c.PaymentTermNo.ToString());
                Assert.Equal(input.Instruction, c.Instructions);
                Assert.Equal(input.WithPayee, c.ChequePayee);
                Assert.Equal(input.RestrictionKey, c.RestrictionId.ToString());
                Assert.Equal(input.ReasonCode, c.RestrictionReasonCode);
                Assert.Equal(input.ExchangeRate.Id, c.ExchangeScheduleId.ToString());
                Assert.Equal(input.ProfitCentre.Code, c.ProfitCentre);
                Assert.Equal(input.LedgerAcc.Id, c.ExpenseAccount.ToString());
                Assert.Equal(input.PurchaseCurrency.Code, c.PurchaseCurrency);
                Assert.Equal(input.WipDisbursement.Key, c.DisbursementWipCode);
            }

            [Fact]
            public async Task ShouldSaveCreditorBankAccountData()
            {
                var creditor = new Creditor { NameId = NameId };

                var f = new SupplierDetailsMaintenanceFixture(Db).WithDefaultCountry();
                f.FakeData
                 .WithDefaultName(NameId)
                 .WithCreditor(creditor);

                var input = new SupplierDetailsSaveModel
                {
                    SupplierType = "1",
                    IntoBankAccountCode = "1^2^3"
                };
                f.Subject.SaveSupplierDetails(NameId, input);
                var c = f.DbContext.Set<Creditor>().First(_ => _.NameId == NameId);
                Assert.Equal(1, c.BankAccountOwner);
                Assert.Equal(2, c.BankNameNo);
                Assert.Equal(3, c.BankSequenceNo);
            }

            [Fact]
            public async Task ShouldUpdateAssociatedName()
            {
                var creditor = new Creditor { NameId = NameId };
                var address1 = new AddressBuilder().Build().In(Db);
                var address2 = new AddressBuilder().Build().In(Db);
                new Name(NameId) { PostalAddressId = address1.Id, StreetAddressId = address1.Id }.In(Db);

                var mainContactName = new Name { FirstName = Fixture.String() }.In(Db);
                var associatedName = new Name { FirstName = Fixture.String(), MainContact = mainContactName, PostalAddressId = address2.Id, StreetAddressId = address2.Id }.In(Db);

                new AssociatedName { RelatedNameId = NameId, Id = NameId, Relationship = KnownRelations.Pay }.In(Db);

                var f = new SupplierDetailsMaintenanceFixture(Db).WithDefaultCountry();
                f.FakeData
                 .WithDefaultName(NameId)
                 .WithCreditor(creditor);

                var input = new SupplierDetailsSaveModel
                {
                    SendToAttentionName = new Inprotech.Web.Picklists.Name { Key = mainContactName.Id },
                    SendToName = new Inprotech.Web.Picklists.Name { Key = associatedName.Id },
                    SendToAddress = new AddressPicklistItem() { Id = address2.Id },
                    SupplierName = new Inprotech.Web.Picklists.Name { Key = NameId },
                    SupplierNameAddress = new AddressPicklistItem() { Id = address1.Id },
                    SupplierMainContact = null,
                    OldSendToAttentionName = null,
                    OldSendToName = new Inprotech.Web.Picklists.Name { Key = NameId },
                    OldSendToAddress = new AddressPicklistItem() { Id = address1.Id }
                };
                f.Subject.SaveSupplierDetails(NameId, input);
                var r = f.DbContext.Set<AssociatedName>().First(_ => _.Id == NameId);
                Assert.Equal(input.SendToName.Key, r.RelatedNameId);
                Assert.Equal(input.SendToAttentionName.Key, r.ContactId);
                Assert.Equal(input.SendToAddress.Id, r.PostalAddressId);
            }

            [Fact]
            public async Task ShouldInsertAssociatedName()
            {
                var creditor = new Creditor { NameId = NameId };
                var address1 = new AddressBuilder().Build().In(Db);
                var address2 = new AddressBuilder().Build().In(Db);
                new Name(NameId) { PostalAddressId = address1.Id, StreetAddressId = address1.Id }.In(Db);

                var mainContactName = new Name { FirstName = Fixture.String() }.In(Db);
                var associatedName = new Name { FirstName = Fixture.String(), MainContact = mainContactName, PostalAddressId = address2.Id, StreetAddressId = address2.Id }.In(Db);

                var f = new SupplierDetailsMaintenanceFixture(Db).WithDefaultCountry();
                f.FakeData
                 .WithDefaultName(NameId)
                 .WithCreditor(creditor);

                var input = new SupplierDetailsSaveModel
                {
                    SendToAttentionName = new Inprotech.Web.Picklists.Name { Key = mainContactName.Id },
                    SendToName = new Inprotech.Web.Picklists.Name { Key = associatedName.Id },
                    SendToAddress = new AddressPicklistItem() { Id = address2.Id },
                    SupplierName = new Inprotech.Web.Picklists.Name { Key = NameId },
                    SupplierNameAddress = new AddressPicklistItem() { Id = address1.Id },
                    SupplierMainContact = null,
                    OldSendToAttentionName = null,
                    OldSendToName = new Inprotech.Web.Picklists.Name { Key = NameId },
                    OldSendToAddress = new AddressPicklistItem() { Id = address1.Id }
                };
                f.Subject.SaveSupplierDetails(NameId, input);
                var r = f.DbContext.Set<AssociatedName>().First(_ => _.Id == NameId);
                Assert.Equal(input.SendToName.Key, r.RelatedNameId);
                Assert.Equal(input.SendToAttentionName.Key, r.ContactId);
                Assert.Equal(input.SendToAddress.Id, r.PostalAddressId);
            }

            [Fact]
            public async Task ShouldDeleteAssociatedName()
            {
                var creditor = new Creditor { NameId = NameId };
                var address1 = new AddressBuilder().Build().In(Db);
                new Name(NameId) { PostalAddressId = address1.Id, StreetAddressId = address1.Id }.In(Db);

                var f = new SupplierDetailsMaintenanceFixture(Db).WithDefaultCountry();
                f.FakeData
                 .WithDefaultName(NameId)
                 .WithCreditor(creditor);

                new AssociatedName { RelatedNameId = NameId, Id = NameId, Relationship = KnownRelations.Pay }.In(Db);
                var actual = f.DbContext.Set<AssociatedName>().Select(_ => _.Id == NameId);
                Assert.Equal(1, actual.Count());

                var input = new SupplierDetailsSaveModel
                {
                    SendToAttentionName = null,
                    SendToName = new Inprotech.Web.Picklists.Name { Key = NameId },
                    SendToAddress = new AddressPicklistItem() { Id = address1.Id },
                    SupplierName = new Inprotech.Web.Picklists.Name { Key = NameId },
                    SupplierNameAddress = new AddressPicklistItem() { Id = address1.Id },
                    SupplierMainContact = null,
                    OldSendToAttentionName = null,
                    OldSendToName = new Inprotech.Web.Picklists.Name { Key = NameId },
                    OldSendToAddress = null
                };
                f.Subject.SaveSupplierDetails(NameId, input);
                var r = f.DbContext.Set<AssociatedName>().Select(_ => _.Id == NameId);
                Assert.Equal(0, r.Count());
            }
        }
    }
}