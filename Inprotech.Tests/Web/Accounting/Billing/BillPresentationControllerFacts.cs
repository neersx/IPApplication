using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.References;
using InprotechKaizen.Model.Components.Accounting.Billing.Presentation;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Billing
{
    public class BillPresentationControllerFacts : FactBase
    {
        readonly IPreferredCultureResolver _preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
        readonly ITranslatedNarrative _translatedNarrative = Substitute.For<ITranslatedNarrative>();
        readonly IReferenceResolver _referenceResolver = Substitute.For<IReferenceResolver>();
        readonly IBillFormatResolver _billFormatResolver = Substitute.For<IBillFormatResolver>();
        readonly IBillLines _billLines = Substitute.For<IBillLines>();

        BillPresentationController CreateSubject()
        {
            var securityContext = Substitute.For<ISecurityContext>();
            securityContext.User.Returns(new User());
            return new BillPresentationController(securityContext, _preferredCultureResolver, _billFormatResolver, _translatedNarrative, _referenceResolver, _billLines);
        }

        [Fact]
        public async Task ShouldCallTranslateNarrativeToReturnTranslatedText()
        {
            var narrativeId = Fixture.Short();
            var languageId = Fixture.Short();
            var fallbackCulture = Fixture.String();
            var translatedText = Fixture.String();

            _preferredCultureResolver.Resolve().Returns(fallbackCulture);

            _translatedNarrative.For(fallbackCulture, narrativeId, languageId: languageId)
                                .Returns(translatedText);

            var subject = CreateSubject();

            var r = await subject.GetTranslatedNarrativeText(narrativeId, languageId);

            Assert.Equal(translatedText, r);
        }

        [Theory]
        [InlineData("1")]
        [InlineData("1,2,3")]
        public async Task ShouldCallReferenceResolverToReturnBillReference(string caseIds)
        {
            var openItemNo = Fixture.String();
            var languageId = Fixture.Integer();
            var useRenewalDebtor = Fixture.Boolean();
            var debtorId = Fixture.Integer();

            var expected = new BillReference();

            _referenceResolver.Resolve(Arg.Any<int>(), Arg.Any<string>(),
                                       Arg.Any<int[]>(), languageId, useRenewalDebtor, debtorId, openItemNo)
                              .Returns(expected);

            var subject = CreateSubject();
            
            var r = await subject.GetBillReference(caseIds, languageId, useRenewalDebtor, debtorId, openItemNo);

            Assert.Equal(expected, r);

            var caseIdArray = caseIds.Split(',')
                                     .Select(_ => int.Parse(_.Trim()))
                                     .ToArray();

            _referenceResolver.Received(1)
                              .Resolve(Arg.Any<int>(), Arg.Any<string>(),
                                       Arg.Is<int[]>(x => caseIdArray.SequenceEqual(x)),
                                       languageId, useRenewalDebtor, debtorId, openItemNo)
                              .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldResolveBillLinesForSingleBill()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            
            var billLine = new BillLine();

            _billLines.Retrieve(itemEntityId, itemTransactionId).Returns(new[] { billLine });
            
            var subject = CreateSubject();

            var result = await subject.GetBillLines(itemEntityId, itemTransactionId);

            Assert.Equal(billLine, result.Single());
        }

        [Fact]
        public async Task ShouldResolveBillLinesForMultipleBills()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();

            var mergeXmlKeys = new MergeXmlKeys
            {
                OpenItemXmls =
                {
                    new OpenItemXmlKey
                    {
                        ItemEntityNo = itemEntityId,
                        ItemTransNo = itemTransactionId
                    }
                }
            };

            var billLine = new BillLine();
            
            _billLines.Retrieve(Arg.Any<MergeXmlKeys>()).Returns(new[] { billLine });
            
            var subject = CreateSubject();

            var result = await subject.GetMergedBillLine(XElement.Parse(mergeXmlKeys.ToString()));

            Assert.Equal(billLine, result.Single());

            _billLines.Received(1)
                      .Retrieve(Arg.Is<MergeXmlKeys>(_ => _.ToString() == mergeXmlKeys.ToString()))
                      .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldResolveBestBillFormatBasedOnSelectionCriteria()
        {
            var billFormatCriteria = new BillFormatCriteria();
            var billFormat = new BillFormat();

            _billFormatResolver.Resolve(Arg.Any<int>(), Arg.Any<string>(), billFormatCriteria)
                               .Returns(billFormat);

            var subject = CreateSubject();
            var result = await subject.GetBestBillFormat(billFormatCriteria);

            Assert.Equal(billFormat, result);
        }

        [Fact]
        public async Task ShouldReturnRequestedBillFormat()
        {
            var billFormatId = Fixture.Integer();
            var billFormat = new BillFormat();

            _billFormatResolver.Resolve(Arg.Any<int>(), Arg.Any<string>(), billFormatId)
                               .Returns(billFormat);

            var subject = CreateSubject();
            var result = await subject.GetBillFormat(billFormatId);

            Assert.Equal(billFormat, result);
        }

        [Fact]
        public async Task ShouldGenerateBillMappedValuesInXmlFromProvidedBillLines()
        {
            var billFormatId = Fixture.Integer();
            var entityId = Fixture.Integer();
            var debtorId = Fixture.Integer();
            var caseId = Fixture.Integer();
            
            var billLine = new BillLine
            {
                ItemLineNo = Fixture.Integer(),
                WipCode = Fixture.String(),
                WipTypeId = Fixture.String(),
                CategoryCode = Fixture.String(),
                NarrativeId = Fixture.Short(),
                StaffKey = Fixture.Integer(),
                CaseRef = Fixture.String()
            };

            var xmlSentToStoredProcedure = billLine.AsXml().ToString();

            var xml = new XElement("something");

            _billLines.GenerateMappedValuesXml(Arg.Any<int>(), Arg.Any<string>(),
                                               Arg.Any<int>(), Arg.Any<int>(), Arg.Any<int>(), Arg.Any<int?>(), Arg.Any<XElement>())
                      .Returns(xml);

            var subject = CreateSubject();
         
            var result = await subject.GetBillMappedXmlData(new BillPresentationController.BillMapXmlParameter
            {
                BillFormatId = billFormatId,
                EntityId = entityId,
                DebtorId = debtorId,
                CaseId = caseId,
                BillLines = new[] { billLine }
            });

            Assert.Equal(xml, result);

            _billLines.Received(1)
                      .GenerateMappedValuesXml(Arg.Any<int>(), Arg.Any<string>(),
                                               Arg.Any<int>(), Arg.Any<int>(), Arg.Any<int>(), Arg.Any<int?>(),
                                               Arg.Is<XElement>(_ => _.FirstNode.ToString() == xmlSentToStoredProcedure))
                      .IgnoreAwaitForNSubstituteAssertion();
        }
    }
}