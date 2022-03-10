using System.Linq;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases.Filing.Electronic
{
    public static class RetrieveCaseEfilingFileDataCommand
    {
        public const string Command = "b2b_RetrieveFileData";

        public static EfilingFileDataItem GetEfilingFileData(this IDbContext dbContext, int? caseKey, int? packageSequence, int? packageFileSequence, int? exchangeId)
        {
            var result = DbContextHelpers.ExecuteSqlQuery<EfilingFileDataItem>(dbContext, Command, caseKey, packageSequence, packageFileSequence, exchangeId);
            return result.FirstOrDefault();
        }
    }

    public class EfilingFileDataItem
    {
        public byte[] FileData { get; set; }
        public string FileType { get; set; }
        public string FileName { get; set; }
    }
}