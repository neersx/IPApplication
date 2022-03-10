using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Reporting;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Utilities;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Reports
{
    public class BillingWorksheetManager : IReportsManager
    {
        readonly IPreferredCultureResolver _preferredCulture;
        readonly ISecurityContext _securityContext;
        readonly ITempStorageHandler _tempStorageHandler;
        readonly IRequestContext _requestContext;
        readonly IStandardReportFormattingDataResolver _formattingData;

        public BillingWorksheetManager(ISecurityContext securityContext, IPreferredCultureResolver preferredCulture, 
                                       ITempStorageHandler tempStorageHandler,
                                       IRequestContext requestContext,
                                       IStandardReportFormattingDataResolver formattingData)
        {
            _securityContext = securityContext;
            _preferredCulture = preferredCulture;
            _tempStorageHandler = tempStorageHandler;
            _requestContext = requestContext;
            _formattingData = formattingData;
        }
        
        public async Task<ReportRequest> CreateReportRequest(JObject criteria, int contentId)
        {
            if (criteria == null) throw new ArgumentNullException(nameof(criteria));

            var billingWorksheetCriteria = criteria.ToObject<BillingWorksheetCriteria>();
            var reportCriteria = FormatCriteria(billingWorksheetCriteria);
            var tempStorageId = await _tempStorageHandler.Add(reportCriteria);
            var userIdentity = _securityContext.User.Id;
            var culture = _preferredCulture.Resolve();
            var formattingData = await _formattingData.Resolve(userIdentity, culture);

            var billingWorksheet = new ReportRequest(new ReportDefinition
            {
                ReportPath = "billing/standard/" + billingWorksheetCriteria.ReportName,
                ReportExportFormat = billingWorksheetCriteria.ReportExportFormat,
                Parameters = new Dictionary<string, string>
                {
                    {"UserIdentity", userIdentity.ToString()},
                    {"Culture", culture},
                    {"FormattingData", formattingData.ToString()},
                    {"XMLFilterCriteria", "<WorkInProgress><FilterCriteria /></wp_ListWorkInProgress>"},
                    {"TempStorageId", tempStorageId.ToString() }
                }
            })
            {
                ContentId = contentId,
                UserIdentityKey = userIdentity,
                UserCulture = culture,
                RequestContextId = _requestContext.RequestId
            };

            return billingWorksheet;
        }

        static string FormatCriteria(BillingWorksheetCriteria criteria)
        {
            if (criteria == null) throw new ArgumentNullException(nameof(criteria));

            if (string.IsNullOrEmpty(criteria.XmlFilterCriteria))
            {
                throw new ArgumentException("XmlFilterCriteria is null or empty");
            }

            var xSearchCriteria = new XElement("Search",
                                               new XElement("Filtering",
                                                            XElement.Parse(criteria.XmlFilterCriteria)
                                                           ));

            var filterRoot = xSearchCriteria.Descendants("FilterCriteria").First();

            var billableWipGroup = filterRoot.Element("BillableWipGroup");
            if (billableWipGroup == null)
            {
                filterRoot.Add(billableWipGroup = new XElement("BillableWipGroup"));
            }

            billableWipGroup.SetAttributeValue("Operator", 0);
            billableWipGroup.Add(
                                 criteria.Items.Select(wip =>
                                                           new XElement("BillableWip", ToBillableWip(wip))
                                                      )
                                );

            return xSearchCriteria.ToString(SaveOptions.DisableFormatting);
        }

        static IEnumerable<XElement> ToBillableWip(BillingWorksheetItem wip)
        {
            if (wip.EntityKey.HasValue) yield return new XElement("EntityKey", wip.EntityKey);
            if (wip.WipNameKey.HasValue) yield return new XElement("NameKey", wip.WipNameKey);
            if (wip.CaseKey.HasValue) yield return new XElement("CaseKey", wip.CaseKey);
        }
    }
}