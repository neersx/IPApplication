using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;

namespace InprotechKaizen.Model.Components.Queries
{
    public interface IPresentationColumnsResolver
    {
        IEnumerable<PresentationColumn> Resolve(int? queryKey, QueryContext? queryContextKey, string xmlSelectedColumns = null);
        IEnumerable<PresentationColumn> AvailableColumns(QueryContext queryContextKey);
        IEnumerable<ColumnGroup> AvailableColumnGroups(QueryContext queryContextKey);
    }

    public class PresentationColumnsResolver : IPresentationColumnsResolver
    {
        readonly string _culture;
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly ISubjectSecurityProvider _subjectSecurity;

        public PresentationColumnsResolver(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver,
                                           ISecurityContext securityContext, ISubjectSecurityProvider subjectSecurity)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _securityContext = securityContext ?? throw new ArgumentNullException(nameof(securityContext));
            _culture = preferredCultureResolver.Resolve();
            _subjectSecurity = subjectSecurity;
        }

        public IEnumerable<PresentationColumn> AvailableColumns(QueryContext queryContextKey)
        {
            var formatArray = new[] {(int) KnownColumnFormat.Text, (int) KnownColumnFormat.ImageKey, (int) KnownColumnFormat.Email, (int) KnownColumnFormat.TelecomNumber};

            var queryContextColumns = _dbContext.Set<QueryContextColumn>().Where(_ => _.ContextId == (int) queryContextKey);

            var availableSubjects = _subjectSecurity.AvailableSubjectsFromDb();

            var topics = availableSubjects
                .Join(_dbContext.Set<TopicDataItems>(), s => s.TopicId, tdi => tdi.TopicId, (s, tdi) => (int?) tdi.DataItemId);

            var r = from qcc in queryContextColumns
                    join qc in _dbContext.Set<QueryColumn>() on qcc.ColumnId equals qc.ColumnId
                    join qdi in _dbContext.Set<QueryDataItem>() on qc.DataItemId equals qdi.DataItemId
                    join t in topics on qdi.DataItemId equals t into topic
                    from tdi in topic.DefaultIfEmpty()
                    join td in _dbContext.Set<TopicDataItems>() on qdi.DataItemId equals td.DataItemId into topicData
                    from tds in topicData.DefaultIfEmpty()
                    where tdi == qdi.DataItemId || tds == null
                    select new PresentationColumn
                    {
                        GroupKey = qcc.Group != null ? (int?) qcc.Group.Id : null,
                        GroupName = qcc.Group != null ? DbFuncs.GetTranslation(qcc.Group.GroupName, null, qcc.Group.GroupNameTId, _culture) : null,
                        ColumnKey = qcc.ColumnId,
                        ColumnLabel = DbFuncs.GetTranslation(qc.ColumnLabel, null, qc.ColumnLabelTid, _culture),
                        Description = DbFuncs.GetTranslation(qc.Description, null, qc.DescriptionTid, _culture),
                        IsDisplayMandatory = qcc.IsMandatory && qcc.IsSortOnly,
                        IsDisplayable = !qcc.IsSortOnly,
                        SortDirection = qdi.SortDirection,
                        IsGroupable = !formatArray.Contains(qdi.DataFormatId),
                        Qualifier = qc.Qualifier,
                        ProcedureItemId = qdi.ProcedureItemId,
                        IsMandatory = qcc.IsMandatory
                    };

            var availableColumns = r.ToArray();
            var qualifierExists = availableColumns.Any(pc => pc.Qualifier != null);
            var results = qualifierExists ? ApplySecurity(availableColumns) : availableColumns;

            return results.OrderBy(_ => _.ColumnLabel);
        }

        public IEnumerable<ColumnGroup> AvailableColumnGroups(QueryContext queryContextKey)
        {
            var validGroupIds = _dbContext.Set<QueryContextColumn>()
                                          .Where(_ => _.GroupId != null && _.ContextId == (int) queryContextKey)
                                          .Select(_ => _.GroupId).Distinct();

            return _dbContext.Set<QueryColumnGroup>().Where(_ => _.ContextId == (int) queryContextKey && validGroupIds.Contains(_.Id))
                             .Select(_ => new ColumnGroup
                             {
                                 GroupKey = _.Id,
                                 GroupName = DbFuncs.GetTranslation(_.GroupName, null, _.GroupNameTId, _culture)
                             }).OrderBy(_ => _.GroupName).ToArray();
        }

