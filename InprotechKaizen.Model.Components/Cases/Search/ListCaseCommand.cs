using System;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using InprotechKaizen.Model.Components.Extensions;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases.Search
{
    public static class ListCaseCommand
    {
        public const string Command = "csw_ListCase";

        public static IEnumerable<CaseListItem> GetCasesForPickList(
            this IDbContext dbContext,
            out int rowCount,
            int userId,
            string culture,
            string searchString,
            string sortBy,
            string sortDir,
            int? skip,
            int? take,
            int? nameKey,
            bool withInstructor, 
            CaseSearchFilter searchFilter = null)
        {
            rowCount = 0;

            var element = new XElement("OutputRequests",
                         QueryHelper.BuildOutputColumn(Command, "CaseKey", "Id"),
                         QueryHelper.BuildOutputColumn(Command, "CaseReference", "CaseRef"),
                         QueryHelper.BuildOutputColumn(Command, "ShortTitle", "Title"),
                         QueryHelper.BuildOutputColumn(Command, "CurrentOfficialNumber", "OfficialNumber"),
                         QueryHelper.BuildOutputColumn(Command, "PropertyTypeDescription", "PropertyTypeDescription"),
                         QueryHelper.BuildOutputColumn(Command, "CountryName", "CountryName")
                        );
            if (withInstructor)
            {
                element.Add(QueryHelper.BuildOutputColumn(Command, "DisplayName", "InstructorName", KnownNameTypes.Instructor));
                element.Add(QueryHelper.BuildOutputColumn(Command, "NameKey", "InstructorNameId", KnownNameTypes.Instructor));
            }

            var outputColumns = new XDocument(element);
            
            QueryHelper.AddSortAttributes(sortBy, sortDir, 1, outputColumns);

            var caseFilterXml =
                XElement.Parse(@"<csw_ListCase><FilterCriteriaGroup><FilterCriteria><CaseNameGroup><CaseName Operator=""0""><TypeKey>I</TypeKey><NameKeys>" + nameKey + @"</NameKeys></CaseName></CaseNameGroup><CaseKey />
                    <PickListSearch></PickListSearch><CaseTypeKey IncludeCRMCases=""1"" /></FilterCriteria></FilterCriteriaGroup></csw_ListCase>");

            if (!string.IsNullOrWhiteSpace(searchString))
                caseFilterXml.Descendants("PickListSearch").First().Value = searchString;
            
            caseFilterXml = CasePicklistSearchFilter.ConstructSearchFilter(caseFilterXml, searchFilter);

            var dbCommand = dbContext.CreateStoredProcedureCommand("csw_ListCase");
            dbCommand.Parameters.AddWithValue("pnRowCount", DBNull.Value);
            dbCommand.Parameters.AddWithValue("pnUserIdentityId", userId);
            dbCommand.Parameters.AddWithValue("psCulture", culture);
            dbCommand.Parameters.AddWithValue("pnQueryContextKey", 5);
            dbCommand.Parameters.AddWithValue("ptXMLOutputRequests", outputColumns.ToString());
            dbCommand.Parameters.AddWithValue("ptXMLFilterCriteria", caseFilterXml.ToString());
            dbCommand.Parameters.AddWithValue("pnPageStartRow", skip.GetValueOrDefault() + 1);
            dbCommand.Parameters.AddWithValue("pnPageEndRow", skip.GetValueOrDefault() + take);
            dbCommand.Parameters.AddWithValue("pbReturnResultSet", true);
            dbCommand.Parameters.AddWithValue("pbGetTotalCaseCount", true);

            using (var reader = dbCommand.ExecuteReader())
            {
                var result = reader.MapTo<CaseListItem>();

                reader.NextResult();
                if (reader.Read())
                    int.TryParse(reader[0].ToString(), out rowCount);

                return result;
            }
        }
    }

    public class CaseListItem
    {
        public int Id { get; set; }

        public string CaseRef { get; set; }

        public string Title { get; set; }

        public string OfficialNumber { get; set; }

        public string PropertyTypeDescription { get; set; }

        public string CountryName { get; set; }
        
        public string InstructorName { get; set; }
        public int? InstructorNameId { get; set; }
    }
}