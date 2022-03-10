using System.Collections.Generic;
using System.IdentityModel;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Wip;
using InprotechKaizen.Model.Components.Core;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Work
{
    public class WipDisbursementsControllerFacts
    {
        public class WipDisbursementsControllerFixture : IFixture<WipDisbursementsController>
        {
            public WipDisbursementsControllerFixture(InMemoryDbContext db, Dictionary<string, bool> siteControls = null)
            {
                var securityContext = Substitute.For<ISecurityContext>();

                CurrentUser = new UserBuilder(db).Build();
                securityContext.User.Returns(CurrentUser);

                var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

                BestNarrativeResolver = Substitute.For<IBestTranslatedNarrativeResolver>();
                SiteControlReader = Substitute.For<ISiteControlReader>();
                SiteControlReader.ReadMany<bool>(Arg.Any<string[]>())
                                 .Returns(x =>
                                 {
                                     var r = ((string[]) x[0]).ToDictionary(k => k, _ => false);

                                     foreach (var sc in siteControls ?? new Dictionary<string, bool>()) r[sc.Key] = sc.Value;

                                     return r;
                                 });

                Entities = Substitute.For<IEntities>();

                WipDisbursements = Substitute.For<IWipDisbursements>();

                Subject = new WipDisbursementsController(securityContext, preferredCultureResolver, Entities, WipDisbursements, SiteControlReader, BestNarrativeResolver);
            }

            public IEntities Entities { get; set; }
            public User CurrentUser { get; set; }
            public int CurrentStaffId => CurrentUser.NameId;
            public IWipDisbursements WipDisbursements { get; set; }
            public ISiteControlReader SiteControlReader { get; set; }
            public IBestTranslatedNarrativeResolver BestNarrativeResolver { get; set; }
            public WipDisbursementsController Subject { get; }
        }

        public class GetViewSupportMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnStaffManualEntryForWipFromSiteControl()
            {
                var staffManualEntryForWipValue = Fixture.Integer();

                var fixture = new WipDisbursementsControllerFixture(Db);

                fixture.SiteControlReader.Read<int?>(SiteControls.StaffManualEntryForWip).Returns(staffManualEntryForWipValue);

                var r = await fixture.Subject.GetViewSupportData();

                Assert.Equal(staffManualEntryForWipValue, r.StaffManualEntryforWIP);
            }

            [Fact]
            public async Task ShouldReturnBillRenewalDebtorFromSiteControl()
            {
                var billRenewalDebtorValue = Fixture.Boolean();

                var fixture = new WipDisbursementsControllerFixture(Db,
                                                                    siteControls: new Dictionary<string, bool>
                                                                    {
                                                                        {SiteControls.BillRenewalDebtor, billRenewalDebtorValue}
                                                                    });

                var r = await fixture.Subject.GetViewSupportData();

                Assert.Equal(billRenewalDebtorValue, r.BillRenewalDebtor);
            }

            [Fact]
            public async Task ShouldReturnAccountsPayableProtocolNumberFromSiteControl()
            {
                var aPProtocolNumberValue = Fixture.Boolean();

                var fixture = new WipDisbursementsControllerFixture(Db,
                                                                    siteControls: new Dictionary<string, bool>
                                                                    {
                                                                        {SiteControls.APProtocolNumber, aPProtocolNumberValue}
                                                                    });

                var r = await fixture.Subject.GetViewSupportData();

                Assert.Equal(aPProtocolNumberValue, r.ProtocolEnabled);
            }
        }

        public class CaseHasMultipleDebtorsFacts : FactBase
        {
            [Fact]
            public async Task ShouldReturnMultiDebtorSettingValueFromWipDisbursementsComponent()
            {
                var caseKey = Fixture.Integer();
                var activityKey = Fixture.String();
                var caseHasMultipleDebtors = Fixture.Boolean();
                var isRenewalWip = Fixture.Boolean();

                var fixture = new WipDisbursementsControllerFixture(Db);

                fixture.WipDisbursements.GetCaseActivityMultiDebtorStatus(caseKey, activityKey)
                       .Returns((caseHasMultipleDebtors, isRenewalWip));

                var r = await fixture.Subject.CaseActivityMultipleDebtorStatus(caseKey, activityKey);

                Assert.Equal(caseHasMultipleDebtors, r.IsMultiDebtorWip);
                Assert.Equal(isRenewalWip, r.IsRenewalWip);
            }
        }

        public class GetDefaultWipInformationMethodFacts : FactBase
        {
            [Fact]
            public async Task ShouldReturnDefaultedWipInfoFromWipDisbursementsComponent()
            {
                var caseKey = Fixture.Integer();
                var returnValue = new { };

                var fixture = new WipDisbursementsControllerFixture(Db);
                fixture.WipDisbursements.GetWipDefaults(caseKey)
                       .Returns(returnValue);

                var r = await fixture.Subject.GetWipDefaults(caseKey);

                Assert.Equal(returnValue, r);
            }
        }

        public class GetWipCostMethodFacts : FactBase
        {
            [Fact]
            public async Task ShouldReturnWipCostFromWipDisbursementsComponent()
            {
                var input = new WipCost();
                var returnValue = new WipCost();

                var fixture = new WipDisbursementsControllerFixture(Db);
                fixture.WipDisbursements.GetWipCost(input)
                       .Returns(returnValue);

                var r = await fixture.Subject.GetWipCost(input);

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
                var fixture = new WipDisbursementsControllerFixture(Db);

                fixture.WipDisbursements.ValidateItemDate(itemDate)
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
                var fixture = new WipDisbursementsControllerFixture(Db);

                await Assert.ThrowsAnyAsync<BadRequestException>(async () =>
                                                                     await fixture.Subject.ValidateItemDate(dateInIncorrectFormat));
            }
        }

        public class GetProtocolDisbursementsMethodFacts : FactBase
        {
            [Fact]
            public async Task ShouldReturnProtocolDisbursementsFromWipDisbursementsComponent()
            {
                var transKey = Fixture.Integer();
                var protocolKey = Fixture.String();
                var protocolDateString = Fixture.String();
                var returnValue = new Disbursement();

                var fixture = new WipDisbursementsControllerFixture(Db);
                fixture.WipDisbursements.Retrieve(Arg.Any<int>(), Arg.Any<string>(), transKey, protocolKey, protocolDateString)
                       .Returns(returnValue);

                var r = await fixture.Subject.ProtocolDisbursements(transKey, protocolKey, protocolDateString);

                Assert.Equal(returnValue, r);
            }
        }

        public class SaveMethodFacts : FactBase
        {
            [Fact]
            public async Task ShouldSaveUsingWipDisbursementsComponent()
            {
                var input = new Disbursement();

                var fixture = new WipDisbursementsControllerFixture(Db);
                fixture.WipDisbursements.Save(Arg.Any<int>(), Arg.Any<string>(), input)
                       .Returns(true);

                var r = await fixture.Subject.Save(input);

                Assert.True(r);
            }
        }

        public class GetSplitWipMethodFacts : FactBase
        {
            [Fact]
            public async Task ShouldReturnWipsSplitFromWipDisbursementsComponent()
            {
                var input = new WipCost();
                var returnValue = new DisbursementWip[0];

                var fixture = new WipDisbursementsControllerFixture(Db);
                fixture.WipDisbursements.GetSplitWipByDebtor(input)
                       .Returns(returnValue);

                var r = await fixture.Subject.GetSplitWip(input);

                Assert.Equal(returnValue, r);
            }
        }

        public class GetDefaultNarrativeFacts : FactBase
        {
            [Fact]
            public async Task ShouldGetDefaultForActivity()
            {
                var activityKey = Fixture.RandomString(6);
                var f = new WipDisbursementsControllerFixture(Db);
                f.BestNarrativeResolver.Resolve(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<int>()).Returns(new BestNarrative {Key = 123});
                var result = await f.Subject.DefaultNarrative(activityKey);
                await f.BestNarrativeResolver.Received(1).Resolve(Arg.Any<string>(), activityKey, f.CurrentStaffId);
                Assert.Equal(123, result.Key);
            }

            [Fact]
            public async Task ShouldGetDefaultForActivityAndStaff()
            {
                var activityKey = Fixture.RandomString(6);
                var staffNameId = Fixture.Integer();
                var f = new WipDisbursementsControllerFixture(Db);
                f.BestNarrativeResolver.Resolve(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<int>()).Returns(new BestNarrative {Key = 789});
                var result = await f.Subject.DefaultNarrative(activityKey, staffNameId: staffNameId);
                await f.BestNarrativeResolver.Received(1).Resolve(Arg.Any<string>(), activityKey, staffNameId);
                Assert.Equal(789, result.Key);
            }
            
            [Fact]
            public async Task ShouldGetDefaultForActivityAndCase()
            {
                var activityKey = Fixture.RandomString(6);
                var caseKey = Fixture.Integer();
                var f = new WipDisbursementsControllerFixture(Db);
                await f.Subject.DefaultNarrative(activityKey, caseKey);
                await f.BestNarrativeResolver.Received(1).Resolve(Arg.Any<string>(), activityKey, f.CurrentStaffId, caseKey);
            }

            [Fact]
            public async Task ShouldGetsDefaultForActivityAndDebtorIfNoCaseSpecified()
            {
                var activityKey = Fixture.RandomString(6);
                var debtorKey = Fixture.Integer();
                var f = new WipDisbursementsControllerFixture(Db);
                await f.Subject.DefaultNarrative(activityKey, caseKey: null, debtorKey);
                await f.BestNarrativeResolver.Received(1).Resolve(Arg.Any<string>(), activityKey, f.CurrentStaffId, null, debtorKey);
            }
        }
    }
}