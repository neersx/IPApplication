using System;
using System.Collections.Generic;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases.Filing.Electronic
{
    public static class ListCaseEfilingPackageCommand
    {
        public const string Command = "b2b_ListPackageDetails";

        public static IEnumerable<EfilingPackageListItem> GetPackages(this IDbContext dbContext, string culture, string cases)
        {
            return DbContextHelpers.ExecuteSqlQuery<EfilingPackageListItem>(dbContext, Command, culture, cases);
        }
    }

    public class EfilingPackageListItem
    {
        public string PackageType { get; set; }
        public string PackageReference { get; set; }
        public string CurrentStatus { get; set; }
        public string CurrentStatusDescription { get; set; }
        public string NextEventDue { get; set; }
        public DateTime LastStatusChange { get; set; }
        public string UserName { get; set; }
        public string Server { get; set; }
        public int ExchangeId { get; set; }
        public int PackageSequence { get; set; }
    }
}