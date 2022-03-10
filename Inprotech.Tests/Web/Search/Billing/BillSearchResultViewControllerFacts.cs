using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Search.Billing;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Billing
{

    public class BillSearchResultViewControllerFacts : FactBase
    {
        [Fact]
        public async Task ShouldThrowForbiddenExceptionIfWebPartSecurityNotProvided()
        {
            var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                            async () =>
                                                                            {
                                                                                var fixture = new BillSearchResultViewControllerFixture(Db);
                                                                                fixture.WebPartSecurity.HasAccessToWebPart(ApplicationWebPart.BillSearch).Returns(false);

                                                                                await fixture.Subject.Get(null, QueryContext.BillingSelection);
                                                                            });

            Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
        }

        [Fact]
        public async Task GetViewData()
        {
            var id = Fixture.Integer();

            var f = new BillSearchResultViewControllerFixture(Db);
            f.BillingUserPermissionSettingsResolver.Resolve().Returns(new BillingUserPermissionsSettings() { CanCreditBill = true, CanDeleteCreditNote = true, CanFinaliseBill = true, CanReverseBill = BillReversalTypeAllowed.CurrentPeriodReversalAllowed });
            var results = await f.Subject.Get(id, QueryContext.BillingSelection);
            Assert.NotNull(results);
            Assert.Null(results.QueryName);
            Assert.NotNull(results.Permissions);
            Assert.Equal((int)QueryContext.BillingSelection, results.QueryContext);
        }
    }

    public class BillSearchResultViewControllerFixture : IFixture<BillSearchResultViewController>
    {
        public BillSearchResultViewControllerFixture(InMemoryDbContext db)
        {
            WebPartSecurity = Substitute.For<IWebPartSecurity>();
            BillingUserPermissionSettingsResolver = Substitute.For<IBillingUserPermissionSettingsResolver>();
            WebPartSecurity.HasAccessToWebPart(ApplicationWebPart.BillSearch).Returns(true);
            Subject = new BillSearchResultViewController(db, WebPartSecurity, BillingUserPermissionSettingsResolver);
        }

        public IWebPartSecurity WebPartSecurity { get; set; }
        public IBillingUserPermissionSettingsResolver BillingUserPermissionSettingsResolver { get; set; }
        public BillSearchResultViewController Subject { get; }
    }
}