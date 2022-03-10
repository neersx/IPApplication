using System;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.Notifications;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using InprotechKaizen.Model.Components.Cases.Comparison.CpaXml;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;

namespace Inprotech.Web.CaseComparison
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.ViewCaseDataComparison)]
    public class CompareGoodsServicesController : ApiController
    {
        const string InnographySystemCode = "IpOneData";
        readonly ICpaXmlProvider _cpaXmlProvider;
        readonly IClassStringComparer _classStringComparer;
        readonly ICpaXmlComparison _cpaXmlComparison;

        public CompareGoodsServicesController(ICpaXmlProvider cpaXmlProvider,
                                              ICpaXmlComparison cpaXmlComparison,
                                              IClassStringComparer classStringComparer)
        {
            _cpaXmlProvider = cpaXmlProvider;
            _classStringComparer = classStringComparer;
            _cpaXmlComparison = cpaXmlComparison;
        }

        [HttpGet]
        [Route("api/casecomparison/imported-goods-services-text/n/{notificationId}/class/{classKey}/language/{languageCode?}")]
        public async Task<string> ImportedGoodsServicesText(int notificationId, string classKey, string languageCode = null)
        {
            if (string.IsNullOrEmpty(classKey)) throw new ArgumentNullException(nameof(classKey));

            var cpaXml = await _cpaXmlProvider.For(notificationId);

            var comparisonScenarios = _cpaXmlComparison.FindComparisonScenarios(cpaXml, InnographySystemCode).ToArray();

            var scenarios = comparisonScenarios.OfType<ComparisonScenario<InprotechKaizen.Model.Components.Cases.Comparison.Models.GoodsServices>>().ToArray();

            var importedGoodsServices = scenarios.Select(_ => _.Mapped).ToList();

            return importedGoodsServices.FirstOrDefault(a =>
                                                      _classStringComparer.Equals(a.Class, classKey) && a.LanguageCode == languageCode)?.Text;
        }
    }
}