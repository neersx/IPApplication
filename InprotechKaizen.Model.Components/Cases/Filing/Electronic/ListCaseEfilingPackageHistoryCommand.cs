using System;
using System.Collections.Generic;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases.Filing.Electronic
{
    public static class ListCaseEfilingPackageHistoryCommand
    {
        public const string Command = "b2b_ListPackageHistory";

        public static IEnumerable<EfilingHistoryDataItem> GetPackageHistory(this IDbContext dbContext, string culture, int exchangeId)
        {
            return DbContextHelpers.ExecuteSqlQuery<EfilingHistoryDataItem>(dbContext, Command, culture, exchangeId);
        }
    }

    public class EfilingHistoryDataItem
    {
        public DateTime StatusDateTime { get; set; }
        public string Status { get; set; }
        public string StatusDescription { get; set; }
    }
}
