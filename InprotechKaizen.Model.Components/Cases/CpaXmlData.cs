using System.Data;
using System.Data.SqlClient;
using System.Xml;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases
{
    public interface ICpaXmlData
    {
        XmlDocument GetCpaXmlData( int identityId, int processId, string culture);
    }

    public class CpaXmlData : ICpaXmlData
    {
        readonly IDbContext _dbContext;
        public const string Command = "ipw_GetCPAXmlData";

        public CpaXmlData(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }
        public XmlDocument GetCpaXmlData( int identityId, int processId, string culture)
        {
            using (var dbCommand = _dbContext.CreateStoredProcedureCommand(Command))
            {
                dbCommand.Parameters.AddWithValue("pnUserIdentityId", identityId);
                dbCommand.Parameters.AddWithValue("psCulture", culture);
                dbCommand.Parameters.AddWithValue("pnProcessId", processId);

                var ds = new DataSet();
                using (var adapter = new SqlDataAdapter(dbCommand))
                {
                    adapter.Fill(ds);
                    var xmlDocument = new XmlDocument { XmlResolver = null };
                    xmlDocument.LoadXml(ds.GetXml());
                    return xmlDocument;
                }
            }
       }
    }
}