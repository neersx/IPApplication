using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;

namespace Inprotech.Web.Search
{
    public interface ISavedSearchService
    {
        dynamic SaveSearch<T>(FilteredSavedSearch<T> saveSearch) where T : SearchRequestFilter;
        dynamic SaveAsSearch<T>(int fromQueryKey, FilteredSavedSearch<T> saveSearch) where T : SearchRequestFilter;
        dynamic Update<T>(int? queryKey, FilteredSavedSearch<T> savedSearch, bool updateDetails = false) where T : SearchRequestFilter;
        SavedSearch Get(int queryKey);
        bool RevertToDefault(QueryContext contextId);
        bool MakeMyDefaultPresentation(SavedSearch savedSearch);
        dynamic DeleteSavedSearch(int presentationId);
    }

    public class SavedSearchService : ISavedSearchService
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;
        readonly IXmlFilterCriteriaBuilderResolver _xmlFilterCriteriaBuilder;

        public SavedSearchService(IDbContext dbContext,
                                  ISecurityContext securityContext,
                                  IPreferredCultureResolver preferredCultureResolver,
                                  IXmlFilterCriteriaBuilderResolver xmlFilterCriteriaBuilder)
        {
            _securityContext = securityContext;
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _xmlFilterCriteriaBuilder = xmlFilterCriteriaBuilder;
        }

        public SavedSearch Get(int queryKey)
        {
            var culture = _preferredCultureResolver.Resolve();

            var savedSearch = _dbContext.Set<Query>().Select(_ => new SavedSearch
            {
                Id = _.Id,
                SearchName = _.Name,
                Description = _.Description,
                GroupKey = _.GroupId,
                GroupName = _.Group != null ? DbFuncs.GetTranslation(_.Group.GroupName, null, _.Group.GroupName_Tid, culture) : null,
                IsPublic = _.IdentityId == null
            }).SingleOrDefault(_ => _.Id == queryKey);

            if (savedSearch == null)
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            return savedSearch;
        }

        public dynamic SaveSearch<T>(FilteredSavedSearch<T> savedSearch) where T : SearchRequestFilter
        {
            if (savedSearch == null || string.IsNullOrEmpty(savedSearch.SearchName))
            {
                throw new ArgumentException(nameof(savedSearch));
            }

            if (NameExists(savedSearch))
            {
                return new
                {
                    Success = false,
                    Error = "duplicate"
                };
            }

            BuildXmlFilter(savedSearch);

            var accessAccountId = savedSearch.IsPublic && _securityContext.User.IsExternalUser ? _securityContext.User.AccessAccount.Id : (int?)null;
            var isDefault = savedSearch.SelectedColumns == null || !savedSearch.SelectedColumns.Any();

            using (var ts = _dbContext.BeginTransaction())
            {
                var queryFilter = InsertFilter(savedSearch);

                int? queryPresentationId = null;

                if (!isDefault)
                {
                    queryPresentationId = InsertPresentation(savedSearch, accessAccountId);
                    InsertSelectedColumns(queryPresentationId.Value, savedSearch);
                }

                var query = new Query
                {
                    ContextId = (int) savedSearch.QueryContext,
                    IdentityId = savedSearch.IsPublic ? null : _securityContext.User.Id,
                    Name = savedSearch.SearchName,
                    GroupId = savedSearch.GroupKey,
                    Description = savedSearch.Description ?? string.Empty,
                    AccessAccountId = accessAccountId,
                    FilterId = queryFilter.Id,
                    PresentationId = queryPresentationId
                };

                _dbContext.Set<Query>().Add(query);
                _dbContext.SaveChanges();

                ts.Complete();

                return new
                {
                    Success = true,
                    QueryKey = query.Id
                };
            }
        }

