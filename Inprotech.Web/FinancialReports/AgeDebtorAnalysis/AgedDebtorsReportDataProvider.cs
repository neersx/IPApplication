using System;
using System.Data;
using System.IO;
using System.Reflection;
using System.Xml.Linq;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.FinancialReports.AgeDebtorAnalysis
{
    public interface IAgedDebtorsReportDataProvider
    {
        XElement Fetch(Period period, string entityId, string debtorName, string categoryId);
    }

    public class AgedDebtorsReportDataProvider : IAgedDebtorsReportDataProvider
    {
            const string ScriptName = "AgedDebtorsReportDataScript.sql";
            readonly IDbContext _dbContext;
            readonly ISecurityContext _securityContext;

            public AgedDebtorsReportDataProvider(IDbContext dbContext, ISecurityContext securityContext)
            {
                _dbContext = dbContext;
                _securityContext = securityContext;
            }

            public XElement Fetch(Period period, string entityId, string debtorName, string categoryId)
            {
                var script = ExtractSqlCommand(ScriptName);
                if (string.IsNullOrWhiteSpace(script))
                    throw new ApplicationException("Unable to extract age debtor analysis report command script");

                var command = _dbContext.CreateSqlCommand(script);
                command.Parameters.AddWithValue("@pnPERIOD", period.Label);
                command.Parameters.AddWithValue("@pnEntityName", entityId);
                command.Parameters.AddWithValue("@psDebtorName", debtorName);
                command.Parameters.AddWithValue("@pnCategory", categoryId);
                command.Parameters.AddWithValue("@pnUserIdentityId", _securityContext.User.Id);

                using (var reader = command.ExecuteReader())
                {
                    var dataTable = new DataTable("AgedDebtors");
                    dataTable.Load(reader);
                    return dataTable.XmlDataForExcel("AgedDebtorsReport");
                }
            }

            string ExtractSqlCommand(string scriptName)
            {
                string contents;
                var scriptResource = string.Format("{0}.{1}", GetType().Namespace, scriptName);
                var resolvedAssembly = Assembly.GetAssembly(GetType());

                var stream = resolvedAssembly.GetManifestResourceStream(scriptResource);
                if (stream == null)
                    throw new InvalidOperationException("Specified report is not available.");

                using (var streamReader = new StreamReader(stream))
                    contents = streamReader.ReadToEnd();
                return contents;
            }
        }
}

