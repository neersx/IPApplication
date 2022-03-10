using System;
using System.IdentityModel;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Accounting.Billing;
using Inprotech.Web.ContentManagement;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Core;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Billing
{
    public class OpenItemControllerFacts
    {
        public class OpenItemControllerFixture : IFixture<OpenItemController>
        {
            public OpenItemControllerFixture()
            {
                var securityContext = Substitute.For<ISecurityContext>();
                securityContext.User.Returns(new User());

                var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                preferredCultureResolver.Resolve().Returns("en");
                
                var requestContext = Substitute.For<IRequestContext>();
                requestContext.RequestId.Returns(Guid.NewGuid());

                var exportContentService = Substitute.For<IExportContentService>();
                exportContentService.GenerateContentId(Arg.Any<string>())
                                    .Returns(Fixture.Integer());

                Subject = new OpenItemController(securityContext, preferredCultureResolver, requestContext, exportContentService, OpenItemService);
            }

            public IOpenItemService OpenItemService { get; } = Substitute.For<IOpenItemService>();

            public OpenItemController Subject { get; }
        }

        public class PrepareNewDraftMethod
        {
            [Theory]
            [InlineData(ItemTypesForBilling.CreditNote)]
            [InlineData(ItemTypesForBilling.DebitNote)]
            [InlineData(ItemTypesForBilling.InternalCreditNote)]
            [InlineData(ItemTypesForBilling.InternalDebitNote)]
            public async Task ShouldDispatchOpenItemForNewDraftBill(ItemTypesForBilling itemType)
            {
                var expected = new OpenItemModel();

                var fixture = new OpenItemControllerFixture();

                fixture.OpenItemService.PrepareForNewDraftBill(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<ItemTypesForBilling>())
                       .Returns(expected);

                var r = await fixture.Subject.PrepareNewDraft(itemType);

                Assert.Equal(expected, r);

                fixture.OpenItemService.Received(1).PrepareForNewDraftBill(Arg.Any<int>(), Arg.Any<string>(), itemType)
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class GetOpenItemMethod
        {
            [Fact]
            public async Task ShouldDispatchOpenItemFromExistingBill()
            {
                var itemEntityId = Fixture.Integer();
                var openItemNo = Fixture.String();

                var expected = new OpenItemModel();

                var fixture = new OpenItemControllerFixture();

                fixture.OpenItemService.RetrieveForExistingBill(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<string>())
                       .Returns(expected);

                var r = await fixture.Subject.GetOpenItem(itemEntityId, openItemNo);

                Assert.Equal(expected, r);

                fixture.OpenItemService.Received(1).RetrieveForExistingBill(Arg.Any<int>(), Arg.Any<string>(), itemEntityId, openItemNo)
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldThrowArgumentExceptionIfOpenItemNoIsNotProvided()
            {
                var fixture = new OpenItemControllerFixture();

                await Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.GetOpenItem(Fixture.Integer(), null); });
            }
        }

        public class MergeDebitNoteDraftsMethod
        {
            [Fact]
            public async Task ShouldReturnMergedOpenItemFromProvidedOpenItemNumbers()
            {
                var openItemNo1 = Fixture.String();
                var openItemNo2 = Fixture.String();

                var expected = new OpenItemModel();

                var fixture = new OpenItemControllerFixture();

                fixture.OpenItemService.MergeSelectedDraftDebitNotes(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<string>())
                       .Returns(expected);

                var r = await fixture.Subject.MergeDebitNoteDrafts(openItemNo1 + "|" + openItemNo2);

                Assert.Equal(expected, r);

                fixture.OpenItemService.Received(1).MergeSelectedDraftDebitNotes(Arg.Any<int>(), Arg.Any<string>(), openItemNo1 + "|" + openItemNo2)
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldThrowArgumentExceptionIfProvidedOpenItemNumberForMergingHadInvalidOrMissingDelimiter()
            {
                var fixture = new OpenItemControllerFixture();

                fixture.OpenItemService.MergeSelectedDraftDebitNotes(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<string>())
                       .Returns(new OpenItemModel());

                var exception = await Assert.ThrowsAsync<ArgumentException>(async () => { await fixture.Subject.MergeDebitNoteDrafts(Fixture.String()); });

                Assert.Equal("There must be more than one Debit Notes to be merged.", exception.Message);
            }
        }

        public class ValidateItemDateMethod : FactBase
        {
            [Fact]
            public async Task ShouldPassValidDateForValidation()
            {
                var itemDate = Fixture.Today();
                var itemDateString = itemDate.ToString("yyyy-MM-dd");
                var returnValidationResult = new ValidationErrorCollection();
                var fixture = new OpenItemControllerFixture();

                fixture.OpenItemService.ValidateItemDate(itemDate)
                       .Returns(returnValidationResult);

                var r = await fixture.Subject.ValidateItemDate(itemDateString);

                Assert.Equal(returnValidationResult, r);
            }

            [Theory]
            [InlineData("as")]
            [InlineData("July 1")]
            [InlineData("11/11/2021")]
            [InlineData("2020/11/11")]
            public async Task ShouldThrowExceptionWhenDateIsProvidedInWrongFormat(string dateInIncorrectFormat)
            {
                var fixture = new OpenItemControllerFixture();

                await Assert.ThrowsAnyAsync<BadRequestException>(async () =>
                                                                     await fixture.Subject.ValidateItemDate(dateInIncorrectFormat));
            }
        }

        public class ValidateOpenItemNoUniqueMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnResultFromOpenItemsComponent()
            {
                var isUnique = Fixture.Boolean();
                var openItemNo = Fixture.String();

                var fixture = new OpenItemControllerFixture();
                fixture.OpenItemService.ValidateOpenItemNoIsUnique(openItemNo).Returns(isUnique);

                var r = await fixture.Subject.ValidateOpenItemNoUnique(openItemNo);

                Assert.Equal(isUnique, r);
            }
        }
    }
}