        public dynamic SaveAsSearch<T>(int fromQueryKey, FilteredSavedSearch<T> saveSearch) where T : SearchRequestFilter
        {
            if (saveSearch == null) throw new ArgumentNullException(nameof(saveSearch));
            if (saveSearch.SearchFilter != null)
            {
                BuildXmlFilter(saveSearch);
            }
            if (string.IsNullOrEmpty(saveSearch.XmlFilter))
            {
                EnsureFilterCriteria(fromQueryKey, saveSearch);
            }

            var saveSearchResponse = SaveSearch(saveSearch);
            if (!saveSearchResponse.Success) return saveSearchResponse;

            if (!saveSearch.UpdatePresentation)
            {
                var fromSavedQuery = _dbContext.Set<Query>().Single(_ => _.Id == fromQueryKey);
                if (fromSavedQuery.PresentationId != null)
                {
                    using (var ts = _dbContext.BeginTransaction())
                    {
                        var fromPresentation = _dbContext.Set<QueryPresentation>()
                                                         .Single(_ => _.Id == fromSavedQuery.PresentationId);

                        var toPresentation = new QueryPresentation
                        {
                            ContextId = fromPresentation.ContextId,
                            IdentityId = saveSearch.IsPublic ? null : _securityContext.User.Id,
                            IsDefault = false,
                            AccessAccountId = saveSearch.IsPublic && _securityContext.User.IsExternalUser ? _securityContext.User.AccessAccount.Id : null,
                            FreezeColumnId = fromPresentation.FreezeColumnId
                        };

                        _dbContext.Set<QueryPresentation>().Add(toPresentation);
                        _dbContext.SaveChanges();

                        var toQueryKey = (int)saveSearchResponse.QueryKey;
                        var toQuery = _dbContext.Set<Query>().Single(_ => _.Id == toQueryKey);
                        toQuery.PresentationId = toPresentation.Id;

                        var fromQueryContents = _dbContext.Set<QueryContent>()
                                                          .Where(_ => _.PresentationId == fromSavedQuery.PresentationId).ToArray();

                        foreach (var fromQueryContent in fromQueryContents)
                        {
                            _dbContext.Set<QueryContent>().Add(new QueryContent
                            {
                                ColumnId = fromQueryContent.ColumnId,
                                PresentationId = toPresentation.Id,
                                DisplaySequence = fromQueryContent.DisplaySequence,
                                SortOrder = fromQueryContent.SortOrder,
                                SortDirection = fromQueryContent.SortDirection,
                                GroupBySortDir = string.IsNullOrEmpty(fromQueryContent.GroupBySortDir) ? null : fromQueryContent.GroupBySortDir,
                                GroupBySequence = fromQueryContent.GroupBySequence,
                                ContextId = fromQueryContent.ContextId
                            });
                        }

                        _dbContext.SaveChanges();

                        ts.Complete();
                    }
                }
            }

            return saveSearchResponse;
        }

        public dynamic Update<T>(int? queryKey, FilteredSavedSearch<T> savedSearch, bool updateDetails = false) where T : SearchRequestFilter
        {
            if (savedSearch == null) throw new ArgumentNullException(nameof(savedSearch));

            if (updateDetails && NameExists(savedSearch, queryKey))
            {
                return new
                {
                    Success = false,
                    Error = "duplicate"
                };
            }

            var savedQuery = _dbContext.Set<Query>().FirstOrDefault(_ => _.Id == queryKey);

            if (savedQuery == null) throw new HttpResponseException(HttpStatusCode.NotFound);
            if (savedSearch.SearchFilter != null)
            {
                BuildXmlFilter(savedSearch);
            }

            using var ts = _dbContext.BeginTransaction();
            UpdatePresentation(savedSearch, savedQuery);

            if (updateDetails)
            {
                savedQuery.IdentityId = savedSearch.IsPublic ? (int?)null : _securityContext.User.Id;
                savedQuery.Name = savedSearch.SearchName;
                savedQuery.GroupId = savedSearch.GroupKey;
                savedQuery.Description = savedSearch.Description ?? string.Empty;
            }

            if (savedSearch.XmlFilter != null)
            {
                var queryFilter = _dbContext.Set<QueryFilter>().First(_ => _.Id == savedQuery.FilterId);
                queryFilter.XmlFilterCriteria = savedSearch.XmlFilter;
            }

            _dbContext.SaveChanges();

            ts.Complete();

            return new
            {
                Success = true
            };
        }

        public bool MakeMyDefaultPresentation(SavedSearch savedSearch)
        {
            if (savedSearch == null) throw new ArgumentException(nameof(savedSearch));

            var accessAccountId = savedSearch.IsPublic && _securityContext.User.IsExternalUser ? _securityContext.User.AccessAccount.Id : (int?)null;

            using (var ts = _dbContext.BeginTransaction())
            {
                RevertToDefault(savedSearch.QueryContext);

                int? queryPresentationId = InsertPresentation(savedSearch, accessAccountId, true);
                InsertSelectedColumns(queryPresentationId.Value, savedSearch);

                _dbContext.SaveChanges();
                ts.Complete();

                return true;
            }
        }

