using System;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Reports;
using InprotechKaizen.Model.Components.Reporting;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Reports
{
    public class BillingWorksheetManagerFacts
    {
        [Fact]
        public async Task ShouldReturnReportModelPrepareBillingWorksheetRequest()
        {
            var f = new BillingWorksheetsManagerFixture();
            var xmlFilterCriteria = @"<Search><Filtering><wp_ListWorkInProgress><FilterCriteria><EntityKey Operator='0'>-283575757</EntityKey><BelongsTo><StaffKey Operator='0' IsCurrentUser='1' /><ActingAs><IsWipStaff>0</IsWipStaff><AssociatedName>1</AssociatedName></ActingAs></BelongsTo><Debtor IsRenewalDebtor='1' /><ResponsibleName><NameKey>42</NameKey><IsInstructor>1</IsInstructor><IsDebtor>1</IsDebtor></ResponsibleName><WipStatus><IsActive>1</IsActive><IsLocked>1</IsLocked></WipStatus><RenewalWip><IsRenewal>1</IsRenewal><IsNonRenewal>1</IsNonRenewal></RenewalWip></FilterCriteria><AggregateFilterCriteria /></wp_ListWorkInProgress></Filtering></Search>";
            var user = new User("john", false);
            var formattingData = new XElement("blah");
            var criteria = new BillingWorksheetCriteria
            {
                ConnectionId = Fixture.String(),
                ReportName = "billingWorksheet",
                Items = new[]
                {
                    new BillingWorksheetItem {CaseKey = 113, EntityKey = -283575757},
                    new BillingWorksheetItem {CaseKey = 114, EntityKey = -283575757}
                },
                ReportExportFormat = ReportExportFormat.Excel,
                XmlFilterCriteria = xmlFilterCriteria
            };
            f.TempStorageHandler.Add(Arg.Any<string>()).Returns(10);
            
            f.SecurityContext.User.Returns(user);
            f.PreferredCultureResolver.Resolve().Returns("en-us");
            f.FormattingDataResolver.Resolve(user.Id, "en-us").Returns(formattingData);
            
            var results = await f.Subject.CreateReportRequest(JObject.FromObject(criteria), Fixture.Integer());

            Assert.Equal("en-us", results.UserCulture);
            Assert.Equal("billing/standard/" + criteria.ReportName, results.ReportDefinitions.Single().ReportPath);
            Assert.Equal(5, results.ReportDefinitions.Single().Parameters.Count);
            Assert.Equal(ReportExportFormat.Excel, results.ReportDefinitions.Single().ReportExportFormat);
            Assert.Equal(user.Id, results.UserIdentityKey);
            Assert.Equal(user.Id.ToString(), results.ReportDefinitions.Single().Parameters["UserIdentity"]);
            Assert.Equal(results.UserCulture, results.ReportDefinitions.Single().Parameters["Culture"]);
            Assert.Equal("10", results.ReportDefinitions.Single().Parameters["TempStorageId"]);
            Assert.Equal("<WorkInProgress><FilterCriteria /></wp_ListWorkInProgress>", results.ReportDefinitions.Single().Parameters["XMLFilterCriteria"]);
            Assert.Equal(formattingData.ToString(), results.ReportDefinitions.Single().Parameters["FormattingData"]);
        }

        [Fact]
        public async Task ShouldThrowExceptionPrepareBillingWorksheetRequest()
        {
            var f = new BillingWorksheetsManagerFixture();
            await Assert.ThrowsAsync<ArgumentNullException>(async () => { await f.Subject.CreateReportRequest(null, Fixture.Integer()); });
        }
    }

    public class BillingWorksheetsManagerFixture : IFixture<BillingWorksheetManager>
    {
        public BillingWorksheetsManagerFixture()
        {
            Subject = new BillingWorksheetManager(SecurityContext, PreferredCultureResolver, TempStorageHandler, RequestContext, FormattingDataResolver);
        }

        public IRequestContext RequestContext { get; } = Substitute.For<IRequestContext>();
        public ISecurityContext SecurityContext { get; } = Substitute.For<ISecurityContext>();
        public IPreferredCultureResolver PreferredCultureResolver { get; } = Substitute.For<IPreferredCultureResolver>();
        public ITempStorageHandler TempStorageHandler { get; } = Substitute.For<ITempStorageHandler>();
        public IStandardReportFormattingDataResolver FormattingDataResolver { get; } = Substitute.For<IStandardReportFormattingDataResolver>();
        public BillingWorksheetManager Subject { get; }
    }
}