        public IEnumerable<PresentationColumn> Resolve(int? queryKey, QueryContext? queryContextKey, string xmlSelectedColumns = null)
        {
            IEnumerable<PresentationColumn> presentationColumns;

            var availableSubjects = _subjectSecurity.AvailableSubjectsFromDb();

            var topics = availableSubjects
                .Join(_dbContext.Set<TopicDataItems>(), s => s.TopicId, tdi => tdi.TopicId, (s, tdi) => (int?) tdi.DataItemId);

            if (queryKey.HasValue
                && _dbContext.Set<Query>().SingleOrDefault(q => q.Id == queryKey && q.PresentationId != null) != null)
            {
                // Extract presentation from saved query
                var r = from q in _dbContext.Set<Query>()
                        join qp in _dbContext.Set<QueryPresentation>() on q.PresentationId equals qp.Id
                        join qc in _dbContext.Set<QueryContent>() on qp.Id equals qc.PresentationId
                        join qcl in _dbContext.Set<QueryColumn>() on qc.ColumnId equals qcl.ColumnId
                        join qdi in _dbContext.Set<QueryDataItem>() on qcl.DataItemId equals qdi.DataItemId
                        join qcc in _dbContext.Set<QueryContextColumn>() on new {qcl.ColumnId, qp.ContextId} equals new {qcc.ColumnId, qcc.ContextId}
                        join tc in _dbContext.Set<TableCode>() on qdi.DataItemId equals tc.Id into tmpTableCodes
                        from tableCodes in tmpTableCodes.DefaultIfEmpty()
                        join t in topics on qdi.DataItemId equals t into topic
                        from tdi in topic.DefaultIfEmpty()
                        join td in _dbContext.Set<TopicDataItems>() on qdi.DataItemId equals td.DataItemId into topicData
                        from tds in topicData.DefaultIfEmpty()
                        where q.Id == queryKey && (tdi == qdi.DataItemId || tds == null)
                        select new PresentationColumn
                        {
                            ColumnKey = qc.ColumnId,
                            DisplaySequence = qc.DisplaySequence,
                            SortOrder = qc.SortOrder,
                            SortDirection = qc.SortDirection,
                            GroupBySortOrder = qc.GroupBySequence,
                            GroupBySortDirection = qc.GroupBySortDir,
                            IsFreezeColumnIndex = qc.ColumnId == qp.FreezeColumnId,
                            ProcedureItemId = qdi.ProcedureItemId,
                            Qualifier = qcl.Qualifier,
                            PublishName = qcc.Usage,
                            Format = tableCodes != null ? DbFuncs.GetTranslation(tableCodes.Name, null, tableCodes.NameTId, _culture) : null,
                            ColumnLabel = DbFuncs.GetTranslation(qcl.ColumnLabel, null, qcl.ColumnLabelTid, _culture),
                            Description = DbFuncs.GetTranslation(qcl.Description, null, qcl.DescriptionTid, _culture),
                            DecimalPlaces = qdi.DecimalPlaces,
                            FormatItemId = qdi.FormatItemId,
                            DataItemKey = qdi.DataItemId,
                            DocItemKey = qcl.DocItemId,
                            ProcedureName = qdi.ProcedureName,
                            GroupKey = qcc.GroupId,
                            IsMandatory = qcc.IsMandatory,
                            IsDefault = false
                        };

                presentationColumns = r;
            }
            // Use the default presentation
            else
            {
                // check for users default presentation
                var r = _dbContext.Set<QueryPresentation>().Where(qp => qp.ContextId == (int) queryContextKey
                                                                        && qp.IsDefault
                                                                        && qp.PresentationType == null
                                                                        && qp.IdentityId == _securityContext.User.Id);

                if (!r.Any())
                {
                    // default to global default presentation
                    r = _dbContext.Set<QueryPresentation>().Where(qp => qp.ContextId == (int) queryContextKey
                                                                        && qp.IsDefault
                                                                        && qp.PresentationType == null
                                                                        && qp.IdentityId == null);
                }

                var result = from qp in r
                             join qc in _dbContext.Set<QueryContent>() on qp.Id equals qc.PresentationId
                             join qcl in _dbContext.Set<QueryColumn>() on qc.ColumnId equals qcl.ColumnId
                             join qdi in _dbContext.Set<QueryDataItem>() on qcl.DataItemId equals qdi.DataItemId
                             join qcc in _dbContext.Set<QueryContextColumn>() on new {qcl.ColumnId, qp.ContextId} equals new {qcc.ColumnId, qcc.ContextId}
                             join tc in _dbContext.Set<TableCode>() on qdi.DataItemId equals tc.Id into tmpTableCodes
                             from tableCodes in tmpTableCodes.DefaultIfEmpty()
                             join t in topics on qdi.DataItemId equals t into topic
                             from tdi in topic.DefaultIfEmpty()
                             join td in _dbContext.Set<TopicDataItems>() on qdi.DataItemId equals td.DataItemId into topicData
                             from tds in topicData.DefaultIfEmpty()
                             where tdi == qdi.DataItemId || tds == null
                             select new PresentationColumn
                             {
                                 ColumnKey = qc.ColumnId,
                                 DisplaySequence = qc.DisplaySequence,
                                 SortOrder = qc.SortOrder,
                                 SortDirection = qc.SortDirection,
                                 GroupBySortOrder = qc.GroupBySequence,
                                 GroupBySortDirection = qc.GroupBySortDir,
                                 IsFreezeColumnIndex = qc.ColumnId == qp.FreezeColumnId,
                                 ProcedureItemId = qdi.ProcedureItemId,
                                 Qualifier = qcl.Qualifier,
                                 PublishName = qcc.Usage,
                                 Format = tableCodes != null ? DbFuncs.GetTranslation(tableCodes.Name, null, tableCodes.NameTId, _culture) : null,
                                 ColumnLabel = DbFuncs.GetTranslation(qcl.ColumnLabel, null, qcl.ColumnLabelTid, _culture),
                                 Description = DbFuncs.GetTranslation(qcl.Description, null, qcl.DescriptionTid, _culture),
                                 DecimalPlaces = qdi.DecimalPlaces,
                                 FormatItemId = qdi.FormatItemId,
                                 DataItemKey = qdi.DataItemId,
                                 DocItemKey = qcl.DocItemId,
                                 ProcedureName = qdi.ProcedureName,
                                 GroupKey = qcc.GroupId,
                                 IsMandatory = qcc.IsMandatory,
                                 IsDefault = true
                             };

                presentationColumns = result;
            }

            var enumerable = presentationColumns as PresentationColumn[] ?? presentationColumns.ToArray();

            var qualifierExists = enumerable.Any(pc => pc.Qualifier != null);
            return qualifierExists ? ApplySecurity(enumerable) : enumerable.ToArray();
        }

