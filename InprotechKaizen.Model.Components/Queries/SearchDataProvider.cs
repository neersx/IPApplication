using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Queries
{
    public interface ISearchDataProvider
    {
        Task<SearchResults> RunSearch(SearchPresentation presentation, CommonQueryParameters queryParameters);
    }

    public class SearchDataProvider : ISearchDataProvider
    {
        readonly IDbContext _dbContext;

        public SearchDataProvider(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<SearchResults> RunSearch(SearchPresentation presentation, CommonQueryParameters queryParameters = null)
        {
            if (presentation == null) throw new ArgumentNullException(nameof(presentation));

            var searchResults = new SearchResults { XmlCriteriaExecuted = presentation.XmlCriteria };

            var xmlOutputRequests = new XDocument(new XElement("OutputRequests",
                                                               from c in presentation.OutputRequests
                                                               select new XElement("Column",
                                                                                   GetOutputRequestAttributes(c))))
                .ToString(SaveOptions.DisableFormatting);

            var searchProcElement = XElement.Parse(presentation.XmlCriteria).DescendantsAndSelf(presentation.ProcedureName).FirstOrDefault();
            if (searchProcElement != null)
            {
                presentation.XmlCriteria = searchProcElement.ToString();
            }

            var idCreator = QueryResultIdCreator.Resolve(presentation.ProcedureName);

            searchResults.RowCount = 0;

            using (var cmd = _dbContext.CreateStoredProcedureCommand(presentation.ProcedureName))
            {
                cmd.CommandTimeout = 0;

                SqlCommandBuilder.DeriveParameters(cmd);

                var startRow = queryParameters?.Skip.GetValueOrDefault() + 1;
                var endRow = startRow + queryParameters?.Take - 1;
                
                for (var iParam = 0; iParam < cmd.Parameters.Count; iParam++)
                {
                    var p = cmd.Parameters[iParam];

                    switch (p.ParameterName)
                    {
                        case "@pnRowCount":
                            p.Value = searchResults.RowCount;
                            break;
                        case "@pnUserIdentityId":
                            p.Value = presentation.UserId;
                            break;
                        case "@psCulture":
                            p.Value = presentation.Culture;
                            break;
                        case "@pnQueryContextKey":
                            p.Value = presentation.QueryContextKey;
                            break;
                        case "@ptXMLOutputRequests":
                            p.Value = xmlOutputRequests;
                            break;
                        case "@ptXMLFilterCriteria":
                            p.Value = presentation.XmlCriteria;
                            break;
                        case "@pbProduceTableName":
                        case "@pbCalledFromCentura":
                            p.Value = 0;
                            break;

                        case "@pbReturnResultSet":
                        case "@pbGetTotalCaseCount":
                        case "@pbGetTotalNameCount":
                        case "@pbGetTotalRowCount":
                            p.Value = 1;
                            break;

                        case "@pnPageStartRow":
                            p.Value = startRow;
                            break;

                        case "@pnPageEndRow":
                            p.Value = endRow;
                            break;

                        default:
                            p.Value = DBNull.Value;
                            break;
                    }
                }

                var idCounter = startRow.GetValueOrDefault();
                using (var dr = await cmd.ExecuteReaderAsync())
                {
                    searchResults.Rows = new List<Dictionary<string, object>>();
                    while (await dr.ReadAsync())
                    {
                        var row = new Dictionary<string, object>(StringComparer.InvariantCultureIgnoreCase);

                        for (var iCol = 0; iCol < dr.FieldCount; iCol++)
                        {
                            if (!await dr.IsDBNullAsync(iCol))
                            {
                                row[dr.GetName(iCol)] = dr.GetValue(iCol);
                            }
                        }

                        idCreator.Invoke(idCounter++, row);

                        searchResults.Rows.Add(row);
                    }

                    await dr.NextResultAsync();

                    // total rows

                    while (await dr.ReadAsync())
                    {
                        if (int.TryParse(dr["SearchSetTotalRows"].ToString(), out var totalRows))
                        {
                            searchResults.TotalRows = totalRows;
                        }
                        else
                        {
                            searchResults.TotalRows = null;
                        }
                    }

                    await dr.NextResultAsync();

                    // row count

                    var rowCountParam = cmd.Parameters
                                           .OfType<SqlParameter>()
                                           .FirstOrDefault(x => x.ParameterName == "@pnRowCount");

                    if (rowCountParam != null && int.TryParse(rowCountParam.Value.ToString(), out var rowCount))
                    {
                        searchResults.RowCount = rowCount;
                        if (!searchResults.TotalRows.HasValue)
                        {
                            searchResults.TotalRows = searchResults.RowCount;
                        }
                    }
                    else
                    {
                        searchResults.RowCount = -1;
                    }

                    return searchResults;
                }
            }
        }

        static IEnumerable<XAttribute> GetOutputRequestAttributes(OutputRequest outputRequest)
        {
            if (!string.IsNullOrEmpty(outputRequest.ProcedureName))
                yield return new XAttribute("ProcedureName", outputRequest.ProcedureName);
         
            yield return new XAttribute("ID", outputRequest.Id);

            if (!string.IsNullOrEmpty(outputRequest.Qualifier))
                yield return new XAttribute("Qualifier", outputRequest.Qualifier);
            
            yield return new XAttribute("PublishName", outputRequest.PublishName);
            
            if (outputRequest.SortOrder.HasValue)
                yield return new XAttribute("SortOrder", outputRequest.SortOrder.Value);
            
            if (outputRequest.SortDirection.HasValue)
                yield return new XAttribute("SortDirection", Formatter(outputRequest.SortDirection));
            
            if (outputRequest.GroupBySortOrder.HasValue)
                yield return new XAttribute("GroupBySortOrder", outputRequest.GroupBySortOrder.Value);
            
            if (outputRequest.GroupBySortDirection.HasValue)
                yield return new XAttribute("GroupBySortDirection", Formatter(outputRequest.GroupBySortDirection));

            if (outputRequest.IsFreezeColumnIndex)
                yield return new XAttribute("IsFreezeColumnIndex", Formatter(outputRequest.IsFreezeColumnIndex));
            
            if (outputRequest.DocItemKey.HasValue)
                yield return new XAttribute("DocItemKey", outputRequest.DocItemKey.Value);
        }

        static string Formatter(SortDirectionType? sortDirection)
        {
            return sortDirection == SortDirectionType.Ascending ? "A" : "D";
        }

        static int Formatter(bool? boolValue)
        {
            return boolValue == true ? 1 : 0;
        }
    }
}