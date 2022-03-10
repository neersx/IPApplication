using System;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using InprotechKaizen.Model.Components.Extensions;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Names
{
    public static class ListNameCommand
    {
        public const string Command = Inprotech.Contracts.StoredProcedures.ListName;

        public static IEnumerable<NameListItem> GetSpecificNamesForPicklist(this IDbContext dbContext,
                                                                            out int rowCount,
                                                                            int userId,
                                                                            string culture,
                                                                            string searchString,
                                                                            EntityTypes forEntityTypes,
                                                                            List<int> nameKeys,
                                                                            string sortBy,
                                                                            string sortDir,
                                                                            int? skip,
                                                                            int? take,
                                                                            bool buildDisplayNameCode = false)
        {
            rowCount = 0;

            var columns = new List<object>(new object[]
            {
                QueryHelper.BuildOutputColumn(Command, "Unavailable", "IsUnavailable"),
                QueryHelper.BuildOutputColumn(Command, "NameKey", "Id"),
                QueryHelper.BuildOutputColumn(Command, "NameCode"),
                QueryHelper.BuildOutputColumn(Command, "DisplayName"),
                QueryHelper.BuildOutputColumn(Command, "Remarks")
            });

            if (buildDisplayNameCode)
                columns.Add(QueryHelper.BuildOutputColumn(Command, "DisplayNameCodeFlag", "ShowNameCode"));

            var outputColumns = new XDocument(new XElement("OutputRequests", columns));

            QueryHelper.AddSortAttributes(sortBy, sortDir, 1, outputColumns);

            var entityFlags = string.Empty;
            var specificNameKeys = string.Empty;

            if (forEntityTypes != null)
                entityFlags = $"<IsClient>{(forEntityTypes.IsClient.GetValueOrDefault() ? "1" : "0")}</IsClient><EntityFlags><IsStaff>{(forEntityTypes.IsStaff.GetValueOrDefault() ? "1" : "0")}</IsStaff><IsIndividual>{(forEntityTypes.IsIndividual.GetValueOrDefault() ? "1" : "0")}</IsIndividual><IsOrganisation>{(forEntityTypes.IsOrganisation.GetValueOrDefault() ? "1" : "0")}</IsOrganisation></EntityFlags>";

            if (nameKeys.Any())
                specificNameKeys = $"<NameKeys>{string.Join(string.Empty, nameKeys.Select(_ => $"<NameKey>{_}</NameKey>"))}</NameKeys>";

            var nameFilterXml = XElement.Parse($"<naw_ListName><FilterCriteriaGroup><FilterCriteria><PickListSearch></PickListSearch>{specificNameKeys}<IsAvailable>1</IsAvailable><IsCurrent>1</IsCurrent><IsSupplier>0</IsSupplier>{entityFlags}</FilterCriteria></FilterCriteriaGroup></naw_ListName>");
            if (!string.IsNullOrEmpty(searchString))
            {
                nameFilterXml.Descendants("PickListSearch").First().Value = searchString;
            }

            if (forEntityTypes != null && forEntityTypes.IsSupplier.GetValueOrDefault())
            {
                nameFilterXml.Descendants("IsSupplier").First().Value = "1";
            }

            using (var dbCommand = dbContext.CreateStoredProcedureCommand(Command))
            {
                dbCommand.Parameters.AddWithValue("pnRowCount", DBNull.Value);
                dbCommand.Parameters.AddWithValue("pnUserIdentityId", userId);
                dbCommand.Parameters.AddWithValue("psCulture", culture);
                dbCommand.Parameters.AddWithValue("pnQueryContextKey", 12);
                dbCommand.Parameters.AddWithValue("ptXMLOutputRequests", outputColumns.ToString());
                dbCommand.Parameters.AddWithValue("ptXMLFilterCriteria", nameFilterXml.ToString());
                dbCommand.Parameters.AddWithValue("pnPageStartRow", skip.GetValueOrDefault() + 1);
                dbCommand.Parameters.AddWithValue("pnPageEndRow", skip.GetValueOrDefault() + take);
                dbCommand.Parameters.AddWithValue("pbReturnResultSet", true);
                dbCommand.Parameters.AddWithValue("pbGetTotalNameCount", true);

                using (var reader = dbCommand.ExecuteReader())
                {
                    var result = reader.MapTo<NameListItem>();

                    reader.NextResult();
                    if (reader.Read())
                    {
                        int.TryParse(reader[0].ToString(), out rowCount);
                    }

                    return result;
                }
            }
        }

        public static IEnumerable<NameListItem> GetNamesForPickList(
            this IDbContext dbContext,
            out int rowCount,
            int userId,
            string culture,
            string searchString,
            string filterNameType,
            EntityTypes forEntityTypes,
            bool? showCeased,
            string sortBy,
            string sortDir,
            int? skip,
            int? take,
            int? associatedNameId = null,
            bool buildDisplayNameCode = false)
        {
            rowCount = 0;

            var columns = new List<object>(new object[]
            {
                QueryHelper.BuildOutputColumn(Command, "Unavailable", "IsUnavailable"),
                QueryHelper.BuildOutputColumn(Command, "NameKey", "Id"),
                QueryHelper.BuildOutputColumn(Command, "NameCode"),
                QueryHelper.BuildOutputColumn(Command, "DisplayName"),
                QueryHelper.BuildOutputColumn(Command, "Remarks"),
                QueryHelper.BuildOutputColumn(Command, "CountryCode"),
                QueryHelper.BuildOutputColumn(Command, "CountryName"),
                QueryHelper.BuildOutputColumn(Command, "DisplayMainEmail")
            });

            if (buildDisplayNameCode)
                columns.Add(QueryHelper.BuildOutputColumn(Command, "DisplayNameCodeFlag", "ShowNameCode"));

            if (showCeased == true) columns.Add(QueryHelper.BuildOutputColumn(Command, "DateCeased", "DateCeased"));

            var outputColumns = new XDocument(new XElement("OutputRequests", columns));

            QueryHelper.AddSortAttributes(sortBy, sortDir, 1, outputColumns);

            var entityFlags = string.Empty;
            var associatedName = string.Empty;

            if (forEntityTypes != null)
                entityFlags = $"<IsClient>{(forEntityTypes.IsClient.GetValueOrDefault() ? "1" : "0")}</IsClient><EntityFlags><IsStaff>{(forEntityTypes.IsStaff.GetValueOrDefault() ? "1" : "0")}</IsStaff><IsIndividual>{(forEntityTypes.IsIndividual.GetValueOrDefault() ? "1" : "0")}</IsIndividual><IsOrganisation>{(forEntityTypes.IsOrganisation.GetValueOrDefault() ? "1" : "0")}</IsOrganisation></EntityFlags>";
            if (associatedNameId != null)
                associatedName = $"<AssociatedName Operator=\"0\" IsReverseRelationship=\"1\"><NameKeys>{associatedNameId.ToString()}</NameKeys></AssociatedName>";

            var nameFilterXml = XElement.Parse($"<naw_ListName><FilterCriteriaGroup><FilterCriteria><PickListSearch></PickListSearch><IsAvailable>1</IsAvailable><IsCurrent>1</IsCurrent><IsSupplier>0</IsSupplier>{entityFlags}{associatedName}</FilterCriteria></FilterCriteriaGroup></naw_ListName>");
            if (!string.IsNullOrEmpty(searchString))
            {
                nameFilterXml.Descendants("PickListSearch").First().Value = searchString;
            }

            if (!string.IsNullOrEmpty(filterNameType))
            {
                nameFilterXml.Descendants("FilterCriteria").First().Add(new XElement("SuitableForNameTypeKey", filterNameType));
            }

            if (showCeased == true)
            {
                nameFilterXml.Descendants("IsAvailable").First().Value = "0";
                nameFilterXml.Descendants("IsCurrent").First().Value = "0";
            }

            if (forEntityTypes != null && forEntityTypes.IsSupplier.GetValueOrDefault())
            {
                nameFilterXml.Descendants("IsSupplier").First().Value = "1";
            }

            using (var dbCommand = dbContext.CreateStoredProcedureCommand(Command))
            {
                dbCommand.Parameters.AddWithValue("pnRowCount", DBNull.Value);
                dbCommand.Parameters.AddWithValue("pnUserIdentityId", userId);
                dbCommand.Parameters.AddWithValue("psCulture", culture);
                dbCommand.Parameters.AddWithValue("pnQueryContextKey", 12);
                dbCommand.Parameters.AddWithValue("ptXMLOutputRequests", outputColumns.ToString());
                dbCommand.Parameters.AddWithValue("ptXMLFilterCriteria", nameFilterXml.ToString());
                dbCommand.Parameters.AddWithValue("pnPageStartRow", skip.GetValueOrDefault() + 1);
                dbCommand.Parameters.AddWithValue("pnPageEndRow", skip.GetValueOrDefault() + take);
                dbCommand.Parameters.AddWithValue("pbReturnResultSet", true);
                dbCommand.Parameters.AddWithValue("pbGetTotalNameCount", true);

                using (var reader = dbCommand.ExecuteReader())
                {
                    var result = reader.MapTo<NameListItem>();

                    reader.NextResult();
                    if (reader.Read())
                    {
                        int.TryParse(reader[0].ToString(), out rowCount);
                    }

                    return result;
                }
            }
        }
    }

    public class NameListItem
    {
        public int Id { get; set; }

        public string NameCode { get; set; }

        public string DisplayName { get; set; }

        public string Remarks { get; set; }

        public bool? IsUnavailable { get; set; }

        public DateTime? DateCeased { get; set; }

        public decimal? ShowNameCode { get; set; }

        public string CountryCode { get; set; } 

        public string CountryName { get; set; } 

        public string DisplayMainEmail { get; set; } 
    }
}