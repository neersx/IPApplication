using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json;

namespace Inprotech.Web.Accounting.Time
{
    public interface IRecentCasesProvider
    {
        Task<IEnumerable<RecentCase>> ForTimesheet(int staffId, DateTime? until = null, int? nameKey = null, string search = null, int take = 10);
    }

    public class RecentCasesProvider : IRecentCasesProvider
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCulture;
        readonly IDisplayFormattedName _displayFormattedName;

        public RecentCasesProvider(IDbContext dbContext, IPreferredCultureResolver preferredCulture, IDisplayFormattedName displayFormattedName)
        {
            _dbContext = dbContext;
            _preferredCulture = preferredCulture;
            _displayFormattedName = displayFormattedName;
        }

        public async Task<IEnumerable<RecentCase>> ForTimesheet(int staffId, DateTime? until = null, int? nameKey = null, string search = null, int take = 10)
        {
            if (!until.HasValue)
            {
                until = DateTime.Today;
            }

            var hasInstructor = nameKey.HasValue;
            var hasSearch = !string.IsNullOrEmpty(search);
            var culture = _preferredCulture.Resolve();

            var instructors = from n in _dbContext.Set<CaseName>()
                              where n.NameTypeId == KnownNameTypes.Instructor
                              select n;

            var diaries = _dbContext.Set<Diary>().Where(d => d.EmployeeNo == staffId).Where(d => d.CaseId != null && d.FinishTime != null && d.FinishTime < until);

            var recentCaseIds = from diary in diaries
                                group diary by diary.CaseId
                                into diariesByCase
                                let maxDate = diariesByCase.Max(d => d.FinishTime)
                                select new
                                {
                                    CaseId = diariesByCase.Key,
                                    LastUsedDate = maxDate
                                };

            var recentCases = await (from c in _dbContext.Set<Case>()
                                     join rc in recentCaseIds on c.Id equals rc.CaseId
                                     join cn in instructors on c.Id equals cn.CaseId into instr
                                     from cn in instr.DefaultIfEmpty(null)
                                     where (!hasInstructor || cn != null && cn.NameId == nameKey) && (!hasSearch || (c.Irn != null && c.Irn.Contains(search) || (c.Title != null && c.Title.Contains(search))))
                                     orderby rc.LastUsedDate descending
                                     select new RecentCase
                                     {
                                         CaseKey = c.Id,
                                         CaseReference = c.Irn,
                                         Title = DbFuncs.GetTranslation(c.Title, null, c.TitleTId, culture),
                                         InstructorNameKey = cn != null ? cn.NameId : (int?) null
                                     }).AsNoTracking()
                                       .Take(take)
                                       .ToArrayAsync();

            if (recentCases.Length <= 0) return Enumerable.Empty<RecentCase>();

            await FormatNamesForDisplay(recentCases);
            return recentCases;
        }

        async Task FormatNamesForDisplay(ICollection<RecentCase> list)
        {
            var instructorIds = list.Where(_ => _.InstructorNameKey.HasValue).Select(_ => _.InstructorNameKey.Value).Distinct().ToArray();
            var formattedNames = await _displayFormattedName.For(instructorIds);

            foreach (var recentCase in list)
            {
                if (!recentCase.InstructorNameKey.HasValue)
                    continue;

                recentCase.InstructorName = formattedNames.TryGetValue(recentCase.InstructorNameKey.Value, out var instructorName) ? instructorName?.Name : string.Empty;
            }
        }
    }

    public class RecentCase
    {
        public int CaseKey { get; set; }
        public string CaseReference { get; set; }
        public string Title { get; set; }
        public int? InstructorNameKey { get; set; }
        public string InstructorName { get; set; }

        [JsonIgnore]
        public DateTime LastUsed { get; set; }

        public Picklists.Case ToCase()
        {
            return new Picklists.Case
            {
                Key = CaseKey,
                Code = CaseReference,
                Value = Title,
                InstructorName = InstructorName,
                InstructorNameId = InstructorNameKey
            };
        }
    }
}