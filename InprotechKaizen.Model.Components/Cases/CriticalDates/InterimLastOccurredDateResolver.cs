using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Cases.CriticalDates
{
    public interface IInterimLastOccurredDateResolver
    {
        Task<IEnumerable<InterimCriticalDate>> Resolve(User user, string culture, CriticalDatesMetadata metadata);
    }

    public class InterimLastOccurredDateResolver : IInterimLastOccurredDateResolver
    {
        const string LastOccurred = "L";

        readonly IDbContext _dbContext;

        public InterimLastOccurredDateResolver(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<IEnumerable<InterimCriticalDate>> Resolve(User user, string culture, CriticalDatesMetadata metadata)
        {
            if (user == null) throw new ArgumentNullException(nameof(user));
            if (metadata == null) throw new ArgumentNullException(nameof(metadata));

            if (user.IsExternalUser) return new InterimCriticalDate[0];

            var excludeEvents = new[]
            {
                (int) KnownEvents.InstructionsReceivedDateForNewCase,
                (int) KnownEvents.DateOfLastChange,
                (int) KnownEvents.DateOfEntry
            };

            var importanceLevelForStringComparison = metadata.ImportanceLevel.ToString();

            var occurredEvents = await (from ce in _dbContext.Set<CaseEvent>()
                                        join ec in _dbContext.Set<ValidEvent>() on new {EventId = ce.EventNo, CriteriaId = ce.CreatedByCriteriaKey} equals new {ec.EventId, CriteriaId = (int?) ec.CriteriaId} into ec1
                                        from ec in ec1
                                        where ce.EventDate != null
                                              && !excludeEvents.Contains(ce.EventNo)
                                              && string.Compare(ec.ImportanceLevel, importanceLevelForStringComparison) >= 0
                                              && ce.CaseId == metadata.CaseId
                                        select new OccurredEvent
                                        {
                                            LastModified = ce.LastModified,
                                            EventDate = ce.EventDate,
                                            ImportanceLevel = ec.ImportanceLevel == null ? "0" : ec.ImportanceLevel,
                                            DisplaySequence = ec.DisplaySequence,
                                            EventId = ec.EventId,
                                            CriteriaId = ec.CriteriaId,
                                            EventDescription = DbFuncs.GetTranslation(ec.Description, null, ec.DescriptionTId, culture),
                                            EventDefinition = DbFuncs.GetTranslation(ec.Event.Notes, null, ec.Event.NotesTId, culture)
                                        })
                .ToArrayAsync();

            var latest = occurredEvents.OrderByDescending(_ => _.Weighting).FirstOrDefault();

            /* result set does not suppress already resolved critical dates in the first interim result set */

            return latest == null
                ? new InterimCriticalDate[0]
                : new[]
                {
                    new InterimCriticalDate
                    {
                        CaseKey = metadata.CaseId,
                        EventDescription = latest.EventDescription,
                        EventDefinition = latest.EventDefinition,
                        DisplayDate = latest.EventDate,
                        OfficialNumber = null,
                        CountryCode = null,
                        IsLastOccurredEvent = true,
                        IsNextDueEvent = false,
                        IsCPARenewalDate = false,
                        DisplaySequence = latest.DisplaySequence,
                        RenewalYear = null,
                        RowKey = LastOccurred,
                        EventKey = latest.EventId,
                        CountryKey = null,
                        IsPriorityEvent = false,
                        NumberTypeCode = null,
                        IsOccurred = true
                    }
                };
        }

        public class OccurredEvent
        {
            public DateTime? LastModified { get; set; }
            public DateTime? EventDate { get; set; }
            public string ImportanceLevel { get; set; }
            public short? DisplaySequence { get; set; }
            public int EventId { get; set; }
            public int CriteriaId { get; set; }
            public string EventDescription { get; set; }
            public string EventDefinition { get; set; }

            public string Weighting => LastModified.ToSql121() +
                                       EventDate.ToSql121()
                                       + ImportanceLevel.PadLeft(2, ' ')
                                       + DisplaySequence.PadRight(11)
                                       + EventId.PadRight(11)
                                       + CriteriaId.PadRight(11);
        }
    }
}