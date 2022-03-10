using System.Collections.Generic;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases.Filing.Electronic
{
    public static class ListCaseEfilingPackageFilesCommand
    {
        public const string Command = "b2b_ListPackageFiles";

        public static IEnumerable<EfilingPackageFilesListItem> GetPackageFiles(this IDbContext dbContext, int caseKey, int exchangeId, int packageSequence)
        {
            return DbContextHelpers.ExecuteSqlQuery<EfilingPackageFilesListItem>(dbContext, Command, caseKey, exchangeId, packageSequence);
        }
    }

    public class EfilingPackageFilesListItem
    {
        public string ComponentDescription { get; set; }
        public string FileName { get; set; }
        public int? FileSize { get; set; }
        public string FileType { get; set; }
        public int Outbound { get; set; }
        public int? PackageFileSequence { get; set; }
    }
}