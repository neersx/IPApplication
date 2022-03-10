using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts.Messages;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Rules;
using Case = InprotechKaizen.Model.Cases.Case;

namespace Inprotech.Web.CaseSupportData
{
    public interface IEventNotesResolver
    {
        IQueryable<CaseEventNotesData> Resolve(int caseId, IEnumerable<int> eventIds);
        IEnumerable<NotesTypeData> EventNoteTypesWithDefault();
        Task<dynamic> Update(CaseEventNotes eventNotes);
        IQueryable<TableCode> GetPredefinedNotes();
        DefaultAdhocInfo GetDefaultAdhocInfo(int caseKey, int eventNo, int cycle);
        Task Update(IEnumerable<CaseEventNotes> eventNotes);
    }

    internal class EventNotesResolver : IEventNotesResolver
    {
        readonly IContextInfo _contextInfo;
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;
        readonly ISiteControlReader _siteControlReader;
        readonly IEventNotesEmailHelper _eventNotesEmailHelper;
        readonly IBus _bus;

        public EventNotesResolver(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, ISecurityContext securityContext,
                                  ISiteControlReader siteControlReader, IContextInfo contextInfo, IEventNotesEmailHelper eventNotesEmailHelper, IBus bus)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _securityContext = securityContext;
            _siteControlReader = siteControlReader;
            _contextInfo = contextInfo;
            _eventNotesEmailHelper = eventNotesEmailHelper;
            _bus = bus;
        }

        public IQueryable<CaseEventNotesData> Resolve(int caseId, IEnumerable<int> eventIds)
        {
            var nullNoteAllowed = true;
            if (_securityContext.User.IsExternalUser)
            {
                nullNoteAllowed = _siteControlReader.Read<bool>(SiteControls.ClientEventText);
            }

            var culture = _preferredCultureResolver.Resolve();
            var defaultNote = GetDefaultNoteTypePreference();
            var results =
                from c in _dbContext.Set<CaseEventText>().Where(_ => _.CaseId == caseId && eventIds.Contains(_.EventId))
                join e in _dbContext.Set<EventText>() on c.EventTextId equals e.Id
                select new CaseEventNotesData
                {
                    EventId = c.EventId,
                    Cycle = c.Cycle,
                    EventText = DbFuncs.GetTranslation(e.Text, null, e.TextTId, culture),
                    NoteType = e.EventNoteType == null ? null : (short?)e.EventNoteType.Id,
                    NoteTypeText = e.EventNoteType == null ? null : DbFuncs.GetTranslation(e.EventNoteType.Description, null, e.EventNoteType.DescriptionTId, culture),
                    LastUpdatedDateTime = e.LogDateTimeStamp,
                    IsExternal = e.EventNoteType == null ? nullNoteAllowed : e.EventNoteType.IsExternal,
                    IsDefault = e.EventNoteTypeId == defaultNote
                };
            if (_securityContext.User.IsExternalUser)
            {
                results = results.Where(_ => _.IsExternal == true);
            }

            results = results.OrderBy(_ => _.NoteTypeText);

            return defaultNote.HasValue ? results.OrderByDescending(_ => _.IsDefault).ThenBy(_ => _.NoteTypeText) : results;
        }

        public async Task Update(IEnumerable<CaseEventNotes> eventNotes)
        {
            var caseEventNotesEnumerable = eventNotes as CaseEventNotes[] ?? eventNotes.ToArray();
            if (!caseEventNotesEnumerable.Any()) return;
            foreach (var eventNote in caseEventNotesEnumerable)
            {
                await Update(eventNote);
            }
        }

        public async Task<dynamic> Update(CaseEventNotes eventNotes)
        {
            var caseEvent = _dbContext.Set<CaseEvent>().SingleOrDefault(_ => _.Id == eventNotes.CaseEventId);

            if (caseEvent == null)
            {
                return new
                {
                    result = "Event Removed"
                };
            }

            EventNotesMailMessage mailMessage = null;
            (EventNotesMailMessage mailMessage, string emailValidationMessage) result = (null, string.Empty);
            var caseEventText = GetEventText(eventNotes, caseEvent);
            if (caseEventText != null)
            {
                if (eventNotes.EventText != caseEventText.EventNote.Text)
                {
                    result = _eventNotesEmailHelper.PrepareEmailMessage(caseEventText, eventNotes.EventText);
                    if (string.IsNullOrEmpty(result.emailValidationMessage))
                        mailMessage = result.mailMessage;
                }
                if (!string.IsNullOrEmpty(eventNotes.EventText))
                {
                    caseEventText.EventNote.Text = eventNotes.EventText;
                }
                else
                {
                    _dbContext.Set<CaseEventText>().Remove(caseEventText);
                    if (!_dbContext.Set<CaseEventText>().Any(cet => cet.EventTextId == caseEventText.EventTextId))
                    {
                        var eventTextRows =
                            _dbContext.Set<EventText>().Where(et => et.Id == caseEventText.EventTextId);
                        foreach (var eventTextRow in eventTextRows)
                            _dbContext.Set<EventText>().Remove(eventTextRow);
                    }
                }
            }
            else if (!string.IsNullOrEmpty(eventNotes.EventText))
            {
                var eventNoteTypeRow =
                    _dbContext.Set<EventNoteType>().FirstOrDefault(et => et.Id == eventNotes.EventNoteType);
                var eventTextRow = new EventText(eventNotes.EventText, eventNoteTypeRow);
                _dbContext.Set<EventText>().Add(eventTextRow);

                var @case =
                    _dbContext.Set<Case>().FirstOrDefault(c => c.Id == caseEvent.CaseId);
                var caseEventTextRow = new CaseEventText(@case, caseEvent.EventNo, caseEvent.Cycle, eventTextRow);
                _dbContext.Set<CaseEventText>().Add(caseEventTextRow);

                result = _eventNotesEmailHelper.PrepareEmailMessage(caseEventTextRow, eventNotes.EventText);
                if (string.IsNullOrEmpty(result.emailValidationMessage))
                    mailMessage = result.mailMessage;
            }
            else
            {
                return null;
            }

            _contextInfo.EnsureUserContext();
            _dbContext.SaveChanges();

            if (!string.IsNullOrEmpty(result.emailValidationMessage))
            {
                return new
                {
                    result = "partialsuccess",
                    message = result.emailValidationMessage
                };
            }

            if (mailMessage != null)
                await _bus.PublishAsync(mailMessage);

            return new
            {
                result = "success"
            };
        }