        public dynamic DeleteSavedSearch(int queryKey)
        {
            var savedQuery = _dbContext.Set<Query>().FirstOrDefault(_ => _.Id == queryKey);
            if (savedQuery == null)
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }
            if (savedQuery.ContextId == (int)QueryContext.TaskPlanner && (savedQuery.Id == (int)QueryKeys.MyReminders || savedQuery.Id == (int)QueryKeys.MyDue || savedQuery.Id == (int)QueryKeys.MyTeamsTasks))
            {
                return false;
            }
            if (savedQuery.PresentationId.HasValue)
            {
                var columnsToRemove = _dbContext.Set<QueryContent>().Where(_ => _.PresentationId == savedQuery.PresentationId);
                _dbContext.RemoveRange(columnsToRemove);
                _dbContext.Delete(_dbContext.Set<QueryPresentation>().Where(_ => _.Id == savedQuery.PresentationId));
            }

            _dbContext.Delete(_dbContext.Set<Query>().Where(_ => _.Id == queryKey));
            _dbContext.Delete(_dbContext.Set<QueryFilter>().Where(_ => _.Id == savedQuery.FilterId));
            _dbContext.SaveChanges();
            return true;
        }

        public bool RevertToDefault(QueryContext contextId)
        {
            var presentation = _dbContext.Set<QueryPresentation>()
                                         .FirstOrDefault(_ => _.ContextId == (int)contextId
                                                              && _.IsDefault
                                                              && _.IdentityId == _securityContext.User.Id);

            if (presentation != null)
            {
                var contentsToRemove = _dbContext.Set<QueryContent>().Where(_ => _.PresentationId == presentation.Id);
                _dbContext.RemoveRange(contentsToRemove);

                _dbContext.Set<QueryPresentation>().Remove(presentation);
                _dbContext.SaveChanges();
            }

            return true;
        }

        void EnsureFilterCriteria(int fromQueryKey, SavedSearch saveSearch)
        {
            var query = _dbContext.Set<Query>().Single(_ => _.Id == fromQueryKey);
            var queryFilter = _dbContext.Set<QueryFilter>().Single(_ => _.Id == query.FilterId);
            saveSearch.XmlFilter = queryFilter.XmlFilterCriteria;
        }

        void UpdatePresentation(SavedSearch savedSearch, Query savedQuery)
        {
            if (!savedSearch.UpdatePresentation)
            {
                return;
            }

            if (savedQuery.PresentationId == null)
            {
                if (savedSearch.SelectedColumns == null || !savedSearch.SelectedColumns.Any()) return;

                var queryPresentationId = InsertPresentation(savedSearch, savedQuery.AccessAccountId);
                InsertSelectedColumns(queryPresentationId, savedSearch);
                savedQuery.PresentationId = queryPresentationId;

                return;
            }

            if (savedSearch.SelectedColumns != null && savedSearch.SelectedColumns.Any())
            {
                var columnsToRemove = _dbContext.Set<QueryContent>().Where(_ => _.PresentationId == savedQuery.PresentationId);
                _dbContext.RemoveRange(columnsToRemove);

                var freezeColumnId = savedSearch.SelectedColumns.SingleOrDefault(_ => _.IsFreezeColumnIndex)?.ColumnKey;
                var queryPresentation = _dbContext.Set<QueryPresentation>()
                                                  .Single(_ => _.Id.Equals(savedQuery.PresentationId.Value));
                queryPresentation.FreezeColumnId = freezeColumnId;

                InsertSelectedColumns(savedQuery.PresentationId.Value, savedSearch);
            }
            else
            {
                var columnsToRemove = _dbContext.Set<QueryContent>().Where(_ => _.PresentationId == savedQuery.PresentationId);
                _dbContext.RemoveRange(columnsToRemove);
                _dbContext.Delete(_dbContext.Set<QueryPresentation>().Where(_ => _.Id == savedQuery.PresentationId));
                savedQuery.PresentationId = null;
            }
        }

        QueryFilter InsertFilter(SavedSearch savedSearch)
        {
            var procedureName = _dbContext.Set<QueryContextModel>()
                                          .Where(_ => _.Id == (int)savedSearch.QueryContext)
                                          .Select(_ => _.ProcedureName)
                                          .Single();

            var queryFilter = new QueryFilter
            {
                ProcedureName = procedureName,
                XmlFilterCriteria = savedSearch.XmlFilter
            };
            _dbContext.Set<QueryFilter>().Add(queryFilter);
            _dbContext.SaveChanges();

            return queryFilter;
        }

        int InsertPresentation(SavedSearch savedSearch, int? accessAccountId, bool isDefault = false)
        {
            var freezeColumnId = savedSearch.SelectedColumns.SingleOrDefault(_ => _.IsFreezeColumnIndex)?.ColumnKey;

            var queryPresentation = new QueryPresentation
            {
                ContextId = (int)savedSearch.QueryContext,
                IdentityId = savedSearch.IsPublic ? null : _securityContext.User.Id,
                IsDefault = isDefault,
                AccessAccountId = accessAccountId,
                FreezeColumnId = freezeColumnId
            };

            _dbContext.Set<QueryPresentation>().Add(queryPresentation);
            _dbContext.SaveChanges();
            return queryPresentation.Id;
        }

        void InsertSelectedColumns(int presentationId, SavedSearch savedSearch)
        {
            foreach (var selectedColumn in savedSearch.SelectedColumns)
            {
                var queryContent = new QueryContent
                {
                    ColumnId = selectedColumn.ColumnKey,
                    PresentationId = presentationId,
                    DisplaySequence = (short?)selectedColumn.DisplaySequence,
                    SortOrder = (short?)selectedColumn.SortOrder,
                    SortDirection = selectedColumn.SortDirection,
                    ContextId = (int)savedSearch.QueryContext,
                    GroupBySequence = (short?)selectedColumn.GroupBySortOrder,
                    GroupBySortDir = string.IsNullOrEmpty(selectedColumn.GroupBySortDirection) ? null : selectedColumn.GroupBySortDirection

                };
                _dbContext.Set<QueryContent>().Add(queryContent);
            }

            _dbContext.SaveChanges();
        }

        public bool NameExists(SavedSearch savedSearch, int? queryKey = null)
        {
            var nameExists = _dbContext.Set<Query>().Where(_ => _.Name.Equals(savedSearch.SearchName)
                                                                && _.ContextId == (int)savedSearch.QueryContext
                                                                && (_.IdentityId == null && savedSearch.IsPublic || _.IdentityId == _securityContext.User.Id && !savedSearch.IsPublic));

            if (queryKey.HasValue)
            {
                nameExists = nameExists.Where(_ => _.Id != queryKey);
            }

            return nameExists.Any();
        }

        void BuildXmlFilter<T>(FilteredSavedSearch<T> filteredSavedSearch) where T : SearchRequestFilter
        {
            if (!string.IsNullOrWhiteSpace(filteredSavedSearch.XmlFilter))
            {
                return;
            }

            var xmlFilterCriteriaBuilder = _xmlFilterCriteriaBuilder.Resolve(filteredSavedSearch.QueryContext);

            filteredSavedSearch.XmlFilter = xmlFilterCriteriaBuilder.Build(filteredSavedSearch.SearchFilter, new CommonQueryParameters(), new FilterableColumnsMapResolver.DefaultFilterableColumnMap());
        }
    }

    public class SavedSearch
    {
        public int? Id { get; set; }
        public QueryContext QueryContext { get; set; }
        public string SearchName { get; set; }
        public bool IsPublic { get; set; }
        public string Description { get; set; }
        public int? GroupKey { get; set; }
        public string GroupName { get; set; }
        public bool UpdatePresentation { get; set; }
        public IEnumerable<SelectedColumn> SelectedColumns { get; set; }
        public string XmlFilter { get; set; }
        public string ProcedureName { get; set; }
    }

    public class FilteredSavedSearch<T> : SavedSearch
    {
        public T SearchFilter { get; set; }
    }
    enum QueryKeys
    {
        MyReminders = -31,
        MyDue = -29,
        MyTeamsTasks = -28
    }
}