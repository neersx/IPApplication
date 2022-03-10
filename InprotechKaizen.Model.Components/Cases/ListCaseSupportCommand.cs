using System.Collections.Generic;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases
{
    public static class ListCaseSupportCommand
    {
        public const string Command = "csw_ListCaseSupport";

        public static IEnumerable<OfficeListItem> GetOffices(
            this IDbContext dbContext,
            int userId,
            string culture,
            bool isExternalUser)
        {
            return DbContextHelpers.ExecuteSqlQuery<OfficeListItem>(
                                                                    dbContext,
                                                                    Command,
                                                                    userId,
                                                                    culture,
                                                                    "Office",
                                                                    (int?) null,
                                                                    1,
                                                                    isExternalUser);
        }

        public static IEnumerable<PropertyTypeListItem> GetPropertyTypes(
            this IDbContext dbContext,
            int userId,
            string culture,
            bool isExternalUser)
        {
            return DbContextHelpers.ExecuteSqlQuery<PropertyTypeListItem>(
                                                                          dbContext,
                                                                          Command,
                                                                          userId,
                                                                          culture,
                                                                          "PropertyTypeWithCRM",
                                                                          (int?) null,
                                                                          1,
                                                                          isExternalUser);
        }

        public static IEnumerable<CaseTypeListItem> GetCaseTypes(
            this IDbContext dbContext,
            int userId,
            string culture,
            bool isExternalUser)
        {
            return DbContextHelpers.ExecuteSqlQuery<CaseTypeListItem>(
                                                                      dbContext,
                                                                      Command,
                                                                      userId,
                                                                      culture,
                                                                      "CaseTypeWithCRM",
                                                                      (int?) null,
                                                                      1,
                                                                      isExternalUser);
        }

        public static IEnumerable<TypeOfMarkListItem> GetTypeOfMarkList(
            this IDbContext dbContext,
            int userId,
            string culture,
            bool isExternalUser)
        {
            return DbContextHelpers.ExecuteSqlQuery<TypeOfMarkListItem>(
                                                                        dbContext,
                                                                        Command,
                                                                        userId,
                                                                        culture,
                                                                        "TypeOfMark",
                                                                        (int?) null,
                                                                        1,
                                                                        isExternalUser);
        }

        public static IEnumerable<ExternalRenewalStatusListItem> GetExternalRenewalStatuses(
            this IDbContext dbContext,
            int userId,
            string culture)
        {
            return DbContextHelpers.ExecuteSqlQuery<ExternalRenewalStatusListItem>(
                                                                                   dbContext,
                                                                                   Command,
                                                                                   userId,
                                                                                   culture,
                                                                                   "ExternalRenewalStatus",
                                                                                   (int?) null,
                                                                                   1,
                                                                                   true);
        }

        public static IEnumerable<ChecklistTypeItem> GetChecklistTypes(
            this IDbContext dbContext,
            int userId,
            string culture,
            bool isExternalUser)
        {
            return DbContextHelpers.ExecuteSqlQuery<ChecklistTypeItem>(
                                                                       dbContext,
                                                                       Command,
                                                                       userId,
                                                                       culture,
                                                                       "ChecklistType",
                                                                       (int?) null,
                                                                       1,
                                                                       isExternalUser);
        }

        public class ChecklistTypeItem
        {
            public short ChecklistTypeKey { get; set; }
            public string ChecklistTypeDescription { get; set; }
        }
    }
}