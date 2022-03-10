using System.Linq;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases
{
    public static class ExportCpaXml
    {
        public const string Command = "apps_CpaXmlExport";

        public static CpaXmlResult GenerateCpaXml(this IDbContext dbContext, string caseIds, long tempStorageId, int userIdentityId, int typeOfRequest)
        {
            var result = DbContextHelpers.ExecuteSqlQuery<CpaXmlResult>(dbContext, Command, caseIds, tempStorageId, userIdentityId, typeOfRequest).FirstOrDefault();
            return result;
        }
    }
   
    public class CpaXmlResult
    {
        public int BackgroundProcessId { get; set; }
        public string ErrorMessage { get; set; }
    }
    
}