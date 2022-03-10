using System;
using System.Data.Entity;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Policing;
using Case = InprotechKaizen.Model.Cases.Case;
using DateOfLaw = InprotechKaizen.Model.ValidCombinations.DateOfLaw;
using Office = InprotechKaizen.Model.Cases.Office;

namespace Inprotech.Web.Policing
{
    public interface IPolicingRequestReader
    {
        PolicingRequestItem FetchAndConvert(int requestId);

        PolicingRequest Fetch(int requestId);

        IQueryable<PolicingRequest> FetchAll(int[] requestIds = null);

        bool IsTitleUnique(string title, int? requestId = null);
    }

    public class PolicingRequestReader : IPolicingRequestReader
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IPolicingCharacteristicsService _policingCharacteristicsService;
        readonly IFormatDateOfLaw _formatDateOfLaw;

        public PolicingRequestReader(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, IPolicingCharacteristicsService policingCharacteristicsService, IFormatDateOfLaw formatDateOfLaw)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _policingCharacteristicsService = policingCharacteristicsService;
            _formatDateOfLaw = formatDateOfLaw;
        }

        public PolicingRequest Fetch(int requestId)
        {
            return _dbContext.Set<PolicingRequest>().SingleOrDefault(_ => _.RequestId == requestId);
        }

        public IQueryable<PolicingRequest> FetchAll(int[] requestIds = null)
        {
            var allrecords = from r in _dbContext.Set<PolicingRequest>()
                             where r.IsSystemGenerated != 1
                             select r;

            if (requestIds != null)
                allrecords = allrecords.Where(_ => requestIds.Contains(_.RequestId));

            return allrecords;
        }

        public bool IsTitleUnique(string title, int? requestId = null)
        {
            return !_dbContext.Set<PolicingRequest>().Any(_ => _.Name == title && (!requestId.HasValue || (requestId.HasValue && _.RequestId != requestId)));
        }

        public PolicingRequestItem FetchAndConvert(int requestId)
        {
            var culture = _preferredCultureResolver.Resolve();

            var policing = _dbContext.Set<PolicingRequest>()
                                     .Include(p => p.NameRecord);

            var cases = _dbContext.Set<Case>();
            var offices = _dbContext.Set<Office>();
            var dateofLaw = _dbContext.Set<DateOfLaw>();

            var requestItem = (from p in policing
                               where p.RequestId == requestId
                               join c in cases on p.Irn equals c.Irn into tempCase
                               from tempc in tempCase.DefaultIfEmpty()
                               join o in offices on p.Office equals o.Id.ToString() into tempOffice
                               from tempo in tempOffice.DefaultIfEmpty()
                               join d in dateofLaw on new {date = p.DateOfLaw, country = p.Jurisdiction, propt = p.PropertyType} equals new {date = (DateTime?) d.Date, country = d.CountryId, propt = d.PropertyTypeId} into tempDateOfLaw
                               from tempD in tempDateOfLaw.DefaultIfEmpty()
                               select new PolicingRequestItem
                               {
                                   RequestId = p.RequestId,
                                   Title = DbFuncs.GetTranslation(p.Name, null, p.PolicingNameTId, culture),
                                   Notes = DbFuncs.GetTranslation(null, p.Notes, p.NotesTId, culture),
                                   DateLetters = p.LetterDate,
                                   DueDateOnly = p.IsDueDateOnly != null && p.IsDueDateOnly == 1,
                                   EndDate = p.UntilDate,
                                   ForDays = p.NoOfDays,
                                   StartDate = p.FromDate,
                                   Options = new PolicingRequestItem.Flags
                                   {
                                       AdhocReminders = p.IsAdhocReminder != null && p.IsAdhocReminder == 1,
                                       Documents = p.IsLetter != null && p.IsLetter == 1,
                                       Update = p.IsUpdate != null && p.IsUpdate == 1,
                                       RecalculateCriteria = p.IsRecalculateCriteria != null && p.IsRecalculateCriteria == 1,
                                       RecalculateDueDates = p.IsRecalculateDueDate != null && p.IsRecalculateDueDate == 1,
                                       RecalculateReminderDates = p.IsRecalculateReminder != null && p.IsRecalculateReminder == 1,
                                       Reminders = p.IsReminder != null && p.IsReminder == 1,
                                       RecalculateEventDates = p.IsRecalculateEventDate ?? false,
                                       EmailReminders = p.IsEmailFlag ?? false
                                   },
                                   Attributes = new CaseAttributes
                                   {
                                       CaseReference = p.Irn == null
                                           ? null
                                           : tempc == null
                                               ? new PicklistModel<int>
                                               {
                                                   Key = 0,
                                                   Code = p.Irn,
                                                   Value = "NOTFOUND"
                                               }
                                               : new PicklistModel<int>
                                               {
                                                   Key = tempc.Id,
                                                   Code = tempc.Irn,
                                                   Value = tempc.Title
                                               },
                                       NameType = p.NameType == null
                                           ? null
                                           : new PicklistModel<int>
                                           {
                                               Key = p.NameTypeRecord.Id,
                                               Code = p.NameTypeRecord.NameTypeCode,
                                               Value = DbFuncs.GetTranslation(p.NameTypeRecord.Name, null, p.NameTypeRecord.NameTId, culture)
                                           },
                                       Event = p.Event == null
                                           ? null
                                           : new PicklistModel<int>
                                           {
                                               Key = p.Event.Id,
                                               Code = p.Event.Id.ToString(),
                                               Value = DbFuncs.GetTranslation(p.Event.Description, null, p.Event.DescriptionTId, culture)
                                           },
                                       CaseType = p.CaseTypeRecord == null
                                           ? null
                                           : new PicklistModel<string>
                                           {
                                               Key = p.CaseTypeRecord.Code,
                                               Code = p.CaseTypeRecord.Code,
                                               Value = p.CaseTypeRecord.Name
                                           },
                                       Jurisdiction = p.JurisdictionRecord == null
                                           ? null
                                           : new PicklistModel<string>
                                           {
                                               Key = p.JurisdictionRecord.Id,
                                               Code = p.JurisdictionRecord.Id,
                                               Value = DbFuncs.GetTranslation(p.JurisdictionRecord.Name, null, p.JurisdictionRecord.NameTId, culture)
                                           },
                                       Office = tempo == null
                                           ? null
                                           : new PicklistModel<int>
                                           {
                                               Key = tempo.Id,
                                               Code = tempo.Id.ToString(),
                                               Value = DbFuncs.GetTranslation(tempo.Name, null, tempo.NameTId, culture)
                                           },
                                       ExcludeAction = p.ExcludeAction != null && p.ExcludeAction == 1,
                                       ExcludeJurisdiction = p.ExcludeJurisdiction != null && p.ExcludeJurisdiction == 1,
                                       ExcludeProperty = p.ExcludeProperty != null && p.ExcludeProperty == 1,
                                       NameRecord = p.NameRecord,
                                       DateOfLawRecord = tempD,
                                       RawCharacteristics = new InprotechKaizen.Model.Components.Configuration.Rules.Characteristics.Characteristics
                                       {
                                           Action = p.Action,
                                           CaseCategory = p.CaseCategory,
                                           SubType = p.SubType,
                                           PropertyType = p.PropertyType,
                                           Jurisdiction = p.Jurisdiction,
                                           CaseType = p.CaseType
                                       }
                                   }
                               }).FirstOrDefault();

            if (requestItem == null)
                return null;

            requestItem.Attributes.DateOfLaw = requestItem.Attributes.DateOfLawRecord == null
                ? null
                : new
                {
                    Key = _formatDateOfLaw.AsId(requestItem.Attributes.DateOfLawRecord.Date),
                    Value = _formatDateOfLaw.Format(requestItem.Attributes.DateOfLawRecord.Date),
                    requestItem.Attributes.DateOfLawRecord.Date
                };

            requestItem.Attributes.Name = requestItem.Attributes.NameRecord == null
                ? null
                : new
                {
                    Key = requestItem.Attributes.NameRecord.Id,
                    Code = requestItem.Attributes.NameRecord.NameCode,
                    DisplayName = requestItem.Attributes.NameRecord.Formatted()
                };

            var validCharacteristics = _policingCharacteristicsService.GetValidatedCharacteristics(requestItem.Attributes.RawCharacteristics);

            requestItem.Attributes.PropertyType = validCharacteristics.PropertyType;
            requestItem.Attributes.CaseCategory = validCharacteristics.CaseCategory;
            requestItem.Attributes.SubType = validCharacteristics.SubType;
            requestItem.Attributes.Action = validCharacteristics.Action;

            return requestItem;
        }
    }
}