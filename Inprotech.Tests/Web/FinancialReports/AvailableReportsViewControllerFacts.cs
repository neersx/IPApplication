using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Reports;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.FinancialReports;
using Inprotech.Web.FinancialReports.Models;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.FinancialReports
{
    public class AvailableReportsViewControllerFacts : FactBase
    {
        readonly ITaskSecurityProvider _taskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
        readonly IPreferredCultureResolver _preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

        [Fact]
        public void ReturnsAuthorisedReportOnly()
        {
            var category = new TableCodeBuilder {TableType = 98}.Build().In(Db);
            var feature = new FeatureBuilder
                {
                    Category = category
                }.Build()
                 .In(Db);

            var allowedTask = new SecurityTaskBuilder().Build().In(Db);
            var disallowedTask = new SecurityTaskBuilder().Build().In(Db);

            allowedTask.ProvidedByFeatures.Add(feature);
            disallowedTask.ProvidedByFeatures.Add(feature);

            feature.SecurityTasks.Add(allowedTask);
            feature.SecurityTasks.Add(disallowedTask);

            var allowedReport = new ExternalReportBuilder
                {
                    SecurityTask = allowedTask
                }.Build()
                 .In(Db);

            var unauthorisedReport = new ExternalReportBuilder
                {
                    SecurityTask = disallowedTask
                }.Build()
                 .In(Db);

            _taskSecurityProvider.ListAvailableTasks()
                                 .Returns(new[]
                                 {
                                     new ValidSecurityTaskBuilder
                                     {
                                         TaskId = allowedTask.Id,
                                         CanExecute = true
                                     }.Build()
                                 });

            var r = (AvailableReportCategoryModel[]) new AvailableReportsViewController(Db, _taskSecurityProvider, _preferredCultureResolver).Get();

            Assert.Single(r);
            Assert.Contains(r.Single().Reports, _ => _.Id == allowedReport.Id);
            Assert.DoesNotContain(r.Single().Reports, _ => _.Id == unauthorisedReport.Id);
        }

        [Fact]
        public void ThrowsForbiddenWhenNoReportsAvailable()
        {
            var exception = Assert.Throws<HttpResponseException>(() => new AvailableReportsViewController(Db, _taskSecurityProvider, _preferredCultureResolver).Get());

            Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
        }
    }
}