        public IEnumerable<NotesTypeData> EventNoteTypesWithDefault()
        {
            var notes = EventNoteTypes().ToList();
            if (!_securityContext.User.IsExternalUser || _siteControlReader.Read<bool>(SiteControls.ClientEventText))
            {
                notes.Add(new NotesTypeData());
            }

            var defaultNoteType = GetDefaultNoteTypePreference();
            var defaultNote = notes.FirstOrDefault(_ => _.Code == defaultNoteType);
            if (defaultNote != null)
            {
                defaultNote.IsDefault = true;
            }

            return notes;
        }

        public IQueryable<TableCode> GetPredefinedNotes()
        {
            return _dbContext.Set<TableCode>().Where(_ => _.TableTypeId == (short)ProtectedTableTypes.EventNotes);
        }

        public DefaultAdhocInfo GetDefaultAdhocInfo(int caseKey, int eventNo, int cycle)
        {
            var caseEvent = _dbContext.Set<CaseEvent>()
                                      .Single(ce => ce.CaseId == caseKey && ce.EventNo == eventNo && ce.Cycle == cycle);

            ValidEvent validEvent = null;
            if (caseEvent.CreatedByCriteriaKey.HasValue)
                validEvent = _dbContext.Set<ValidEvent>()
                                       .FirstOrDefault(ve => ve.CriteriaId == caseEvent.CreatedByCriteriaKey.Value && ve.EventId == caseEvent.EventNo);
            var eventDescription = validEvent == null ? caseEvent.Event.Description : validEvent.Description;

            return new DefaultAdhocInfo
            {
                DueDate = caseEvent.EventDueDate,
                Message = eventDescription,
                Case = new Picklists.Case
                {
                    Key = caseEvent.Case.Id,
                    Code = caseEvent.Case.Irn,
                    Value = caseEvent.Case.Title
                }
            };
        }

        IQueryable<NotesTypeData> EventNoteTypes()
        {
            var culture = _preferredCultureResolver.Resolve();
            var result = _dbContext.Set<EventNoteType>().AsQueryable();
            if (_securityContext.User.IsExternalUser)
            {
                result = result.Where(_ => _.IsExternal);
            }

            return result.Select(_ => new NotesTypeData
            {
                Code = _.Id,
                Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture)
            });
        }

        int? GetDefaultNoteTypePreference()
        {
            if (_securityContext.User.IsExternalUser)
            {
                return _dbContext.Set<SettingValues>().Where(sc => sc.SettingId == KnownSettingIds.DefaultEventNoteType && sc.User == null).Select(_ => _.IntegerValue).FirstOrDefault();
            }

            return _dbContext.Set<SettingValues>().Where(sc => sc.SettingId == KnownSettingIds.DefaultEventNoteType && (sc.User == null || sc.User.Id == _securityContext.User.Id)).OrderByDescending(r => r.User.Id).Select(_ => _.IntegerValue).FirstOrDefault();
        }

        public CaseEventText GetEventText(CaseEventNotes eventNotes, CaseEvent caseEvent)
        {
            var eventNoteTypeRow = eventNotes.EventNoteType == null ? null : _dbContext.Set<EventNoteType>().First(et => et.Id == eventNotes.EventNoteType);

            CaseEventText eventText;
            if (eventNoteTypeRow == null)
            {
                eventText = _dbContext.Set<CaseEventText>()
                                      .FirstOrDefault(
                                                      cet =>
                                                          cet.CaseId == caseEvent.CaseId && cet.EventId == caseEvent.EventNo && cet.Cycle == caseEvent.Cycle &&
                                                          cet.EventNote.EventNoteType == null);
            }
            else
            {
                eventText = _dbContext.Set<CaseEventText>()
                                      .FirstOrDefault(
                                                      cet =>
                                                          cet.CaseId == caseEvent.CaseId && cet.EventId == caseEvent.EventNo && cet.Cycle == caseEvent.Cycle
                                                          && cet.EventNote.EventNoteType != null && cet.EventNote.EventNoteType.Id == eventNoteTypeRow.Id);
            }

            return eventText;
        }

    }
}