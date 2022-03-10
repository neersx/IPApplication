using System;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Extensions;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Queries
{
    public static class ListSearchRequirementsCommand
    {
        public const string Command = "ip_ListSearchRequirements";

        public static async Task<SearchPresentation> ListSearchRequirements(this IDbContext dbContext,
                                                                int userIdentityKey,
                                                                string culture,
                                                                int queryContextKey,
                                                                int? queryKey,
                                                                string xmlSelectedColumns,
                                                                int? reportToolKey,
                                                                string presentationType,
                                                                bool isExternalUser)
        {
            using (var dbCommand = dbContext.CreateStoredProcedureCommand(Command))
            {
                var psProcedureName = dbCommand.CreateParameter();
                psProcedureName.ParameterName = "psProcedureName";
                psProcedureName.SqlDbType = SqlDbType.NVarChar;
                psProcedureName.Size = 50;
                psProcedureName.Direction = ParameterDirection.Output;

                dbCommand.Parameters.Add(psProcedureName);
                dbCommand.Parameters.AddWithValue("pnUserIdentityId", userIdentityKey);
                dbCommand.Parameters.AddWithValue("psCulture", culture);
                dbCommand.Parameters.AddWithValue("pnQueryContextKey", queryContextKey);
                dbCommand.Parameters.AddWithValue("pnQueryKey", queryKey);
                dbCommand.Parameters.AddWithValue("ptXMLSelectedColumns", xmlSelectedColumns);
                dbCommand.Parameters.AddWithValue("pnReportToolKey", reportToolKey);
                dbCommand.Parameters.AddWithValue("psPresentationType", presentationType);
                dbCommand.Parameters.AddWithValue("pbCalledFromCentura", false);
                dbCommand.Parameters.AddWithValue("pbUseDefaultPresentation", false);
                dbCommand.Parameters.AddWithValue("pbIsExternalUser", isExternalUser);
                dbCommand.Parameters.AddWithValue("psResultRequired", DBNull.Value);

                var retval = new SearchPresentation();

                using (var reader = await dbCommand.ExecuteReaderAsync())
                {
                    // columns

                    retval.ColumnFormats = reader.MapTo<ColumnFormat>();
                    await reader.NextResultAsync();

                    // links

                    var links = reader.MapTo<Link>();

                    foreach (var col in retval.ColumnFormats)
                        col.Links = links.Where(x => x.Id.Equals(col.Id, StringComparison.InvariantCultureIgnoreCase)).ToList();

                    reader.NextResult();

                    // link arguments

                    var linkArguments = reader.MapTo<LinkArgument>();

                    foreach (var match in from a in linkArguments
                                          from c in retval.ColumnFormats
                                          where c.Id.Equals(a.Id, StringComparison.InvariantCultureIgnoreCase)
                                          from l in c.Links
                                          where l.Id.Equals(a.Id, StringComparison.InvariantCultureIgnoreCase)
                                          select new {a, l})
                    {
                        match.l.LinkArguments.Add(match.a);
                    }

                    await reader.NextResultAsync();

                    // output requests

                    retval.OutputRequests = reader.MapTo<OutputRequest>();
                    await reader.NextResultAsync();

                    // XMLCriteria

                    if (await reader.ReadAsync())
                        if (!reader.IsDBNull(reader.GetOrdinal("XMLCriteria")))
                            retval.XmlCriteria = reader["XMLCriteria"].ToString();

                    await reader.NextResultAsync();

                    // search reports

                    retval.SearchReports = reader.MapTo<SearchReport>();
                    await reader.NextResultAsync();

                    // context links

                    retval.ContextLinks = reader.MapTo<ContextLink>();
                    await reader.NextResultAsync();

                    // context arguments

                    var contextArguments = reader.MapTo<ContextArgument>();
                    foreach (var match in from a in contextArguments
                                          from l in retval.ContextLinks
                                          where string.Equals(a.Type, l.Type, StringComparison.InvariantCultureIgnoreCase)
                                          select new {a, l})
                    {
                        match.l.ContextArguments.Add(match.a);
                    }

                    await reader.NextResultAsync();

                    // procedure name

                    retval.ProcedureName = psProcedureName.Value.ToString();
                }

                return retval;
            }
        }
    }
}
