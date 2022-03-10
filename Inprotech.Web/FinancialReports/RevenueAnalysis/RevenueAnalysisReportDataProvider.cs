using System;
using System.Data;
using System.IO;
using System.Reflection;
using System.Xml.Linq;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.FinancialReports.RevenueAnalysis
{
    public interface IRevenueAnalysisReportDataProvider
    {
        XElement Fetch(Period fromPeriod, Period toPeriod, string debtorCodeFilter);
    }

    public class RevenueAnalysisReportDataProvider : IRevenueAnalysisReportDataProvider
    {
        const string ScriptName = "RevenueAnalysisReportDataScript.sql";
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;

        public RevenueAnalysisReportDataProvider(IDbContext dbContext, ISecurityContext securityContext)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
        }

        public XElement Fetch(Period fromPeriod, Period toPeriod, string debtorCodeFilter)
        {
            var script = ExtractSqlCommand(ScriptName);
            if(string.IsNullOrWhiteSpace(script))
                throw new ApplicationException("Unable to extract revenue analysis report command script");

            var command = _dbContext.CreateSqlCommand(script);
            command.Parameters.AddWithValue("@pnFromPeriod", fromPeriod.Label);
            command.Parameters.AddWithValue("@pnToPeriod", toPeriod.Label);
            command.Parameters.AddWithValue("@psDebtorCode", debtorCodeFilter);
            command.Parameters.AddWithValue("@pnUserIdentityId", _securityContext.User.Id);
            command.CommandTimeout = 0;
            using (var reader = command.ExecuteReader())
            {
                var dataTable = new DataTable("RevenueAnalysis");
                dataTable.Load(reader);
                return dataTable.XmlDataForExcel("RevenueAnalysisReport");
            }
        }

        string ExtractSqlCommand(string scriptName)
        {
            string contents;
            var scriptResource = string.Format("{0}.{1}", GetType().Namespace, scriptName);
            var resolvedAssembly = Assembly.GetAssembly(GetType());

            var stream = resolvedAssembly.GetManifestResourceStream(scriptResource);
            if(stream == null)
                throw new InvalidOperationException("Specified report is not available.");

            using(var streamReader = new StreamReader(stream))
                contents = streamReader.ReadToEnd();
            return contents;
        }
    }
}