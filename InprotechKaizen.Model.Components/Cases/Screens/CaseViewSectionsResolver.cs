using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json;

namespace InprotechKaizen.Model.Components.Cases.Screens
{
    public interface ICaseViewFieldMapper
    {
        IEnumerable<ControllableField> Map(IEnumerable<ControllableField> fields);
    }

    public interface ICaseViewSectionsResolver
    {
        Task<CaseViewSections> Resolve(int caseId, string programId = null, string name = KnownCaseScreenWindowNames.CaseDetails);

        Task<IEnumerable<CaseViewSection>> ResolveSections(int screenCriteriaId);
    }

    public class CaseViewSectionsResolver : ICaseViewSectionsResolver
    {
        static readonly Dictionary<string, string> FriendlyNameMap = new Dictionary<string, string>
        {
            {KnownCaseScreenTopics.EventsDueHeader, "due"},
            {KnownCaseScreenTopics.EventsOccurredHeader, "occurred"}
        };

        static readonly Dictionary<string, (string WindowName, string[] TopicNames)> SubSections = new Dictionary<string, (string, string[])>
        {
            {KnownCaseScreenTopics.Events, (KnownCaseScreenWindowNames.CaseEvents, new[] {KnownCaseScreenTopics.EventsDueHeader, KnownCaseScreenTopics.EventsOccurredHeader})}
        };

        readonly ICaseViewFieldMapper _caseViewFieldMapper;
        readonly ISubjectSecurityProvider _subjectSecurity;
        readonly ICriteriaReader _criteriaReader;
        readonly string _culture;
        readonly IDbContext _dbContext;

        readonly string[] _knownCombinedFilterNames = { "TextTypeKey", "NameTypeKey", "CustomContentUrl", "LoadImmediately", "ParentAccessAllowed", "ItemKey" };

        readonly ISecurityContext _securityContext;

        public CaseViewSectionsResolver(
            IDbContext dbContext,
            ICriteriaReader criteriaReader,
            ISecurityContext securityContext,
            IPreferredCultureResolver preferredCultureResolver,
            ICaseViewFieldMapper caseViewFieldMapper,
            ISubjectSecurityProvider subjectSecurity)
        {
            _dbContext = dbContext;
            _criteriaReader = criteriaReader;
            _securityContext = securityContext;
            _caseViewFieldMapper = caseViewFieldMapper;
            _subjectSecurity = subjectSecurity;
            _culture = preferredCultureResolver.Resolve();
        }

        public async Task<CaseViewSections> Resolve(int caseId, string programId = null, string name = KnownCaseScreenWindowNames.CaseDetails)
        {
            var result = new CaseViewSections { ProgramId = programId ?? ResolveProgramId() };

            if (!_criteriaReader.TryGetScreenCriteriaId(caseId, result.ProgramId, out var screenCriteriaId))
            {
                return result;
            }

            var windowName = name ?? KnownCaseScreenWindowNames.CaseDetails;

            var summarySection = await ResolveSummarySection(screenCriteriaId, windowName);

            var otherSections = (from t in await ResolveSections(screenCriteriaId, windowName)
                                 where !KnownCaseScreenTopics.CaseHeaderSummary.Contains(t.TopicRawName)
                                 select new CaseViewSection
                                 {
                                     TopicName = t.TopicBaseName,
                                     Title = t.Title,
                                     Suffix = t.TopicSuffix,
                                     Filters = t.Filters,
                                     Ref = t.Ref
                                 }).ToArray();

            foreach (var subTopic in otherSections.Where(_ => SubSections.ContainsKey(_.TopicName)))
            {
                var metadata = SubSections[subTopic.TopicName];

                var innerSections = await GetSections(screenCriteriaId, metadata.WindowName, metadata.TopicNames);

                subTopic.SubTopics = (from i in innerSections
                                      join r in metadata.TopicNames on i.TopicRawName equals r
                                      select new CaseViewSection
                                      {
                                          TopicName = FriendlyNameMap.Get(i.TopicRawName) ?? i.TopicRawName,
                                          Title = i.Title,
                                          Suffix = i.TopicSuffix
                                      }).ToArray();
            }

            result.ScreenCriterion = screenCriteriaId;

            if (summarySection != null) result.Sections.Add(summarySection);

            result.Sections.AddRange(otherSections);

            return result;
        }

