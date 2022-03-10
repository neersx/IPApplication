using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Names.Details;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Banking;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names.Payment;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Names.Details
{
    public class NameViewResolverFacts
    {
        public class NameViewResolverFixture : IFixture<NameViewResolver>
        {
            public NameViewResolverFixture(InMemoryDbContext db)
            {
                DbContext = db;
                FakeData = new Data(db);
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                SiteConfiguration = Substitute.For<ISiteConfiguration>();
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                Subject = new NameViewResolver(DbContext, PreferredCultureResolver, TaskSecurityProvider);
            }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public ISiteConfiguration SiteConfiguration { get; set; }
            public InMemoryDbContext DbContext { get; set; }
            public ITaskSecurityProvider TaskSecurityProvider { get; set; }
            public NameViewResolver Subject { get; }

            public Data FakeData { get; }

            public static Country DefaultCountry = new Country
            {
                Name = "Australia",
                Id = "AU"
            };

            public class Data
            {
                readonly InMemoryDbContext _db;

                public Data(InMemoryDbContext db)
                {
                    _db = db;
                }
                
                public Data WithSupplierType(int id, string name)
                {
                    new TableCode(id, (short)TableTypes.SupplierType, name).In(_db);
                    return this;
                }

                public Data WithTaxTreatments(int id, string name)
                {
                    new TableCode(id, (short)TableTypes.TaxTreatment, name).In(_db);
                    return this;
                }

                public Data WithTaxCodes(int id, string name)
                {
                    new TaxRate(id.ToString()){Description = name, DescriptionTId = Fixture.Integer()}.In(_db);
                    return this;
                }

                public Data WithPaymentTerm(int id, string name)
                {
                    new Frequency(id, 1, name, Fixture.Integer()).In(_db);
                    return this;
                }

                public Data WithPaymentMethod(int paymentMethodId)
                {
                    new PaymentMethods(Fixture.Integer()){Description = Fixture.String(), UsedBy = paymentMethodId}.In(_db);
                    return this;
                }

                public Data WithIntoBankAccount(int bankNameNo, int seqNo, int? nameId)
                {
                    new BankAccount
                    {
                        AccountName = Fixture.String(),
                        AccountOwner = nameId ?? Fixture.Integer(),
                        BankNameNo = bankNameNo,
                        SequenceNo = seqNo
                    }.In(_db);
                    return this;
                }

                public Data WithPaymentRestriction()
                {
                    new CrRestriction(Fixture.Integer()){ActionFlag = Fixture.Integer(), Description = Fixture.String()}.In(_db);
                    return this;
                }

                public Data WithReasonsForRestriction(int usedBy)
                {
                    new Reason(Fixture.String()){UsedBy = usedBy, Description = Fixture.String()}.In(_db);
                    return this;
                }
            }
        }

        public class GetNameViewRequiredData : FactBase
        {
            const int NameId = 1234;

            [Fact]
            public void ReturnsNameDetails()
            {
                var paymentTermText = Fixture.String();
                var taxText = Fixture.String();
                var taxTreatmentText = Fixture.String();
                var supplierTypeText = Fixture.String();
                
                var f = new NameViewResolverFixture(Db);
                f.FakeData
                 .WithPaymentTerm(Fixture.Integer(), paymentTermText)
                 .WithTaxCodes(Fixture.Integer(), taxText)
                 .WithTaxTreatments(Fixture.Integer(), taxTreatmentText)
                 .WithSupplierType(Fixture.Integer(), supplierTypeText);

                var r = f.Subject.GetPaymentTerms();

                Assert.Equal(paymentTermText, r.First().Value);

                r = f.Subject.GetSupplierTypes();

                Assert.Equal(supplierTypeText, r.First().Value);

                r = f.Subject.GetTaxTreatment();

                Assert.Equal(taxTreatmentText, r.First().Value);

                r = f.Subject.GetTaxRates();

                Assert.Equal(taxText, r.First().Value);
            }

            [Fact]
            public void ReturnsPaymentMethods()
            {
                var f = new NameViewResolverFixture(Db);
                f.FakeData
                 .WithPaymentMethod(0)
                 .WithPaymentMethod((int)KnownPaymentMethod.Payable)
                 .WithPaymentMethod((int)KnownPaymentMethod.Payable);

                var r = f.Subject.GetPaymentMethods();

                Assert.Equal(2, r.Count());
            }

            [Fact]
            public void ReturnsIntoAccounts()
            {
                var f = new NameViewResolverFixture(Db);
                f.FakeData
                 .WithIntoBankAccount(1111, 1, NameId)
                 .WithIntoBankAccount(2222, 2, NameId)
                 .WithIntoBankAccount(3333, 3, null);

                var r = f.Subject.GetIntoBankAccounts(NameId);

                var intoAccounts = r as KeyValuePair<string, string>[] ?? r.ToArray();
                Assert.Equal("1234^1111^1", intoAccounts.First().Key);
                Assert.Equal(2, intoAccounts.Length);
            }

            [Fact]
            public void ReturnsRestrictions()
            {
                var f = new NameViewResolverFixture(Db);
                f.FakeData
                 .WithPaymentRestriction()
                 .WithPaymentRestriction();

                var r = f.Subject.GetPaymentRestrictions();

                Assert.Equal(2, r.Count());
            }

            [Fact]
            public void ReturnsRestrictionReasons()
            {
                var f = new NameViewResolverFixture(Db);
                f.FakeData
                 .WithReasonsForRestriction((int) KnownApplicationUsage.AccountsReceivable)
                 .WithReasonsForRestriction((int) KnownApplicationUsage.AccountsPayable)
                 .WithReasonsForRestriction((int) KnownApplicationUsage.Timesheet);
                var r = f.Subject.GetReasonsForRestrictions();

                Assert.Equal(2, r.Count());
            }
        }
    }
}