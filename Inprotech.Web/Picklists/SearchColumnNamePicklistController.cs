using System;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/searchColumn")]
    public class SearchColumnNamePicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly string _culture;

        static readonly CommonQueryParameters SortByParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "Description",
                SortDir = "asc"
            });

        public SearchColumnNamePicklistController(IDbContext dbContext,
                                                    IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _culture = preferredCultureResolver.Resolve();
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(QueryColumnGroupPayload), ApplicationTask.MaintainPublicSearch)]
        public PagedResults Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                   CommonQueryParameters queryParameters = null,
                                   string search = "", int? queryContext = null)
        {
            var queryParams = SortByParameters.Extend(queryParameters);

            var queryImpliedColumns = from qii in _dbContext.Set<QueryImpliedItem>()
                                      join qid in _dbContext.Set<QueryImpliedData>() on qii.Id equals qid.Id
                                      where qid.DataItemId == null && qii.Usage != null
                                      select new QueryImpliedDataset
                                      {
                                         ProcedureItemId = qii.ProcedureItemId,
                                         ContextId = qid.ContextId
                                      };

            var q1 = from qdi in _dbContext.Set<QueryDataItem>()
                     join qc in _dbContext.Set<QueryContextModel>() on qdi.ProcedureName equals qc.ProcedureName
                     join tc in _dbContext.Set<TableCode>() on qdi.DataFormatId equals tc.Id
                     join qic in queryImpliedColumns on new {ContextId = qc.Id, qdi.ProcedureItemId} equals new {qic.ContextId, qic.ProcedureItemId} into tmpImpliedColumns
                     from impliedColumns in tmpImpliedColumns.DefaultIfEmpty()
                     where qc.Id == queryContext
                     select new SearchColumnNamePayload
                     {
                         Key = qdi.DataItemId,
                         Description = qdi.ProcedureItemId,
                         QueryContext = qc.Id,
                         IsQualifierAvailable = qdi.QualifierType != null,
                         IsUserDefined = qdi.ProcedureItemId.StartsWith("UserColumn"),
                         IsUsedBySystem = impliedColumns != null && impliedColumns.ProcedureItemId != null,
                         DataFormat = DbFuncs.GetTranslation(tc.Name, null, tc.NameTId, _culture)
                     };

            var q2 = from qcc in _dbContext.Set<QueryContextColumn>()
                     join qc in _dbContext.Set<QueryColumn>() on qcc.ColumnId equals qc.ColumnId
                     join qdi in _dbContext.Set<QueryDataItem>() on qc.DataItemId equals qdi.DataItemId
                     join tc in _dbContext.Set<TableCode>() on qdi.DataFormatId equals tc.Id
                     join qic in queryImpliedColumns on new { qcc.ContextId, qdi.ProcedureItemId } equals new { qic.ContextId, qic.ProcedureItemId } into tmpImpliedColumns
                     from impliedColumns in tmpImpliedColumns.DefaultIfEmpty()
                     where qcc.ContextId == queryContext
                     select new SearchColumnNamePayload
                     {
                         Key = qdi.DataItemId,
                         Description = qdi.ProcedureItemId,
                         QueryContext = qcc.ContextId,
                         IsQualifierAvailable = qdi.QualifierType != null,
                         IsUserDefined = qdi.ProcedureItemId.StartsWith("UserColumn"),
                         IsUsedBySystem = impliedColumns != null && impliedColumns.ProcedureItemId != null,
                         DataFormat = DbFuncs.GetTranslation(tc.Name, null, tc.NameTId, _culture)
                     };

            var result = q1.Union(q2).ToArray();
            if (!string.IsNullOrWhiteSpace(search))
            {
                result = result.Where(_ => _.Description.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) >= 0).ToArray();
            }

            var pagedResults = Helpers.GetPagedResults(result,
                                           queryParams,
                                           x => x.Key.ToString(), x => x.Description, search);
            return pagedResults;
        }
    }

    public class QueryImpliedDataset
    {
        public string ProcedureItemId { get; set; }
        public int ContextId { get; set; }
    }

    public class SearchColumnNamePayload
    {
        [PicklistKey]
        public int Key { get; set; }

        [DisplayName("description")]
        [DisplayOrder(1)]
        [Required]
        [MaxLength(50)]
        public string Description { get; set; }

        public int QueryContext { get; set; }

        public bool IsQualifierAvailable { get; set; }

        public bool IsUserDefined { get; set; }

        public string DataFormat { get; set; }

        public bool IsUsedBySystem { get; set; }
    }
}
