using System.Collections.Generic;
using System.IdentityModel;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Accounting;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting.Wip;
using InprotechKaizen.Model.Components.Core;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Work
{
    public class WipAdjustmentsControllerFacts
    {
        public class WipAdjustmentsControllerFixture : IFixture<WipAdjustmentsController>
        {
            public WipAdjustmentsControllerFixture(InMemoryDbContext db, User user = null, Dictionary<string, bool> siteControls = null)
            {
                var securityContext = Substitute.For<ISecurityContext>();
                securityContext.User.Returns(user ?? new User(Fixture.String(), false).In(db));

                var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

                SiteControlReader = Substitute.For<ISiteControlReader>();
                SiteControlReader.ReadMany<bool>(Arg.Any<string[]>())
                                 .Returns(x =>
                                 {
                                     var r = ((string[])x[0]).ToDictionary(k => k, v => false);

                                     foreach (var sc in siteControls ?? new Dictionary<string, bool>()) r[sc.Key] = sc.Value;

                                     return r;
                                 });

                WipAdjustments = Substitute.For<IWipAdjustments>();

                Subject = new WipAdjustmentsController(db, SiteControlReader, securityContext, preferredCultureResolver, WipAdjustments);
            }

            public IWipAdjustments WipAdjustments { get; set; }

            public ISiteControlReader SiteControlReader { get; set; }

            public WipAdjustmentsController Subject { get; }
        }

        public class GetViewSupportMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnLocalCurrencyFromSiteControl()
            {
                var fixture = new WipAdjustmentsControllerFixture(Db);
                var currency = Fixture.String();

                fixture.SiteControlReader.Read<string>(SiteControls.CURRENCY).Returns(currency);

                var r = await fixture.Subject.GetViewSupportData();

                Assert.Equal(currency, r.LocalCurrency);
            }

            [Fact]
            public async Task ShouldReturnWriteDownLimitConfiguredAgainstTheUser()
            {
                var user = new User(Fixture.String(), false)
                {
                    WriteDownLimit = Fixture.Decimal()
                }.In(Db);

                var fixture = new WipAdjustmentsControllerFixture(Db, user);

                var r = await fixture.Subject.GetViewSupportData();

                Assert.Equal(user.WriteDownLimit, r.WriteDownLimit);
            }

            [Fact]
            public async Task ShouldReturnWipSplitMultiDebtorSetting()
            {
                var wipSplitMultiDebtorValue = Fixture.Boolean();

                var fixture = new WipAdjustmentsControllerFixture(Db,
                                                                  siteControls: new Dictionary<string, bool>
                                                                  {
                                                                      {SiteControls.WIPSplitMultiDebtor, wipSplitMultiDebtorValue}
                                                                  });

                var r = await fixture.Subject.GetViewSupportData();

                Assert.Equal(wipSplitMultiDebtorValue, r.SplitWipMultiDebtor);
            }

            [Fact]
            public async Task ShouldReturnWipWriteDownRestrictedSetting()
            {
                var wipWriteDownRestrictedValue = Fixture.Boolean();

                var fixture = new WipAdjustmentsControllerFixture(Db,
                                                                  siteControls: new Dictionary<string, bool>
                                                                  {
                                                                      {SiteControls.WIPWriteDownRestricted, wipWriteDownRestrictedValue}
                                                                  });

                var r = await fixture.Subject.GetViewSupportData();

                Assert.Equal(wipWriteDownRestrictedValue, r.WipWriteDownRestricted);
            }

            [Fact]
            public async Task ShouldReturnTransferSetting()
            {
                var transferAssociatedDiscountValue = Fixture.Boolean();

                var fixture = new WipAdjustmentsControllerFixture(Db,
                                                                  siteControls: new Dictionary<string, bool>
                                                                  {
                                                                      {SiteControls.TransferAssociatedDiscount, transferAssociatedDiscountValue}
                                                                  });

                var r = await fixture.Subject.GetViewSupportData();

                Assert.Equal(transferAssociatedDiscountValue, r.TransferAssociatedDiscount);
            }
        }

        public class CaseHasMultipleDebtorsFacts : FactBase
        {
            [Fact]
            public async Task ShouldReturnMultiDebtorSettingValueFromWipAdjustmentComponent()
            {
                var caseKey = Fixture.Integer();
                var caseHasMultipleDebtors = Fixture.Boolean();

                var fixture = new WipAdjustmentsControllerFixture(Db);

                fixture.WipAdjustments.CaseHasMultipleDebtors(caseKey)
                       .Returns(caseHasMultipleDebtors);

                var r = await fixture.Subject.CaseHasMultipleDebtors(caseKey);

                Assert.Equal(caseHasMultipleDebtors, r);
            }
        }

        public class GetDefaultWipInformationMethodFacts : FactBase
        {
            [Fact]
            public async Task ShouldReturnDefaultedWipInfoFromWipAdjustmentComponent()
            {
                var caseKey = Fixture.Integer();
                var wipCode = Fixture.String();
                var returnValue = new { };

                var fixture = new WipAdjustmentsControllerFixture(Db);
                fixture.WipAdjustments.GetWipDefaults(caseKey, wipCode)
                       .Returns(returnValue);

                var r = await fixture.Subject.GetDefaultWipInformation(caseKey, wipCode);

                Assert.Equal(returnValue, r);
            }
        }

        public class ValidateItemDateMethodFacts : FactBase
        {
            [Fact]
            public async Task ShouldPassValidDateForValidation()
            {
                var itemDate = Fixture.Today();
                var itemDateString = itemDate.ToString("yyyy-MM-dd");
                var returnValidationResult = new ValidationErrorCollection();
                var fixture = new WipAdjustmentsControllerFixture(Db);

                fixture.WipAdjustments.ValidateItemDate(itemDate)
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
                var fixture = new WipAdjustmentsControllerFixture(Db);

                await Assert.ThrowsAnyAsync<BadRequestException>(async () =>
                                                                     await fixture.Subject.ValidateItemDate(dateInIncorrectFormat));
            }
        }

        public class GetItemForAdjustmentMethodFacts : FactBase
        {
            [Fact]
            public async Task ShouldReturnRequestedWipItemSuitableForAdjustments()
            {
                var entityKey = Fixture.Integer();
                var transKey = Fixture.Integer();
                var wipSeqKey = Fixture.Integer();
                var user = new User(Fixture.String(), true).In(Db);
                var expectedReturn = new { };

                var fixture = new WipAdjustmentsControllerFixture(Db, user);

                fixture.WipAdjustments.GetItemToAdjust(user.Id, Arg.Any<string>(), entityKey, transKey, wipSeqKey)
                       .Returns(expectedReturn);

                var r = await fixture.Subject.ItemForAdjustment(entityKey, transKey, wipSeqKey);

                Assert.Equal(expectedReturn, r);
            }
        }

        public class GetStaffProfitCenterFacts : FactBase
        {
            [Fact]
            public async Task ShouldReturnStaffProfitCenterRecords()
            {
                var nameKey = Fixture.Integer();
                var user = new User(Fixture.String(), true).In(Db);
                var expectedReturn = new { code = Fixture.String(), description = Fixture.String() };

                var fixture = new WipAdjustmentsControllerFixture(Db, user);

                fixture.WipAdjustments.GetStaffProfitCenter(nameKey, Arg.Any<string>())
                       .Returns(expectedReturn);

                var r = await fixture.Subject.GetStaffProfitCenter(nameKey);

                Assert.Equal(expectedReturn, r);
            }
        }

        public class SaveItemForAdjustmentMethodFacts : FactBase
        {
            [Fact]
            public async Task ShouldDelegateAdjustmentsAndReturnResult()
            {
                var newTransKey = Fixture.Integer();
                var changeSetEntry = new ChangeSetEntry<AdjustWipItemDto>
                {
                    Entity = new AdjustWipItemDto()
                };
                var user = new User(Fixture.String(), true).In(Db);

                var fixture = new WipAdjustmentsControllerFixture(Db, user);

                fixture.WipAdjustments
                       .When(_ => _.AdjustItems(user.Id,
                                                Arg.Any<string>(),
                                                Arg.Any<ChangeSetEntry<AdjustWipItemDto>[]>()))
                       .Do(x =>
                       {
                           var item = (ChangeSetEntry<AdjustWipItemDto>[])x[2];

                           item.Single().Entity.NewTransKey = newTransKey;
                       });

                var r = await fixture.Subject.ItemForAdjustment(changeSetEntry);

                Assert.Equal(newTransKey, r.Entity.NewTransKey);
            }

            [Fact]
            public async Task ShouldReturnValidationErrors()
            {
                var validationErrors = new List<ValidationResultInfo>();
                var changeSetEntry = new ChangeSetEntry<AdjustWipItemDto>();
                var user = new User(Fixture.String(), true).In(Db);

                var fixture = new WipAdjustmentsControllerFixture(Db, user);

                fixture.WipAdjustments
                       .When(_ => _.AdjustItems(user.Id, Arg.Any<string>(), Arg.Any<ChangeSetEntry<AdjustWipItemDto>[]>()))
                       .Do(x =>
                       {
                           var item = (ChangeSetEntry<AdjustWipItemDto>[])x[2];

                           item.Single().ValidationErrors = validationErrors;
                       });

                var r = await fixture.Subject.ItemForAdjustment(changeSetEntry);

                Assert.Equal(validationErrors, r.ValidationErrors);
            }
        }

        public class GetItemToSplitMethodFacts : FactBase
        {
            [Fact]
            public async Task ShouldReturnRequestedWipItemSuitableForSplitting()
            {
                var entityKey = Fixture.Integer();
                var transKey = Fixture.Integer();
                var wipSeqKey = Fixture.Integer();
                var user = new User(Fixture.String(), true).In(Db);
                var expectedReturn = new { };

                var fixture = new WipAdjustmentsControllerFixture(Db, user);

                fixture.WipAdjustments.GetItemToSplit(user.Id, Arg.Any<string>(), entityKey, transKey, wipSeqKey)
                       .Returns(expectedReturn);

                var r = await fixture.Subject.ItemToSplit(entityKey, transKey, wipSeqKey);

                Assert.Equal(expectedReturn, r);
            }
        }

        public class SaveItemToSplitMethodFacts : FactBase
        {
            [Fact]
            public async Task ShouldDelegateSplittingAndReturnResult()
            {
                var newTransKey = Fixture.Integer();
                var changeSetEntries = new[]
                {
                    new ChangeSetEntry<SplitWipItem>
                    {
                        Entity = new SplitWipItem()
                    }
                };
                var user = new User(Fixture.String(), true).In(Db);

                var fixture = new WipAdjustmentsControllerFixture(Db, user);

                fixture.WipAdjustments
                       .When(_ => _.SplitItems(user.Id, Arg.Any<string>(), Arg.Any<ChangeSetEntry<SplitWipItem>[]>()))
                       .Do(x =>
                       {
                           var item = (ChangeSetEntry<SplitWipItem>[])x[2];

                           item.Single().Entity.NewTransKey = newTransKey;
                       });

                var r = await fixture.Subject.ItemToSplit(changeSetEntries);

                Assert.Equal(newTransKey, r.Single().Entity.NewTransKey);
            }

            [Fact]
            public async Task ShouldReturnValidationErrors()
            {
                var validationErrors = new List<ValidationResultInfo>();
                var changeSetEntries = new[] { new ChangeSetEntry<SplitWipItem>() };
                var user = new User(Fixture.String(), true).In(Db);

                var fixture = new WipAdjustmentsControllerFixture(Db, user);

                fixture.WipAdjustments
                       .When(_ => _.SplitItems(user.Id, Arg.Any<string>(), Arg.Any<ChangeSetEntry<SplitWipItem>[]>()))
                       .Do(x =>
                       {
                           var item = (ChangeSetEntry<SplitWipItem>[])x[2];

                           item.Single().ValidationErrors = validationErrors;
                       });

                var r = await fixture.Subject.ItemToSplit(changeSetEntries);

                Assert.Equal(validationErrors, r.Single().ValidationErrors);
            }
        }
    }
}