        public async Task<IEnumerable<CaseViewSection>> ResolveSections(int screenCriteriaId)
        {
            var otherSections = (from t in await ResolveSections(screenCriteriaId, KnownCaseScreenWindowNames.CaseDetails)
                                 where !KnownCaseScreenTopics.CaseHeaderSummary.Contains(t.TopicRawName)
                                 select new CaseViewSection
                                 {
                                     TopicName = t.TopicBaseName,
                                     Title = t.Title,
                                     Suffix = t.TopicSuffix,
                                     Filters = t.Filters,
                                     Ref = t.Ref
                                 }).ToArray();

            foreach (var subTopic in otherSections.Where(_ => SubSections.ContainsKey(_.TopicName)))
            {
                var metadata = SubSections[subTopic.TopicName];

                var innerSections = await GetSections(screenCriteriaId, metadata.WindowName, metadata.TopicNames);

                subTopic.SubTopics = (from i in innerSections
                                      join r in metadata.TopicNames on i.TopicRawName equals r
                                      select new CaseViewSection
                                      {
                                          TopicName = FriendlyNameMap.Get(i.TopicRawName) ?? i.TopicRawName,
                                          Title = i.Title,
                                          Suffix = i.TopicSuffix
                                      }).ToArray();
            }

            return otherSections;
        }

        async Task<CaseViewSection> ResolveSummarySection(int? screenCriteriaId, string windowName)
        {
            var summarySectionFields = await (from r in
                                                  from ec in _dbContext.Set<ElementControl>()
                                                  join tc in _dbContext.Set<TopicControl>() on ec.TopicControlId equals tc.Id into tc1
                                                  from tc in tc1
                                                  where tc.WindowControl.CriteriaId == screenCriteriaId
                                                        && tc.WindowControl.Name == windowName
                                                        && KnownCaseScreenTopics.CaseHeaderSummary.Contains(tc.Name)
                                                  select new
                                                  {
                                                      TopicName = tc.Name,
                                                      Field = new ControllableField
                                                      {
                                                          FieldName = ec.ElementName,
                                                          Label = ec.FullLabel,
                                                          Hidden = ec.IsHidden
                                                      }
                                                  }
                                              group r by r.TopicName
                                              into r1
                                              select new
                                              {
                                                  TopicName = r1.Key,
                                                  Fields = r1.Select(_ => _.Field)
                                              }).ToDictionaryAsync(k => k.TopicName, v => v.Fields);

            var mappedFields = new List<ControllableField>();

            if (summarySectionFields.TryGetValue(KnownCaseScreenTopics.CaseHeader, out var headerFields))
            {
                var h = headerFields.ToArray();
                if (h.Any()) mappedFields.AddRange(_caseViewFieldMapper.Map(h));
            }

            if (summarySectionFields.TryGetValue(KnownCaseScreenTopics.Image, out var imageFields))
            {
                var i = imageFields.ToArray();
                if (i.Any()) mappedFields.AddRange(_caseViewFieldMapper.Map(i));
            }

            if (mappedFields.Any())
            {
                return new CaseViewSection
                {
                    TopicName = "summary",
                    Fields = mappedFields
                };
            }

            return null;
        }

        async Task<IEnumerable<Section>> ResolveSections(int? screenCriteriaId, string windowName)
        {
            var results = new List<Section>();

            var sectionsInterim = await GetSections(screenCriteriaId, windowName);

            var groups = (from s in sectionsInterim
                          where s.RawFilters.Count() == 1
                                && s.RawFilters.Any(_ => _knownCombinedFilterNames.Contains(_.FilterName))
                                && s.RawFilters.Count(_ => _.FilterValue != null) > 0 && s.TabId != null
                          group s by new { s.TabId, s.TopicBaseName, Count = s.RawFilters.Count() }
                          into g1
                          select new
                          {
                              g1.Key.TabId,
                              g1.Key.TopicBaseName,
                              TopicIds = g1.Select(_ => _.TopicId)
                          }).ToArray();

            var alreadyIncluded = new List<int>();

            var canEfiling = _subjectSecurity.HasAccessToSubject(ApplicationSubject.EFiling);

            foreach (var s in sectionsInterim)
            {
                if (alreadyIncluded.Contains(s.TopicId)) continue;
                if (!canEfiling && s.TopicBaseName == KnownCaseScreenTopics.Efiling) continue;

                if (s.TabId == null)
                {
                    alreadyIncluded.Add(s.TopicId);
                    results.Add(CreateSection(s));
                    continue;
                }

                if (!s.RawFilters.Any())
                {
                    alreadyIncluded.Add(s.TopicId);
                    results.Add(CreateSection(s));
                    continue;
                }

                var group = groups.SingleOrDefault(_ => _.TabId == s.TabId && _.TopicBaseName == s.TopicBaseName);
                if (group != null)
                {
                    var topicIds = group.TopicIds.ToArray();
                    var combinedFilters = sectionsInterim
                                          .Where(_ => topicIds.Contains(_.TopicId))
                                          .SelectMany(t => t.RawFilters.Select(f => f.FilterValue))
                                          .ToArray();

                    var combinedSection = CreateSection(s);
                    combinedSection.TabId = s.TabId;
                    combinedSection.Filters[combinedSection.Filters.Single().Key] = string.Join(",", combinedFilters);
                    combinedSection.IsCombined = topicIds.Length > 1;
                    alreadyIncluded.AddRange(topicIds);

                    results.Add(combinedSection);
                    continue;
                }

                alreadyIncluded.Add(s.TopicId);
                results.Add(CreateSection(s));
            }

            Section CreateSection(dynamic t)
            {
                return new Section
                {
                    TabId = t.TabId,
                    TopicId = t.TopicId,
                    TopicRawName = t.TopicRawName,
                    TopicSuffix = t.TopicSuffix,
                    TabTitle = t.TabTitle,
                    TopicTitle = t.TopicTitle,
                    Filters = ((IEnumerable<TopicControlFilter>)t.RawFilters ?? Enumerable.Empty<TopicControlFilter>()).ToDictionary(k => k.FilterName, v => v.FilterValue)
                };
            }

            return results;
        }

