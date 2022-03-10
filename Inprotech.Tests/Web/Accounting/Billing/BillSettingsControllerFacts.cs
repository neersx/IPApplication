using System.IdentityModel;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Billing
{
    public class BillSettingsControllerFacts
    {
        public static BillSettingsController CreateSubject()
        {
            var securityContext = Substitute.For<ISecurityContext>();
            securityContext.User.Returns(new User());

            var billSettingsResolver = Substitute.For<IBillSettingsResolver>();
            billSettingsResolver.Resolve(Arg.Any<int>(), Arg.Any<int?>(), Arg.Any<string>(), Arg.Any<int?>())
                                .Returns(new BillSettings());

            var billingSiteSettingsResolver = Substitute.For<IBillingSiteSettingsResolver>();
            billingSiteSettingsResolver.Resolve(Arg.Any<BillingSiteSettingsScope>())
                                       .Returns(new BillingSiteSettings());

            var billingUserPermissionSettingsResolver = Substitute.For<IBillingUserPermissionSettingsResolver>();
            billingUserPermissionSettingsResolver.Resolve()
                                                 .Returns(new BillingUserPermissionsSettings());

            var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

            return new BillSettingsController(securityContext, billSettingsResolver, billingSiteSettingsResolver, billingUserPermissionSettingsResolver, preferredCultureResolver);
        }

        [Fact]
        public async Task ShouldResolveSiteSettingsIfScopeNotSpecified()
        {
            var subject = CreateSubject();

            var r = await subject.GetSettings(null);

            Assert.Null(r.User);
            Assert.NotNull(r.Site);
        }

        [Fact]
        public async Task ShouldResolveSiteSettingsIfScopeSpecified()
        {
            var subject = CreateSubject();

            var r = await subject.GetSettings("site");

            Assert.Null(r.User);
            Assert.NotNull(r.Site);
        }

        [Fact]
        public async Task ShouldResolveUserSettingsIfScopeSpecified()
        {
            var subject = CreateSubject();

            var r = await subject.GetSettings("user");

            Assert.NotNull(r.User);
            Assert.Null(r.Site);
        }
        
        [Theory]
        [InlineData(1, null, null, null)]
        [InlineData(1, 1, null, null)]
        [InlineData(1, 1, "a", null)]
        [InlineData(1, 1, "a", 1)]
        [InlineData(1, 1, null, 1)]
        [InlineData(1, null, null, 1)]
        public async Task ShouldResolveBillSettingsIfScopeSpecifiedAndDebtorIdIsProvided(int debtorId, int? caseId, string action, int? entityId)
        {
            var subject = CreateSubject();

            var r = await subject.GetSettings("bill", debtorId, caseId, entityId, action);

            Assert.Null(r.User);
            Assert.Null(r.Site);
            Assert.NotNull(r.Bill);
        }

        [Fact]
        public async Task ShouldResolveBothSettingsIfSpecified()
        {
            var subject = CreateSubject();

            var r = await subject.GetSettings("site,user");

            Assert.NotNull(r.User);
            Assert.NotNull(r.Site);
        }

        [Fact]
        public async Task ShouldResolveAllSettingsIfSpecified()
        {
            var subject = CreateSubject();

            var r = await subject.GetSettings("site,user,bill", debtorId: 1);

            Assert.NotNull(r.User);
            Assert.NotNull(r.Site);
            Assert.NotNull(r.Bill);
        }

        [Fact]
        public async Task ShouldThrowExceptionWhenBillScopeRequestedButDebtorIdNotProvided()
        {
            var subject = CreateSubject();

            await Assert.ThrowsAsync<BadRequestException>(async () => await subject.GetSettings("bill"));
        }
    }
}