        IEnumerable<PresentationColumn> ApplySecurity(IEnumerable<PresentationColumn> presentationColumns)
        {
            // If qualifiers are present, subset security needs to be applied to ensure
            // that the user has access to the qualifier
            presentationColumns = presentationColumns
                                  .FilterByQualifier(QualifierType.UserTextTypes, _dbContext, _securityContext, _culture)
                                  .FilterByQualifier(QualifierType.UserNameTypes, _dbContext, _securityContext, _culture)
                                  .FilterByQualifier(QualifierType.UserNumberTypes, _dbContext, _securityContext, _culture)
                                  .FilterByQualifier(QualifierType.UserAliasTypes, _dbContext, _securityContext, _culture);

            if (!_securityContext.User.IsExternalUser) return presentationColumns;

            presentationColumns = presentationColumns
                                  .FilterByQualifier(QualifierType.UserEvents, _dbContext, _securityContext, _culture)
                                  .FilterByQualifier(QualifierType.UserInstructionTypes, _dbContext, _securityContext, _culture);

            return presentationColumns;
        }
    }

    public static class PresentationColumnResolver
    {
        public static IEnumerable<PresentationColumn> FilterByQualifier(this IEnumerable<PresentationColumn> presentationColumns,
                                                                        QualifierType qualifierType,
                                                                        IDbContext dbContext,
                                                                        ISecurityContext securityContext,
                                                                        string culture)
        {
            var qType = (int) qualifierType;

            var filterQualifier = presentationColumns.ToList();
            var r = filterQualifier.Join(dbContext.Set<QueryDataItem>(),
                                         pc => pc.DataItemKey, qdi => qdi.DataItemId, (pc, qdi) => new {pc, qdi})
                                   .Where(_ => _.pc.Qualifier != null && _.qdi.QualifierType == qType)
                                   .Select(_ => _.pc).ToArray();

            if (!r.Any()) return filterQualifier;

            var rowsToRemove = Enumerable.Empty<PresentationColumn>();
            switch (qualifierType)
            {
                case QualifierType.UserTextTypes:
                    var userTextTypes = dbContext.FilterUserTextTypes(securityContext.User.Id,
                                                                      culture, securityContext.User.IsExternalUser,
                                                                      false).Select(_ => _.TextType).ToArray();

                    rowsToRemove = r.Where(_ => !userTextTypes.Contains(_.Qualifier));
                    break;
                case QualifierType.UserNameTypes:
                    var userNameTypes = dbContext.FilterUserNameTypes(securityContext.User.Id,
                                                                      culture, securityContext.User.IsExternalUser,
                                                                      false).Select(_ => _.NameType).ToArray();

                    rowsToRemove = r.Where(_ => !userNameTypes.Contains(_.Qualifier));
                    break;
                case QualifierType.UserNumberTypes:
                    var userNumberTypes = dbContext.FilterUserNumberTypes(securityContext.User.Id,
                                                                          culture, securityContext.User.IsExternalUser,
                                                                          false).Select(_ => _.NumberType);

                    rowsToRemove = r.Where(pc => !userNumberTypes.Contains(pc.Qualifier));
                    break;
                case QualifierType.UserAliasTypes:
                    var userAliasTypes = dbContext.FilterUserAliasTypes(securityContext.User.Id,
                                                                        culture, securityContext.User.IsExternalUser,
                                                                        false).Select(_ => _.AliasType);

                    rowsToRemove = r.Where(pc => !userAliasTypes.Contains(pc.Qualifier));
                    break;
                case QualifierType.UserEvents:
                    var userEvents = dbContext.FilterUserEvents(securityContext.User.Id,
                                                                culture, securityContext.User.IsExternalUser).ToArray().Select(_ => _.EventNo.ToString());

                    rowsToRemove = r.Where(pc => !userEvents.Contains(pc.Qualifier));
                    break;
                case QualifierType.UserInstructionTypes:
                    var userInstructionTypes = dbContext.FilterUserInstructionTypes(securityContext.User.Id,
                                                                                    culture, securityContext.User.IsExternalUser).Select(_ => _.InstructionType);

                    rowsToRemove = r.Where(pc => !userInstructionTypes.Contains(pc.Qualifier));
                    break;
            }

            foreach (var pc in rowsToRemove) filterQualifier.Remove(pc);

            return filterQualifier;
        }
    }

    public class PresentationColumn
    {
        public int? GroupKey { get; set; }
        public string GroupName { get; set; }
        public int ColumnKey { get; set; }
        public short? DisplaySequence { get; set; }
        public short? SortOrder { get; set; }
        public string SortDirection { get; set; }
        public short? GroupBySortOrder { get; set; }
        public string GroupBySortDirection { get; set; }
        public bool IsFreezeColumnIndex { get; set; }
        public string ProcedureItemId { get; set; }
        public string Qualifier { get; set; }
        public string PublishName { get; set; }
        public string ColumnLabel { get; set; }
        public string Format { get; set; }
        public byte? DecimalPlaces { get; set; }
        public string FormatItemId { get; set; }
        public int DataItemKey { get; set; }
        public int? DocItemKey { get; set; }
        public string ProcedureName { get; set; }
        public string Description { get; set; }
        public bool IsDisplayMandatory { get; set; }
        public bool IsDisplayable { get; set; }
        public bool IsGroupable { get; set; }
        public bool IsDefault { get; set; }
        public bool IsMandatory { get; set; }
    }

    public class ColumnGroup
    {
        public int GroupKey { get; set; }

        public string GroupName { get; set; }
    }
}