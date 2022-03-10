using System;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Tax;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Billing
{
    public class DebitOrCreditNotesControllerFacts
    {
        readonly IElectronicBillingXmlResolver _electronicBillingXmlResolver = Substitute.For<IElectronicBillingXmlResolver>();
        readonly IDebitOrCreditNotes _debitOrCreditNotes = Substitute.For<IDebitOrCreditNotes>();
        readonly ITaxRateResolver _taxRateResolver = Substitute.For<ITaxRateResolver>();

        DebitOrCreditNotesController CreateSubject()
        {
            var securityContext = Substitute.For<ISecurityContext>();
            securityContext.User.Returns(new User());

            var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

            return new DebitOrCreditNotesController(securityContext, preferredCultureResolver, _electronicBillingXmlResolver, _debitOrCreditNotes, _taxRateResolver);
        }

        [Fact]
        public async Task ShouldReturnRequestedDebitNote()
        {
            var entityId = Fixture.Integer();
            var transactionId = Fixture.Integer();
            var debitOrCreditNote = new DebitOrCreditNote();

            _debitOrCreditNotes.Retrieve(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<int>())
                               .Returns(new[] { debitOrCreditNote });

            var subject = CreateSubject();
            var result = await subject.GetDebitNotes(entityId, transactionId);

            Assert.Equal(debitOrCreditNote, result.Single());

            _debitOrCreditNotes.Received(1)
                               .Retrieve(Arg.Any<int>(), Arg.Any<string>(), entityId, transactionId)
                               .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldReturnRequestedMergedDebitNotes()
        {
            var entityId = Fixture.Integer();
            var transactionId = Fixture.Integer();

            var mergeXmlKeys = new MergeXmlKeys
            {
                OpenItemXmls =
                {
                    new OpenItemXmlKey
                    {
                        ItemEntityNo = entityId,
                        ItemTransNo = transactionId
                    }
                }
            };

            var debitOrCreditNote = new DebitOrCreditNote();

            _debitOrCreditNotes.MergedCreditItems(Arg.Any<int>(), Arg.Any<string>(),
                                                  Arg.Any<MergeXmlKeys>(), Arg.Any<int>(), Arg.Any<int>())
                               .Returns(new[] { debitOrCreditNote });

            var subject = CreateSubject();
            var result = await subject.GetMergedDebitNotes(entityId, transactionId, XElement.Parse(mergeXmlKeys.ToString()));

            Assert.Equal(debitOrCreditNote, result.Single());

            _debitOrCreditNotes.Received(1)
                               .MergedCreditItems(Arg.Any<int>(), Arg.Any<string>(),
                                                  Arg.Is<MergeXmlKeys>(_ => _.ToString() == mergeXmlKeys.ToString()),
                                                  entityId, transactionId)
                               .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldReturnEffectiveTaxRates()
        {
            var entityId = Fixture.Integer();
            var raisedByStaffId = Fixture.Integer();
            var billDate = Fixture.Today();
            var taxCode = Fixture.String();
            var sourceCountry = Fixture.String();

            var taxRate = new TaxRate();

            _taxRateResolver.Resolve(Arg.Any<int>(), Arg.Any<string>(),
                                     Arg.Any<string>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<int>(), Arg.Any<DateTime>())
                            .Returns(taxRate);

            var subject = CreateSubject();
            var result = await subject.GetEffectiveTaxRate(entityId, raisedByStaffId, billDate, taxCode, sourceCountry);

            Assert.Equal(taxRate, result);

            _taxRateResolver.Received(1)
                            .Resolve(Arg.Any<int>(), Arg.Any<string>(), taxCode, sourceCountry, raisedByStaffId, entityId, billDate)
                            .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldReturnAvailableCredits()
        {
            var entityId = Fixture.Integer();
            var caseIds = new[] { Fixture.Integer() };
            var debtorIds = new[] { Fixture.Integer() };
            var creditItem = new CreditItem();

            _debitOrCreditNotes.AvailableCredits(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<int[]>(), Arg.Any<int[]>())
                               .Returns(new[] { creditItem });

            var subject = CreateSubject();
            var result = await subject.GetAvailableCredits(new DebitOrCreditNotesController.AvailableCreditsParameters
            {
                EntityId = entityId,
                CaseIds = caseIds,
                DebtorIds = debtorIds
            });

            Assert.Equal(creditItem, result.Single());

            _debitOrCreditNotes.Received(1)
                               .AvailableCredits(Arg.Any<int>(), Arg.Any<string>(), entityId, caseIds, debtorIds)
                               .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldReturnAvailableCreditsForMergedBill()
        {
            var mergeXmlKeys = new MergeXmlKeys
            {
                OpenItemXmls =
                {
                    new OpenItemXmlKey
                    {
                        ItemEntityNo = Fixture.Integer(),
                        ItemTransNo = Fixture.Integer()
                    }
                }
            };

            var creditItem = new CreditItem();

            _debitOrCreditNotes.MergedAvailableCredits(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<MergeXmlKeys>())
                               .Returns(new[] { creditItem });

            var subject = CreateSubject();
            var result = await subject.GetMergedAvailableCredits(XElement.Parse(mergeXmlKeys.ToString()));

            Assert.Equal(creditItem, result.Single());

            _debitOrCreditNotes.Received(1)
                               .MergedAvailableCredits(Arg.Any<int>(), Arg.Any<string>(),
                                                       Arg.Is<MergeXmlKeys>(_ => _.ToString() == mergeXmlKeys.ToString()))
                               .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldReturnRequestedElectronicBillXmlData()
        {
            var openItemNo = Fixture.String();
            var itemEntityId = Fixture.Integer();
            var eBill = new ElectronicBillingData();

            _electronicBillingXmlResolver.Resolve(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<int>())
                                         .Returns(eBill);

            var subject = CreateSubject();
            var result = await subject.ResolveElectronicBillingData(openItemNo, itemEntityId);

            Assert.Equal(eBill, result);

            _electronicBillingXmlResolver.Received(1)
                                         .Resolve(Arg.Any<int>(), Arg.Any<string>(), openItemNo, itemEntityId)
                                         .IgnoreAwaitForNSubstituteAssertion();
        }
    }
}
