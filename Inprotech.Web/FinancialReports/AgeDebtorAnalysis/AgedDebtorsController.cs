using System;
using System.Linq;
using System.Web.Http;
using System.Xml.Linq;
using Inprotech.Infrastructure.Formatting;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.FinancialReports.AgeDebtorAnalysis
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ViewAgedDebtorsReport)]
    [RoutePrefix("api/reports/ageddebtors")]
    [UseXmlFormatter]
    public class AgedDebtorsController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IAgedDebtorsReportDataProvider _reportDataPovider;

        public AgedDebtorsController(IDbContext dbContext, IAgedDebtorsReportDataProvider reportDataPovider)
        {
            if (dbContext == null) throw new ArgumentNullException(nameof(dbContext));
            if (reportDataPovider == null) throw new ArgumentNullException(nameof(reportDataPovider));

            _dbContext = dbContext;
            _reportDataPovider = reportDataPovider;
        }

        [HttpGet]
        [NoEnrichment]
        [Route("report")]
        public XElement Report(int periodId, string entity, string debtor, string category)
        {
            if (string.IsNullOrEmpty(entity))
                throw Exceptions.BadRequest("Either an exact entity name or a wildcard must be provided.");

            if (string.IsNullOrEmpty(category))
                throw Exceptions.BadRequest("Either an exact category name or a wildcard must be provided.");

            if (string.IsNullOrEmpty(debtor))
                throw Exceptions.BadRequest("Either an exact debtor code or a debtor code wildcard must be provided.");

            var periodRange = _dbContext.Set<Period>().Where(p => p.Id == periodId);
            if (!periodRange.Any()) throw Exceptions.NotFound("No such period");
            
            return _reportDataPovider.Fetch(periodRange.Single(), entity, debtor, category);
        }

        [HttpGet]
        [NoEnrichment]
        [Route("availableperiods")]
        public XElement AvailablePeriods()
        {
            var element = new XElement("AvailablePeriods");
            var periods = _dbContext.Set<Period>().ToArray();
            foreach (var period in periods)
            {
                element.Add(
                    new XElement("Period",
                        new XElement("Id", period.Id),
                        new XElement("Label", period.Label)));
            }

            return element;
        }

        [HttpGet]
        [NoEnrichment]
        [Route("availableentities")]
        public XElement AvailableEntities()
        {
            var element = new XElement("AvailableEntities");
            var entities =
                _dbContext.Set<SpecialName>().Where(sn => sn.IsEntity.HasValue && sn.IsEntity.Value == 1).ToArray();
            foreach (var entity in entities)
            {
                element.Add(
                    new XElement("Entity",
                        new XElement("Id", entity.Id),
                        new XElement("Name", entity.EntityName.LastName)));
            }
            return element; 
        }

        [HttpGet]
        [NoEnrichment]
        [Route("availablecategories")]
        public XElement AvailableCategories()
        {
            var element = new XElement("AvailableCategories");
            var categories =
                _dbContext.Set<TableCode>()
                    .Where(tc => tc.TableTypeId == (short) ProtectedTableTypes.Category)
                    .ToArray();
            foreach (var category in categories)
            {
                element.Add(
                    new XElement("Category",
                        new XElement("Id", category.Id),
                        new XElement("Name", category.Name)));
            }
            return element;
        }
    }
}