        async Task<Section[]> GetSections(int? screenCriteriaId, string windowName, params string[] sectionsRequired)
        {
            // To avoid N+1 in SubSection population
            // This method can be further optimised to take (WindowName + SectionRequired) array then grouped by window name
            var sectionsInterim = from t in from topic in _dbContext.Set<TopicControl>()
                                            join tab in _dbContext.Set<TabControl>() on topic.TabId equals tab.Id into tabJoin
                                            from tab in tabJoin.DefaultIfEmpty()
                                            join window in _dbContext.Set<WindowControl>() on new { windowName, criteriaId = screenCriteriaId } equals new { windowName = window.Name, criteriaId = (int?)window.CriteriaId } into windowJoin
                                            from window in windowJoin
                                            where topic.WindowControlId == window.Id || (tab != null && tab.WindowControlId == window.Id)
                                            select new
                                            {
                                                Topic = topic,
                                                TabTitle = tab == null ? null : tab.Title,
                                                TabId = tab == null ? (int?)null : tab.Id,
                                                DisplaySequence = tab == null ? topic.RowPosition : tab.DisplaySequence * 10 + topic.RowPosition
                                            }
                                  orderby t.DisplaySequence
                                  select new Section
                                  {
                                      TabId = t.TabId,
                                      TopicId = t.Topic.Id,
                                      TopicRawName = t.Topic.Name,
                                      TopicSuffix = t.Topic.TopicSuffix,
                                      TabTitle = t.TabTitle,
                                      TopicTitle = DbFuncs.GetTranslation(t.Topic.Title, null, t.Topic.TitleTId, _culture),
                                      RawFilters = t.Topic.Filters
                                  };

            return await (sectionsRequired.Any()
                ? (from s in sectionsInterim
                   where sectionsRequired.Contains(s.TopicRawName)
                   select s)
                : sectionsInterim).ToArrayAsync();
        }

        string ResolveProgramId()
        {
            var user = _securityContext.User;
            var profile = user.Profile;
            if (profile != null)
            {
                var attr = profile.ProfileAttributes.SingleOrDefault(_ => _.AttributeType == ProfileAttributeType.DefaultCaseProgram);
                if (attr != null)
                {
                    return attr.Value;
                }
            }

            var siteControl = user.IsExternalUser
                ? SiteControls.CaseProgramForClientAccess
                : SiteControls.CaseScreenDefaultProgram;

            return _dbContext.Set<SiteControl>().Single(sc => sc.ControlId == siteControl).StringValue;
        }
    }

    public class CaseViewSections
    {
        public CaseViewSections()
        {
            Sections = new List<CaseViewSection>();
        }

        public int? ScreenCriterion { get; set; }

        public string ProgramId { get; set; }

        public ICollection<CaseViewSection> Sections { get; set; }
    }

    public class CaseViewSection
    {
        public CaseViewSection()
        {
            Fields = new List<ControllableField>();

            SubTopics = new List<CaseViewSection>();
        }

        public Guid Id { get; set; } = Guid.NewGuid();

        public string Name => string.IsNullOrWhiteSpace(TopicName) ? TopicName : TopicName.Replace("_Component", string.Empty).Replace("Topic", string.Empty).Replace("Case_", "Case").Replace("Name_", "Name").ToCamelCase();

        public string Ref { get; set; }

        public string Title { get; set; }

        public string Suffix { get; set; }

        public IEnumerable<ControllableField> Fields { get; set; }

        [JsonIgnore]
        public string TopicName { get; set; }

        public Dictionary<string, string> Filters { get; set; }

        public IEnumerable<CaseViewSection> SubTopics { get; set; }
    }
}