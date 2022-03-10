using System;
using System.Linq;
using System.Web.Http;
using System.Xml.Linq;
using Inprotech.Infrastructure.Formatting;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.FinancialReports.RevenueAnalysis
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ViewRevenueAnalysisReport)]
    [UseXmlFormatter]
    [RoutePrefix("api/reports/revenueanalysis")]
    public class RevenueAnalysisController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IRevenueAnalysisReportDataProvider _reportDataPovider;

        public RevenueAnalysisController(IDbContext dbContext, IRevenueAnalysisReportDataProvider reportDataPovider)
        {
            if(dbContext == null) throw new ArgumentNullException(nameof(dbContext));
            if(reportDataPovider == null) throw new ArgumentNullException(nameof(reportDataPovider));

            _dbContext = dbContext;
            _reportDataPovider = reportDataPovider;
        }

        [HttpGet]
        [NoEnrichment]
        [Route("report")]
        public XElement Report(int fromPeriodId, int toPeriodId, string debtorCodeFilter)
        {
            if (string.IsNullOrEmpty(debtorCodeFilter))
                throw Exceptions.BadRequest("Either an exact debtor code or a debtor code wildcard must be provided.");

            var periodRange = _dbContext.Set<Period>().Where(p => p.Id == fromPeriodId || p.Id == toPeriodId);
            Period fromPeriod;
            Period toPeriod;

            if(!periodRange.Any()) throw Exceptions.NotFound("No such period");
            if(periodRange.Count() != 1)
            {
                fromPeriod = periodRange.Single(p => p.Id == fromPeriodId);
                toPeriod = periodRange.Single(p => p.Id == toPeriodId);

                if(fromPeriod.StartDate > toPeriod.StartDate)
                    throw Exceptions.BadRequest("From period must be less than To period");
            }
            else
            {
                fromPeriod = periodRange.Single();
                toPeriod = periodRange.Single();
            }
            
            return _reportDataPovider.Fetch(fromPeriod, toPeriod, debtorCodeFilter);
        }

        [HttpGet]
        [NoEnrichment]
        [Route("availableperiods")]
        public XElement AvailablePeriods()
        {
            var element = new XElement("AvailablePeriods");
            var periods = _dbContext.Set<Period>().ToArray();
            foreach(var period in periods)
            {
                element.Add(
                            new XElement(
                                "Period",
                                new XElement("Id", period.Id),
                                new XElement("Label", period.Label)));
            }
            return element;
        }
    }
}