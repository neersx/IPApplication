using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Components.Cases.Screens;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json;

namespace InprotechKaizen.Model.Components.Names.Screens
{
    public interface INameViewSectionsResolver
    {
        Task<NameViewSections> Resolve(int nameId, string programId = null, string name = KnownNameScreenWindowNames.NameDetails);
    }

    public class NameViewSectionsResolver : INameViewSectionsResolver
    {
        readonly ICriteriaReader _criteriaReader;
        readonly string _culture;
        readonly IDbContext _dbContext;
        readonly ISubjectSecurityProvider _subjectSecurity;
        readonly INameViewSectionsTaskSecurity _nameViewSectionsTaskSecurity;
        readonly IDefaultNameTypeClassification _defaultNameTypeClassification;

        public NameViewSectionsResolver(IDbContext dbContext, 
                                        ICriteriaReader criteriaReader, 
                                        IPreferredCultureResolver preferredCultureResolver, 
                                        ISubjectSecurityProvider subjectSecurity, 
                                        INameViewSectionsTaskSecurity nameViewSectionsTaskSecurity,
                                        IDefaultNameTypeClassification defaultNameTypeClassification)
        {
            _dbContext = dbContext;
            _criteriaReader = criteriaReader;
            _subjectSecurity = subjectSecurity;
            _nameViewSectionsTaskSecurity = nameViewSectionsTaskSecurity;
            _defaultNameTypeClassification = defaultNameTypeClassification;
            _culture = preferredCultureResolver.Resolve();
        }

        public async Task<NameViewSections> Resolve(int nameId, string programId = null, string name = KnownNameScreenWindowNames.NameDetails)
        {
            var selectedNameTypeClassification = _defaultNameTypeClassification.FetchNameTypeClassification(null, nameId).Where(v => v.IsSelected && v.NameTypeKey != KnownNameTypes.UnrestrictedNameTypes).ToList();
            if (selectedNameTypeClassification.Any() && selectedNameTypeClassification.All(v => v.IsCrmOnly))
            {
                programId = KnownNamePrograms.NameCrm;
            }

            var result = new NameViewSections { ProgramId = programId };

            if (!_criteriaReader.TryGetNameScreenCriteriaId(nameId, result.ProgramId, out var screenCriteriaId))
            {
                return result;
            }

            var windowName = name ?? KnownNameScreenWindowNames.NameDetails;

            var otherSections = (from t in await ResolveSections(screenCriteriaId, windowName)
                                 select new NameViewSection
                                 {
                                     TopicName = t.TopicBaseName,
                                     Title = t.Title,
                                     Suffix = t.TopicSuffix,
                                     Filters = t.Filters,
                                     Ref = t.Ref
                                 }).ToList();

            result.ScreenNameCriteria = screenCriteriaId;

            result.Sections.AddRange(_nameViewSectionsTaskSecurity.Filter(otherSections));

            return result;
        }

        async Task<IEnumerable<Section>> ResolveSections(int? screenCriteriaId, string windowName)
        {
            var results = new List<Section>();

            var canSupplierDetails = _subjectSecurity.HasAccessToSubject(ApplicationSubject.SupplierDetails);
            var canTrustAccounting = _subjectSecurity.HasAccessToSubject(ApplicationSubject.TrustAccounting);

            var sectionsInterim = await GetNameSections(screenCriteriaId, windowName);

            var alreadyIncluded = new List<int>();

            foreach (var s in sectionsInterim)
            {
                if (alreadyIncluded.Contains(s.TopicId)) continue;
                if (!canSupplierDetails && s.TopicBaseName == KnownNameScreenTopics.SupplierDetails) continue;
                if (!canTrustAccounting && s.TopicBaseName == KnownNameScreenTopics.TrustAccounting) continue;

                if (s.TabId == null)
                {
                    alreadyIncluded.Add(s.TopicId);
                    results.Add(CreateSection(s));
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

        async Task<Section[]> GetNameSections(int? screenNameCriteriaId, string windowName, params string[] sectionsRequired)
        {
            var sectionsInterim = from t in from topic in _dbContext.Set<TopicControl>()
                                            join tab in _dbContext.Set<TabControl>() on topic.TabId equals tab.Id into tabJoin
                                            from tab in tabJoin.DefaultIfEmpty()
                                            join window in _dbContext.Set<WindowControl>() on new { windowName, screenNameCriteriaId } equals new { windowName = window.Name, screenNameCriteriaId = window.NameCriteriaId } into windowJoin
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
    }

    public class NameViewSections
    {
        public NameViewSections()
        {
            Sections = new List<NameViewSection>();
        }

        public int? ScreenNameCriteria { get; set; }

        public string ProgramId { get; set; }

        public ICollection<NameViewSection> Sections { get; set; }
    }

    public class NameViewSection
    {
        public NameViewSection()
        {
            Fields = new List<ControllableField>();

            SubTopics = new List<NameViewSection>();
        }

        public Guid Id { get; set; } = Guid.NewGuid();

        public string Name => string.IsNullOrWhiteSpace(TopicName) ? TopicName : TopicName.Replace("_Component", string.Empty).Replace("Topic", string.Empty).Replace("Name_", "Name").Replace("Name_", "Name").ToCamelCase();

        public string Ref { get; set; }

        public string Title { get; set; }

        public string Suffix { get; set; }

        public IEnumerable<ControllableField> Fields { get; set; }

        [JsonIgnore]
        public string TopicName { get; set; }

        public Dictionary<string, string> Filters { get; set; }

        public IEnumerable<NameViewSection> SubTopics { get; set; }
    }
}
