using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Validations;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Extentions;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;

namespace Inprotech.Web.Search.Columns
{
    [Authorize]
    [RoutePrefix("api/search/columns")]
    public class SearchColumnsMaintenanceController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IQueryContextTypeResolver _queryContextTypeResolver;
        readonly ISearchColumnMaintainabilityResolver _searchColumnMaintainabilityResolver;

        static readonly CommonQueryParameters SortByParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "DisplayName",
                SortDir = "asc"
            });

        public SearchColumnsMaintenanceController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver,
                                      ISearchColumnMaintainabilityResolver searchColumnMaintainabilityResolver,
                                      IQueryContextTypeResolver queryContextTypeResolver)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _preferredCultureResolver = preferredCultureResolver;
            _searchColumnMaintainabilityResolver = searchColumnMaintainabilityResolver;
            _queryContextTypeResolver = queryContextTypeResolver;
        }

        [HttpGet]
        [Route("viewdata/{queryContextKey}")]
        [NoEnrichment]
        public dynamic ViewData(QueryContext queryContextKey)
        {
            var context = _dbContext.Set<QueryContextModel>()
                                    .SingleOrDefault(_ => _.Id == (int)queryContextKey);
            if (context == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            CheckAccess(queryContextKey);

            var queryContextPermissions = new List<SearchColumnQueryContextPermissions>();

            if (!QueryContextGroup.QueryContextDictionary.TryGetValue(queryContextKey, out var queryContexts))
            {
                queryContexts = new[] { queryContextKey };
            }

            foreach (var queryContext in queryContexts)
            {
                var isInternal = false;
                var queryContextType = _queryContextTypeResolver.Resolve(queryContext);

                var maintainability = _searchColumnMaintainabilityResolver.Resolve(queryContext);
                if (queryContext == queryContextKey)
                {
                    isInternal = true;
                }

                var obj = new SearchColumnQueryContextPermissions
                {
                    DisplayForInternal = isInternal,
                    QueryContext = (int)queryContext,
                    QueryContextType = queryContextType,
                    CanCreateSearchColumn = maintainability.CanCreateColumnSearch,
                    CanUpdateSearchColumn = maintainability.CanUpdateColumnSearch,
                    CanDeleteSearchColumn = maintainability.CanDeleteColumnSearch
                };
                queryContextPermissions.Add(obj);
            }

            return new
            {
                QueryContextKey = (int)queryContextKey,
                QueryContextPermissions = queryContextPermissions.OrderByDescending(_ => _.QueryContextType.ToString()).ToList()
            };
        }

        [HttpGet]
        [Route("search")]
        [NoEnrichment]
        public List<SearchColumn> Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "searchOption")] SearchColumnOptions searchColumnOptions,
                                       [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "queryParams")] CommonQueryParameters queryParameters = null)
        {
            CheckAccess((QueryContext)searchColumnOptions.QueryContextKey);

            var queryParams = SortByParameters.Extend(queryParameters);

            var culture = _preferredCultureResolver.Resolve();
            var results = (from qcc in _dbContext.Set<QueryContextColumn>()
                           join qc in _dbContext.Set<QueryColumn>() on qcc.ColumnId equals qc.ColumnId
                           join qdi in _dbContext.Set<QueryDataItem>() on qc.DataItemId equals qdi.DataItemId
                           where qcc.ContextId == searchColumnOptions.QueryContextKey
                                 && (qc.ColumnLabel.Contains(searchColumnOptions.Text)
                                     || qc.Description.Contains(searchColumnOptions.Text))
                           select new SearchColumn
                           {
                               DisplayName = DbFuncs.GetTranslation(qc.ColumnLabel, null, qc.ColumnLabelTid, culture),
                               ColumnNameDescription = DbFuncs.GetTranslation(!string.IsNullOrEmpty(qc.Description) ? qc.Description.Trim() : qc.Description, null, qc.DescriptionTid, culture),
                               DataItemId = qc.DataItemId,
                               ContextId = qcc.ContextId,
                               ColumnId = qc.ColumnId
                           }).ToList();
            results = results.OrderByProperty(queryParams.SortBy, queryParams.SortDir).ToList();

            return results;
        }

        void CheckAccess(QueryContext queryContext)
        {
            var maintainability = _searchColumnMaintainabilityResolver.Resolve(queryContext);
            if (!maintainability.CanCreateColumnSearch && !maintainability.CanUpdateColumnSearch && !maintainability.CanDeleteColumnSearch)
                throw new UnauthorizedAccessException();
        }

        [HttpGet]
        [Route("context/{queryContextKey}/{columnKey}")]
        [NoEnrichment]
        public SearchColumnSaveDetails SearchColumn(int queryContextKey, int columnKey)
        {
            CheckAccess((QueryContext)queryContextKey);

            var queryColumn = _dbContext.Set<QueryColumn>()
                                     .SingleOrDefault(_ => _.ColumnId == columnKey);

            if (queryColumn == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            var q = from qcl in _dbContext.Set<QueryColumn>()
                    join qdi in _dbContext.Set<QueryDataItem>() on qcl.DataItemId equals qdi.DataItemId
                    join qcc in _dbContext.Set<QueryContextColumn>() on qcl.ColumnId equals qcc.ColumnId
                    join qcg in _dbContext.Set<QueryColumnGroup>() on new { qcc.GroupId, qcc.ContextId } equals new { GroupId = (int?)qcg.Id, qcg.ContextId } into tmpColumnGroups
                    from columnGroups in tmpColumnGroups.DefaultIfEmpty()
                    join tc in _dbContext.Set<TableCode>() on qdi.DataFormatId equals tc.Id
                    join i in _dbContext.Set<DocItem>() on qcl.DocItemId equals (int?)i.Id into tmpItems
                    from docItems in tmpItems.DefaultIfEmpty()
                    where qcc.ContextId == queryContextKey && qcl.ColumnId == columnKey
                    select new SearchColumnSaveDetails()
                    {
                        ColumnId = qcl.ColumnId,
                        DisplayName = qcl.ColumnLabel,
                        ColumnName = new SearchColumnNamePayload
                        {
                            Key = qdi.DataItemId,
                            Description = qdi.ProcedureItemId,
                            QueryContext = qcc.ContextId,
                            IsQualifierAvailable = qdi.QualifierType != null,
                            IsUserDefined = qdi.ProcedureItemId.StartsWith("UserColumn"),
                            DataFormat = tc.Name
                        },
                        Parameter = qcl.Qualifier,
                        DocItem = docItems != null ? new DataItem
                        {
                            Key = docItems.Id,
                            Code = docItems.Name,
                            Value = docItems.Description
                        }
                        : null,
                        Description = qcl.Description,
                        IsMandatory = qcc.IsMandatory,
                        IsVisible = true,
                        DataFormat = tc.Name,
                        ColumnGroup = columnGroups != null ? new QueryColumnGroupPayload
                        {
                            Key = columnGroups.Id,
                            Value = columnGroups.GroupName,
                            ContextId = qcc.ContextId
                        }
                        : null
                    };

            var searchColumn = q.FirstOrDefault();
            return searchColumn;
        }

        [HttpGet]
        [Route("usage/{columnKey}")]
        [NoEnrichment]
        public IEnumerable<ColumnUsage> Usage(int columnKey)
        {
            var columnUsages = from qcc in _dbContext.Set<QueryContextColumn>()
                               join qcl in _dbContext.Set<QueryColumn>() on qcc.ColumnId equals qcl.ColumnId
                               join qc in _dbContext.Set<QueryContextModel>() on qcc.ContextId equals qc.Id
                               join qdi in _dbContext.Set<QueryDataItem>() on qcl.DataItemId equals qdi.DataItemId
                               where qcl.ColumnId == columnKey
                               select new ColumnUsage
                               {
                                   SearchType = qc.Name,
                                   ColumnDisplayName = qcl.ColumnLabel
                               };

            return columnUsages.OrderBy(_ => _.SearchType).ToArray();
        }

        [HttpPost]
        [Route("")]
        [NoEnrichment]
        public dynamic Save(SearchColumnSaveDetails saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException(nameof(saveDetails));

            CheckAccess((QueryContext)saveDetails.QueryContextKey);

            var validationErrors = Validate(saveDetails, Operation.Add).ToArray();
            if (!validationErrors.Any())
            {
                using (var tcs = _dbContext.BeginTransaction())
                {
                    var queryColumn = new QueryColumn
                    {
                        ColumnLabel = saveDetails.DisplayName,
                        DataItemId = saveDetails.ColumnName.Key,
                        DocItemId = saveDetails.DocItem?.Key,
                        Description = saveDetails.Description,
                        Qualifier = saveDetails.Parameter
                    };
                    _dbContext.Set<QueryColumn>().Add(queryColumn);
                    _dbContext.SaveChanges();

                    if (saveDetails.IsVisible)
                    {
                        var internalQueryContextColumn = new QueryContextColumn
                        {
                            ContextId = saveDetails.QueryContextKey,
                            ColumnId = queryColumn.ColumnId,
                            GroupId = saveDetails.ColumnGroup?.Key,
                            IsMandatory = saveDetails.IsMandatory
                        };
                        _dbContext.Set<QueryContextColumn>().Add(internalQueryContextColumn);

                        _dbContext.SaveChanges();
                    }

                    tcs.Complete();
                    return new
                    {
                        Result = "success",
                        UpdatedId = queryColumn.ColumnId
                    };
                }
            }

            return validationErrors.AsErrorResponse();
        }

        [HttpPut]
        [Route("{columnId}")]
        [NoEnrichment]
        public dynamic Update(int columnId, SearchColumnSaveDetails saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException(nameof(saveDetails));

            CheckAccess((QueryContext)saveDetails.QueryContextKey);

            var validationErrors = Validate(saveDetails, Operation.Update).ToArray();
            if (!validationErrors.Any())
            {
                using (var tcs = _dbContext.BeginTransaction())
                {
                    var contextId = saveDetails.QueryContextKey;
                    var entityToUpdate = _dbContext.Set<QueryColumn>().Single(_ => _.ColumnId == columnId);
                    entityToUpdate.ColumnLabel = saveDetails.DisplayName;
                    entityToUpdate.DataItemId = saveDetails.ColumnName.Key;
                    entityToUpdate.DocItemId = saveDetails.DocItem?.Key;
                    entityToUpdate.Description = saveDetails.Description;
                    entityToUpdate.Qualifier = saveDetails.Parameter;
                    _dbContext.SaveChanges();

                    var contextToUpdate = _dbContext.Set<QueryContextColumn>()
                                                    .Single(_ => _.ContextId == contextId && _.ColumnId == columnId);
                    if (!saveDetails.IsVisible)
                    {
                        _dbContext.Set<QueryContextColumn>().Remove(contextToUpdate);
                    }
                    else
                    {
                        contextToUpdate.GroupId = saveDetails.ColumnGroup?.Key;
                        contextToUpdate.IsMandatory = saveDetails.IsMandatory;
                    }
                    _dbContext.SaveChanges();

                    tcs.Complete();
                    return new
                    {
                        Result = "success",
                        UpdatedId = entityToUpdate.ColumnId
                    };
                }
            }

            return validationErrors.AsErrorResponse();
        }

        IEnumerable<Infrastructure.Validations.ValidationError> Validate(SearchColumnSaveDetails searchColumn, Operation operation)
        {
            foreach (var validationError in CommonValidations.Validate(searchColumn))
                yield return validationError;

            foreach (var vr in CheckForErrors(searchColumn, operation)) yield return vr;
        }

        IEnumerable<Infrastructure.Validations.ValidationError> CheckForErrors(SearchColumnSaveDetails searchColumn, Operation operation)
        {
            var all = _dbContext.Set<QueryColumn>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.ColumnId != searchColumn.ColumnId))
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            if (searchColumn.ColumnName != null && searchColumn.ColumnName.IsUserDefined && searchColumn.DocItem == null)
                yield return ValidationErrors.Required("dataItem");

            if (searchColumn.ColumnName != null && searchColumn.ColumnName.IsQualifierAvailable
                                                && string.IsNullOrEmpty(searchColumn.Parameter))
                yield return ValidationErrors.Required("parameter");
        }

        [HttpPost]
        [Route("delete")]
        [NoEnrichment]
        public DeleteResponseModel Delete(SearchColumnDeleteRequest deleteRequestModel)
        {
            if (deleteRequestModel == null)
                throw new ArgumentNullException(nameof(deleteRequestModel));

            CheckAccess((QueryContext)deleteRequestModel.ContextId);

            var response = new DeleteResponseModel();
            var columnsToDelete = new List<int>();

            using (var txScope = _dbContext.BeginTransaction())
            {
                var queryContextColumns = _dbContext.Set<QueryContextColumn>().
                                             Where(_ => deleteRequestModel.ContextId == _.ContextId
                                                           && deleteRequestModel.Ids.Contains(_.ColumnId)).ToArray();

                response.InUseIds = new List<int>();

                foreach (var queryContextColumn in queryContextColumns)
                {
                    try
                    {
                        _dbContext.Set<QueryContextColumn>().Remove(queryContextColumn);
                        _dbContext.SaveChanges();
                        columnsToDelete.Add(queryContextColumn.ColumnId);
                    }
                    catch (Exception e)
                    {
                        var sqlException = e.FindInnerException<SqlException>();
                        if (sqlException != null && sqlException.Number == (int)SqlExceptionType.ForeignKeyConstraintViolationsOnDelete)
                        {
                            response.InUseIds.Add(queryContextColumn.ColumnId);
                        }
                        _dbContext.Detach(queryContextColumn);
                    }
                }

                EnsureDeleteQueryColumns(columnsToDelete);
                txScope.Complete();

                if (response.InUseIds.Any())
                {
                    response.HasError = true;
                    response.Message = ConfigurationResources.InUseErrorMessage;
                    return response;
                }
            }
            return response;
        }

        void EnsureDeleteQueryColumns(List<int> columnIds)
        {
            var queryColumns = _dbContext.Set<QueryColumn>()
                                         .Where(_ => columnIds.Contains(_.ColumnId)).ToArray();

            foreach (var queryColumn in queryColumns)
            {
                _dbContext.Set<QueryColumn>().Remove(queryColumn);
                _dbContext.SaveChanges();
            }
        }
    }

    public class SearchColumnQueryContextPermissions
    {
        public int QueryContext { get; set; }
        public QueryContextType QueryContextType { get; set; }
        public bool DisplayForInternal { get; set; }
        public bool CanCreateSearchColumn { get; set; }
        public bool CanUpdateSearchColumn { get; set; }
        public bool CanDeleteSearchColumn { get; set; }
    }

    public class SearchColumn
    {
        public int DataItemId { get; set; }
        public int ContextId { get; set; }
        public string DisplayName { get; set; }
        public string ColumnNameDescription { get; set; }

        public int ColumnId { get; set; }
    }

    public class ColumnUsage
    {
        public string SearchType { get; set; }
        public string ColumnDisplayName { get; set; }
    }

    public class SearchColumnOptions : SearchOptions
    {
        public int QueryContextKey { get; set; }
    }

    public class SearchColumnSaveDetails
    {
        public int? ColumnId { get; set; }
        [Required]
        [MaxLength(50)]
        public string DisplayName { get; set; }
        [Required]
        public SearchColumnNamePayload ColumnName { get; set; }
        [MaxLength(20)]
        public string Parameter { get; set; }
        public DataItem DocItem { get; set; }
        [MaxLength(254)]
        public string Description { get; set; }
        public bool IsMandatory { get; set; }
        public bool IsVisible { get; set; }
        public string DataFormat { get; set; }
        public QueryColumnGroupPayload ColumnGroup { get; set; }
        public int QueryContextKey { get; set; }
    }

    public class SearchColumnDeleteRequest : DeleteRequestModel
    {
        public int ContextId { get; set; }
    }
}